//
//  AccountPreferencesViewController.m
//  Hostr for Mac
//
//  Created by Jonathan Cremin on 23/03/2013.
//  Copyright (c) 2013 Jonathan Cremin. All rights reserved.
//

#import "AccountPreferencesViewController.h"
#import "User.h"
#import "constants.h"
#import "AppDelegate.h"

@implementation AccountPreferencesViewController

- (void)viewWillAppear
{
    NSLog(@"%@", self.accountName.stringValue);
    User *user = [User getInstance];
    self.accountName.stringValue = user.email;
    self.accountType.stringValue = user.plan;
    NSString *allowance = @"∞";
    if (![user.dailyUploadAllowance isEqual:@"unlimited"]) {
        allowance = [NSString stringWithFormat:@"%@", user.dailyUploadAllowance];
    }
    NSArray *up = [[NSArray alloc] initWithObjects:user.uploadsToday, @"/", allowance, nil];
    self.uploads.stringValue = [up componentsJoinedByString:@""];
}

- (id)init
{
    return [super initWithNibName:@"AccountPreferencesView" bundle:nil];
}

- (IBAction)logout:(id)sender
{
    [(AppDelegate *)[[NSApplication sharedApplication] delegate] logout];
}

#pragma mark -
#pragma mark MASPreferencesViewController

- (NSString *)identifier
{
    return @"AccountPreferences";
}

- (NSImage *)toolbarItemImage
{
    return [NSImage imageNamed:NSImageNameUser];
}

- (NSString *)toolbarItemLabel
{
    return NSLocalizedString(@"Account", @"Toolbar item name for the Account preference pane");
}

@end
