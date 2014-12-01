//
//  RootWindowView.m
//  ProtoKit
//
//  Created by Michael Feldstein on 8/25/14.
//  Copyright (c) 2014 Macromeez. All rights reserved.
//

#import "RootWindowView.h"

@implementation RootWindowView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.layer.cornerRadius = 10;
    }
    return self;
}

@end
