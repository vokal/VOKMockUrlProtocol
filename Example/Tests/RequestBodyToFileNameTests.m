//
//  RequestBodyToFileNameTests.m
//  VOKMockUrlProtocol
//
//  Created by Isaac Greenspan on 1/2/15.
//  Copyright (c) 2015 Isaac Greenspan. All rights reserved.
//

#import <XCTest/XCTest.h>

#import <AFNetworking/AFURLRequestSerialization.h>
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

- (void)testPostFormDictionary
{
    AFHTTPRequestSerializer *serializer = [AFHTTPRequestSerializer serializer];
    
    NSURLRequest *request = [serializer requestWithMethod:kHTTPMethodPost
                                                URLString:@"http://example.com/"
                                               parameters:@{
                                                            @"foo": @"bar",
                                                            }
                                                    error:NULL];
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

- (void)testPostJsonDictionary
{
    AFJSONRequestSerializer *serializer = [AFJSONRequestSerializer serializer];
    
    NSURLRequest *request = [serializer requestWithMethod:kHTTPMethodPost
                                                URLString:@"http://example.com/"
                                               parameters:@{
                                                            @"foo": @"bar",
                                                            }
                                                    error:NULL];
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

- (void)testPostJsonDictionaryHash
{
    AFJSONRequestSerializer *serializer = [AFJSONRequestSerializer serializer];
    
    NSURLRequest *request = [serializer requestWithMethod:kHTTPMethodPost
                                                URLString:@"http://example.com/"
                                               parameters:@{
                                                            @"foo": @"baz",
                                                            }
                                                    error:NULL];
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
