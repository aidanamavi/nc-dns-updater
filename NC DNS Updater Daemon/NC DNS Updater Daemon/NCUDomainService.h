//
//  NCUDomainService.h
//  NC DNS Updater Daemon
//
//  Created by Spencer Müller Diniz on 21/01/15.
//  Copyright (c) 2015 LARATECH. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NCUDomainService : NSObject

- (void)updateDomains:(NSMutableArray *)namecheapDomains;

@end
