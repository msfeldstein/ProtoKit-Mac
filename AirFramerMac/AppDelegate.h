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

@interface AppDelegate : NSObject <NSApplicationDelegate, NSNetServiceDelegate>

@property (assign) IBOutlet NSWindow *window;
@property NSNetService* netService;
@property HTTPServer* server;
@property CDEvents* watcher;
@end
