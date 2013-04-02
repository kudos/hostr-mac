//
//  AboutView.h
//  
//
//  Created by Jonathan Cremin on 17/10/2014.
//
//

#import "MASPreferencesViewController.h"

@interface AboutViewController : NSViewController <MASPreferencesViewController>

@property (weak) IBOutlet NSTextFieldCell *version;

@end
