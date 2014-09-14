//
//  CompileOperation.m
//  AirFramerMac
//
//  Created by Michael Feldstein on 8/20/14.
//  Copyright (c) 2014 Macromeez. All rights reserved.
//

#import "CompileOperation.h"
#import "ResourcesGenerator.h"

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
    NSFileManager* fm = [NSFileManager defaultManager];
    NSLog(@"Compiling %@", self.directory);
    if (![fm fileExistsAtPath:self.directory]) {
        NSLog(@"Folder no longer exists %@", self.directory);
        return;
    }
    NSURL *outputURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:[[NSProcessInfo processInfo] globallyUniqueString]] isDirectory:YES];
    NSError* error;
    [fm createDirectoryAtURL:outputURL withIntermediateDirectories:YES attributes:nil error:&error];
    [self compileFolder:self.directory toFolder:outputURL.path];
    [self copyJavascriptsAtFolder:[self.directory stringByAppendingPathComponent:@"scripts"] toFolder:outputURL.path];
    [self generateResources:self.directory toFolder:outputURL.path];
    NSURL* outFolder = [NSURL fileURLWithPath:[self.directory stringByAppendingPathComponent:@"out"]];
    [fm createDirectoryAtURL:outFolder withIntermediateDirectories:YES attributes:nil error:&error];
    NSString* compiledFile = [self.directory stringByAppendingPathComponent:@"out/compiled.js"];
    [self concatFolder:outputURL toFile:compiledFile];
    [fm removeItemAtURL:outputURL error:nil];
}

- (void)copyJavascriptsAtFolder:(NSString*)folder toFolder:(NSString*)destination {
    NSString* env = [[NSBundle mainBundle] pathForResource:@"JSEnv" ofType:@""];
    NSString* nodePath = [env stringByAppendingPathComponent:@"node"];
    NSString* scriptPath = [[NSBundle mainBundle] pathForResource:@"copy-javascripts" ofType:@"js"];
    NSPipe *pipe = [NSPipe pipe];
    NSTask *task = [[NSTask alloc] init];
    task.launchPath = nodePath;
    task.arguments = @[scriptPath, folder, destination];
    task.standardOutput = pipe;
    task.standardError = pipe;
    [task launch];
    
    // We need to actually read the data here otherwise NSTask will return asynchronously and the files wont be there for the next step
    [[pipe fileHandleForReading] readDataToEndOfFile];
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
        NSString* message = parts[1];
        notification.title = filepath;
        notification.informativeText = message;
        notification.soundName = @"Sosumi";
        [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
    }
    [file closeFile];
}

- (void)generateResources:(NSString*)path toFolder:(NSString*)destination {
    ResourcesGenerator* generator = [[ResourcesGenerator alloc] init];
    NSDictionary* files = [generator generateManifestInProject:path directory:@"images"];
    NSError* err;
    NSData* data = [NSJSONSerialization dataWithJSONObject:files options:0 error:&err];
    if (err) {
        NSLog(@"Error creating resources %@", err);
        return;
    }
    NSURL* destinationURL = [NSURL fileURLWithPath:[destination stringByAppendingPathComponent:@"resources.js"]];
    NSFileManager* fm = [NSFileManager defaultManager];
    [fm createFileAtPath:destinationURL.path contents:nil attributes:nil];
    NSFileHandle *writer = [NSFileHandle fileHandleForWritingAtPath:destinationURL.path];
    [writer writeData:[@"\n\nwindow.Resources = " dataUsingEncoding:NSUTF8StringEncoding]];
    [writer writeData:data];
    [writer writeData:[@";\n\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [writer closeFile];
}

- (void)concatFolder:(NSURL*)input toFile:(NSString*)destination {
    NSURL* output = [NSURL fileURLWithPath:destination];
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
    NSURL * appPath = nil;
    for (NSURL *url in enumerator) {
        NSError *error;
        NSNumber *isDirectory = nil;
        NSString* filename = [[url pathComponents]lastObject];
        if ([filename isEqualToString:@"app.js"]) {
            // Lets append app.js last so it as access to all classes
            appPath = url;
            continue;
        }
        if ([filename rangeOfString:@"."].location == 0) continue;
        if (! [url getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:&error]) {
            NSLog(@"Error in determining if a file is a directory: %@", error);
        } else if (![isDirectory boolValue]) {
            [self appendFile:url.path toFile:writer];
        }
    }
    [self appendFile:appPath.path toFile:writer];
    
    
    [writer closeFile];
}

- (void) appendFile:(NSString*)path toFile:(NSFileHandle*)writer {
    NSFileHandle* reader = [NSFileHandle fileHandleForReadingAtPath:path];
    [reader seekToFileOffset:0];
    [writer writeData:[reader readDataToEndOfFile]];
    [reader closeFile];
}

@end
