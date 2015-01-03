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

- (void)testNonexistentFileGives404
{
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://example.com/DoesntExist.html"]];
    NSError *error;
    NSHTTPURLResponse *response;
    NSData *data = [NSURLConnection sendSynchronousRequest:request
                                         returningResponse:&response
                                                     error:&error];
    XCTAssertEqual(response.statusCode, kHTTPStatusCodeNotFound);
    XCTAssertEqual(data.length, 0);
}

- (void)testHttpFileEmpty
{
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://example.com/empty"]];
    NSError *error;
    NSHTTPURLResponse *response;
    NSData *data = [NSURLConnection sendSynchronousRequest:request
                                         returningResponse:&response
                                                     error:&error];
    if (!data) {
        XCTFail();
        return;
    }
    XCTAssertNil(error);
    XCTAssertEqual(response.statusCode, kHTTPStatusCodeAccepted);
    XCTAssertEqual(response.allHeaderFields.count, 0);
    XCTAssertEqual(data.length, 0);
}

- (void)testHttpFileBodyNoHeaders
{
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://example.com/bodyNoHeaders"]];
    NSError *error;
    NSHTTPURLResponse *response;
    NSData *data = [NSURLConnection sendSynchronousRequest:request
                                         returningResponse:&response
                                                     error:&error];
    if (!data) {
        XCTFail();
        return;
    }
    XCTAssertNil(error);
    XCTAssertEqual(response.statusCode, kHTTPStatusCodeAccepted);
    XCTAssertEqual(response.allHeaderFields.count, 0);
    XCTAssertNotEqual(data.length, 0);
}

- (void)testHttpFileHeadersNoBody
{
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://example.com/headersNoBody"]];
    NSError *error;
    NSHTTPURLResponse *response;
    NSData *data = [NSURLConnection sendSynchronousRequest:request
                                         returningResponse:&response
                                                     error:&error];
    if (!data) {
        XCTFail();
        return;
    }
    XCTAssertNil(error);
    XCTAssertEqual(response.statusCode, kHTTPStatusCodeAccepted);
    XCTAssertNotEqual(response.allHeaderFields.count, 0);
    XCTAssertEqual(data.length, 0);
}

@end