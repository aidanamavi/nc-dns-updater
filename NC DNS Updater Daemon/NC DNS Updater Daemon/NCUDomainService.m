//
//  NCUDomainService.m
//  NC DNS Updater Daemon
//
//  Created by Spencer Müller Diniz on 21/01/15.
//  Copyright (c) 2015 LARATECH. All rights reserved.
//

#import "NCUDomainService.h"
#import "NCUIPService.h"
#import "NCUNamecheapDomain.h"

@implementation NCUDomainService

- (instancetype)init {
    if (self = [super init]) {
        [NCUIPService setAppVersion:@"2.2"];
    }
    
    return self;
}

- (void)updateDomains:(NSMutableArray *)namecheapDomains {
    [NCUIPService getExternalIPAddressWithCompletionBlock:^(NSString *ipAddress, NSError *error) {
        NSString *internalIP = [NCUIPService getInternalIPAddress];
        
        for (NCUNamecheapDomain *namecheapDomain in namecheapDomains) {
            
            NSString *currentIP = [NCUIPService getIPAddressForURL:namecheapDomain.httpUrl];
            if ([NCUIPService isStringAnIP:currentIP]) {
                namecheapDomain.currentIP = currentIP;
            }
            else {
                namecheapDomain.currentIP = nil;
            }
            
            NSString *referenceIP;
            
            if ([namecheapDomain.ipSource integerValue] == NCUIpSourceExternal) {
                referenceIP = ipAddress;
            }
            else {
                referenceIP = internalIP;
            }
            
            if ([namecheapDomain.currentIP isEqualToString:referenceIP]) {
                NWLog(@"%@ IP is up to date.", [namecheapDomain completeHostName]);
            }
            else {
                NWLog(@"%@ IP is outdated.%@", [namecheapDomain completeHostName], [namecheapDomain.enabled boolValue] ? @" Update request will be issued." : @" Automatic updates are disabled.");
            }
            
            if (![namecheapDomain.currentIP isEqualToString:referenceIP] && [namecheapDomain.enabled boolValue]) {
                [self updateDnsWithNamecheapDomain:namecheapDomain];
            }
        }
    }];
}

- (void)updateDnsWithNamecheapDomain:(NCUNamecheapDomain *)namecheapDomain {
    NWLog(@"Processing %@.", [namecheapDomain completeHostName]);
    
    if ([namecheapDomain.ipSource integerValue] == NCUIpSourceExternal) {
        NWLog(@"Determining external IP address.");
        [NCUIPService getExternalIPAddressWithCompletionBlock:^(NSString *ipAddress, NSError *error) {
            if (error) {
                NWLog(@"ERROR determining external IP address. %@", error.localizedDescription);
            }
            else {
                if (ipAddress) {
                    NWLog(@"External IP address is %@.", ipAddress);
                    if ([NCUIPService isStringAnIP:ipAddress]) {
                        NWLog(@"Requesting IP address update for %@ to %@.", [namecheapDomain completeHostName], ipAddress);
                        [NCUIPService updateNamecheapDomain:namecheapDomain withIP:ipAddress forceUpdate:NO withCompletionBlock:^(NCUNamecheapDomain *namecheapDomain, NSError *error) {
                            NWLog(@"%@", error ? [error localizedDescription] : @"Update request issued successfully. Please wait for update to propagate.");
                        }];
                    }
                    else {
                        NWLog(@"%@ is not a valid IP address.", ipAddress);
                    }
                }
                else {
                    NWLog(@"Could not determine external IP address.");
                }
            }
        }];
    }
    else {
        NWLog(@"Determining internal IP address.");
        id ipAddress = [NCUIPService getInternalIPAddress];
        if (ipAddress) {
            NWLog(@"Internal IP address is %@.", ipAddress);
            if ([NCUIPService isStringAnIP:ipAddress]) {
                NWLog(@"Requesting IP address update for %@ to %@.", [namecheapDomain completeHostName], ipAddress);
                [NCUIPService updateNamecheapDomain:namecheapDomain withIP:ipAddress forceUpdate:NO withCompletionBlock:^(NCUNamecheapDomain *namecheapDomain, NSError *error) {
                    NWLog(@"%@", error ? [error localizedDescription] : @"Update request issued successfully. Please wait for update to propagate.");
                }];
            }
            else {
                NWLog(@"%@ is not a valid IP address.", ipAddress);
            }
        }
        else {
            NWLog(@"Could not determine internal IP address.");
        }
    }
}

@end
