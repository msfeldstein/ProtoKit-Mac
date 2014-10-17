//
//  SImulatorWindowController.m
//  AirFramerMac
//
//  Created by Michael Feldstein on 8/18/14.
//  Copyright (c) 2014 Macromeez. All rights reserved.
//

#import "SimulatorWindowController.h"
#import <WebKit/WebKit.h>
#import "FrameWindow.h"
@interface SimulatorWindowController ()

@end

@implementation SimulatorWindowController

- (id)init
{
    NSImage* device = [NSImage imageNamed:@"iphone5s"];
    NSRect frame = CGRectMake(0, 0, device.size.width, device.size.height);
    NSWindow* window  = [[FrameWindow alloc] initWithContentRect:frame
                                                     styleMask:NSBorderlessWindowMask
                                                       backing:NSBackingStoreBuffered
                                                         defer:NO];
    [window makeKeyAndOrderFront:NSApp];
    [window setOpaque:YES];
//    [window setBackgroundColor:[NSColor clearColor]];
    self = [super initWithWindow:window];
    CGRect webFrame = CGRectMake(25, 96, 274, 490);
    self.webView = [[WebView alloc] initWithFrame:webFrame];
    
    NSImageView* frameImage = [[NSImageView alloc]initWithFrame:window.frame];
    frameImage.image = device;
    [window.contentView addSubview:frameImage];
//    [window.contentView addSubview:self.webView];

//    self.window = window;
    return self;
}

- (void)loadURL:(NSString*)url {

    self.webView.mainFrameURL = url;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    self.webView.frameLoadDelegate = self;
}

- (void)toggleConsole {
    [self.drawer toggle:nil];
}


//this returns a nice name for the method in the JavaScript environment
+(NSString*)webScriptNameForSelector:(SEL)sel
{
    if(sel == @selector(logJavaScriptString:))
        return @"log";
    if (sel == @selector(warnJavaScriptString:))
        return @"warn";
    if (sel == @selector(errorJavaScriptString:))
        return @"error";
    return nil;
}

//this allows JavaScript to call the -logJavaScriptString: method
+ (BOOL)isSelectorExcludedFromWebScript:(SEL)sel
{
    if(sel == @selector(logJavaScriptString:) || sel == @selector(warnJavaScriptString:) || sel == @selector(errorJavaScriptString:))
        return NO;
    return YES;
}

//this is a simple log command
- (void)logJavaScriptString:(NSString*) logText
{
    [self log:logText];
}
//this is a simple log command
- (void)warnJavaScriptString:(NSString*) logText
{
    [self log:logText];
}
//this is a simple log command
- (void)errorJavaScriptString:(NSString*) logText
{
    NSLog(@"JavaScript: %@",logText);
    [self log:logText];
}

- (void)log:(NSString*)logText {
    [self.consoleOutput setString:[[self.consoleOutput string] stringByAppendingString:logText]];
    [self.consoleOutput setString:[[self.consoleOutput string] stringByAppendingString:@"\n"]];
}

//this is called as soon as the script environment is ready in the webview
- (void)webView:(WebView *)sender didClearWindowObject:(WebScriptObject *)windowScriptObject forFrame:(WebFrame *)frame
{
    //add the controller to the script environment
    //the "Cocoa" object will now be available to JavaScript
    [windowScriptObject setValue:self forKey:@"console"];

}

- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame {
    NSString* scale = [NSString stringWithFormat:@"window.content.scale = %f", 50.0f / 100.0f];
    NSLog(@"Scale %@", scale);
    [self.webView stringByEvaluatingJavaScriptFromString:scale];
}

- (void)setZoomLevel:(int)zoomLevel {
    NSLog(@"Zoom level %@", self.window);
    CGSize size = CGSizeMake(640, 1136);
    size.width *= zoomLevel / 100.0f;
    size.height *= zoomLevel / 100.0f;
    CGRect frame = self.window.frame;
    frame.size = size;
    [self.window setFrame:frame display:YES];
    NSString* scale = [NSString stringWithFormat:@"window.content.scale = %f", zoomLevel / 100.0f];
    NSLog(@"Scale %@", scale);
    [self.webView stringByEvaluatingJavaScriptFromString:scale];
}


@end
