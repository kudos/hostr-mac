//
//  User.m
//  Localhostr
//
//  Created by Jonathan Cremin on 04/01/2013.
//  Copyright (c) 2013 Jonathan Cremin. All rights reserved.
//

#import "User.h"

@implementation User

@synthesize id, email, password, plan, dailyUploadAllowance, uploadsToday, fileCount, maxFilesize;

static User *instance =nil;    

+(User*)getInstance{
    @synchronized(self)
    {
        if(instance == nil)
        {
            instance = [User new];
        }
    }
    return instance;
}

-(User*)clear{
    @synchronized(self)
    {
        instance = [User new];
    }
    return instance;
}

@end