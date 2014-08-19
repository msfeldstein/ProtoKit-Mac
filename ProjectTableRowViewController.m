//
//  ProjectTableRowViewController.m
//  AirFramerMac
//
//  Created by Michael Feldstein on 8/18/14.
//  Copyright (c) 2014 Macromeez. All rights reserved.
//

#import "ProjectTableRowViewController.h"
#import "AppDelegate.h"

@interface ProjectTableRowViewController ()

@end

@implementation ProjectTableRowViewController

- (id)init
{
    self = [super initWithNibName:@"ProjectTableRow" bundle:[NSBundle mainBundle]];
    if (self) {

    }
    return self;
}

- (void)setProject:(NSString *)project {
    self.projectName = project;
    self.titleField.stringValue = project;
}

- (void)awakeFromNib {
    self.titleField.stringValue = self.projectName;
}

- (IBAction)showSimulator:(id)sender {
    NSLog(@"Show simulator %@", self.projectName);
    AppDelegate* delegate = ((AppDelegate*)[NSApplication sharedApplication].delegate);
    [delegate showSimulator:self.projectName];
}

@end
