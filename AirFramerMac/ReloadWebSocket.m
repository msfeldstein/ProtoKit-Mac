//
//  ReloadWebSocket.m
//  AirFramerMac
//
//  Created by Michael Feldstein on 8/21/14.
//  Copyright (c) 2014 Macromeez. All rights reserved.
//

#import "ReloadWebSocket.h"

@implementation ReloadWebSocket

- (void)didOpen
{
	[super didOpen];
}

- (void)didReceiveMessage:(NSString *)msg
{
	[self sendMessage:[NSString stringWithFormat:@"%@", [NSDate date]]];
}

- (void)didClose
{
	[super didClose];
}

@end
