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
        NSLog(@"Running compile operation for %@", self.directory);
        [self compile];
    }
}

- (void)compile {
    NSURL *outputURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:[[NSProcessInfo processInfo] globallyUniqueString]] isDirectory:YES];
    NSError* error;
    [[NSFileManager defaultManager] createDirectoryAtURL:outputURL withIntermediateDirectories:YES attributes:nil error:&error];
    NSLog(@"output %@ %@", outputURL, outputURL.path);
    
    [self compileFolder:self.directory toFolder:outputURL.path];
    [self concatFolder:outputURL toFile:@"/Users/michael/Desktop/out2.js"];
//    [[NSFileManager defaultManager] removeItemAtURL:outputURL error:nil];
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
    [task launch];
    //    NSData *data = [file readDataToEndOfFile];
    //    NSString *grepOutput = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
    //    NSLog (@"grep returned:\n%@", grepOutput);
    [file closeFile];
    
}

- (void)concatFolder:(NSURL*)input toFile:(NSString*)destination {
    NSURL* output = [NSURL URLWithString:destination];
    NSFileManager* fm = [NSFileManager defaultManager];
    [fm createFileAtPath:output.path contents:nil attributes:nil];
    NSError* err;
    NSArray* files = [fm contentsOfDirectoryAtPath:input.path error:&err];
    if (err) {
        NSLog(@"Error getting contents of path %@: %@", input.path, err);
        return;
    }
    
    NSFileHandle *writer = [NSFileHandle fileHandleForWritingAtPath:output.path];
    
    for (NSString* file in files) {
        NSFileHandle* reader = [NSFileHandle fileHandleForReadingAtPath:[input.path stringByAppendingPathComponent:file]];
        [reader seekToFileOffset:0];
        [writer writeData:[reader readDataToEndOfFile]];
        [reader closeFile];
    }
    [writer closeFile];
    
}

@end
