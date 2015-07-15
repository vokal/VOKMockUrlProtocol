//
//  VOKMockUrlProtocol.h
//
//  Created by Isaac Greenspan on 7/31/14.
//  Copyright (c) 2014 Vokal. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  URL Protocol to intercept requests and return mocked data from local files without hitting an actual remote server.
 */
@interface VOKMockUrlProtocol : NSURLProtocol

/**
 *  Mock data should go into a directory with the name defined in this string.
 *  It defaults to "VOKMockData", but its default can be overwritten by subclassing
 *  VOKMockUrlProtocol and overriding - initWithRequest:cachedResponse:client.
 */
@property (copy, nonatomic) NSString *mockDataDirectory;

@end
