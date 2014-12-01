//
//  ProjectTableRowViewController.h
//
//  Created by Michael Feldstein on 8/18/14.
//  Copyright (c) 2014 Macromeez. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ProjectTableRowViewController : NSViewController
@property IBOutlet NSButton* simulatorButton;
@property IBOutlet NSTextField* titleField;

@property NSString* projectName;

- (void)setProject:(NSString*) project;

- (IBAction)showSimulator:(id)sender;
@end
