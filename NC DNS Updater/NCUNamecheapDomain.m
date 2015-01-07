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
@dynamic interval;
@dynamic ipSource;
@dynamic name;
@dynamic password;
@dynamic currentIP;

- (NSString *)completeHostName {
    return [NSString stringWithFormat:@"%@.%@", self.host, self.domain];
}

- (NSURL *)httpUrl {
    return [NSURL URLWithString:[NSString stringWithFormat:@"http://%@", [self completeHostName]]];
}

@end
