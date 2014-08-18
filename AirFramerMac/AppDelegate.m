//
//  AppDelegate.m
//  AirFramerMac
//
//  Created by Michael Feldstein on 8/6/14.
//  Copyright (c) 2014 Macromeez. All rights reserved.
//

#import "AppDelegate.h"
#import "MyHTTPConnection.h"
#import "ManifestGenerator.h"
#import "QRCodeGenerator.h"
#import "ResourcesGenerator.h"

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    self.connectedSockets = [NSMutableArray array];
    [self setupWatcherSocket];
    [self setupBonjour];
    NSString* defaultDirectory = [[NSUserDefaults standardUserDefaults] objectForKey:@"prototypeDirectory"];
    if (!defaultDirectory) {
        defaultDirectory = [@"~/Prototypes/" stringByExpandingTildeInPath];
        [[NSUserDefaults standardUserDefaults] setObject:defaultDirectory forKey:@"prototypeDirectory"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    self.folder = [NSURL fileURLWithPath:defaultDirectory];
    
    [self reconfig];
    
    self.statusIndicator.layer.cornerRadius = 6;
    self.statusIndicator.layer.backgroundColor = [NSColor colorWithCalibratedRed:1.0 green:127.0 / 255.0 blue:127.0 / 255.0 alpha:1.0].CGColor;

    [self.reloadButton setHidden:YES];
    
    self.qrView.layer.backgroundColor = [NSColor whiteColor].CGColor;
    self.qrView.image = [QRCodeGenerator qrImageForString:[self getIPAddress] imageSize:self.qrView.bounds.size.width];
}

- (IBAction)chooseFolder:(id)sender {
    NSOpenPanel* openDlg = [NSOpenPanel openPanel];
    openDlg.canChooseFiles = NO;
    openDlg.canChooseDirectories = YES;
    openDlg.prompt = @"Select";
    openDlg.title = @"Select Workspace Folder";
    if ([openDlg runModal] == NSOKButton) {
        NSURL* url = openDlg.URL;
        if ([url.pathExtension isEqualToString:@"framer"]) {
            url = [NSURL URLWithString:[url.absoluteString stringByDeletingLastPathComponent]];
        }
        self.folder = url;
        [[NSUserDefaults standardUserDefaults] setObject:self.folder.path forKey:@"prototypeDirectory"];
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

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag { }

- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket {
    NSLog(@"Did accept new socket");
    [self.connectedSockets addObject:newSocket];
    [self updateLabel];
}

- (void) socketDidDisconnect:(GCDAsyncSocket *)socket withError:(NSError *)err {
    NSLog(@"Did disconnect socket");
    [self.connectedSockets removeObject:socket];
    [self updateLabel];
}

- (void)updateLabel {
    if (self.connectedSockets.count > 0) {
        self.statusIndicator.layer.backgroundColor = [NSColor colorWithCalibratedRed:185.0 / 255.0 green:233.0 / 255.0 blue:134.0 / 255.0 alpha:1.0].CGColor;
        if (self.connectedSockets.count == 1) {
            self.statusText.stringValue = @"One phone Connected";
        } else {
            self.statusText.stringValue = [NSString stringWithFormat:@"%lu phones connected", (unsigned long)self.connectedSockets.count];
        }
        [self.reloadButton setHidden:NO];
        [self.helpButton setHidden:YES];
    } else {
        [self.reloadButton setHidden:YES];
        [self.helpButton setHidden:NO];
        self.statusIndicator.layer.backgroundColor = [NSColor colorWithCalibratedRed:1.0 green:127.0 / 255.0 blue:127.0 / 255.0 alpha:1.0].CGColor;
        self.statusText.stringValue = @"No Phone Connected (Make sure it's on the same wifi network)";
    }
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
    if (!self.folder) return;
    NSArray* paths = @[self.folder];
    self.watcher = [[CDEvents alloc] initWithURLs:paths block:^(CDEvents *watcher, CDEvent *event) {
        [self sendChangeNotification];
    }];
}

- (void) sendChangeNotification {
    NSData* data = [@"CHANGE\n" dataUsingEncoding:NSUTF8StringEncoding];
    for (GCDAsyncSocket* socket in self.connectedSockets) {
        [socket writeData:data withTimeout:-1 tag:0];
    }
}

- (IBAction)sendChange:(id)sender {
    [self sendChangeNotification];
}

-(NSString *)getIPAddress
{
    for (NSString* address in [[NSHost currentHost] addresses]) {
        if ([address componentsSeparatedByString:@"."].count == 4) {
            if (![address isEqualToString:@"127.0.0.1"]) {
                return address;
            }
        }
    }
    return nil;
}

- (IBAction)showHelp:(id)sender {
    [self.helpPanel makeKeyAndOrderFront:self];
}

@end
