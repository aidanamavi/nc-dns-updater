//
//  NCUNamecheapDomain.m
//  NC DNS Updater
//
//  Created by Spencer Müller Diniz on 7/28/14.
//  Copyright (c) 2014 SPENCER. All rights reserved.
//

#import "NCUNamecheapDomain.h"


@implementation NCUNamecheapDomain

@dynamic domain;
@dynamic enabled;
@dynamic host;
@dynamic identifier;
@dynamic ipSource;
@dynamic name;
@dynamic password;
@dynamic currentIP;
@dynamic comment;

- (NSString *)completeHostName {
    NSString *completeHostName;
    
    if ([self.host isEqualToString:@"@"]) {
        completeHostName = self.domain;
    }
    else {
        completeHostName = [NSString stringWithFormat:@"%@.%@", self.host, self.domain];
    }

    return completeHostName;
}

- (NSURL *)httpUrl {
    return [NSURL URLWithString:[NSString stringWithFormat:@"http://%@", [self completeHostName]]];
}

@end
