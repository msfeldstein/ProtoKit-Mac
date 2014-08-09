//
//  AppDelegate.h
//  AirFramerMac
//
//  Created by Michael Feldstein on 8/6/14.
//  Copyright (c) 2014 Macromeez. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <CocoaHTTPServer/HTTPServer.h>
#import <CDEvents/CDEvents.h>
#import <CocoaAsyncSocket/AsyncSocket.h>

#import <CocoaAsyncSocket/GCDAsyncSocket.h>

@interface AppDelegate : NSObject <NSApplicationDelegate, NSNetServiceDelegate, GCDAsyncSocketDelegate>

@property (assign) IBOutlet NSWindow* window;
@property (assign) IBOutlet NSView* statusIndicator;
@property (assign) IBOutlet NSTextField* statusText;
@property NSNetService* netService;
@property HTTPServer* server;
@property CDEvents* watcher;
@property GCDAsyncSocket* watcherSocket;
@property GCDAsyncSocket* connectedSocket;

@property NSURL* folder;

- (IBAction)chooseFolder:(id)sender;
@end
