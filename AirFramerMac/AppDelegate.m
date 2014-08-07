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
    self.netService = [[NSNetService alloc] initWithDomain:@"" type:@"_airframer._tcp" name:@"" port:3007];
    if (self.netService) {
        [self.netService scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:@"PrivateMyMacServiceMode"];
        
        [self.netService setDelegate:self];
        [self.netService publish];
        [self.netService startMonitoring];
        NSLog(@"SUCCESS!");
    } else {
        NSLog(@"FAIL!");
    }
    
    self.server = [[HTTPServer alloc] init];
    self.server.type = @"_http._tcp.";
    self.server.port = 3007;
    self.server.documentRoot = [@"~/Prototypes" stringByExpandingTildeInPath];
    self.server.connectionClass = [MyHTTPConnection class];
    NSLog(@"Root %@", self.server.documentRoot);
    NSError *error = nil;
	if(![self.server start:&error])
	{
		NSLog(@"Error starting HTTP Server: %@", error);
	}
    
    
    NSArray* paths = @[[NSURL URLWithString:[@"~/Prototypes/" stringByExpandingTildeInPath]]];
    self.watcher = [[CDEvents alloc] initWithURLs:paths block:^(CDEvents *watcher, CDEvent *event) {
        NSLog(@"CHANGE IT %@", event);
    }];
}


@end
