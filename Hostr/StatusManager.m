//
//  StatusManager.m
//  Hostr for Mac
//
//  Created by Jonathan Cremin on 02/04/2013.
//  Copyright (c) 2013 Jonathan Cremin. All rights reserved.
//

#import "StatusManager.h"
#import "constants.h"
#import "File.h"
#import <AFHTTPClient.h>
#import "AppDelegate.h"
#import "HostrApiClient.h"
#import "SRWebSocket.h"
#import "SBJson4.h"

@interface StatusManager () <SRWebSocketDelegate>

@end

@implementation StatusManager {
    SRWebSocket *_webSocket;
    NSMutableArray *_messages;
}

@synthesize activityList, fileList, endList, percentages, menu;

static StatusManager *instance = nil;
static SRWebSocket *_webSocket;

+(StatusManager*)getInstance{
    @synchronized(self)
    {
        if(instance == nil)
        {
            instance = [StatusManager new];
        }
    }
    return instance;
}

- (void) initWithMenu:(id)statusMenu
{
    menu = statusMenu;
}

- (void)_reconnect;
{
    _webSocket.delegate = nil;
    [_webSocket close];
    
    _webSocket = [[SRWebSocket alloc] initWithURLRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:webSocketBase]]];
    _webSocket.delegate = self;
    
    NSLog(@"Connecting...");
    [_webSocket open];
}

- (void)reconnect:(id)sender;
{
    [self _reconnect];
}

- (void) addToActivityList:(id)activityItem percentage:(float)percent
{
    
    if(activityList == nil) {
        activityList = [[NSMutableArray alloc] init];
        percentages = [[NSMutableArray alloc] init];
    }
    [activityList addObject:activityItem];
    NSLog(@"%lu", (unsigned long)[activityList indexOfObject:activityItem]);
    [percentages insertObject:[[NSNumber numberWithFloat:percent] stringValue] atIndex:[activityList indexOfObject:activityItem]];
    [self buildMenu];
}

- (void) updatePercent:activityItem percentage:(float)percent
{
    long roundedPercent = lroundf(percent);
    [percentages replaceObjectAtIndex:[activityList indexOfObject:activityItem] withObject:[[NSNumber numberWithLong:roundedPercent] stringValue]];
    [self buildMenu];
    [menu update];
}

- (void) removeFromActivityList:(id)activityItem
{
    [activityList removeObject:activityItem];
    [self buildMenu];
}

- (void) addToFileList:(id)fileItem
{
    if(fileList == nil) {
        fileList = [[DataTube alloc] init];
    }
    [fileList push:fileItem];
    [self buildMenu];
}

- (void) buildMenu
{
    [menu removeAllItems];
    int *menuCount = 0;
    NSMenuItem *sep = [NSMenuItem separatorItem];
    if([activityList count]) {
        NSMenuItem *activityTitle = [[NSMenuItem alloc] initWithTitle:@"Uploading..." action:Nil keyEquivalent:@""];
        [activityTitle setEnabled:NO];
        [menu addItem:activityTitle];
    }
    for (NSInteger i = 0; i < [activityList count]; i++) {
        File *file = [activityList objectAtIndex:i];
        
        NSMutableString *fileName = [[NSMutableString alloc] initWithString:file.name];
        
        NSMutableString *trimmedFileName = [self formatFileName:fileName];
        
        // Stick a percentage after the filename
        [trimmedFileName appendString:@" "];
        
        [trimmedFileName appendString:[percentages objectAtIndex:i]];
        
        [trimmedFileName appendString:@"%"];
        
        NSMenuItem *newMenu = [[NSMenuItem alloc] initWithTitle:trimmedFileName action:Nil keyEquivalent:@""];
        [newMenu setRepresentedObject:file];
        [newMenu setEnabled:NO];
        if([fileName length] > 30){
            [newMenu setToolTip:fileName];
        }
        [menu addItem:newMenu];
        menuCount++;
    }
    
    if (menuCount > 0){
        [menu addItem:sep];
    }
    
    NSMenuItem *latestTitle =[[NSMenuItem alloc] initWithTitle:@"Recent Uploads" action:Nil keyEquivalent:@""];
    
    [latestTitle setEnabled:NO];
    
    [menu addItem:latestTitle];
    
    for (NSInteger i = 0; i < [fileList count]; i++) {
        File *file = [fileList objectAtIndex:i];
        
        NSMutableString *fileName = [[NSMutableString alloc] initWithString:file.name];
        
        NSMutableString *trimmedFileName = [self formatFileName:fileName];
        
        NSMenuItem *newMenu = [[NSMenuItem alloc] initWithTitle:trimmedFileName action:@selector(clickLink:) keyEquivalent:@""];
        [newMenu setRepresentedObject:file];
        if([fileName length] > 30){
            [newMenu setToolTip:fileName];
        }
        [menu addItem:newMenu];
    }
    
    NSMenuItem *sep2 = [NSMenuItem separatorItem];
    [menu addItem:sep2];
    NSMenuItem *openWebApp = [[NSMenuItem alloc] initWithTitle:@"Open Web App" action:@selector(openWeb) keyEquivalent:@""];
    [menu addItem:openWebApp];
    NSMenuItem *preferences = [[NSMenuItem alloc] initWithTitle:@"Preferences" action:@selector(openPreferences) keyEquivalent:@""];
    [menu addItem:preferences];
    NSMenuItem *quit = [[NSMenuItem alloc] initWithTitle:@"Quit" action:@selector(appQuit) keyEquivalent:@""];
    [menu addItem:quit];
#ifdef DEBUG
    NSMenuItem *debugTitle =[[NSMenuItem alloc] initWithTitle:@"Debug Mode Active" action:Nil keyEquivalent:@""];
    [debugTitle setEnabled:NO];
    [menu addItem:debugTitle];
#endif
}

- (void) clearFileList
{
    [fileList clear];
}

- (NSMutableString *) formatFileName:(NSMutableString *)fileName
{    
    NSMutableString *trimmedFileName = [[NSMutableString alloc] initWithString:fileName];
    
    if([trimmedFileName length] > 40){
        trimmedFileName = [[NSMutableString alloc] initWithString:[trimmedFileName substringToIndex:15]];
        [trimmedFileName appendString:@"..."];
        [trimmedFileName appendString:[fileName substringFromIndex:[fileName length]-15]];
    }
    return trimmedFileName;
}

- (void)webSocketDidOpen:(SRWebSocket *)webSocket;
{
    NSLog(@"Websocket Connected");
    NSLog(@"Connected!");
    [[HostrApiClient sharedInstance] getPath:@"/token" parameters:nil
         success:^(AFHTTPRequestOperation *operation, id response) {
             NSLog(@"%@", [response objectForKey:@"token"]);
             
             NSMutableString *temp = [[NSMutableString alloc] initWithString:@"{\"authorization\":\""];
             NSString *token = [[temp stringByAppendingString:[response objectForKey:@"token"]] stringByAppendingString:@"\"}"];
             
             [_webSocket send:token];
         }
         failure:^(AFHTTPRequestOperation *operation, NSError *error) {
             NSLog(@"ERROR");
             NSLog(@"%@", error);
         }
     ];
}

- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error;
{
    NSLog(@":( Websocket Failed With Error %@", error);
    
    NSLog(@"Connection Failed! (see logs)");
    _webSocket = nil;
    [self _reconnect];
}

- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message;
{
    SBJson4ValueBlock block = ^(id message, BOOL *stop) {
        if ([[message objectForKey:@"type"]  isEqual: @"file-accepted"]) {
            NSUserNotification *notification = [[NSUserNotification alloc] init];
            notification.title = @"File Uploading";
            notification.subtitle = @"URL copied to clipboard";
            notification.informativeText = [[message objectForKey:@"data"] objectForKey:@"href"];
            notification.identifier = [[message objectForKey:@"data"] objectForKey:@"href"];
            notification.soundName = @"Glass";
            
            [notification setHasActionButton: NO];;
            [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            if ([defaults integerForKey:@"automaticallyCopy"] == 1) {
                NSPasteboard *pboard = [NSPasteboard generalPasteboard];
                [pboard declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:self];
                [pboard setString:[[message objectForKey:@"data"] objectForKey:@"href"] forType:NSStringPboardType];
            }
        }
    };
    
    SBJson4ErrorBlock eh = ^(NSError* err) {
        NSLog(@"OOPS: %@", err);
    };
    
    SBJson4Parser *parser = [SBJson4Parser parserWithBlock:block allowMultiRoot:YES unwrapRootArray:YES errorHandler:eh];
    [parser parse:[message dataUsingEncoding:NSUTF8StringEncoding]];
    
}

- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean;
{
    NSLog(@"WebSocket closed");
    NSLog(@"Connection Closed! (see logs)");
    _webSocket = nil;
    [self _reconnect];
}

@end