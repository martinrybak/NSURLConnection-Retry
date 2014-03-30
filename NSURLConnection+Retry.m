//
//  NSURLConnection+Retry.m
//
//  Created by Martin Rybak on 3/30/14.
//  Copyright (c) 2014 Martin Rybak. All rights reserved.
//

#import "NSURLConnection+Retry.h"
#import "NSObject+BKBlockExecution.h"

static NSTimeInterval const NSURLConnectionDefaultWaitInterval = 1.0;
static NSTimeInterval const NSURLConnectionDefaultTimeoutInterval = 5.0;

@implementation NSURLConnection (Retry)

+ (void)sendAsynchronousRequest:(NSURLRequest*)request queue:(NSOperationQueue*)queue retryCount:(NSUInteger)retryCount completionHandler:(void (^)(NSURLResponse* response, NSData* data, NSError* connectionError))handler
{
	[self sendAsynchronousRequest:request queue:queue retryCount:retryCount timeoutInterval:NSURLConnectionDefaultTimeoutInterval completionHandler:handler];
}

+ (void)sendAsynchronousRequest:(NSURLRequest*)request queue:(NSOperationQueue*)queue retryCount:(NSUInteger)retryCount timeoutInterval:(NSTimeInterval)timeoutInterval completionHandler:(void (^)(NSURLResponse* response, NSData* data, NSError* connectionError))handler
{
	[self sendAsynchronousRequest:request queue:queue retryCount:retryCount waitInterval:NSURLConnectionDefaultWaitInterval timeoutInterval:timeoutInterval completionHandler:handler];
}

+ (void)sendAsynchronousRequest:(NSURLRequest*)request queue:(NSOperationQueue*)queue retryCount:(NSUInteger)retryCount waitInterval:(NSTimeInterval)waitInterval timeoutInterval:(NSTimeInterval)timeoutInterval completionHandler:(void (^)(NSURLResponse* response, NSData* data, NSError* connectionError))handler
{
	//Request timeout cannot be longer than connection timeout
	if (request.timeoutInterval > timeoutInterval) {
		NSMutableURLRequest* mutableRequest = [request mutableCopy];
		mutableRequest.timeoutInterval = timeoutInterval;
		request = [mutableRequest copy];
	}
	
	NSDate* start = [NSDate date];
	[self sendAsynchronousRequest:request queue:queue completionHandler:^(NSURLResponse* response, NSData* data, NSError* connectionError) {
	
		//Check for connection error
		if (connectionError.code == kCFURLErrorTimedOut ||
			connectionError.code == kCFURLErrorCannotFindHost ||
			connectionError.code == kCFURLErrorCannotConnectToHost ||
			connectionError.code == kCFURLErrorNetworkConnectionLost ||
			connectionError.code == kCFURLErrorDNSLookupFailed ||
			connectionError.code == kCFURLErrorNotConnectedToInternet) {
			
			//If there are retries left and the timeout hasn't been reached, try again
			if (retryCount > 0 && timeoutInterval > 0.0) {
				[self bk_performBlock:^{
					NSUInteger retriesLeft = retryCount - 1;
					NSTimeInterval elapsed = [[NSDate date] timeIntervalSinceDate:start];
					NSTimeInterval timeoutLeft = MAX(timeoutInterval - elapsed, 0.0);
					NSLog(@"Connection failed, waiting %f seconds and trying %d more times until timeout in %f seconds", waitInterval, retriesLeft, timeoutLeft);
					[self sendAsynchronousRequest:request queue:queue retryCount:retriesLeft waitInterval:waitInterval timeoutInterval:timeoutLeft completionHandler:handler];
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
