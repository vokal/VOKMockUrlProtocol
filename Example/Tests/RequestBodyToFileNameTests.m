//
//  RequestBodyToFileNameTests.m
//  VOKMockUrlProtocol
//
//  Created by Isaac Greenspan on 1/2/15.
//  Copyright (c) 2015 Isaac Greenspan. All rights reserved.
//

#import <XCTest/XCTest.h>

#import <HTTPMethods.h>
#import <HTTPStatusCodes.h>
#import <VOKMockUrlProtocol.h>

@interface RequestBodyToFileNameTests : XCTestCase

@end

@implementation RequestBodyToFileNameTests

+ (void)setUp
{
    [super setUp];
    
    // Register the mock URL protocol class, so that all calls will be mocked, rather than hitting a remote server.
    [NSURLProtocol registerClass:[VOKMockUrlProtocol class]];
}

+ (void)tearDown
{
    // Un-register the mock URL protocol class.
    [NSURLProtocol unregisterClass:[VOKMockUrlProtocol class]];
    
    [super tearDown];
}

- (NSURLRequest *)POSTRequestWithURLString:(NSString *)URLString
                                      body:(NSDictionary *)bodyParameters
                                    asJSON:(BOOL)bodyAsJSON
{
    NSURL *url = [NSURL URLWithString:URLString];

    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    request.HTTPMethod = kHTTPMethodPost;
    
    if (bodyAsJSON) {
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        request.HTTPBody = [NSJSONSerialization dataWithJSONObject:bodyParameters
                                                           options:0
                                                             error:NULL];
    } else {
        //body as form data
        [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];

        NSMutableArray *pairs = [NSMutableArray array];
        [bodyParameters enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *obj, BOOL *stop) {
            NSString *pair = [NSString stringWithFormat:@"%@=%@", key.description, obj.description];
            [pairs addObject:pair];
        }];
        NSString *bodyString = [pairs componentsJoinedByString:@"&"];

        request.HTTPBody = [bodyString dataUsingEncoding:NSUTF8StringEncoding];
    }
    
    return request;
}

- (void)verifyRequest:(NSURLRequest *)request
{
    XCTestExpectation *expectation = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    NSURLSession *session = [NSURLSession sharedSession];
    [[session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *urlResponse, NSError *error) {
        if (!data) {
            XCTFail();
            return;
        }
        XCTAssertNil(error);
        NSHTTPURLResponse *response = (NSHTTPURLResponse *)urlResponse;
        XCTAssertEqual(response.statusCode, kHTTPStatusCodeAccepted);
        XCTAssertEqual(response.allHeaderFields.count, 0);
        XCTAssertEqual(data.length, 0);
        
        [expectation fulfill];
    }] resume];
    [self waitForExpectationsWithTimeout:1.0 handler:nil];
}

- (void)testPostFormDictionary
{
    NSURLRequest *request = [self POSTRequestWithURLString:@"http://example.com/"
                                                      body:@{
                                                             @"foo": @"bar",
                                                             }
                                                    asJSON:NO];
    [self verifyRequest:request];
}

- (void)testPostJsonDictionary
{
    NSURLRequest *request = [self POSTRequestWithURLString:@"http://example.com/"
                                                      body:@{
                                                             @"foo": @"bar",
                                                             }
                                                    asJSON:YES];
    [self verifyRequest:request];
}

- (void)testPostJsonDictionaryHash
{
    NSURLRequest *request = [self POSTRequestWithURLString:@"http://example.com/"
                                                      body:@{
                                                             @"foo": @"baz",
                                                             }
                                                    asJSON:YES];
    [self verifyRequest:request];
}

- (void)testPostWildcardBody
{
    [VOKMockUrlProtocol setAllowsWildcardInMockDataFiles:YES];
    NSURLRequest *request = [self POSTRequestWithURLString:@"http://example.com/purchase"
                                                      body:@{
                                                             @"date": [NSDate date].description,
                                                             }
                                                    asJSON:YES];
    [self verifyRequest:request];
    [VOKMockUrlProtocol setAllowsWildcardInMockDataFiles:NO];
}

- (void)testPostWildcardQueryAndBody
{
    [VOKMockUrlProtocol setAllowsWildcardInMockDataFiles:YES];
    NSString *urlString = [NSString stringWithFormat:@"http://example.com/purchase?timestamp=%@",
                           @([NSDate date].timeIntervalSinceReferenceDate)];
    NSURLRequest *request = [self POSTRequestWithURLString:urlString
                                                      body:@{
                                                             @"date": [NSDate date].description,
                                                             }
                                                    asJSON:YES];
    [self verifyRequest:request];
    [VOKMockUrlProtocol setAllowsWildcardInMockDataFiles:NO];
}

@end
