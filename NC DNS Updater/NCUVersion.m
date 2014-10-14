//
//  NCUVersion.m
//  NC DNS Updater
//
//  Created by Spencer Müller Diniz on 14/10/14.
//  Copyright (c) 2014 SPENCER. All rights reserved.
//

#import "NCUVersion.h"

@implementation NCUVersion

- (instancetype) initWithVersionNumber:(NSString *)versionNumber andReleaseDate:(NSString *)releaseDate {
    if (self = [super init]) {
        self.versionNumber = versionNumber;
        self.releaseDate = releaseDate;
    }
    
    return self;
}

@end
