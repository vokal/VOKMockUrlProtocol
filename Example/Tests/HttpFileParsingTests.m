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

- (void)testHttpLongQueryFile
{
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://example.com/details?one=1&two=2&three=3&four=4&five=5&six=6&seven=7&eight=8&nine=9&ten=10&eleven=11&twelve=12&thirteen=13&fourteen=14&fifteen=15&sixteen=16&seventeen=17&eighteen=18&nineteen=19&twenty=20&twentyone=21&twntytwo=22&twentythree=23&twentyfour=24&twentyfive=25"]];
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

@end