//
//  HttpFileParsingTests.m
//  VOKMockUrlProtocolTests
//
//  Created by Isaac Greenspan on 10/27/2014.
//  Copyright (c) 2014 Isaac Greenspan. All rights reserved.
//

#import <XCTest/XCTest.h>

#import <HTTPStatusCodes.h>
#import <VOKMockUrlProtocol.h>

@interface HttpFileParsingTests : XCTestCase

@end

@implementation HttpFileParsingTests

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

- (void)verifyRequestWithURLString:(NSString *)urlString
                        completion:(void (^)(NSData *data, NSHTTPURLResponse *response, NSError *error))completion
{
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    XCTestExpectation *expectation = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    NSURLSession *session = [NSURLSession sharedSession];
    [[session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *urlResponse, NSError *error) {
        completion(data, (NSHTTPURLResponse *)urlResponse, error);
        [expectation fulfill];
    }] resume];
    [self waitForExpectationsWithTimeout:1.0 handler:nil];
}

- (void)testNonexistentFileGives404
{
    [self verifyRequestWithURLString:@"http://example.com/DoesntExist.html"
                          completion:^(NSData *data, NSHTTPURLResponse *response, NSError *error) {
                              XCTAssertEqual(response.statusCode, kHTTPStatusCodeNotFound);
                              XCTAssertEqual(data.length, 0);
                          }];
}

- (void)testHttpFileEmpty
{
    [self verifyRequestWithURLString:@"http://example.com/empty"
                          completion:^(NSData *data, NSHTTPURLResponse *response, NSError *error) {
                              if (!data) {
                                  XCTFail();
                                  return;
                              }
                              XCTAssertNil(error);
                              XCTAssertEqual(response.statusCode, kHTTPStatusCodeAccepted);
                              XCTAssertEqual(response.allHeaderFields.count, 0);
                              XCTAssertEqual(data.length, 0);
                          }];
}

- (void)testHttpFileBodyNoHeaders
{
    [self verifyRequestWithURLString:@"http://example.com/bodyNoHeaders"
                          completion:^(NSData *data, NSHTTPURLResponse *response, NSError *error) {
                              if (!data) {
                                  XCTFail();
                                  return;
                              }
                              XCTAssertNil(error);
                              XCTAssertEqual(response.statusCode, kHTTPStatusCodeAccepted);
                              XCTAssertEqual(response.allHeaderFields.count, 0);
                              XCTAssertNotEqual(data.length, 0);
                          }];
}

- (void)testHttpFileHeadersNoBody
{
    [self verifyRequestWithURLString:@"http://example.com/headersNoBody"
                          completion:^(NSData *data, NSHTTPURLResponse *response, NSError *error) {
                              if (!data) {
                                  XCTFail();
                                  return;
                              }
                              XCTAssertNil(error);
                              XCTAssertEqual(response.statusCode, kHTTPStatusCodeAccepted);
                              XCTAssertNotEqual(response.allHeaderFields.count, 0);
                              XCTAssertEqual(data.length, 0);
                          }];
}

- (void)testHttpLongQueryFile
{
    [self verifyRequestWithURLString:@"http://example.com/details?one=1&two=2&three=3&four=4&five=5&six=6&seven=7&eight=8&nine=9&ten=10&eleven=11&twelve=12&thirteen=13&fourteen=14&fifteen=15&sixteen=16&seventeen=17&eighteen=18&nineteen=19&twenty=20&twentyone=21&twntytwo=22&twentythree=23&twentyfour=24&twentyfive=25"
                          completion:^(NSData *data, NSHTTPURLResponse *response, NSError *error) {
                              if (!data) {
                                  XCTFail();
                                  return;
                              }
                              XCTAssertNil(error);
                              XCTAssertEqual(response.statusCode, kHTTPStatusCodeAccepted);
                              XCTAssertEqual(response.allHeaderFields.count, 0);
                              XCTAssertEqual(data.length, 0);
                          }];
}

- (void)testWildcardQueryFile
{
    //Given a URL resource that is date based and difficult to mock
    NSDateFormatter *formatter = [NSDateFormatter new];
    formatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss";
    NSString *urlString = [NSString stringWithFormat:@"http://example.com/search?start=%@",
                           [formatter stringFromDate:[NSDate date]]];
    [self verifyRequestWithURLString:urlString
                          completion:^(NSData *data, NSHTTPURLResponse *response, NSError *error) {
                              XCTAssertEqual(response.statusCode, kHTTPStatusCodeNotFound);
                              XCTAssertEqual(data.length, 0);
                              XCTAssertNil(error);
                          }];

    //It is possible to serve a mock data file using a wildcard for the query string
    [VOKMockUrlProtocol setAllowsWildcardInMockDataFiles:YES];
    [self verifyRequestWithURLString:urlString
                          completion:^(NSData *data, NSHTTPURLResponse *response, NSError *error) {
                              [VOKMockUrlProtocol setAllowsWildcardInMockDataFiles:NO];
                              if (!data) {
                                  XCTFail();
                                  return;
                              }
                              XCTAssertNil(error);
                              XCTAssertEqual(response.statusCode, kHTTPStatusCodeAccepted);
                              XCTAssertEqual(response.allHeaderFields.count, 0);
                              XCTAssertEqual(data.length, 0);
                          }];
}

- (void)testWildcardQueryFilePrefersExactMatch
{
    [VOKMockUrlProtocol setAllowsWildcardInMockDataFiles:YES];
    //We have an exact match for this request and a wildcard file that could also match
    //but we expect to prefer matching the exact filename
    [self verifyRequestWithURLString:@"http://example.com/search?start=2017-03-19"
                          completion:^(NSData *data, NSHTTPURLResponse *response, NSError *error) {
                              [VOKMockUrlProtocol setAllowsWildcardInMockDataFiles:NO];
                              if (!data) {
                                  XCTFail();
                                  return;
                              }
                              XCTAssertNil(error);
                              //the more specific mock data file has a different status code from the wildcard one
                              XCTAssertEqual(response.statusCode, kHTTPStatusCodeOK);
                              XCTAssertEqual(response.allHeaderFields.count, 0);
                              XCTAssertEqual(data.length, 0);
                          }];
}

@end
