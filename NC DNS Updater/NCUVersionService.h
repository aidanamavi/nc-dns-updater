//
//  NCUVersionService.h
//  NC DNS Updater
//
//  Created by Spencer Müller Diniz on 14/10/14.
//  Copyright (c) 2014 SPENCER. All rights reserved.
//

#import <Foundation/Foundation.h>

@class NCUVersion;

@interface NCUVersionService : NSObject

+ (NCUVersion *)getCurrentVersion;

+ (void)getAvailableVersionWithCompletionBlock:(void (^)(NCUVersion *availableVersion, NSError* error))completionBlock;

@end
