//
//  ResourcesGenerator.m
//  AirFramerMac
//
//  Created by Michael Feldstein on 8/13/14.
//  Copyright (c) 2014 Macromeez. All rights reserved.
//

#import "ResourcesGenerator.h"

@implementation ResourcesGenerator

- (NSDictionary*)generateManifest:(NSString*)folder {
    NSMutableDictionary* files = [NSMutableDictionary dictionary];
    NSURL* url = [NSURL fileURLWithPath:[folder stringByAppendingString:@"/"]];
    files = [self recursiveFileFetch:url appendTo:files];
    return files;
}

- (NSMutableDictionary*) recursiveFileFetch:(NSURL*) directory appendTo:(NSMutableDictionary*)existing {
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
        NSString* filename = [[url pathComponents]lastObject];
        
        if ([filename rangeOfString:@"."].location == 0) continue;
        if (! [url getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:&error]) {
            NSLog(@"Error in determining if a file is a directory: %@", error);
        } else if ([isDirectory boolValue]) {
            NSMutableDictionary* nodes = [NSMutableDictionary dictionary];
            existing[filename] = nodes;
            [self recursiveFileFetch:url appendTo:nodes];
        } else {
            existing[filename] = [self dictionaryForImage:url];
        }
    }
    return existing;
}

- (NSDictionary*)dictionaryForImage:(NSURL*)imagePath {
    NSImage* image = [[NSImage alloc] initByReferencingURL:imagePath];
    return @{@"path": imagePath.path,
             @"width": [NSNumber numberWithDouble:image.size.width],
             @"height":[NSNumber numberWithDouble:image.size.height]};
}

@end
