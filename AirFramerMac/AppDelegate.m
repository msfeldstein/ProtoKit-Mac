//
//  AppDelegate.m
//  AirFramerMac
//
//  Created by Michael Feldstein on 8/6/14.
//  Copyright (c) 2014 Macromeez. All rights reserved.
//

#import "AppDelegate.h"
#import "MyHTTPConnection.h"
#import "ManifestGenerator.h"
#import "QRCodeGenerator.h"
#import "ResourcesGenerator.h"
#import "SimulatorWindowController.h"
#import "Compiler.h"

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    self.connectedSockets = [NSMutableArray array];
    [self setupWatcherSocket];
    [self setupBonjour];
    NSString* defaultDirectory = [[NSUserDefaults standardUserDefaults] objectForKey:@"prototypeDirectory"];
    if (!defaultDirectory) {
        defaultDirectory = [@"~/Prototypes/" stringByExpandingTildeInPath];
        [[NSFileManager defaultManager] createDirectoryAtPath:defaultDirectory withIntermediateDirectories:YES attributes:nil error:nil];
        [[NSUserDefaults standardUserDefaults] setObject:defaultDirectory forKey:@"prototypeDirectory"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }

    self.folder = [NSURL fileURLWithPath:defaultDirectory];
    
    [self reconfig];
    
    self.statusIndicator.layer.cornerRadius = 8;
    self.statusIndicator.layer.backgroundColor = [NSColor colorWithCalibratedRed:1.0 green:127.0 / 255.0 blue:127.0 / 255.0 alpha:1.0].CGColor;

    [self.reloadButton setHidden:YES];
    
    self.qrView.layer.backgroundColor = [NSColor whiteColor].CGColor;
    self.qrView.image = [QRCodeGenerator qrImageForString:[self getIPAddress] imageSize:self.qrView.bounds.size.width];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changed:) name:@"COMPILE_COMPLETE" object:nil];
    self.window.backgroundColor = [NSColor whiteColor];
    [self addBorders];
    self.simulatorController = [[SimulatorWindowController alloc] init];
}

- (void) addBorders {
    CGRect frame = self.statusContainer.bounds;
    frame.origin.y = frame.size.height - 1;
    frame.size.height = 1;
    frame.size.width -= 60;
    frame.origin.x = 30;
    
    NSView* border = [[NSView alloc] initWithFrame:frame];
    border.wantsLayer = YES;
    border.layer.backgroundColor = [NSColor colorWithWhite:0.94 alpha:1].CGColor;
    [self.statusContainer addSubview:border];

    frame.origin.y = 494;
    border = [[NSView alloc] initWithFrame:frame];
    border.wantsLayer = YES;
    border.layer.backgroundColor = [NSColor colorWithWhite:0.94 alpha:1].CGColor;
    [self.window.contentView addSubview:border];
}

- (void) changed:(NSNotification*) n {
    Compiler* c = n.object;
    [self sendChangeNotification:[NSString stringWithFormat:@"change:%@", c.directory.lastPathComponent]];
}

- (void)showSimulator:(NSString*)project {
    NSString* urlStr = [self urlForProject:project];
    NSURL* url = [NSURL URLWithString:[urlStr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    [[NSWorkspace sharedWorkspace] openURL:url];
    //    [self.simulatorController showWindow:nil];
    

    //    [self.simulatorController loadURL:[urlStr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
}

- (void)launchInChrome:(NSString*)project {
    NSString* urlStr = [self urlForProject:project];
    NSURL* url = [NSURL URLWithString:[urlStr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    [[NSWorkspace sharedWorkspace] openURL:url];
}


- (void)showFolder:(NSString*)project {
    NSString* path = [self filePathForProjectFolder:project];
    NSWorkspace* ws = [NSWorkspace sharedWorkspace];
    [ws openURL:[NSURL fileURLWithPath:path]];
}

- (void)openInEditor: (NSString*)project {
    NSString* path = [self filePathForProjectFolder:project];
    NSWorkspace* ws = [NSWorkspace sharedWorkspace];
    [ws openFile:path withApplication:@"Sublime Text 2"];
}

- (NSString*)filePathForProjectFolder:(NSString*)project {
    return [self.folder.path stringByAppendingPathComponent:project];
}

- (NSString*)urlForProject:(NSString*)project {
    return [NSString stringWithFormat:@"http://%@:%i/%@/index.html",[self getIPAddress], 3007, project];
}

- (IBAction)chooseFolder:(id)sender {
    NSOpenPanel* openDlg = [NSOpenPanel openPanel];
    openDlg.canChooseFiles = NO;
    openDlg.canChooseDirectories = YES;
    openDlg.prompt = @"Select";
    openDlg.title = @"Select Workspace Folder";
    if ([openDlg runModal] == NSOKButton) {
        NSURL* url = openDlg.URL;
        if ([url.pathExtension isEqualToString:@"framer"]) {
            url = [NSURL URLWithString:[url.absoluteString stringByDeletingLastPathComponent]];
        }
        self.folder = url;
        [[NSUserDefaults standardUserDefaults] setObject:self.folder.path forKey:@"prototypeDirectory"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [self reconfig];
    }
}

- (void) reconfig {
    NSString* title = [NSString stringWithFormat:@"Frame - %@", [self.folder.path stringByAbbreviatingWithTildeInPath]];
    [self.titleLabel setStringValue:title];
    [self.projects setFolder:self.folder];
    [self.projects reload];
//    CGRect frame = self.window.frame;
//    CGRect tableFrame = self.projectList.frame;
//    NSPoint tableOrigin = [self.projectList convertPoint:self.projectList.frame.origin toView:nil];
//    frame.size.height = 50 * [self.projects projects].count + 300;
//    [self.window setFrame:frame display:YES animate:YES];
    [self setupServer];
    [self sendChangeNotification:@"CHANGE"];
}

- (void) setupServer {
    if (!self.server) {
        self.server = [[HTTPServer alloc] init];
        self.server.type = @"_http._tcp.";
        self.server.port = 3007;
        self.server.connectionClass = [MyHTTPConnection class];
        NSError *error = nil;
        if(![self.server start:&error])
        {
            NSLog(@"Error starting HTTP Server: %@", error);
        }
    }
    self.server.documentRoot = self.folder.path;
}

- (void)setupWatcherSocket {
    self.watcherSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    NSError* err;
    [self.watcherSocket acceptOnPort:3008 error:&err];
    self.watcherSocket.delegate = self;
    if (err) {
        NSLog(@"ERROR %@", err);
    }
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag { }

- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket {
    NSLog(@"Did accept new socket");
    [self.connectedSockets addObject:newSocket];
    [self updateLabel];
}

- (void) socketDidDisconnect:(GCDAsyncSocket *)socket withError:(NSError *)err {
    NSLog(@"Did disconnect socket");
    [self.connectedSockets removeObject:socket];
    [self updateLabel];
}

- (void)updateLabel {
    if (self.connectedSockets.count > 0) {
        self.statusIndicator.layer.backgroundColor = [NSColor colorWithCalibratedRed:185.0 / 255.0 green:233.0 / 255.0 blue:134.0 / 255.0 alpha:1.0].CGColor;
        self.statusSubText.stringValue = @"";
        if (self.connectedSockets.count == 1) {
            self.statusText.stringValue = @"One phone connected";
            
        } else {
            self.statusText.stringValue = [NSString stringWithFormat:@"%lu phones connected", (unsigned long)self.connectedSockets.count];
        }
        [self.reloadButton setHidden:NO];
        [self.helpButton setHidden:YES];
    } else {
        [self.reloadButton setHidden:YES];
        [self.helpButton setHidden:NO];
        self.statusIndicator.layer.backgroundColor = [NSColor colorWithCalibratedRed:1.0 green:127.0 / 255.0 blue:127.0 / 255.0 alpha:1.0].CGColor;
        self.statusText.stringValue = @"No device connected";
        self.statusSubText.stringValue = @"Make sure it's on the same Wi-Fi network";
    }
}

- (void) setupBonjour {
    self.netService = [[NSNetService alloc] initWithDomain:@"" type:@"_airframer._tcp" name:@"" port:3007];
    if (self.netService) {
        [self.netService scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:@"PrivateMyMacServiceMode"];
        
        [self.netService setDelegate:self];
        [self.netService publish];
        [self.netService startMonitoring];
    } else {
        NSLog(@"FAIL setupBonjour!");
    }
    
}


- (void) sendChangeNotification:(NSString*)message {
    NSData* data = [message dataUsingEncoding:NSUTF8StringEncoding];
    for (GCDAsyncSocket* socket in self.connectedSockets) {
        [socket writeData:data withTimeout:-1 tag:0];
    }
}

- (IBAction)sendChange:(id)sender {
    [self sendChangeNotification:@"CHANGE"];
}

-(NSString *)getIPAddress
{
    for (NSString* address in [[NSHost currentHost] addresses]) {
        if ([address componentsSeparatedByString:@"."].count == 4) {
            if (![address isEqualToString:@"127.0.0.1"]) {
                return address;
            }
        }
    }
    return nil;
}

- (IBAction)showHelp:(id)sender {
    [self.helpPanel makeKeyAndOrderFront:self];
}

- (IBAction)newProject:(id)sender {
    NSString* name = [self input:@"Name of prototype" defaultValue:@"New Project"];
    if (!name || [name length] == 0) return;
    name = [name stringByAppendingPathExtension:@"framer"];
    NSFileManager* fm = [NSFileManager defaultManager];
    NSBundle* bundle = [NSBundle mainBundle];
    NSString* templatePath = [bundle pathForResource:@"example" ofType:@"framer"];
    NSError* err;
    NSString* newPath = [self.folder.path stringByAppendingPathComponent:name];
    [fm copyItemAtPath:templatePath toPath:newPath error:&err];
    if (err) {
        NSLog(@"Error copying new project template %@", err);
    }
    NSURL* folderURL = [NSURL fileURLWithPath:newPath];

    [[NSWorkspace sharedWorkspace] openURL: [NSURL URLWithString:[self urlForProject:name]]];
    [[NSWorkspace sharedWorkspace] openURL: folderURL];
    [self.projects reload];
}

- (NSString *)input: (NSString *)prompt defaultValue: (NSString *)defaultValue {
    NSAlert *alert = [NSAlert alertWithMessageText: prompt
                                     defaultButton:@"OK"
                                   alternateButton:@"Cancel"
                                       otherButton:nil
                         informativeTextWithFormat:@""];
    
    NSTextField *input = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 200, 24)];
    [input setStringValue:defaultValue];
    [alert setAccessoryView:input];
    NSInteger button = [alert runModal];
    if (button == NSAlertDefaultReturn) {
        [input validateEditing];
        return [input stringValue];
    }
    return nil;
}

- (IBAction)toggleConsole:(id)sender {
    [self.simulatorController toggleConsole];
}

- (IBAction)setSimulatorZoomLevel:(NSMenuItem*)sender {
    [self.simulatorController setZoomLevel:(int)sender.tag];
}

@end
