//
//  DropTargetView.m
//  AirFramerMac
//
//  Created by Michael Feldstein on 8/7/14.
//  Copyright (c) 2014 Macromeez. All rights reserved.
//

#import "DropTargetView.h"

@implementation DropTargetView
- (id) init {
    self = [super init];
    NSLog(@"SELF");
    return self;
}

- (void)awakeFromNib {
    [self registerForDraggedTypes:@[NSURLPboardType]];
}
@end
