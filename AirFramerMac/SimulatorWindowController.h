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
- (void)loadURL:(NSString*)url;
@end
