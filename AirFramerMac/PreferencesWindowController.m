//
//  PreferencesWindowController.m
//  AirFramerMac
//
//  Created by Michael Feldstein on 9/4/14.
//  Copyright (c) 2014 Macromeez. All rights reserved.
//

#import "PreferencesWindowController.h"
#import "RegistrationManager.h"
#import "Constants.h"
#import "Macros.h"

@interface PreferencesWindowController () {
}
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
    [self updateRegistrationState];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:kIsRegisteredKey]) {
        [self updateRegistrationState];
    }
}

- (void)updateRegistrationState {
    RegistrationManager* regMgr = [RegistrationManager sharedManager];
    self.licenseField.stringValue = [regMgr currentKey];
    [regMgr addObserver:self forKeyPath:kIsRegisteredKey options:0 context:nil];
    if (regMgr.registered) {
        [self.registrationStatus setTextColor: SUCCESS_GREEN];
        self.registrationStatus.stringValue = @"Registered";
    } else {
        [self.registrationStatus setTextColor:FAIL_RED];
        self.registrationStatus.stringValue = @"Unregistered";
    }
}

- (IBAction)changeLicenseKey:(NSTextField*)sender {
    RegistrationManager* regMgr = [RegistrationManager sharedManager];
    [regMgr setLicenseKey:sender.stringValue];
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

- (IBAction)email:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"mailto:msfeldstein@gmail.com"]];
}

@end
