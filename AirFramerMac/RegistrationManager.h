//
//  RegistrationManager.h
//  Frame Pro for Mac
//
//  Created by Michael Feldstein on 10/5/14.
//  Copyright (c) 2014 Macromeez. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RegistrationManager : NSObject

@property BOOL registered;

+(id)sharedManager;

- (NSString*)currentKey;
- (void)setLicenseKey:(NSString*)key;

@end
