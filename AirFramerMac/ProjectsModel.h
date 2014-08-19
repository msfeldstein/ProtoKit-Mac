//
//  ProjectsModel.h
//  AirFramerMac
//
//  Created by Michael Feldstein on 8/18/14.
//  Copyright (c) 2014 Macromeez. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ProjectsModel : NSObject <NSTableViewDataSource, NSTableViewDelegate>
@property IBOutlet NSTableView* tableView;
@property NSURL* folder;
- (void)reload;
- (IBAction)showSim:(id)sender;
@end
