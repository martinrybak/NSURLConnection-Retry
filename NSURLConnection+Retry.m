//
//  NSURLConnection+Retry.m
//
//  Created by Martin Rybak on 3/30/14.
//  Copyright (c) 2014 Martin Rybak. All rights reserved.
//

#import "NSURLConnection+Retry.h"
#import "NSObject+BKBlockExecution.h"

static NSTimeInterval const NSURLConnectionDefaultWaitInterval = 1.0;

@implementation NSURLConnection (Retry)

+ (void)sendAsynchronousRequest:(NSURLRequest*)request queue:(NSOperationQueue*)queue timeoutInterval:(NSTimeInterval)timeoutInterval completionHandler:(void (^)(NSURLResponse* response, NSData* data, NSError* connectionError))handler
{
	[self sendAsynchronousRequest:request queue:queue waitInterval:NSURLConnectionDefaultWaitInterval timeoutInterval:timeoutInterval completionHandler:handler];
}

+ (void)sendAsynchronousRequest:(NSURLRequest*)request queue:(NSOperationQueue*)queue waitInterval:(NSTimeInterval)waitInterval timeoutInterval:(NSTimeInterval)timeoutInterval completionHandler:(void (^)(NSURLResponse* response, NSData* data, NSError* connectionError))handler
{
	NSMutableURLRequest* mutableRequest = [request mutableCopy];
	
	//Request timeout cannot be longer than connection timeout
	if (request.timeoutInterval > timeoutInterval) {
		mutableRequest.timeoutInterval = timeoutInterval;
	}
	
	NSDate* start = [NSDate date];
	[self sendAsynchronousRequest:mutableRequest queue:queue completionHandler:^(NSURLResponse* response, NSData* data, NSError* connectionError) {
		
		//Check for connection error other than no internet connection
		if (connectionError && connectionError.code != kCFURLErrorNotConnectedToInternet) {
			
			//If the timeout hasn't been reached, try again
            NSTimeInterval elapsed = [[NSDate date] timeIntervalSinceDate:start];
            NSTimeInterval timeoutLeft = MAX(timeoutInterval - elapsed, 0.0);
			NSLog(@"[NSURLConnection+Retry] Connection failed after %f seconds", elapsed);
            if (timeoutLeft > 0.0) {
				[NSObject bk_performBlock:^{
					NSLog(@"[NSURLConnection+Retry] Waiting %f seconds and trying until timeout in %f seconds", waitInterval, timeoutLeft - waitInterval);
					[self sendAsynchronousRequest:request queue:queue waitInterval:waitInterval timeoutInterval:timeoutLeft - waitInterval completionHandler:handler];
				} afterDelay:waitInterval];
				return;
			}
		}
		
		//Pass through to the original handler
		if (handler) {
			handler(response, data, connectionError);
		}
	}];
}

@end
