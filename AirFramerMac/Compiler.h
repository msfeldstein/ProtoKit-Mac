//
//  Compiler.h
//  AirFramerMac
//
//  Created by Michael Feldstein on 8/20/14.
//  Copyright (c) 2014 Macromeez. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Compiler : NSObject

@property NSString* directory;

- (id) initWithProjectDirectory:(NSString*)directory;
//- (void)compile;
@end
