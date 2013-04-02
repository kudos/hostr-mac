//
//  HostrApiClient.m
//  Hostr for Mac
//
//  Created by Jonathan Cremin on 23/03/2013.
//  Copyright (c) 2013 Jonathan Cremin. All rights reserved.
//

#import "HostrApiClient.h"
#import "constants.h"

@implementation HostrApiClient

+ (id)sharedInstance {
    static HostrApiClient *__sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __sharedInstance = [[HostrApiClient alloc] initWithBaseURL:
                            [NSURL URLWithString:apiBase]];
    });
    
    return __sharedInstance;
}

- (void)setUsername:(NSString *)username andPassword:(NSString *)password;
{
    [self clearAuthorizationHeader];
    [self setAuthorizationHeaderWithUsername:username password:password];
}

- (id)initWithBaseURL:(NSURL *)url {
    self = [super initWithBaseURL:url];
    if (self) {
        //custom settings        
        [self registerHTTPOperationClass:[AFJSONRequestOperation class]];
        [self setDefaultHeader:@"Accept" value:@"application/json"];
    }
    
    return self;
}


@end
