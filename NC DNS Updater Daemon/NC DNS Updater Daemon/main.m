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

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        NCUDbManager *dbManager = [[NCUDbManager alloc] init];

        NSString *logPath = [NSString stringWithFormat:@"%@/%@", [[dbManager databaseFilesDirectory] path], @"Daemon.log"];
        
        NWLFilePrinter *logPrinter = [[NWLFilePrinter alloc] initAndOpenPath:logPath];
        [[NWLMultiLogger shared] addPrinter:logPrinter];

        NWLog(@"Log path: %@", logPath);
        
        [dbManager loadDomains];
        
        NCUDomainService* domainService = [[NCUDomainService alloc] init];
        
        for (NCUNamecheapDomain *domain in dbManager.namecheapDomains) {
            NWLog(@"DOMAIN: %@", [domain completeHostName]);
        }

        [domainService updateDomains:dbManager.namecheapDomains];
        
        NSRunLoop *theRL = [NSRunLoop currentRunLoop];
        [theRL runUntilDate:[NSDate dateWithTimeIntervalSinceNow:30]];
   }
    
    return 0;
}