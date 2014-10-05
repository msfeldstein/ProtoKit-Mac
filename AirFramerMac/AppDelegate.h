//
//  AppDelegate.h
//  AirFramerMac
//
//  Created by Michael Feldstein on 8/6/14.
//  Copyright (c) 2014 Macromeez. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <CocoaHTTPServer/HTTPServer.h>
#import <CDEvents/CDEvents.h>
#import <CocoaAsyncSocket/AsyncSocket.h>

#import <CocoaAsyncSocket/GCDAsyncSocket.h>
#import "ProjectsModel.h"

@class SimulatorWindowController, PreferencesWindowController;

@interface AppDelegate : NSObject <NSApplicationDelegate, NSNetServiceDelegate, GCDAsyncSocketDelegate>

@property (assign) IBOutlet NSWindow* window;
@property (assign) IBOutlet NSPanel* helpPanel;
@property (assign) IBOutlet NSButton* helpButton;
@property (assign) IBOutlet NSButton* reloadButton;
@property (assign) IBOutlet NSView* statusIndicator;
@property (assign) IBOutlet NSTextField* statusText;
@property (assign) IBOutlet NSTextField* statusSubText;
@property (assign) IBOutlet NSImageView* qrView;
@property (assign) IBOutlet NSTableView* projectList;
@property (assign) IBOutlet ProjectsModel* projects;
@property (assign) IBOutlet NSView* statusContainer;
@property (assign) IBOutlet NSTextField* titleLabel;

@property (assign) IBOutlet NSView* trialView;
@property (assign) IBOutlet NSButton* purchaseButton;
@property (assign) IBOutlet NSButton* enterSerialButton;


@property NSNetService* netService;
@property HTTPServer* server;
@property CDEvents* watcher;
@property GCDAsyncSocket* watcherSocket;
@property WebSocket* reloadSocket;
@property NSMutableArray* connectedSockets;
@property SimulatorWindowController* simulatorController;
@property PreferencesWindowController* preferencesController;

@property NSURL* folder;

- (void)showSimulator:(NSString*)project;
- (void)showFolder:(NSString*)project;
- (void)openInEditor: (NSString*)project;

- (IBAction)newProject:(id)sender;
- (IBAction)chooseFolder:(id)sender;
- (IBAction)sendChange:(id)sender;
- (IBAction)showHelp:(id)sender;
- (IBAction)toggleConsole:(id)sender;
- (IBAction)showPreferences:(id)sender;
- (IBAction)minimize:(id)sender;

- (IBAction)purchase:(id)sender;
- (IBAction)enterLicense:(id)sender;
@end
