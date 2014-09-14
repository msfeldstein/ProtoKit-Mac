//
//  PreferencesWindowController.m
//  AirFramerMac
//
//  Created by Michael Feldstein on 9/4/14.
//  Copyright (c) 2014 Macromeez. All rights reserved.
//

#import "PreferencesWindowController.h"

@interface PreferencesWindowController ()

@end

@implementation PreferencesWindowController

- (id)init
{
    self = [super initWithWindowNibName:@"Preferences"];
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    NSString* editorURL = [[NSUserDefaults standardUserDefaults] stringForKey:@"editor_url"];
    self.currentEditorPath.stringValue = editorURL;
}

- (IBAction)chooseTextEditor:(id)sender {
    NSOpenPanel* openDlg = [NSOpenPanel openPanel];
    openDlg.canChooseFiles = YES;
    openDlg.canChooseDirectories = NO;
    openDlg.prompt = @"Open";
    openDlg.title = @"Choose Text Editor";
    openDlg.directoryURL = [NSURL URLWithString:@"/Applications"];
    if ([openDlg runModal] == NSOKButton) {
        NSString* editorURL = openDlg.URL.path;
        [[NSUserDefaults standardUserDefaults] setValue:editorURL forKey:@"editor_url"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        self.currentEditorPath.stringValue = editorURL;
        

    }

}

- (IBAction)tweet:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://twitter.com/msfeldstein"]];
}

@end
