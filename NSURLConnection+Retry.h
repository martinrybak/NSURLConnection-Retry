//
//  NSURLConnection+Retry.h
//
//  Created by Martin Rybak on 3/30/14.
//  Copyright (c) 2014 Martin Rybak. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSURLConnection (Retry)

+ (void)sendAsynchronousRequest:(NSURLRequest*)request queue:(NSOperationQueue*)queue timeoutInterval:(NSTimeInterval)timeoutInterval completionHandler:(void (^)(NSURLResponse* response, NSData* data, NSError* connectionError))handler;
+ (void)sendAsynchronousRequest:(NSURLRequest*)request queue:(NSOperationQueue*)queue waitInterval:(NSTimeInterval)waitInterval timeoutInterval:(NSTimeInterval)timeoutInterval completionHandler:(void (^)(NSURLResponse* response, NSData* data, NSError* connectionError))handler;

@end
