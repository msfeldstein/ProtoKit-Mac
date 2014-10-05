//
//  RegistrationManager.m
//  Frame Pro for Mac
//
//  Created by Michael Feldstein on 10/5/14.
//  Copyright (c) 2014 Macromeez. All rights reserved.
//

#import "RegistrationManager.h"
#import <AFNetworking/AFNetworking.h>
#import "Constants.h"

@interface RegistrationManager () {
    BOOL _isRegistered;
}
@end

@implementation RegistrationManager

+ (id)sharedManager {
    static RegistrationManager *sharedMyManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
    });
    return sharedMyManager;
}

- (id)init {
    self = [super init];
    NSUserDefaults* def = [NSUserDefaults standardUserDefaults];
    self.registered = [def boolForKey:kIsRegisteredKey];
    return self;
}

- (NSString*)currentKey {
    return [[NSUserDefaults standardUserDefaults] stringForKey:@"LICENSE_KEY"];
}

- (void)setRegistered:(BOOL)registered {
    _isRegistered = registered;
    NSUserDefaults* def = [NSUserDefaults standardUserDefaults];
    [def setBool:registered forKey:kIsRegisteredKey];
}

- (BOOL)registered {
    return _isRegistered;
}

- (void)setLicenseKey:(NSString*)key {
    [[NSUserDefaults standardUserDefaults] setObject:key forKey:@"LICENSE_KEY"];
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSDictionary *parameters = @{@"product_permalink": @"framepro", @"license_key": key};
    [manager POST:@"https://api.gumroad.com/v2/licenses/verify" parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"JSON: %@", responseObject);
        if (responseObject[@"success"]) {
            self.registered = YES;
            
            [[NSNotificationCenter defaultCenter] postNotificationName:kRegistrationSuccessNotificationKey object:nil];
        } else {
            self.registered = NO;
            [[NSNotificationCenter defaultCenter] postNotificationName:kRegistrationFailureNotificationKey object:nil];
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
}

@end
