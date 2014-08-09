//
//  ManifestGenerator.m
//  AirFramerMac
//
//  Created by Michael Feldstein on 8/8/14.
//  Copyright (c) 2014 Macromeez. All rights reserved.
//

#import "ManifestGenerator.h"

@implementation ManifestGenerator

- (NSString*)generateManifest:(NSString*)folder {
    return [self recursiveFileFetch:[NSURL URLWithString:folder] appendTo:@"CACHE MANIFEST\n" root:folder];
}

- (NSString*) recursiveFileFetch:(NSURL*) directory appendTo:(NSString*)existing root:(NSString*)root {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *directoryURL = directory;
    NSArray *keys = [NSArray arrayWithObject:NSURLIsDirectoryKey];
    
    NSDirectoryEnumerator *enumerator = [fileManager
                                         enumeratorAtURL:directoryURL
                                         includingPropertiesForKeys:keys
                                         options:0
                                         errorHandler:^(NSURL *url, NSError *error) {
                                             // Return YES if the enumeration should continue after the error.
                                             return YES;
                                         }];
    
    for (NSURL *url in enumerator) {
        NSError *error;
        NSNumber *isDirectory = nil;
        if (! [url getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:&error]) {
            NSLog(@"Error in determining if a file is a directory: %@", error);
        } else if ([isDirectory boolValue]) {
            [self recursiveFileFetch:url appendTo:existing root:root];
        } else {
            NSString* relativePath = [url.path stringByReplacingOccurrencesOfString:root withString:@""];
            relativePath = [relativePath stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:@""];
            existing = [existing stringByAppendingString:[NSString stringWithFormat:@"%@\n", relativePath]];
        }
    }
    return existing;
}

@end
