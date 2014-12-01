//
//  Compiler.h
//
//  Created by Michael Feldstein on 8/20/14.
//  Copyright (c) 2014 Macromeez. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CDEvents/CDEventsDelegate.h>
@interface Compiler : NSObject <CDEventsDelegate>

@property NSString* directory;
@property BOOL isFrameProject; // Whether this will be compiled


- (id) initWithProjectDirectory:(NSString*)directory;
- (void)convertToFrameProject;

@end
