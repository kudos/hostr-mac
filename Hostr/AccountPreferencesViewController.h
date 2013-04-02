//
//  AccountPreferencesViewController.h
//  Hostr for Mac
//
//  Created by Jonathan Cremin on 23/03/2013.
//  Copyright (c) 2013 Jonathan Cremin. All rights reserved.
//

#import <MASPreferencesViewController.h>


@interface AccountPreferencesViewController : NSViewController <MASPreferencesViewController> 

@property (assign, nonatomic) IBOutlet NSTextField *accountName;
@property (assign, nonatomic) IBOutlet NSTextField *accountType;
@property (assign, nonatomic) IBOutlet NSTextField *uploads;

- (IBAction)logout:(id)sender;

@end
