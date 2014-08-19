//
//  ProjectsModel.m
//  AirFramerMac
//
//  Created by Michael Feldstein on 8/18/14.
//  Copyright (c) 2014 Macromeez. All rights reserved.
//

#import "ProjectsModel.h"

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

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return _projects.count;
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row {
    return 60;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    NSString* project = _projects[row];
    NSTextField* view = [[NSTextField alloc]initWithFrame:NSMakeRect(0, 0, 200, 60)];
    view.stringValue = project;
    [view setEditable:NO];
    return view;
}
@end
