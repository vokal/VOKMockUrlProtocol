//
//  VOKMockUrlProtocol.m
//
//  Created by Isaac Greenspan on 7/31/14.
//  Copyright (c) 2014 VOKAL Interactive. All rights reserved.
//

#import "VOKMockUrlProtocol.h"

#import <HTTPStatusCodes.h>
#import <HTTPMethods.h>

#ifndef DLOG
    // Define DLOG to log to NSLog when DEBUG is defined
    #ifdef DEBUG
        #define DLOG(...) NSLog(@"%s:%d %@", __PRETTY_FUNCTION__, __LINE__, [NSString stringWithFormat:__VA_ARGS__])
    #else
        #define DLOG(...) do {} while (NO)
    #endif
#endif

static NSString *const MockDataDirectory = @"VOKMockData";

#pragma mark -

@interface VOKMockUrlProtocolResponseAndDataContainer : NSObject

@property (nonatomic, strong) NSHTTPURLResponse *response;
@property (nonatomic, strong) NSData *data;

+ (instancetype)containerWithResponse:(NSHTTPURLResponse *)response data:(NSData *)data;

@end

#pragma mark -

@interface VOKMockUrlProtocol() <NSStreamDelegate>
@property (nonatomic) NSMutableData *streamData;
@property (nonatomic) NSString *bodyString;

@end

@implementation VOKMockUrlProtocol

+ (BOOL)canInitWithRequest:(NSURLRequest *)request
{
    return YES;
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request
{
    return request;
}

- (void)stopLoading
{
    // Must be overridden, but does nothing here.
}

- (void)startLoading
{
    VOKMockUrlProtocolResponseAndDataContainer *container = [self responseAndData];
    
    [[self client] URLProtocol:self
            didReceiveResponse:container.response
            cacheStoragePolicy:NSURLCacheStorageNotAllowed];
    [[self client] URLProtocol:self
                   didLoadData:container.data];
    [[self client] URLProtocolDidFinishLoading:self];
}

#pragma mark - Helpers

/**
 *  Define a resource name based on the HTTP method, the full path, the query string, and possibly the body of the
 *  current request.
 *
 *  @return The file name for mock data corresponding to our request.
 */
- (NSString *)resourceName
{
    NSMutableString *resourceName = [self.request.HTTPMethod mutableCopy];
    [resourceName appendFormat:@"|%@", self.request.URL.path];
    if (self.request.URL.query) {
        [resourceName appendFormat:@"?%@", self.request.URL.query];
    }
    if ([kHTTPMethodPost isEqualToString:self.request.HTTPMethod]
        || [kHTTPMethodPatch isEqualToString:self.request.HTTPMethod]
        || [kHTTPMethodPut isEqualToString:self.request.HTTPMethod]) {
        if (self.request.HTTPBody) {
            //Easy!
            [resourceName appendFormat:@"|%@",
             [[NSString alloc] initWithData:self.request.HTTPBody
                                   encoding:NSUTF8StringEncoding]];
        } else {
            //*shakes fist* APPPLLLLLLLEEEE
            [self readDataFromStream:self.request.HTTPBodyStream];
            
            //Let the stream actually get read in.
            VOKIdleFor(0.5);
            
            [resourceName appendString:@"|"];
            if (self.bodyString) {
                //Percent escape in case JSON
                [resourceName appendString:[self.bodyString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
            }
        }
    }
    
    NSRange fullStringRange = NSMakeRange(0, [resourceName length]);
    
    // Replace any colons with hyphens
    [resourceName replaceOccurrencesOfString:@":"
                                  withString:@"-"
                                     options:0
                                       range:fullStringRange];
    
    // Replace any slashes with hyphens.
    [resourceName replaceOccurrencesOfString:@"/"
                                  withString:@"-"
                                     options:0
                                       range:fullStringRange];
    
    return resourceName;
}

#pragma mark Stream Handling

void VOKIdleFor(NSTimeInterval idleInterval) {
    NSRunLoop *theRL = [NSRunLoop currentRunLoop];
    NSDate *stopDate = [NSDate dateWithTimeIntervalSinceNow:idleInterval];
    while ([theRL runMode:NSDefaultRunLoopMode beforeDate:stopDate]
           && [stopDate compare:[NSDate date]] == NSOrderedDescending);
}

- (void)readDataFromStream:(NSInputStream *)bodyStream
{
    [bodyStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    bodyStream.delegate = self;
    [bodyStream open];
}

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode
{
    if (!self.streamData) {
        self.streamData = [NSMutableData data];
    }
    
    switch (eventCode) {
        case NSStreamEventHasBytesAvailable: {
            uint8_t buffer[1024];
            int length = 0;
            
            length = [(NSInputStream *)aStream read:buffer maxLength:1024];
            if (length > 0) {
                [self.streamData appendBytes:buffer length:length];
            } 
        }   break;
        case NSStreamEventEndEncountered: 
            self.bodyString = [[NSString alloc] initWithBytes:self.streamData.bytes
                                                       length:self.streamData.length
                                                     encoding:NSUTF8StringEncoding];
            break;
        default:
            break;
    }
}

#pragma mark Mock Response

/**
 *  Construct an NSHTTPURLResponse and NSData based on a complete HTTP response, as a string.
 *
 *  @param httpResponseString The complete HTTP response, as a string
 *
 *  @return A container object containing the response and data.
 */
- (VOKMockUrlProtocolResponseAndDataContainer *)responseAndDataFromHTTPResponseString:(NSString *)httpResponseString
{
    NSError *regexError;
    NSRegularExpression *statusHeadersBodyRegex = [NSRegularExpression
                                                   regularExpressionWithPattern:@"^([^\r\n]*)[\r\n](.*)[\r\n]{2}(.*)$"
                                                   options:NSRegularExpressionDotMatchesLineSeparators
                                                   error:&regexError];
    if (!statusHeadersBodyRegex) {
        DLOG(@"regex error: %@", regexError);
        return nil;
    }
    NSTextCheckingResult *regexResult = [statusHeadersBodyRegex
                                         firstMatchInString:httpResponseString
                                         options:0
                                         range:NSMakeRange(0, [httpResponseString length])];
    NSString *statusLine = [httpResponseString substringWithRange:[regexResult rangeAtIndex:1]];
    NSString *headerLines = [httpResponseString substringWithRange:[regexResult rangeAtIndex:2]];
    NSString *body = [httpResponseString substringWithRange:[regexResult rangeAtIndex:3]];
    
    // Parse the status line.
    NSArray *statusParts = [statusLine componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *httpVersion = [statusParts firstObject];
    NSInteger statusCode = 0;
    if ([statusParts count] > 1) {
        statusCode = [statusParts[1] integerValue];
    }
    
    
    NSMutableArray *headers = [[headerLines componentsSeparatedByString:@"\n"] mutableCopy];
    
    // Parse the headers into a dictionary.
    NSRegularExpression *headerRegex = [NSRegularExpression
                                        regularExpressionWithPattern:@"^([^:]*):(.*)$"
                                        options:NSRegularExpressionAnchorsMatchLines
                                        error:&regexError];
    if (!headerRegex) {
        DLOG(@"header regex error: %@", regexError);
        return nil;
    }
    NSMutableDictionary *headerDict = [NSMutableDictionary dictionaryWithCapacity:[headers count] - 1];
    [headerRegex
     enumerateMatchesInString:headerLines
     options:0
     range:NSMakeRange(0, [headerLines length])
     usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
         NSString *headerName = [headerLines substringWithRange:[result rangeAtIndex:1]];
         NSString *headerValue = [headerLines substringWithRange:[result rangeAtIndex:2]];
         if (headerName && headerValue) {
             headerDict[headerName] = headerValue;
         }
     }];
    
    // Get the body data.
    NSData *data = [body dataUsingEncoding:NSUTF8StringEncoding];
    
    // Return the response and data.
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:self.request.URL
                                                              statusCode:statusCode
                                                             HTTPVersion:httpVersion
                                                            headerFields:headerDict];
    return [VOKMockUrlProtocolResponseAndDataContainer containerWithResponse:response
                                                                        data:data];
}

/**
 *  Get the NSHTTPURLResponse and NSData for the current request.
 *
 *  @return A container object containing the response and data.
 */
- (VOKMockUrlProtocolResponseAndDataContainer *)responseAndData
{
    NSString *resourceName = [self resourceName];
    NSString *filePath;
    
    // First, look for a complete-HTTP-response file.
    filePath = [[NSBundle bundleForClass:[self class]] pathForResource:resourceName
                                                                ofType:@"http"
                                                           inDirectory:MockDataDirectory];
    NSString *fileContents = [NSString stringWithContentsOfFile:filePath
                                                       encoding:NSUTF8StringEncoding
                                                          error:NULL];
    if (fileContents) {
        // We've got a complete-HTTP-response file, so parse it.
        DLOG(@"Serving mock data from complete HTTP response file (%@)", filePath);
        return [self responseAndDataFromHTTPResponseString:fileContents];
    }
    
    // Otherwise, look for a JSON data file.
    filePath = [[NSBundle bundleForClass:[self class]] pathForResource:resourceName
                                                                ofType:@"json"
                                                           inDirectory:MockDataDirectory];
    NSData *data = [NSData dataWithContentsOfFile:filePath];
    if (data) {
        // We've got a JSON data file, so send it.
        DLOG(@"Serving mock data from JSON response body file (%@)", filePath);
        NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:self.request.URL
                                                                  statusCode:kHTTPStatusCodeOK
                                                                 HTTPVersion:@"HTTP/1.1"
                                                                headerFields:@{
                                                                               @"Content-type": @"text/json",
                                                                               }];
        return [VOKMockUrlProtocolResponseAndDataContainer containerWithResponse:response
                                                                            data:data];
    }
    
    // Otherwise, failure.
    DLOG(@"failed to get mock data for resource name: \"%@\"", resourceName);
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:self.request.URL
                                                              statusCode:kHTTPStatusCodeNotFound
                                                             HTTPVersion:@"HTTP/1.1"
                                                            headerFields:nil];
    return [VOKMockUrlProtocolResponseAndDataContainer containerWithResponse:response
                                                                        data:nil];
}

@end

#pragma mark -

@implementation VOKMockUrlProtocolResponseAndDataContainer

+ (instancetype)containerWithResponse:(NSHTTPURLResponse *)response data:(NSData *)data
{
    VOKMockUrlProtocolResponseAndDataContainer *container = [[self alloc] init];
    container.response = response;
    container.data = data;
    return container;
}

@end
