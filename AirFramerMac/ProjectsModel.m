//
//  ProjectsModel.m
//  AirFramerMac
//
//  Created by Michael Feldstein on 8/18/14.
//  Copyright (c) 2014 Macromeez. All rights reserved.
//

#import "ProjectsModel.h"
#import "AppDelegate.h"
#import "ProjectTableRowViewController.h"

@interface ProjectsModel () {
    NSMutableArray* _projects;
}

@end

@implementation ProjectsModel

- (id)init {
    self = [super init];
    if (self) {
        [self addObserver:self forKeyPath:@"folder" options:NSKeyValueObservingOptionInitial context:nil];
        _projects = [NSMutableArray array];
    }
    return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"folder"]) {
        [self loadFolder];
    }
}

- (void)reload {
    [self loadFolder];
}

- (void)loadFolder {
    [_projects removeAllObjects];
    if (self.folder) {
        NSError* err;
        NSArray* allFolders = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.folder.path error:&err];
        if (err) {
            NSLog(@"Error getting projects %@", err);
        }
        for (NSString* directory in allFolders) {
            NSString* indexPath = [[self.folder.path stringByAppendingPathComponent:directory] stringByAppendingPathComponent:@"index.html"];
            if ([[NSFileManager defaultManager] fileExistsAtPath:indexPath]) {
                [_projects addObject:directory];
            }
        }
    }
    [self.tableView reloadData];
    
}

- (IBAction)showSim:(id)sender {
    NSButton *button = (NSButton *)sender;
    NSTextField* textField = [(NSTextField *)[button superview] viewWithTag:100];
    NSLog(@"Rep obj %@", textField.stringValue);
    AppDelegate* delegate = ((AppDelegate*)[NSApplication sharedApplication].delegate);
    [delegate showSimulator:textField.stringValue];
}

- (IBAction)showFolder:(id)sender {
    NSButton *button = (NSButton *)sender;
    NSTextField* textField = [(NSTextField *)[button superview] viewWithTag:100];
    AppDelegate* delegate = ((AppDelegate*)[NSApplication sharedApplication].delegate);
    [delegate showFolder:textField.stringValue];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return _projects.count;
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row {
    return 50;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    NSString* project = _projects[row];
    NSView* view = [self.tableView makeViewWithIdentifier:@"justText" owner:self];
    NSTextField* title = [view viewWithTag:100];
    title.stringValue = project;
    return view;
}
@end
