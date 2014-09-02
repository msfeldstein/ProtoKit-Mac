//
//  SImulatorWindowController.h
//  AirFramerMac
//
//  Created by Michael Feldstein on 8/18/14.
//  Copyright (c) 2014 Macromeez. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

@interface SimulatorWindowController : NSWindowController
@property IBOutlet WebView* webView;
@property IBOutlet NSDrawer* drawer;
@property IBOutlet NSTextView* consoleOutput;
- (void)loadURL:(NSString*)url;

- (void)toggleConsole;
- (void)setZoomLevel:(int)zoomLevel;
@end
