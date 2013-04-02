//
//  AppDelegate.m
//  Hostr for Mac
//
//  Created by Jonathan Cremin on 17/01/2013.
//  Copyright (c) 2013 Jonathan Cremin. All rights reserved.
//

#import "AppDelegate.h"
#import "constants.h"
#import "NSStatusItem+BCStatusItem.h"
#import "BCStatusItemView.h"
#import "HostrApiClient.h"
#import <AFHTTPClient.h>
#import "File.h"
#import "User.h"
#import "SSKeychain.h"
#import "DataTube.h"
#import <Sparkle/Sparkle.h>
#import <MASPreferencesWindowController.h>
#import "AccountPreferencesViewController.h"
#import "GeneralPreferencesViewController.h"
#import "UpdatePreferencesViewController.h"
#import "AboutViewController.h"
#import "StatusManager.h"
#import <QuartzCore/QuartzCore.h>


@implementation AppDelegate

@synthesize emailField, passwordField, registerLabel, errorLabel, active, statusManager, defaults, knownScreenshotsOnDesktop, screenshotLocation;

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication {
    User *user = [User getInstance];
    if(user.email || (active == nil)) {
        return NO;
    }
    return YES;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {

    defaults = [NSUserDefaults standardUserDefaults];
    
    if ([defaults objectForKey:@"automaticallyCopy"] == NULL) {
        [defaults setInteger:1 forKey:@"automaticallyCopy"];
    }
    
    if ([defaults objectForKey:@"automaticallyUpload"] == NULL) {
        [defaults setInteger:1 forKey:@"automaticallyUpload"];
    }

    if ([defaults objectForKey:@"automaticallyUpload"] == [NSNumber numberWithInteger:1]) {
        knownScreenshotsOnDesktop = [NSDictionary dictionary];
        knownScreenshotsOnDesktop = [self screenshotsOnDesktop];
        NSString *desktop = NSHomeDirectory();
        screenshotLocation = [desktop stringByAppendingString:@"/Desktop"];
        NSURL *url  = [NSURL URLWithString:screenshotLocation];
        NSArray *urls = [NSArray arrayWithObject:url];
        self.events = [[CDEvents alloc] initWithURLs:urls block:
           ^(CDEvents *watcher, CDEvent *event) {
               NSLog(
                     @"URLWatcher: %@\nEvent: %@",
                     watcher,
                     event
                     );
               if ([defaults objectForKey:@"automaticallyUpload"] == [NSNumber numberWithInteger:1]) {
                   [self checkForScreenshotsAtPath:screenshotLocation];
               }
           }];
        
        self.events.ignoreEventsFromSubDirectories = YES;
    }
    
    if ([defaults objectForKey:@"autoUpdate"] == NULL) {
        [defaults setInteger:1 forKey:@"autoUpdate"];
    }
    else {
        [[SUUpdater sharedUpdater] setAutomaticallyChecksForUpdates:[defaults objectForKey:@"autoUpdate"]];
    }

    [self.loginWindow close];
    
    NSMutableAttributedString *coloredString;
    
    coloredString = [[NSMutableAttributedString alloc] initWithString:@"I don't have an account"
                                                    attributes:[NSDictionary dictionaryWithObject:[NSColor blackColor]
                                                                                           forKey:NSForegroundColorAttributeName]];
    
    [coloredString addAttribute:NSUnderlineStyleAttributeName value:[[NSNumber alloc] initWithInt:NSUnderlineStyleSingle] range:NSMakeRange(0,coloredString.length)];
     
    [registerLabel setAttributedTitle:coloredString];
    
    // Setup Status Item
	statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    NSImage *image = [NSImage imageNamed:@"menu-icon"];
    NSImage *alternateImage = [NSImage imageNamed:@"menu-icon-alt"];
    [alternateImage setTemplate:YES];
	[statusItem setupView];
	
	[statusItem setMenu:statusMenu];
	[statusItem setHighlightMode:YES];
	
	[statusItem setImage:image];
	[statusItem setAlternateImage:alternateImage];
	
    [statusItem setTarget:self];
    [statusItem setAction:@selector(logout)];
    
	[statusItem setViewDelegate:self];
	[[statusItem view] registerForDraggedTypes:[NSArray arrayWithObjects:NSFilenamesPboardType, nil]];
    
    self.filesTube = [[DataTube alloc] initWithSize:5];
    statusManager = [StatusManager getInstance];
    [statusManager initWithMenu:statusMenu];
    
    // Check for existing valid credentials
    NSArray *accounts = [SSKeychain accountsForService:siteBase];

    if (accounts.count > 0){
        NSString *account = accounts[0][@"acct"];
        NSLog(@"Authenticating from applicationDidFinishLaunching");
        [self authenticate:account withPassword:[SSKeychain passwordForService:siteBase account:account] newLogin:NO];
    }
    else{
        NSLog(@"No Stored Accounts Found");
        [self.loginWindow makeKeyAndOrderFront:nil];
        active = YES;
    }
    
    [self.loginWindow setBackgroundColor:[NSColor colorWithPatternImage:[NSImage imageNamed:@"login-backdrop.png"]]];
    [NSApp activateIgnoringOtherApps:YES];
    [[NSUserNotificationCenter defaultUserNotificationCenter] setDelegate:self];
}

-(void)checkForScreenshotsAtPath:(NSString *)dirpath {
	NSDictionary *files;
	NSArray *paths;
    
	// find new screenshots
	if (!(files = [self findUnprocessedScreenshotsOnDesktop]))
		return;
    
	// sort on key (path)
	paths = [files keysSortedByValueUsingComparator:^(id a, id b) { return [b compare:a]; }];
    
	// process each file
	for (NSString *path in paths) {
        [self uploadFile:[[NSURL alloc] initFileURLWithPath:path]];
	}
}

// This keeps state, so be careful when calling since it will return different
// thing for each call (or nil if there are no new files).
-(NSDictionary *)findUnprocessedScreenshotsOnDesktop {
	NSDictionary *currentFiles;
	NSMutableDictionary *files;
	NSMutableSet *newFilenames;
    
	currentFiles = [self screenshotsOnDesktop];
	files = nil;
    
	if ([currentFiles count]) {
		newFilenames = [NSMutableSet setWithArray:[currentFiles allKeys]];
		// filter: remove allready processed screenshots
		[newFilenames minusSet:[NSSet setWithArray:[knownScreenshotsOnDesktop allKeys]]];
		if ([newFilenames count]) {
			files = [NSMutableDictionary dictionaryWithCapacity:1];
			for (NSString *path in newFilenames) {
				[files setObject:[currentFiles objectForKey:path] forKey:path];
			}
		}
	}
    
	knownScreenshotsOnDesktop = currentFiles;
	return files;
}

-(NSDictionary *)screenshotsOnDesktop {
	NSDate *lmod = [NSDate dateWithTimeIntervalSinceNow:-5]; // max 5 sec old
	return [self screenshotsAtPath:screenshotLocation modifiedAfterDate:lmod];
}

/**
 * Pick-up workshorse function.
 */
-(NSDictionary *)screenshotsAtPath:(NSString *)dirpath modifiedAfterDate:(NSDate *)lmod {
	NSFileManager *fm = [NSFileManager defaultManager];
	NSArray *direntries;
	NSMutableDictionary *files = [NSMutableDictionary dictionary];
	NSString *path;
	NSDate *mod;
	NSError *error;
	NSDictionary *attrs;
    
	direntries = [fm contentsOfDirectoryAtPath:dirpath error:&error];
	if (!direntries) {
		return nil;
	}
    
	for (NSString *fn in direntries) {
		//[log debug:@"%s testing %@", _cmd, fn];
        
		// always skip dotfiles
		if ([fn hasPrefix:@"."]) {
			//[log debug:@"%s skipping: filename begins with a dot", _cmd];
			continue;
		}
        
		// skip any file not ending in screenshotFilenameSuffix (".png" by default)
		if (([fn length] < 10) ||
            // ".png" suffix is expected
            (![fn compare:@"png" options:NSCaseInsensitiveSearch range:NSMakeRange([fn length]-5, 4)] != NSOrderedSame)
            )
		{
			//[log debug:@"%s skipping: not ending in \".png\" (case-insensitive)", _cmd];
			continue;
		}
        
		// build path
		path = [dirpath stringByAppendingPathComponent:fn];
        
		// Skip any file which name does not contain a SP.
		// This is a semi-ugly fix -- since we want to avoid matching the filename against
		// all possible screenshot file name schemas (must be hundreds), we make the
		// assumption that all language formats have this in common: it contains at least one SP.
		if ([fn rangeOfString:@" "].location == NSNotFound) {
			//[log debug:@"%s skipping: not containing SP", _cmd];
			continue;
		}
        
		// query file attributes (rich stat)
		attrs = [fm attributesOfItemAtPath:path error:&error];
		if (!attrs) {
			//[log error:@"failed to read attributes of '%@' because: %@ -- skipping", path, error];
			continue;
		}
        
		// must be a regular file
		if ([attrs objectForKey:NSFileType] != NSFileTypeRegular) {
			//[log debug:@"%s skipping: not a regular file", _cmd];
			continue;
		}
        
		// check last modified date
		mod = [attrs objectForKey:NSFileModificationDate];
		if (lmod && (!mod || [mod compare:lmod] == NSOrderedAscending)) {
			// file is too old
			//[log debug:@"%s skipping: too old", _cmd];
			continue;
		}
        
		// find key for NSFileExtendedAttributes
		NSString *xattrsKey = nil;
		for (NSString *k in [attrs keyEnumerator]) {
			if ([k isEqualToString:@"NSFileExtendedAttributes"]) {
				xattrsKey = k;
				break;
			}
		}
		if (!xattrsKey) {
			// no xattrs
			continue;
		}
		NSDictionary *xattrs = [attrs objectForKey:xattrsKey];
		if (!xattrs || ![xattrs objectForKey:@"com.apple.metadata:kMDItemIsScreenCapture"]) {
			continue;
		}
        
		// ok, let's use this file (set: string path => date modified)
		[files setObject:mod forKey:path];
	}
    
	return files;
}

-(void)loadFiles
{
    [statusManager clearFileList];
    [[HostrApiClient sharedInstance] getPath:@"/api/file?perpage=5" parameters:nil
        success:^(AFHTTPRequestOperation *operation, id response) {
            for (id value in [response reverseObjectEnumerator])
            {
                File *file = [File alloc];
                [file setId:[value objectForKey:@"id"]];
                [file setName:[value objectForKey:@"name"]];
                [file setHref:[value objectForKey:@"href"]];
                [file setDirect:[value objectForKey:@"direct"]];
                [file setSize:[value objectForKey:@"size"]];
                [statusManager addToFileList:file];
            }
        }
        failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"ERROR");
            NSLog(@"%@", error);
        }
    ];
}


-(void)refreshUser
{
    [[HostrApiClient sharedInstance] getPath:@"/api/user" parameters:nil
         success:^(AFHTTPRequestOperation *operation, id response) {
             User *user = [User getInstance];
             
             [user setId:[response objectForKey:@"id"]];
             [user setPlan:[response objectForKey:@"plan"]];
             [user setDailyUploadAllowance:[response objectForKey:@"daily_upload_allowance"]];
             [user setUploadsToday:[response objectForKey:@"uploads_today"]];
             [user setFileCount:[response objectForKey:@"file_count"]];
             [user setMaxFilesize:[response objectForKey:@"max_filesize"]];
         }
         failure:^(AFHTTPRequestOperation *operation, NSError *error) {
             NSLog(@"ERROR");
             NSLog(@"%@", error);
         }
     ];
}

- (void)authenticate:(NSString *)email withPassword:(NSString *)password newLogin:(BOOL)newLogin{
    
    [[HostrApiClient sharedInstance] setUsername:email andPassword:password];
    
    [[HostrApiClient sharedInstance] getPath:@"/api/user" parameters:nil
        success:^(AFHTTPRequestOperation *operation, id response) {
            User *user = [User getInstance];
            
            [user setId:[response objectForKey:@"id"]];
            [user setEmail:[response objectForKey:@"email"]];
            [user setPassword:password];
            [user setPlan:[response objectForKey:@"plan"]];
            [user setDailyUploadAllowance:[response objectForKey:@"daily_upload_allowance"]];
            [user setUploadsToday:[response objectForKey:@"uploads_today"]];
            [user setFileCount:[response objectForKey:@"file_count"]];
            [user setMaxFilesize:[response objectForKey:@"max_filesize"]];
            
            NSLog(@"Logged in");
            [errorLabel setStringValue:@""];
            [SSKeychain setPassword:password forService:siteBase account:email];
            [[StatusManager getInstance] buildMenu];
            [self loadFiles];
            [self.loginWindow close];
            active = YES;
            [[StatusManager getInstance] _reconnect];
        }
        failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"ERROR");
            NSLog(@"%@", error);
            
            if(kCFURLErrorNotConnectedToInternet == [error code]) {
                NSLog(@"NO INTERNETS");
            }
            
            if([[error localizedRecoverySuggestion] hasPrefix:@"{"]) {
                NSData* data = [[error localizedRecoverySuggestion] dataUsingEncoding:NSUTF8StringEncoding];
                NSDictionary *errorJSON = [NSJSONSerialization JSONObjectWithData:data options:nil error:nil];
                NSLog(@"%@", [errorJSON objectForKey:@"error"]);

                [errorLabel setStringValue:[[errorJSON objectForKey:@"error"] objectForKey:@"message"]];
            }
            if (!newLogin && kCFURLErrorNotConnectedToInternet == [error code]) {
                [[StatusManager getInstance] buildMenu];
            }
            else {
                [errorLabel setStringValue:@"There was an error logging you in"];
                [self.loginWindow makeKeyAndOrderFront:self];
                active = YES;
            }
        }
    ];
}

-(void)authenticateLogin: (id)sender{
    NSLog(@"Authenticating from Login Form");
    [self authenticate:emailField.stringValue withPassword:passwordField.stringValue newLogin:YES];
}

- (NSDragOperation)statusItemView:(BCStatusItemView *)view draggingEntered:(id <NSDraggingInfo>)info
{
	return NSDragOperationCopy;
}

- (void)statusItemView:(BCStatusItemView *)view draggingExited:(id <NSDraggingInfo>)info
{

}

- (BOOL)statusItemView:(BCStatusItemView *)view prepareForDragOperation:(id <NSDraggingInfo>)info
{
	return YES;
}

// Handle files dropped on the status item

- (BOOL)statusItemView:(BCStatusItemView *)view performDragOperation:(id <NSDraggingInfo>)info
{
    User *user = [User getInstance];
    int i;
    NSInteger count;
    
    count = [info.draggingPasteboard.pasteboardItems count];
    
    if (![user.dailyUploadAllowance isEqual:@"unlimited"] && count > ((int)user.dailyUploadAllowance-(int)user.uploadsToday)) {
        NSUserNotification *notification = [[NSUserNotification alloc] init];
        notification.title = @"File Upload Error! :(";
        notification.informativeText = [NSString stringWithFormat: @"You tried to upload %d more than your daily allowance. Upgrade to pro for unlimited uploads.", count > ((int)user.dailyUploadAllowance-(int)user.uploadsToday)];
        notification.soundName = @"Tink.aiff";
        
        [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
        return NO;
    }
    
    for (i = 0; i < count; i++)
    {
        NSPasteboardItem *item = info.draggingPasteboard.pasteboardItems[i];
        
        NSURL *fileURL = [[NSURL alloc] initWithString:[item stringForType:@"public.file-url"]];
        NSDictionary *filesize = [fileURL resourceValuesForKeys:[[NSArray alloc] initWithObjects:NSURLFileSizeKey, nil] error:nil];
        NSLog(@"%@", filesize[NSURLFileSizeKey]);
        NSLog(@"%@", user.maxFilesize);
        if(filesize[NSURLFileSizeKey] > user.maxFilesize) {
            NSUserNotification *notification = [[NSUserNotification alloc] init];
            notification.title = @"File Upload Error! :(";
            notification.informativeText = @"The file you tried to upload is too large.";
            notification.soundName = @"Tink.aiff";
            
            [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
            return NO;
        }
        
        [self uploadFile:fileURL];
    }
	return YES;
}

-(void)uploadFile:(id)fileURL
{
    User *user = [User getInstance];
    File *uploadingFile = [File alloc];
    [uploadingFile setName:[[fileURL pathComponents] lastObject]];
    [statusManager addToActivityList:uploadingFile percentage:0];
    
    NSURLRequest *request = [[HostrApiClient sharedInstance] multipartFormRequestWithMethod:@"POST" path:@"/api/file" parameters:nil constructingBodyWithBlock: ^(id <AFMultipartFormData> formData) {
        [formData appendPartWithFileURL:fileURL name:@"file" error:nil];
    }];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request
        success:^(NSURLRequest *request, NSHTTPURLResponse *response, id uploadedFile) {
            File *file = [File alloc];
            [file setId:[uploadedFile objectForKey:@"id"]];
            [file setName:[uploadedFile objectForKey:@"name"]];
            [file setHref:[uploadedFile objectForKey:@"href"]];
            [file setDirect:[uploadedFile objectForKey:@"direct"]];
            [file setSize:[uploadedFile objectForKey:@"size"]];
            
//            if ([defaults integerForKey:@"automaticallyCopy"] == 1) {
//                NSPasteboard *pboard = [NSPasteboard generalPasteboard];
//                [pboard declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:self];
//                [pboard setString:file.href forType:NSStringPboardType];
//            }
            
            [statusManager removeFromActivityList:uploadingFile];
            [statusManager addToFileList:file];
            
            NSUserNotification *notification = [[NSUserNotification alloc] init];
            notification.title = @"File Uploaded!";
            notification.subtitle = @"URL copied to clipboard";
            notification.informativeText = file.href;
            notification.identifier = file.href;
            notification.soundName = @"Glass";

            [notification setHasActionButton: NO];
            
            [notification setContentImage:[[NSImage alloc] initWithContentsOfURL:fileURL]];
            
            [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
            NSLog(@"%d", [user.uploadsToday intValue]);
            int uploadCount = [user.uploadsToday intValue]+1;
            
            [user setUploadsToday:[NSNumber numberWithInt:uploadCount]];
        }
        failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
            [statusManager removeFromActivityList:uploadingFile];
            NSUserNotification *notification = [[NSUserNotification alloc] init];
            notification.title = @"File Upload Error! :(";
            notification.soundName = @"Tink.aiff";
            
            if([[error localizedRecoverySuggestion] hasPrefix:@"{"]) {
                NSData* data = [[error localizedRecoverySuggestion] dataUsingEncoding:NSUTF8StringEncoding];
                NSDictionary *errorJSON = [NSJSONSerialization JSONObjectWithData:data options:nil error:nil];
                notification.informativeText = [[errorJSON objectForKey:@"error"] objectForKey:@"message"];
            }
            else {
                notification.informativeText = @"There was an error uploading your file.";
            }
            
            [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
            
            NSLog(@"%@", error);
        }
    ];
    
    [operation setUploadProgressBlock:^(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
        float percentDone = ((float)((int)totalBytesWritten) / (float)((int)totalBytesExpectedToWrite))*100;
        [statusManager updatePercent:uploadingFile percentage:percentDone];
    }];
    
    [operation start];
}

// Links clicked from the Status Item

-(IBAction)clickLink:(id)sender
{
    File *file = [sender representedObject];
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:file.href]];
}

-(IBAction)openWeb
{
    [[HostrApiClient sharedInstance] getPath:@"/api/user/token" parameters:nil
         success:^(AFHTTPRequestOperation *operation, id response) {
             NSLog(@"%@", response);
             NSURL *url = [[NSURL alloc] initWithString:[siteBase stringByAppendingString:[@"?app-token=" stringByAppendingString:[response objectForKey:@"token"]]]];
                           [[NSWorkspace sharedWorkspace] openURL:url];
         }
         failure:^(AFHTTPRequestOperation *operation, NSError *error) {
             NSLog(@"ERROR");
             NSLog(@"%@", error);
         }
    ];
}

- (void)logout
{
    NSLog(@"Logging out");
    User *user = [User getInstance];
    [SSKeychain deletePasswordForService:siteBase account:user.email];
    [user clear];
    [statusManager clearFileList];
    [statusManager.fileList clear];
    [[self preferencesWindowController] close];
    _preferencesWindowController = nil;
    [self.loginWindow makeKeyAndOrderFront:nil];
}

- (void)startAnimating
{
    currentFrame = 0;
    animTimer = [NSTimer scheduledTimerWithTimeInterval:1.0/3.0 target:self selector:@selector(updateImage:) userInfo:nil repeats:YES];
}

- (void)stopAnimating
{
    [animTimer invalidate];
}

- (void)updateImage:(NSTimer*)timer
{
    //get the image for the current frame
    NSImage* image = [NSImage imageNamed:[NSString stringWithFormat:@"status-image-%d",currentFrame]];
    [statusItem setImage:image];
}

- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center shouldPresentNotification:(NSUserNotification *)notification{
    return YES;
}

- (void)userNotificationCenter:(NSUserNotificationCenter *)center didActivateNotification:(NSUserNotification *)notification{
    if([[notification title] isEqualToString:@"File Uploaded!"]) {
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[notification informativeText]]];
    }
}

- (void)openPreferences
{
    [[self preferencesWindowController] showWindow:nil];
    [NSApp activateIgnoringOtherApps:YES];
}

- (void) appQuit
{
    [[NSApplication sharedApplication] terminate:nil];
}

- (IBAction)doRegister:(id)sender
{
    NSURL *url = [[NSURL alloc] initWithString:[siteBase stringByAppendingString:@"signup"]];
    [[NSWorkspace sharedWorkspace] openURL:url];
}

- (NSWindowController *)preferencesWindowController
{
    if (_preferencesWindowController == nil)
    {
        GeneralPreferencesViewController *generalViewController = [[GeneralPreferencesViewController alloc] init];
        AccountPreferencesViewController *accountViewController = [[AccountPreferencesViewController alloc] init];
        UpdatePreferencesViewController *updateViewController = [[UpdatePreferencesViewController alloc] init];
        //AboutViewController *aboutViewController = [[AboutViewController alloc] init];
        
        NSArray *controllers = [[NSArray alloc] initWithObjects:generalViewController, accountViewController, updateViewController, nil];
        
        NSString *title = NSLocalizedString(@"Preferences", @"Common title for Preferences window");
        _preferencesWindowController = [[MASPreferencesWindowController alloc] initWithViewControllers:controllers title:title];
        [[_preferencesWindowController window] setStyleMask:[[_preferencesWindowController window] styleMask] & ~NSResizableWindowMask];
        [[[_preferencesWindowController window] standardWindowButton:NSWindowZoomButton] setEnabled:NO];
    }
    return _preferencesWindowController;
}

@end
