//
//  AppDelegate.m
//  AirFramerMac
//
//  Created by Michael Feldstein on 8/6/14.
//  Copyright (c) 2014 Macromeez. All rights reserved.
//

#import "AppDelegate.h"
#import "MyHTTPConnection.h"


@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [self setupServer];
    [self setupWatcherSocket];
    [self setupBonjour];
    [self setupWatcher];
    
}

- (void) setupServer {
    self.server = [[HTTPServer alloc] init];
    self.server.type = @"_http._tcp.";
    self.server.port = 3007;
    self.server.documentRoot = [@"~/Prototypes" stringByExpandingTildeInPath];
    self.server.connectionClass = [MyHTTPConnection class];
    NSError *error = nil;
	if(![self.server start:&error])
	{
		NSLog(@"Error starting HTTP Server: %@", error);
	}

}

- (void)setupWatcherSocket {
    self.watcherSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    NSError* err;
    [self.watcherSocket acceptOnPort:3008 error:&err];
    self.watcherSocket.delegate = self;
    if (err) {
        NSLog(@"ERROR %@", err);
    }
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag {
    NSLog(@"Wrote some data");
}

- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket {
    NSLog(@"Did accept new socket");
    self.connectedSocket = newSocket;
}

- (void) setupBonjour {
    self.netService = [[NSNetService alloc] initWithDomain:@"" type:@"_airframer._tcp" name:@"" port:3007];
    if (self.netService) {
        [self.netService scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:@"PrivateMyMacServiceMode"];
        
        [self.netService setDelegate:self];
        [self.netService publish];
        [self.netService startMonitoring];
    } else {
        NSLog(@"FAIL setupBonjour!");
    }
    
}

- (void)setupWatcher {
    NSArray* paths = @[[NSURL URLWithString:[@"~/Prototypes/" stringByExpandingTildeInPath]]];
    self.watcher = [[CDEvents alloc] initWithURLs:paths block:^(CDEvents *watcher, CDEvent *event) {
        NSLog(@"CHANGE\n");
        NSData* data = [@"CHANGE\n" dataUsingEncoding:NSUTF8StringEncoding];
        [self.connectedSocket writeData:data withTimeout:-1 tag:0];
    }];
}

@end
