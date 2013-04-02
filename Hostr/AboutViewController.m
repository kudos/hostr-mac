//
//  AboutView.m
//  
//
//  Created by Jonathan Cremin on 17/10/2014.
//
//

#import "AboutViewController.h"

@implementation AboutViewController

- (void)viewWillAppear
{
    NSMutableString *version = [[NSMutableString alloc] initWithString:@"Hostr v"];
    self.version.stringValue = [version stringByAppendingString:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]];
}

- (id)init
{
    return [super initWithNibName:@"AboutView" bundle:nil];
}

#pragma mark -
#pragma mark MASPreferencesViewController

- (NSString *)identifier
{
    return @"About";
}

- (NSImage *)toolbarItemImage
{
    return [NSImage imageNamed:NSImageNameApplicationIcon];
}

- (NSString *)toolbarItemLabel
{
    return NSLocalizedString(@"About", @"Toolbar item name for the about pane");
}

@end

