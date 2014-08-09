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
    [self setupWatcherSocket];
    [self setupBonjour];
    NSString* defaultDirectory = [[NSUserDefaults standardUserDefaults] objectForKey:@"prototypeDirectory"];
    if (!defaultDirectory) {
        defaultDirectory = [@"~/Prototypes/" stringByExpandingTildeInPath];
        [[NSUserDefaults standardUserDefaults] setObject:defaultDirectory forKey:@"prototypeDirectory"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    self.folder = [NSURL URLWithString:defaultDirectory];
    [self reconfig];
    self.statusIndicator.layer.cornerRadius = 6;
    self.statusIndicator.layer.backgroundColor = [NSColor colorWithCalibratedRed:1.0 green:127.0 / 255.0 blue:127.0 / 255.0 alpha:1.0].CGColor;
    
}

- (IBAction)chooseFolder:(id)sender {
    NSOpenPanel* openDlg = [NSOpenPanel openPanel];
    [openDlg setCanChooseFiles:NO];
    [openDlg setCanChooseDirectories:YES];
    [openDlg setPrompt:@"Select"];
    if ([openDlg runModal] == NSOKButton) {
        self.folder = [openDlg URL];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    [self reconfig];
}

- (void) reconfig {
    [self setupServer];
    [self setupWatcher];
    [self sendChangeNotification];
}

- (void) setupServer {
    if (!self.server) {
        self.server = [[HTTPServer alloc] init];
        self.server.type = @"_http._tcp.";
        self.server.port = 3007;
        self.server.connectionClass = [MyHTTPConnection class];
        NSError *error = nil;
        if(![self.server start:&error])
        {
            NSLog(@"Error starting HTTP Server: %@", error);
        }
    }
    NSLog(@"Path %@", self.folder.path);
    self.server.documentRoot = self.folder.path;


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
    self.statusIndicator.layer.backgroundColor = [NSColor colorWithCalibratedRed:185.0 / 255.0 green:233.0 / 255.0 blue:134.0 / 255.0 alpha:1.0].CGColor;
    self.statusText.stringValue = @"Phone Connected!";
}

- (void) socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err {
    NSLog(@"Socket %@ %@", sock, err);
    self.connectedSocket = nil;
    self.statusIndicator.layer.backgroundColor = [NSColor colorWithCalibratedRed:1.0 green:127.0 / 255.0 blue:127.0 / 255.0 alpha:1.0].CGColor;
    self.statusText.stringValue = @"No Phone Connected (Make sure it's on the same wifi network)";
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
    NSArray* paths = @[self.folder];
    self.watcher = [[CDEvents alloc] initWithURLs:paths block:^(CDEvents *watcher, CDEvent *event) {
        [self sendChangeNotification];
    }];
}

- (void) sendChangeNotification {
    NSLog(@"CHANGE\n");
    NSData* data = [@"CHANGE\n" dataUsingEncoding:NSUTF8StringEncoding];
    [self.connectedSocket writeData:data withTimeout:-1 tag:0];
}

@end
