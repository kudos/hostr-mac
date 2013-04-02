
#import "GeneralPreferencesViewController.h"
#import "LaunchAtLoginController.h"

@implementation GeneralPreferencesViewController

@synthesize defaults, automaticallyCopy, automaticallyUpload, startAtLogin;

- (id)init
{
    return [super initWithNibName:@"GeneralPreferencesView" bundle:nil];
}

- (void)viewWillAppear
{
    LaunchAtLoginController *loginLaunch = [[LaunchAtLoginController alloc] init];
    defaults = [NSUserDefaults standardUserDefaults];
    [automaticallyCopy setState:[defaults integerForKey:@"automaticallyCopy"]];
    NSLog(@"%ld", (long)[defaults integerForKey:@"automaticallyCopy"]);
    [automaticallyUpload setState:[defaults integerForKey:@"automaticallyUpload"]];
    NSLog(@"%ld", (long)[defaults integerForKey:@"automaticallyUpload"]);
    [startAtLogin setState:[loginLaunch launchAtLogin]];
}

-(IBAction)automaticallyCopy:(id)sender
{
    NSLog(@"%ld", (long)[sender state]);
    [defaults setInteger:[sender state] forKey:@"automaticallyCopy"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(IBAction)automaticallyUpload:(id)sender
{
    NSLog(@"%ld", (long)[sender state]);
    [defaults setInteger:[sender state] forKey:@"automaticallyUpload"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(IBAction)startAtLogin:(id)sender
{
    LaunchAtLoginController *loginLaunch = [[LaunchAtLoginController alloc] init];
    [loginLaunch setLaunchAtLogin:[sender state]];
    [[NSUserDefaults standardUserDefaults] synchronize];
}


#pragma mark -
#pragma mark MASPreferencesViewController

- (NSString *)identifier
{
    return @"GeneralPreferences";
}

- (NSImage *)toolbarItemImage
{
    return [NSImage imageNamed:NSImageNamePreferencesGeneral];
    
}

- (NSString *)toolbarItemLabel
{
    return NSLocalizedString(@"General", @"Toolbar item name for the General preference pane");
}

@end
