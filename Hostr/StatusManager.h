//
//  StatusManager.h
//  Hostr for Mac
//
//  Created by Jonathan Cremin on 02/04/2013.
//  Copyright (c) 2013 Jonathan Cremin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DataTube.h"

@interface StatusManager : NSObject

+(StatusManager*)getInstance;

@property (strong, nonatomic) NSMutableArray *activityList;
@property (strong, nonatomic) NSMutableArray *percentages;
@property (strong, nonatomic) DataTube *fileList;
@property (strong, nonatomic) NSMutableArray *endList;
@property (strong, nonatomic) NSMenu *menu;

- (void) initWithMenu:(id)statusMenu;
- (void) addToFileList:(id)fileItem;
- (void) addToActivityList:(id)activityItem percentage:(float)percent;
- (void) updatePercent:activityItem percentage:(float)percent;
- (void) removeFromActivityList:(id)statusItem;
- (void) buildMenu;
- (void) clearFileList;
- (void) _reconnect;

@end