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
#import <ifaddrs.h>
#import <arpa/inet.h>
#import <net/if.h>

#define NETWORK_ADAPTER0 @"en0"
#define NETWORK_ADAPTER1 @"en1"
#define IP_ADDR_IPv4 @"ipv4"
#define IP_ADDR_IPv6 @"ipv6"

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

+ (NSString *)getInternalIPAddress {
    NSArray *searchArray = @[NETWORK_ADAPTER0 @"/" IP_ADDR_IPv4, NETWORK_ADAPTER1 @"/" IP_ADDR_IPv4];
    
    NSDictionary *addresses = [self getInternalIPAddresses];
    NSLog(@"addresses: %@", addresses);
    
    __block NSString *address;
    [searchArray enumerateObjectsUsingBlock:^(NSString *key, NSUInteger idx, BOOL *stop)
     {
         address = addresses[key];
         if(address) *stop = YES;
     } ];

    return address ? address : @"unable to determine ip address";
}

+ (NSDictionary *)getInternalIPAddresses
{
    NSMutableDictionary *addresses = [NSMutableDictionary dictionaryWithCapacity:8];
    
    // retrieve the current interfaces - returns 0 on success
    struct ifaddrs *interfaces;
    if(!getifaddrs(&interfaces)) {
        // Loop through linked list of interfaces
        struct ifaddrs *interface;
        for(interface=interfaces; interface; interface=interface->ifa_next) {
            if(!(interface->ifa_flags & IFF_UP) /* || (interface->ifa_flags & IFF_LOOPBACK) */ ) {
                continue; // deeply nested code harder to read
            }
            const struct sockaddr_in *addr = (const struct sockaddr_in*)interface->ifa_addr;
            char addrBuf[ MAX(INET_ADDRSTRLEN, INET6_ADDRSTRLEN) ];
            if(addr && (addr->sin_family==AF_INET || addr->sin_family==AF_INET6)) {
                NSString *name = [NSString stringWithUTF8String:interface->ifa_name];
                NSString *type;
                if(addr->sin_family == AF_INET) {
                    if(inet_ntop(AF_INET, &addr->sin_addr, addrBuf, INET_ADDRSTRLEN)) {
                        type = IP_ADDR_IPv4;
                    }
                } else {
                    const struct sockaddr_in6 *addr6 = (const struct sockaddr_in6*)interface->ifa_addr;
                    if(inet_ntop(AF_INET6, &addr6->sin6_addr, addrBuf, INET6_ADDRSTRLEN)) {
                        type = IP_ADDR_IPv6;
                    }
                }
                if(type) {
                    NSString *key = [NSString stringWithFormat:@"%@/%@", name, type];
                    addresses[key] = [NSString stringWithUTF8String:addrBuf];
                }
            }
        }
        // Free memory
        freeifaddrs(interfaces);
    }
    return [addresses count] ? addresses : nil;
}

@end
