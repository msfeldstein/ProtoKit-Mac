//
//  PreferencesWindowController.h
//
//  Created by Michael Feldstein on 9/4/14.
//  Copyright (c) 2014 Macromeez. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface PreferencesWindowController : NSWindowController

@property IBOutlet NSTextField* currentEditorPath;
@property IBOutlet NSTextField* licenseField;
@property IBOutlet NSTextField* registrationStatus;

- (IBAction)chooseTextEditor:(id)sender;
- (IBAction)tweet:(id)sender;
- (IBAction)email:(id)sender;
- (IBAction)changeLicenseKey:(id)sender;

@end
