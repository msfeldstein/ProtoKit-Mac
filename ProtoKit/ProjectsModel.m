//
//  ProjectsModel.m
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

- (IBAction)showNonFrameAlert:(id)sender {
    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:@"Okay"];
    [alert addButtonWithTitle:@"Convert"];
    [alert setInformativeText:@"This project was not created in frame so you won't get some of the benefits."];
    [alert setAlertStyle:NSWarningAlertStyle];
    NSModalResponse resp = [alert runModal];
    if (resp == NSAlertSecondButtonReturn) {
        NSLog(@"Convert");
        Compiler* compiler = _compilers[self.tableView.selectedRow];
        [compiler convertToFrameProject];
        NSAlert *alert = [[NSAlert alloc] init];
        [alert addButtonWithTitle:@"Done"];
        [alert setInformativeText:@"You'll need to replace the coffee-script.js, framer.js, and init.js script tags in index.html with a script tag to out/compiled.js.\n\nDelete These:\n<script src=\"framer/coffee-script.js\"></script>\n<script src=\"framer/framer.js\"></script>\n<script src=\"framer/init.js\"></script>\n\nAdd This\n<script src=\"out/compiled.js\"></script>"];
        [alert runModal];
        [self tableViewSelectionIsChanging:nil];
    }
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return _projects.count;
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row {
    return 34;
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
        [[cell viewWithTag:206] setHidden:YES];
        NSTableRowView *myRowView = [self.tableView rowViewAtRow:i makeIfNecessary:NO];
        [myRowView setEmphasized:NO];
    }

    NSInteger selected = [self.tableView selectedRow];
    if (selected == -1) return;
    NSTableCellView *cell = [self.tableView viewAtColumn:0 row:selected makeIfNecessary:YES];
    [[cell viewWithTag:200] setHidden:NO];
    [[cell viewWithTag:201] setHidden:NO];
    [[cell viewWithTag:202] setHidden:NO];
    Compiler* compiler = _compilers[selected];
    if (!compiler.isFrameProject)
        [[cell viewWithTag:206] setHidden:NO];
}

- (void)createProject:(NSString *)name {
    NSFileManager* fm = [NSFileManager defaultManager];
    NSBundle* bundle = [NSBundle mainBundle];
    NSString* templatePath = [bundle pathForResource:@"example" ofType:@"framer"];
    NSError* err;
    NSString* newPath = [self.folder.path stringByAppendingPathComponent:name];
    [fm copyItemAtPath:templatePath toPath:newPath error:&err];
    if (err) {
        NSLog(@"Error copying new project template %@", err);
    }
    
    //    NSURL* folderURL = [NSURL fileURLWithPath:newPath];
    //    [[NSWorkspace sharedWorkspace] openURL: [NSURL URLWithString:[self urlForProject:name]]];
    //    [[NSWorkspace sharedWorkspace] openURL: folderURL];
    [self reload];
    NSIndexSet* index = [NSIndexSet indexSetWithIndex:[self.projects indexOfObject:name]];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, .1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [self.tableView selectRowIndexes:index byExtendingSelection:NO];
        NSTableCellView *cell = [self.tableView viewAtColumn:0 row:[self.projects indexOfObject:name] makeIfNecessary:YES];
        [[cell viewWithTag:200] setHidden:NO];
        [[cell viewWithTag:201] setHidden:NO];
        [[cell viewWithTag:202] setHidden:NO];
    });

}
@end
