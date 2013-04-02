//
//  User.h
//  Localhostr
//
//  Created by Jonathan Cremin on 04/01/2013.
//  Copyright (c) 2013 Jonathan Cremin. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface User : NSObject

@property (strong, nonatomic) NSString *id;
@property (strong, nonatomic) NSString *email;
@property (strong, nonatomic) NSString *password;
@property (strong, nonatomic) NSString *plan;
@property (strong, nonatomic) NSNumber *dailyUploadAllowance;
@property (strong, nonatomic) NSNumber *uploadsToday;
@property (strong, nonatomic) NSNumber *fileCount;
@property (strong, nonatomic) NSNumber *maxFilesize;

+(User*)getInstance;
-(User*)clear;

@end
