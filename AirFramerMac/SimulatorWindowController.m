//
//  SImulatorWindowController.m
//  AirFramerMac
//
//  Created by Michael Feldstein on 8/18/14.
//  Copyright (c) 2014 Macromeez. All rights reserved.
//

#import "SimulatorWindowController.h"

@interface SimulatorWindowController ()

@end

@implementation SimulatorWindowController

- (id)init
{
    return [super initWithWindowNibName:@"Simulator"];
}

- (void)loadURL:(NSString*)url {

    self.webView.mainFrameURL = url;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
}

@end
