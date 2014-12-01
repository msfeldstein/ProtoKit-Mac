//
//  ProjectsModel.h
//
//  Created by Michael Feldstein on 8/18/14.
//  Copyright (c) 2014 Macromeez. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "VDKQueue.h"

@interface ProjectsModel : NSObject <NSTableViewDataSource, NSTableViewDelegate, VDKQueueDelegate>
@property IBOutlet NSTableView* tableView;
@property IBOutlet NSWindow* window;
@property NSURL* folder;
- (void)reload;
- (IBAction)showSim:(id)sender;
- (IBAction)showFolder:(id)sender;
- (IBAction)showNonFrameAlert:(id)sender;
- (NSArray*)projects;
- (void)createProject:(NSString*)name;
@end
