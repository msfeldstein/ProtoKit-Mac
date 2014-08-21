//
//  Compiler.m
//  AirFramerMac
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
    _queue = [[NSOperationQueue alloc] init];
    NSArray* paths = @[[NSURL fileURLWithPath:self.directory]];
    CDEventsEventStreamCreationFlags creationFlags = kCDEventsDefaultEventStreamFlags | kFSEventStreamCreateFlagIgnoreSelf | kFSEventStreamCreateFlagFileEvents;
    _watcher = [[CDEvents alloc] initWithURLs:paths delegate:self onRunLoop:[NSRunLoop currentRunLoop] sinceEventIdentifier:kCDEventsSinceEventNow notificationLantency:1.0f ignoreEventsFromSubDirs:NO excludeURLs:@[] streamCreationFlags:creationFlags];
    [self doCompile];
    return self;
}

- (void)URLWatcher:(CDEvents *)URLWatcher eventOccurred:(CDEvent *)event {
    if (![event.URL.lastPathComponent isEqualToString:@"compiled.js"])
        [self doCompile];
}

- (void)doCompile {
    CompileOperation* compilation = [[CompileOperation alloc] initWithProjectDirectory:self.directory];
    NSBlockOperation* complete = [NSBlockOperation blockOperationWithBlock:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:@"SOURCE_HAS_CHANGED" object:self];
        });
    }];
    [complete addDependency:compilation];
    [_queue addOperation:compilation];
    [_queue addOperation:complete];
}

@end
