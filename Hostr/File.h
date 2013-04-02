//
//  File.h
//  Hostr
//
//  Created by Jonathan Cremin on 03/01/2013.
//  Copyright (c) 2013 Jonathan Cremin. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface File : NSObject

@property (strong, nonatomic) NSString *id;
@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) NSString *href;
@property (strong, nonatomic) NSDictionary *direct;
@property (strong, nonatomic) NSNumber *size;
@property (nonatomic) float percent;

@end
