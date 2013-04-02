//
//  AppDelegate.h
//  Hostr for Mac
//
//  Created by Jonathan Cremin on 17/01/2013.
//  Copyright (c) 2013 Jonathan Cremin. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DataTube.h"
#import "StatusManager.h"
#import <CDEvents/CDEvents.h>

@interface AppDelegate : NSObject <NSApplicationDelegate, NSUserNotificationCenterDelegate>
{
    NSWindow *_preferencesWindow;
    NSWindowController *_preferencesWindowController;
	NSStatusItem *statusItem;
	IBOutlet NSMenu *statusMenu;
    NSTimer *animTimer;
    int currentFrame;
}

@property (strong, nonatomic) NSString *screenshotLocation;

@property (strong, nonatomic) NSDictionary *knownScreenshotsOnDesktop;

@property (strong, nonatomic) NSUserDefaults *defaults;

@property (strong, nonatomic) CDEvents *events;

@property (strong, nonatomic) NSNumber *uploadsCount;

@property (nonatomic, readonly) NSWindowController *preferencesWindowController;

@property (assign) IBOutlet NSWindow *loginWindow;

@property (strong, nonatomic) DataTube *filesTube;

@property (strong, nonatomic) StatusManager *statusManager;

@property (strong, nonatomic) IBOutlet NSTextField *emailField;
@property (strong, nonatomic) IBOutlet NSTextField *passwordField;

@property (strong, nonatomic) IBOutlet NSButton *registerLabel;
@property (strong, nonatomic) IBOutlet NSTextField *errorLabel;

@property (assign) BOOL *active;


- (IBAction)doRegister:(id)sender;
- (IBAction)authenticateLogin:(id)sender;
- (void)openPreferences;
- (void)logout;
- (void)appQuit;

@end
