//
//  constants.h
//  Hostr for Mac
//
//  Created by Jonathan Cremin on 16/02/2013.
//  Copyright (c) 2013 Jonathan Cremin. All rights reserved.
//

#ifndef Hostr_for_Mac_constants_h
#define Hostr_for_Mac_constants_h

#import <TargetConditionals.h>

#if DEBUG

#define apiBase @"https://localhost.hostr.co/api"
#define siteBase @"https://localhost.hostr.co/"
#define webSocketBase @"wss://localhost.hostr.co/user"

#else

#define apiBase @"https://hostr.co/api"
#define siteBase @"https://hostr.co/"
#define webSocketBase @"wss://api.hostr.co/user"

#endif

#endif
