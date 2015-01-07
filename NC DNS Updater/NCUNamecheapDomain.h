//
//  NCUNamecheapDomain.h
//  NC DNS Updater
//
//  Created by Spencer Müller Diniz on 7/28/14.
//  Copyright (c) 2014 SPENCER. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

typedef NS_ENUM(NSInteger, NCUIpSource) {
    NCUIpSourceExternal = 0,
    NCUIpSourceInternal = 1
};

@interface NCUNamecheapDomain : NSManagedObject

@property (nonatomic, retain) NSString * domain;
@property (nonatomic, retain) NSNumber * enabled;
@property (nonatomic, retain) NSString * host;
@property (nonatomic, retain) NSString * identifier;
@property (nonatomic, retain) NSNumber * interval;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * password;
@property (nonatomic, retain) NSString * currentIP;
@property (nonatomic, retain) NSNumber * ipSource;

- (NSString *)completeHostName;
- (NSURL *)httpUrl;

@end
