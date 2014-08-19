//
//  ResourcesGenerator.m
//  AirFramerMac
//
//  Created by Michael Feldstein on 8/13/14.
//  Copyright (c) 2014 Macromeez. All rights reserved.
//

#import "ResourcesGenerator.h"

@implementation ResourcesGenerator

- (NSDictionary*)generateManifestInProject:(NSString*)folder directory:(NSString*)directory {
    NSMutableDictionary* files = [NSMutableDictionary dictionary];
    NSString* path = [[folder stringByAppendingPathComponent:directory] stringByAppendingString:@"/"];
    NSLog(@"path %@", path);
    NSURL* url = [NSURL fileURLWithPath:path];
    files = [self recursiveFileFetch:url appendTo:files withPath:directory];
    return files;
}

- (NSMutableDictionary*) recursiveFileFetch:(NSURL*) directory appendTo:(NSMutableDictionary*)existing withPath:(NSString*)path {
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
        NSLog(@"FILENAME %@", filename);
        if (! [url getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:&error]) {
            NSLog(@"Error in determining if a file is a directory: %@", error);
        } else if ([isDirectory boolValue]) {
            NSMutableDictionary* nodes = [NSMutableDictionary dictionary];
            existing[filename] = nodes;
            [self recursiveFileFetch:url appendTo:nodes withPath:[path stringByAppendingPathComponent:filename]];
        } else {
            existing[filename] = [self dictionaryForImage:url atPath:path];
        }
    }
    return existing;
}

- (NSDictionary*)dictionaryForImage:(NSURL*)imagePath atPath:(NSString*)path {
    NSImage* image = [[NSImage alloc] initByReferencingURL:imagePath];
    NSString* filename = imagePath.pathComponents.lastObject;
    
    return @{@"path": [path stringByAppendingPathComponent:filename],
             @"width": [NSNumber numberWithDouble:image.size.width],
             @"height":[NSNumber numberWithDouble:image.size.height]};
}

@end
