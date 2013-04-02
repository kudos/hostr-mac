//
// This is a sample Advanced preference pane
//

#import "MASPreferencesViewController.h"

@interface UpdatePreferencesViewController : NSViewController <MASPreferencesViewController>

@property (strong, nonatomic) NSUserDefaults *defaults;
@property IBOutlet NSButton *autoUpdate;
@property (weak) IBOutlet NSTextField *version;

-(IBAction)autoUpdate:(id)sender;

-(IBAction)updateCheck:(id)sender;

@end
