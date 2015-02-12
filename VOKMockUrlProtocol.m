//
//  VOKMockUrlProtocol.m
//
//  Created by Isaac Greenspan on 7/31/14.
//  Copyright (c) 2014 Vokal. All rights reserved.
//

#import "VOKMockUrlProtocol.h"

#import <CommonCrypto/CommonDigest.h>

#import <HTTPStatusCodes.h>
#import <HTTPMethods.h>
#import <VOKBenkode.h>
#import <sys/syslimits.h>

#ifndef DLOG
    // Define DLOG to log to NSLog when DEBUG is defined
    #ifdef DEBUG
        #define DLOG(...) NSLog(@"%s:%d %@", __PRETTY_FUNCTION__, __LINE__, [NSString stringWithFormat:__VA_ARGS__])
    #else
        #define DLOG(...) do {} while (NO)
    #endif
#endif

static NSString *const MockDataDirectory = @"VOKMockData";

static NSString *const AppendSeparatorFormat = @"|%@";

static NSString *const HTTPHeaderContentType = @"Content-type";
static NSString *const HTTPHeaderContentTypeFormUrlencoded = @"application/x-www-form-urlencoded";
static NSString *const HTTPHeaderContentTypeJson = @"application/json";

//255 HFS+ filename limit - 5 for file extension suffix
static NSInteger const MaxBaseFilenameLength = NAME_MAX - 5;

#pragma mark -

@interface VOKMockUrlProtocolResponseAndDataContainer : NSObject

@property (nonatomic, strong) NSHTTPURLResponse *response;
@property (nonatomic, strong) NSData *data;

+ (instancetype)containerWithResponse:(NSHTTPURLResponse *)response data:(NSData *)data;

@end

#pragma mark -

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
 *  Define one or more resource names based on the HTTP method, the full path, the query string, and possibly the body 
 *  of the current request.
 *
 *  @return An array of potential file names for mock data corresponding to our request.
 */
- (NSArray *)resourceNames
{
    // Start with the HTTP method.
    NSMutableString *resourceName = [self.request.HTTPMethod mutableCopy];
    
    // Append separator and the path.
    [resourceName appendFormat:AppendSeparatorFormat, self.request.URL.path];
    
    NSMutableArray *resourceNames = [NSMutableArray arrayWithObject:resourceName];
    
    // If there's a query string, append ? and the query string.
    if (self.request.URL.query) {
        NSString *queryFormat = @"?%@";
        //take the SHA-256 hash of the query, just in case things get too long later
        NSData *queryData = [self.request.URL.query dataUsingEncoding:NSUTF8StringEncoding];
        NSString *hashedQuery = [self sha256HexOfData:queryData];
        [resourceNames addObject:[[resourceName stringByAppendingFormat:queryFormat, hashedQuery] mutableCopy]];
        
        [resourceName appendFormat:queryFormat, self.request.URL.query];
    }
    
    // If the request is one that can have a body...
    if ([kHTTPMethodPost isEqualToString:self.request.HTTPMethod]
        || [kHTTPMethodPatch isEqualToString:self.request.HTTPMethod]
        || [kHTTPMethodPut isEqualToString:self.request.HTTPMethod]) {
        NSData *bodyData = [self bodyDataFromRequest:self.request];
        
        // Compute the SHA-256 of the body and generate a resource name from that.
        NSString *bodyHash = [self sha256HexOfData:bodyData];
        
        NSString *contentType = [self.request valueForHTTPHeaderField:HTTPHeaderContentType];
        
        NSString *bodyString;
        if ([contentType hasPrefix:HTTPHeaderContentTypeFormUrlencoded]) {
            // If it's form-URL-encoded, generate a resource name by appending the body as a string.
            bodyString = [[NSString alloc] initWithData:bodyData encoding:NSUTF8StringEncoding];
            
        } else if ([contentType hasPrefix:HTTPHeaderContentTypeJson]) {
            // Otherwise, if it's JSON, generate a resource name by bencoding the JSON datastructure and
            // percent-escaping the resulting string.
            NSData *bencoded = [VOKBenkode encode:
                                [NSJSONSerialization JSONObjectWithData:bodyData
                                                                options:NSJSONReadingAllowFragments
                                                                  error:NULL]];
            if (bencoded) {
                bodyString = [[NSString alloc] initWithData:bencoded encoding:NSUTF8StringEncoding];
                bodyString = [bodyString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            }
        }
        
        NSArray *resourceNamesWithoutBody = [resourceNames copy];
        [resourceNames removeAllObjects];
        for (NSMutableString *name in resourceNamesWithoutBody) {
            if (bodyString) {
                [resourceNames addObject:[[name stringByAppendingFormat:AppendSeparatorFormat, bodyString] mutableCopy]];
            }
            [resourceNames addObject:[[name stringByAppendingFormat:AppendSeparatorFormat, bodyHash] mutableCopy]];
        }
    }
    
    for (NSMutableString *name in [resourceNames copy]) {
        
        //test to see if the filename is too long
        if (name.length > MaxBaseFilenameLength) {
            [resourceNames removeObject:name];
            continue;
        }
        
        [self replacePathSeparatorsInMutableString:name];
    }
    
    return resourceNames;
}

/**
 *  Replace any instance of path separator characters (slash `/` and colon `:`) with hyphens.
 *
 *  @param string The mutable string in which to make the replacements
 */
- (void)replacePathSeparatorsInMutableString:(NSMutableString *)string
{
    NSRange fullStringRange = NSMakeRange(0, string.length);
    
    // Replace any colons with hyphens.
    [string replaceOccurrencesOfString:@":"
                            withString:@"-"
                               options:0
                                 range:fullStringRange];
    
    // Replace any slashes with hyphens.
    [string replaceOccurrencesOfString:@"/"
                            withString:@"-"
                               options:0
                                 range:fullStringRange];
}

/**
 *  Get the request body as `NSData` from an `NSURLRequest` (whether from the `body` or `bodyStream` property).
 *
 *  @param request The target `NSURLRequest`
 *
 *  @return The body data
 */
- (NSData *)bodyDataFromRequest:(NSURLRequest *)request
{
    NSData *bodyData = request.HTTPBody;
    if (!bodyData && request.HTTPBodyStream) {
        NSMutableData *mutableData = [NSMutableData data];
        NSInputStream *bodyStream = request.HTTPBodyStream;
        [bodyStream open];
        NSUInteger length = 0;
        static NSUInteger const BufferSize = 1024;
        uint8_t buffer[BufferSize];
        // Read in chunks of up to BufferSize until there's nothing left to read.
        do {
            [mutableData appendBytes:buffer length:length];
            length = [bodyStream read:buffer maxLength:BufferSize];
        } while (length > 0);
        
        bodyData = mutableData;
    }
    return bodyData;
}

/**
 *  Get the 64-character lower-case hex form of the SHA-256 of an NSData object.
 *
 *  @param data The data object
 *
 *  @return The 64-character lower-case hex SHA-256 of the data
 */
- (NSString *)sha256HexOfData:(NSData *)data
{
    unsigned char hash[CC_SHA256_DIGEST_LENGTH];
    if (!CC_SHA256(data.bytes, (CC_LONG)data.length, hash)) {
        return nil;
    }
    
    // Convert the bytes into a hex string.
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_SHA256_DIGEST_LENGTH * 2];
    for (NSUInteger index = 0; index < CC_SHA256_DIGEST_LENGTH; index++) {
        [output appendFormat:@"%02x", hash[index]];
    }
    return output;
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
                                                   regularExpressionWithPattern:@"^([^\r\n]*)[\r\n]?(.*)[\r\n]{2}(.*)$"
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
    
    // Parse the headers into a dictionary.
    NSRegularExpression *headerRegex = [NSRegularExpression
                                        regularExpressionWithPattern:@"^([^:]*):(.*)$"
                                        options:NSRegularExpressionAnchorsMatchLines
                                        error:&regexError];
    if (!headerRegex) {
        DLOG(@"header regex error: %@", regexError);
        return nil;
    }
    NSMutableDictionary *headerDict = [NSMutableDictionary dictionary];
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
    NSArray *resourceNames = [self resourceNames];
    NSString *filePath;
    
    // First, look for a complete-HTTP-response file.
    for (NSString *resourceName in resourceNames) {
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
    }
    
    // Otherwise, look for a JSON data file.
    for (NSString *resourceName in resourceNames) {
        filePath = [[NSBundle bundleForClass:[self class]] pathForResource:resourceName
                                                                    ofType:@"json"
                                                               inDirectory:MockDataDirectory];
        NSData *data = [NSData dataWithContentsOfFile:filePath];
        if (data) {
            // We've got a JSON data file, so send it.
            DLOG(@"Serving mock data from JSON response body file (%@)", filePath);
            NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc]
                                           initWithURL:self.request.URL
                                           statusCode:kHTTPStatusCodeOK
                                           HTTPVersion:@"HTTP/1.1"
                                           headerFields:@{
                                                          HTTPHeaderContentType: HTTPHeaderContentTypeJson,
                                                          }];
            return [VOKMockUrlProtocolResponseAndDataContainer containerWithResponse:response
                                                                                data:data];
        }
    }
    
    // Otherwise, failure.
    for (NSString *resourceName in resourceNames) {
        DLOG(@"failed to get mock data for resource name: \"%@\"", resourceName);
    }
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
