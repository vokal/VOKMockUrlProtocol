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

@end
