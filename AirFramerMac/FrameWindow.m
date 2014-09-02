//
//  FrameWindow.m
//  AirFramerMac
//
//  Created by Michael Feldstein on 8/25/14.
//  Copyright (c) 2014 Macromeez. All rights reserved.
//

#import "FrameWindow.h"

@implementation FrameWindow


- (id)initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)aStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag
{
    self = [super initWithContentRect:contentRect styleMask:NSBorderlessWindowMask backing:bufferingType defer:flag];
    
    if ( self )
    {
        [self setStyleMask:NSBorderlessWindowMask];
        [self setOpaque:NO];
//        [self setBackgroundColor:[NSColor clearColor]];
    }
    
    return self;
}

/*
 Custom windows that use the NSBorderlessWindowMask can't become key by default. Override this method
 so that controls in this window will be enabled.
 */
- (BOOL)canBecomeKeyWindow {
    
    return YES;
}



- (BOOL)isMovableByWindowBackground {
    return YES;
}

@end
