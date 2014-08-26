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
#import "Compiler.h"
#import "VDKQueue.h"
@interface ProjectsModel () {
    NSMutableArray* _projects;
    NSMutableArray* _compilers;
    VDKQueue* _watcher;
}

@end

@implementation ProjectsModel

- (id)init {
    self = [super init];
    if (self) {
        _projects = [NSMutableArray array];
        _compilers = [NSMutableArray array];
        _watcher = [[VDKQueue alloc] init];
        [_watcher setDelegate:self];
        [self addObserver:self forKeyPath:@"folder" options:NSKeyValueObservingOptionInitial context:nil];
    }
    return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"folder"]) {
        [self folderChanged];
    }
}

- (NSArray*)projects {
    return _projects;
}

- (void) folderChanged {
    [self loadFolder];
    [self listenForProjectChanges];
    [self setupCompile];
}

- (void) listenForProjectChanges {
    [_watcher removeAllPaths];
    if (!self.folder) return;
    [_watcher addPath:self.folder.path notifyingAbout:VDKQueueNotifyDefault];
}

- (void)VDKQueue:(VDKQueue *)queue receivedNotification:(NSString *)noteName forPath:(NSString *)fpath {
    [self folderChanged];
}

- (void)reload {
    [self loadFolder];
}

- (void) setupCompile {
    [_compilers removeAllObjects];
    for (NSString* project in _projects) {
        NSString* url = [self.folder.path stringByAppendingPathComponent:project];
        Compiler* compiler = [[Compiler alloc] initWithProjectDirectory:url];
        [_compilers addObject:compiler];
    }
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
    AppDelegate* delegate = ((AppDelegate*)[NSApplication sharedApplication].delegate);
    [delegate showSimulator:textField.stringValue];
}

- (IBAction)showFolder:(id)sender {
    NSButton *button = (NSButton *)sender;
    NSTextField* textField = [(NSTextField *)[button superview] viewWithTag:100];
    AppDelegate* delegate = ((AppDelegate*)[NSApplication sharedApplication].delegate);
    [delegate showFolder:textField.stringValue];
}

- (IBAction)editProject:(id)sender {
    NSButton *button = (NSButton *)sender;
    NSTextField* textField = [(NSTextField *)[button superview] viewWithTag:100];
    AppDelegate* delegate = ((AppDelegate*)[NSApplication sharedApplication].delegate);
    [delegate openInEditor:textField.stringValue];
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

- (void)tableViewSelectionIsChanging:(NSNotification *)notification {
    for (int i = 0; i < _projects.count; ++i) {
        // Jesus is this really how you do this?
        NSTableCellView *cell = [self.tableView viewAtColumn:0 row:i makeIfNecessary:YES];
        [[cell viewWithTag:200] setHidden:YES];
        [[cell viewWithTag:201] setHidden:YES];
        [[cell viewWithTag:202] setHidden:YES];
    }

    NSInteger selected = [self.tableView selectedRow];
    NSTableCellView *cell = [self.tableView viewAtColumn:0 row:selected makeIfNecessary:YES];
    [[cell viewWithTag:200] setHidden:NO];
    [[cell viewWithTag:201] setHidden:NO];
    [[cell viewWithTag:202] setHidden:NO];
}
@end
