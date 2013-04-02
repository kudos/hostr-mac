
#import "UpdatePreferencesViewController.h"
#import <Sparkle/Sparkle.h>

@implementation UpdatePreferencesViewController

@synthesize defaults, autoUpdate;

#pragma mark -

- (id)init
{
    return [super initWithNibName:@"UpdatePreferencesView" bundle:nil];
}

- (void)viewWillAppear
{
    NSMutableString *version = [[NSMutableString alloc] initWithString:@"Hostr v"];
    self.version.stringValue = [version stringByAppendingString:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]];
    defaults = [NSUserDefaults standardUserDefaults];
    [autoUpdate setState:[defaults integerForKey:@"autoUpdate"]];
}

-(IBAction)autoUpdate:(id)sender
{
    [defaults setInteger:[sender state] forKey:@"autoUpdate"];
}

-(IBAction)updateCheck:(id)sender
{
    [[SUUpdater sharedUpdater] checkForUpdates:sender];
}

#pragma mark -
#pragma mark MASPreferencesViewController

- (NSString *)identifier
{
    return @"UpdatePreferences";
}

- (NSImage *)toolbarItemImage
{
    return [NSImage imageNamed:@"Software_Update_icon"];
}

- (NSString *)toolbarItemLabel
{
    return NSLocalizedString(@"Update", @"Toolbar item name for the Update preference pane");
}

@end
