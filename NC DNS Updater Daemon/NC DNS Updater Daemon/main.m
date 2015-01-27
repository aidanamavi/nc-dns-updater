//
//  main.m
//  NC DNS Updater Daemon
//
//  Created by Spencer Müller Diniz on 21/01/15.
//  Copyright (c) 2015 LARATECH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NCUDbManager.h"
#import "NCUNamecheapDomain.h"
#import "NCUDomainService.h"
#import "NCUAppSetting.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        NCUDbManager *dbManager = [[NCUDbManager alloc] init];
        [dbManager loadAppSettings];

        if ([dbManager.activityLoggingState.settingValue boolValue]) {
            NWLog(@"Activity logging is enabled.");
            NSString *logPath = [NSString stringWithFormat:@"%@/%@", [[dbManager databaseFilesDirectory] path], @"nc_dns_updater.log"];
            NWLog(@"Log path: %@", logPath);
            NWLFilePrinter *logPrinter = [[NWLFilePrinter alloc] initAndOpenPath:logPath];
            [[NWLMultiLogger shared] addPrinter:logPrinter];
        }
        
        [dbManager loadDomains];
        
        if ([dbManager.masterSwitchState.settingValue boolValue]) {
            NWLog(@"Master Switch enabled. Processing domains.");
            NCUDomainService* domainService = [[NCUDomainService alloc] init];
            [domainService updateDomains:dbManager.namecheapDomains];
        }
        else {
            NWLog(@"Master Switch disabled. Domains will not be processed.");
        }
        
        NSRunLoop *theRL = [NSRunLoop currentRunLoop];
        [theRL runUntilDate:[NSDate dateWithTimeIntervalSinceNow:15]];
   }
    
    return 0;
}