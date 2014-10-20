//
//  NCUVersionService.m
//  NC DNS Updater
//
//  Created by Spencer Müller Diniz on 14/10/14.
//  Copyright (c) 2014 SPENCER. All rights reserved.
//

#import "NCUVersionService.h"
#import <AFNetworking/AFHTTPRequestOperationManager.h>
#import "NCUVersion.h"

@implementation NCUVersionService

+ (void)getAvailableVersionWithCompletionBlock:(void (^)(NCUVersion *availableVersion, NSError* error))completionBlock {
    
    AFHTTPRequestOperationManager *session = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:[NSURL URLWithString:@"http://echoip.gosmd.net"]];
    
    session.responseSerializer = [[AFJSONResponseSerializer alloc] init];
    
    [session GET:@"ncdnsupdaterversion.json" parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (completionBlock) {
            NCUVersion *version = [[NCUVersion alloc] initWithVersionNumber:responseObject[@"versionNumber"] andReleaseDate:responseObject[@"releaseDate"]];
            completionBlock(version, nil);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"FAIL: %@", error.localizedDescription);
        if (completionBlock) {
            completionBlock(nil, error);
        }
    }];
}

+ (NCUVersion *)getCurrentVersion {
    NSString *versionNumber = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    
    NSString *releaseDate = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"ReleaseDate"];
    
    
    NCUVersion *currentVersion = [[NCUVersion alloc] initWithVersionNumber:versionNumber andReleaseDate:releaseDate];
    
    return currentVersion;
}

@end
