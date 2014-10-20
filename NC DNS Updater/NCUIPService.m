//
//  NCUIPService.m
//  NC DNS Updater
//
//  Created by Spencer Müller Diniz on 7/28/14.
//  Copyright (c) 2014 SPENCER. All rights reserved.
//

#import "NCUIPService.h"
#import <AFNetworking/AFHTTPRequestOperationManager.h>
#import "NCUNamecheapDomain.h"

@implementation NCUIPService

+ (void)getExternalIPAddressWithCompletionBlock:(void (^)(NSString * ipAddress, NSError* error))completionBlock {

    
    AFHTTPRequestOperationManager *echoIPSession = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:[NSURL URLWithString:@"http://echoip.gosmd.net"]];

    echoIPSession.responseSerializer = [[AFHTTPResponseSerializer alloc] init];
    
    [echoIPSession GET:@"" parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSString *detectedIpAddress = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
        NSLog(@"IP: %@", detectedIpAddress);
        
        if (completionBlock) {
            completionBlock(detectedIpAddress, nil);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"FAIL: %@", error.localizedDescription);
        
        if (completionBlock) {
            completionBlock(nil, error);
        }
    }];
}

+ (void)updateNamecheapDomain:(NCUNamecheapDomain *)namecheapDomain withIP:(NSString *)ip{
    AFHTTPRequestOperationManager *namecheapSession = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:[NSURL URLWithString:@"https://dynamicdns.park-your-domain.com"]];
    
    namecheapSession.responseSerializer = [[AFHTTPResponseSerializer alloc] init];
    
    [namecheapSession GET:@"/update" parameters:@{@"host":namecheapDomain.host, @"domain":namecheapDomain.domain, @"password":namecheapDomain.password, @"ip":ip} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NWLog(@"Successfully update %@.%@ with to %@.", namecheapDomain.host, namecheapDomain.domain, ip);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"ERROR UPDATING %@.%@ to %@: %@", namecheapDomain.host, namecheapDomain.domain, ip, error.localizedDescription);
    }];    
}

+ (BOOL)isStringAnIP:(NSString *)stringValue {
    NSString *ipRegEx = @"\\b\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\b";
    NSPredicate *ipTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", ipRegEx];
    
    return [ipTest evaluateWithObject:stringValue];
}

@end
