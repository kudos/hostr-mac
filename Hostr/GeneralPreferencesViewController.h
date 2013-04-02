//
// This is a sample General preference pane
//

#import "MASPreferencesViewController.h"

@interface GeneralPreferencesViewController : NSViewController <MASPreferencesViewController>

@property (strong, nonatomic) NSUserDefaults *defaults;
@property IBOutlet NSButton *automaticallyCopy;
@property IBOutlet NSButton *automaticallyUpload;
@property IBOutlet NSButton *startAtLogin;


-(IBAction)automaticallyCopy:(id)sender;

-(IBAction)startAtLogin:(id)sender;

@end
