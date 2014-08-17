//
//  ResourcesGenerator.h
//  AirFramerMac
//
//  Created by Michael Feldstein on 8/13/14.
//  Copyright (c) 2014 Macromeez. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ResourcesGenerator : NSObject
- (NSDictionary*)generateManifest:(NSString*)folder;
@end
