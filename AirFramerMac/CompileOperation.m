//
//  CompileOperation.m
//  AirFramerMac
//
//  Created by Michael Feldstein on 8/20/14.
//  Copyright (c) 2014 Macromeez. All rights reserved.
//

#import "CompileOperation.h"

@implementation CompileOperation

- (id) initWithProjectDirectory:(NSString*)directory {
    self = [super init];
    self.directory = directory;
    return self;
}

- (void) main {
    @autoreleasepool {
        [self compile];
    }
}

- (void)compile {
    NSLog(@"Compiling %@", self.directory);
    NSURL *outputURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:[[NSProcessInfo processInfo] globallyUniqueString]] isDirectory:YES];
    NSError* error;
    [[NSFileManager defaultManager] createDirectoryAtURL:outputURL withIntermediateDirectories:YES attributes:nil error:&error];
    [self compileFolder:self.directory toFolder:outputURL.path];
    NSString* compiledFile = [self.directory stringByAppendingPathComponent:@"out/compiled.js"];
    [self concatFolder:outputURL toFile:compiledFile];
    [[NSFileManager defaultManager] removeItemAtURL:outputURL error:nil];
}

- (void)compileFolder:(NSString*)folder toFolder:(NSString*)destination {
    NSString* env = [[NSBundle mainBundle] pathForResource:@"JSEnv" ofType:@""];
    NSString* nodePath = [env stringByAppendingPathComponent:@"node"];
    NSString* coffeePath = [env stringByAppendingPathComponent:@"coffee/bin/coffee"];
    NSPipe *pipe = [NSPipe pipe];
    NSFileHandle *file = pipe.fileHandleForReading;
    NSTask *task = [[NSTask alloc] init];
    task.launchPath = nodePath;
    task.arguments = @[coffeePath, @"-o", destination, @"-c", folder];
    task.standardOutput = pipe;
    task.standardError = pipe;
    [task launch];
    
    // We need to actually read the data here otherwise NSTask will return asynchronously and the files wont be there for the next step
    NSData *outputData = [[pipe fileHandleForReading] readDataToEndOfFile];
    NSString* output = [[NSString alloc] initWithData:outputData encoding:NSUTF8StringEncoding];
    if (output && output.length > 0) {
        NSLog(@"There was an error: %@", output);
        NSUserNotification* notification = [[NSUserNotification alloc] init];

        NSArray* parts = [output componentsSeparatedByString:@"error: "];
        NSString* filepath = [[parts[0] componentsSeparatedByString:@"/"] lastObject];
        NSLog(@"FilePath %@", filepath);
        NSString* message = parts[1];
        notification.title = filepath;
        notification.informativeText = message;
        notification.soundName = @"Sosumi";
        [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
    }
    [file closeFile];
}

- (void)concatFolder:(NSURL*)input toFile:(NSString*)destination {
    NSURL* output = [NSURL URLWithString:destination];
    NSFileManager* fm = [NSFileManager defaultManager];
    [fm createFileAtPath:output.path contents:nil attributes:nil];
    NSFileHandle *writer = [NSFileHandle fileHandleForWritingAtPath:output.path];
    input = [input URLByResolvingSymlinksInPath];
    
    NSDirectoryEnumerator *enumerator = [fm
                                         enumeratorAtURL:input
                                         includingPropertiesForKeys:@[NSURLIsDirectoryKey]
                                         options:NSDirectoryEnumerationSkipsHiddenFiles
                                         errorHandler:^(NSURL *url, NSError *error) {
                                             return YES;
                                         }];
    for (NSURL *url in enumerator) {
        NSError *error;
        NSNumber *isDirectory = nil;
        NSString* filename = [[url pathComponents]lastObject];
        if ([filename rangeOfString:@"."].location == 0) continue;
        if (! [url getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:&error]) {
            NSLog(@"Error in determining if a file is a directory: %@", error);
        } else if (![isDirectory boolValue]) {
            NSFileHandle* reader = [NSFileHandle fileHandleForReadingAtPath:url.path];
            [reader seekToFileOffset:0];
            [writer writeData:[reader readDataToEndOfFile]];
            [reader closeFile];
        }
    }
    [writer closeFile];
}

@end
