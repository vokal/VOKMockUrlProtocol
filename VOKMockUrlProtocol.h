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
 *  Sets a custom test bundle to use to look for the mock data files. Primarily useful 
 *  when VOKMockUrlProtocol is being used as a framework (for example, with Swift).
 *
 *  @param bundle The test bundle to use, or nil to reset to the bundle VOKMockUrlProtocol is in.
 */
+ (void)setTestBundle:(NSBundle *)bundle;

@end
