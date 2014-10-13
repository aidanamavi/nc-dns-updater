//
//  NCUIPService.m
//  NC DNS Updater
//
//  Created by Spencer Müller Diniz on 7/28/14.
//  Copyright (c) 2014 SPENCER. All rights reserved.
//

#import "NCUIPService.h"
#import <AFNetworking/AFNetworking.h>
#import "NCUNamecheapDomain.h"

@implementation NCUIPService

+ (void)getExternalIPAddressWithCompletionBlock:(void (^)(NSString * ipAddress, NSError* error))completionBlock {
    AFHTTPSessionManager *echoIPSession = [[AFHTTPSessionManager alloc] initWithBaseURL:[NSURL URLWithString:@"http://echoip.gosmd.net"]];

    echoIPSession.responseSerializer = [[AFHTTPResponseSerializer alloc] init];
    
    [echoIPSession GET:@"" parameters:nil success:^(NSURLSessionDataTask *task, id responseObject) {
        NSString *detectedIpAddress = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
        NSLog(@"IP: %@", detectedIpAddress);
        
        if (completionBlock) {
            completionBlock(detectedIpAddress, nil);
        }
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        NSLog(@"FAIL: %@", error.localizedDescription);
        
        if (completionBlock) {
            completionBlock(nil, error);
        }
    }];
}

+ (void)updateNamecheapDomain:(NCUNamecheapDomain *)namecheapDomain withIP:(NSString *)ip{
    AFHTTPSessionManager *namecheapSession = [[AFHTTPSessionManager alloc] initWithBaseURL:[NSURL URLWithString:@"https://dynamicdns.park-your-domain.com"]];
    
    namecheapSession.responseSerializer = [[AFHTTPResponseSerializer alloc] init];
    
    [namecheapSession GET:@"/update" parameters:@{@"host":namecheapDomain.host, @"domain":namecheapDomain.domain, @"password":namecheapDomain.password, @"ip":ip} success:^(NSURLSessionDataTask *task, id responseObject) {
        NWLog(@"Successfully update %@.%@ with to %@.", namecheapDomain.host, namecheapDomain.domain, ip);
        
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        NSLog(@"ERROR UPDATING %@.%@ to %@: %@", namecheapDomain.host, namecheapDomain.domain, ip, error.localizedDescription);
    }];
}

+ (BOOL)isStringAnIP:(NSString *)stringValue {
    NSString *ipRegEx = @"\\b\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\b";
    NSPredicate *ipTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", ipRegEx];
    
    return [ipTest evaluateWithObject:stringValue];
}

@end
