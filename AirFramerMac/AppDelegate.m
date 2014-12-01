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
#import "PreferencesWindowController.h"
#import "QRCodeGenerator.h"
#import "ResourcesGenerator.h"
#import "SimulatorWindowController.h"
#import "Compiler.h"
#import "Constants.h"

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
    //self.simulatorController = [[SimulatorWindowController alloc] init];
    
    self.trialView.layer.backgroundColor = [NSColor colorWithCalibratedRed:74.0 / 255.0 green:144.0 / 255.0 blue:226.0 / 255.0 alpha:1.0].CGColor;
    [self checkTrialStatus];
    [[NSUserDefaults standardUserDefaults] setBool:TRUE forKey:@"WebKitDeveloperExtras"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void) addBorders {
    self.divider.wantsLayer = YES;
    self.divider.layer.backgroundColor = [NSColor colorWithWhite:0 alpha:0.1].CGColor;
    self.bottomDivider.wantsLayer = YES;
    self.bottomDivider.layer.backgroundColor = [NSColor colorWithWhite:0 alpha:0.1].CGColor;
    self.background.wantsLayer = YES;
    self.background.layer.backgroundColor = [NSColor colorWithWhite:1.0 alpha:1.0].CGColor;

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
    

      //  [self.simulatorController loadURL:[urlStr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
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
    NSString* editorURL = [[NSUserDefaults standardUserDefaults] stringForKey:@"editor_url"];
    if (!editorURL) {
        NSOpenPanel* openDlg = [NSOpenPanel openPanel];
        openDlg.canChooseFiles = YES;
        openDlg.canChooseDirectories = NO;
        openDlg.prompt = @"Open";
        openDlg.title = @"Choose Text Editor";
        openDlg.directoryURL = [NSURL URLWithString:@"/Applications"];
        if ([openDlg runModal] == NSOKButton) {
            editorURL = openDlg.URL.path;
        }
    }
    NSString* path = [self filePathForProjectFolder:project];
    NSWorkspace* ws = [NSWorkspace sharedWorkspace];
    BOOL success = [ws openFile:path withApplication:editorURL];
    if (success) {
        [[NSUserDefaults standardUserDefaults] setValue:editorURL forKeyPath:@"editor_url"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    } else {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert addButtonWithTitle:@"Okay :("];
        [alert setMessageText:@"Oops"];
        [alert setInformativeText:@"Couldn't open the project folder with that app.  Try something else."];
        [alert setAlertStyle:NSWarningAlertStyle];
        [alert beginSheetModalForWindow:[self window] modalDelegate:self didEndSelector:nil contextInfo:nil];
    }
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
    NSString* title = [NSString stringWithFormat:@"ProtoKit (%@)", [self.folder.path stringByAbbreviatingWithTildeInPath]];
    [self.titleLabel setStringValue:title];
    [self.projects setFolder:self.folder];
    [self.projects reload];
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
    [self.projects createProject:name];
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

- (IBAction)showPreferences:(id)sender {
    self.preferencesController = [[PreferencesWindowController alloc] init];
    [self.preferencesController showWindow:nil];
}

- (IBAction)minimize:(id)sender {
    [self.window miniaturize:sender];
}

- (IBAction)purchase:(id)sender {
    NSURL* url = [NSURL URLWithString:@"https://gumroad.com/l/framepro"];
    [[NSWorkspace sharedWorkspace] openURL:url];
}

- (IBAction)enterLicense:(id)sender {
    [self showPreferences:nil];
}

- (void)checkTrialStatus {
    NSUserDefaults* def = [NSUserDefaults standardUserDefaults];
    if ([def boolForKey:@"registered"]) {
        [self hideTrialBar];
    } else {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(registrationSuccess:) name:kRegistrationSuccessNotificationKey object:nil];
    }
    [self hideTrialBar];
}

- (void)registrationSuccess:(NSNotification*)n {
    [self hideTrialBar];
}

- (void)hideTrialBar {
    NSView* view = self.trialView;
    [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[view(==0)]"
                                                                 options:0
                                                                 metrics:nil
                                                                   views:NSDictionaryOfVariableBindings(view)]];
}

@end
