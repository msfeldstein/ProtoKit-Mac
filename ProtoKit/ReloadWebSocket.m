//
//  ReloadWebSocket.m
//  ProtoKit
//
//  Created by Michael Feldstein on 8/21/14.
//  Copyright (c) 2014 Macromeez. All rights reserved.
//

#import "ReloadWebSocket.h"

@implementation ReloadWebSocket

- (void)didOpen
{
    NSLog(@"Did open");
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sendReload:) name:@"COMPILE_COMPLETE" object:nil];
	[super didOpen];
    self.connected = YES;
}

- (void)sendReload:(NSNotification*)n {
    NSLog(@"Reload %@", self);
    [self sendMessage:@"reload"];
}

- (void)didClose
{
    NSLog(@"Did close");
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.connected = NO;
    [self.connection myWebSocketDidDisconnect:self];
	[super didClose];
}

@end
