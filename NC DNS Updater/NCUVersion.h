//
//  NCUVersion.h
//  NC DNS Updater
//
//  Created by Spencer Müller Diniz on 14/10/14.
//  Copyright (c) 2014 SPENCER. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NCUVersion : NSObject

@property (strong, nonatomic) NSString *versionNumber;
@property (strong, nonatomic) NSString *releaseDate;

- (instancetype) initWithVersionNumber:(NSString *)versionNumber andReleaseDate:(NSString *)releaseDate;

@end
