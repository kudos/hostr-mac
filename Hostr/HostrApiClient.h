//
//  HostrApiClient.h
//  Hostr for Mac
//
//  Created by Jonathan Cremin on 23/03/2013.
//  Copyright (c) 2013 Jonathan Cremin. All rights reserved.
//

#import <AFNetworking.h>

@interface HostrApiClient : AFHTTPClient

+ (id)sharedInstance;

- (void)setUsername:(NSString *)username andPassword:(NSString *)password;

@end
