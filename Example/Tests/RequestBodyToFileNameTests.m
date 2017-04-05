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

@interface VOKMockUrlProtocol (TestPrivateMethod)

//expose the resourceNames method so we can test it
- (NSArray *)resourceNames;

@end

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

- (void)testResourceNamesWithQueryAndBody
{
    NSURLRequest *request = [self POSTRequestWithURLString:@"http://example.com/foo/bar?baz=bat"
                                                      body:@{
                                                             @"abc": @"def",
                                                             }
                                                    asJSON:YES];
    VOKMockUrlProtocol *urlProtocol = [[VOKMockUrlProtocol alloc] initWithRequest:request
                                                                   cachedResponse:nil
                                                                           client:nil];
    NSArray *nonWildcardNames = @[
                               @"POST|-foo-bar?baz=bat|d3-abc3-defe",
                               @"POST|-foo-bar?baz=bat|2c3fbda5f48b04e39d3a87f89e5bd00b48b6e5e3c4a093de65de0a87b8cc8b3b",
                               @"POST|-foo-bar?36c88ea447b6ce20b8eeb9403bab33e55ca7ac64b29801be663dc8ee0609a15c|d3-abc3-defe",
                               @"POST|-foo-bar?36c88ea447b6ce20b8eeb9403bab33e55ca7ac64b29801be663dc8ee0609a15c|2c3fbda5f48b04e39d3a87f89e5bd00b48b6e5e3c4a093de65de0a87b8cc8b3b",
                               ];
    XCTAssertEqualObjects([urlProtocol resourceNames], nonWildcardNames);

    [VOKMockUrlProtocol setAllowsWildcardInMockDataFiles:YES];
    NSArray *wildcardNames = @[
                               @"POST|-foo-bar?baz=bat|*",
                               @"POST|-foo-bar?36c88ea447b6ce20b8eeb9403bab33e55ca7ac64b29801be663dc8ee0609a15c|*",
                               @"POST|-foo-bar?*|d3-abc3-defe",
                               @"POST|-foo-bar?*|2c3fbda5f48b04e39d3a87f89e5bd00b48b6e5e3c4a093de65de0a87b8cc8b3b",
                               @"POST|-foo-bar?*|*",
                               ];

    NSArray *allNames = [nonWildcardNames arrayByAddingObjectsFromArray:wildcardNames];
    XCTAssertEqualObjects([urlProtocol resourceNames], allNames);
}

- (void)testResourceNamesWithBody
{
    NSURLRequest *requestNoQuery = [self POSTRequestWithURLString:@"http://example.com/foo/bar"
                                                             body:@{
                                                                    @"abc": @"def",
                                                                    }
                                                           asJSON:NO];
    VOKMockUrlProtocol *urlProtocol = [[VOKMockUrlProtocol alloc] initWithRequest:requestNoQuery
                                                                   cachedResponse:nil
                                                                           client:nil];
    [VOKMockUrlProtocol setAllowsWildcardInMockDataFiles:YES];
    
    NSArray *allNamesNoQuery = @[
                                 @"POST|-foo-bar|abc=def",
                                 @"POST|-foo-bar|697d1bc6c73a3c6761a85836aa4557d1272f6d251759a885671e94119e8c6f82",
                                 @"POST|-foo-bar|*",
                                 ];
    XCTAssertEqualObjects([urlProtocol resourceNames], allNamesNoQuery);
}

- (void)testResourceNamesWithQuery
{
    NSURLRequest *requestNoBody = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://example.com/foo?bar=baz"]];
    VOKMockUrlProtocol *urlProtocol = [[VOKMockUrlProtocol alloc] initWithRequest:requestNoBody
                                                                   cachedResponse:nil
                                                                           client:nil];
    [VOKMockUrlProtocol setAllowsWildcardInMockDataFiles:YES];
    
    NSArray *allNamesNoBody = @[
                                 @"GET|-foo?bar=baz",
                                 @"GET|-foo?f572f8dbb5d18f875512ecb02f6852d29fa1baf9ebd1f241d96afd978e721852",
                                 @"GET|-foo?*",
                                 ];
    XCTAssertEqualObjects([urlProtocol resourceNames], allNamesNoBody);
    
    [VOKMockUrlProtocol setAllowsWildcardInMockDataFiles:NO];
}

@end
