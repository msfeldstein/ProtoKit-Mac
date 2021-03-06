//
//  Compiler.m
//  ProtoKit
//
//  Created by Michael Feldstein on 8/20/14.
//  Copyright (c) 2014 Macromeez. All rights reserved.
//

#import "Compiler.h"
#import <CDEvents/CDEvents.h>
#import "CompileOperation.h"

@interface Compiler () {
    CDEvents* _watcher;
    NSOperationQueue* _queue;
}

@end

@implementation Compiler

- (id) initWithProjectDirectory:(NSString*)directory {
    self = [super init];
    self.directory = directory;
    if (![[NSFileManager defaultManager] fileExistsAtPath:[self.directory stringByAppendingPathComponent:@"frame-compile.json"]]) {
        self.isFrameProject = NO;
        return self;
    }
    self.isFrameProject = YES;
    [self setupWatchers];
    return self;
}

- (void)setupWatchers {
    _queue = [[NSOperationQueue alloc] init];
    NSArray* paths = @[[NSURL fileURLWithPath:self.directory]];
    CDEventsEventStreamCreationFlags creationFlags = kCDEventsDefaultEventStreamFlags | kFSEventStreamCreateFlagIgnoreSelf | kFSEventStreamCreateFlagFileEvents;
    _watcher = [[CDEvents alloc] initWithURLs:paths delegate:self onRunLoop:[NSRunLoop currentRunLoop] sinceEventIdentifier:kCDEventsSinceEventNow notificationLantency:1.0f ignoreEventsFromSubDirs:NO excludeURLs:@[] streamCreationFlags:creationFlags];
    [self doCompile];
}

- (void)URLWatcher:(CDEvents *)URLWatcher eventOccurred:(CDEvent *)event {
    if ([event.URL.lastPathComponent isEqualToString:@"compiled.js"] || [event.URL.lastPathComponent hasPrefix:@"."])
        return;
    [self doCompile];
}

- (void)doCompile {
    CompileOperation* compilation = [[CompileOperation alloc] initWithProjectDirectory:self.directory];
    NSBlockOperation* complete = [NSBlockOperation blockOperationWithBlock:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:@"COMPILE_COMPLETE" object:self];
        });
    }];
    [complete addDependency:compilation];
    [_queue addOperation:compilation];
    [_queue addOperation:complete];
}

- (void)convertToFrameProject {
    [self writeConfigFile];
    [self rewriteHTML];
    self.isFrameProject = YES;
    [self setupWatchers];
}

- (void)writeConfigFile {
    NSString* config = @"{\"compile\": true,\"resources\": true}";
    NSString* configPath = [self.directory stringByAppendingPathComponent:@"frame-compile.json"];
    NSLog(@"Config Path %@", configPath);
    if (![[NSFileManager defaultManager] fileExistsAtPath:configPath]) {
        NSError* err;
        [config writeToFile:configPath atomically:YES encoding:NSASCIIStringEncoding error:&err];
        if (err) {
            NSLog(@"Error creating config file %@", err);
        }
    }
}

- (void)rewriteHTML {
    
}

@end
