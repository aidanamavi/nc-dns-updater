//
//  NamecheapDomain.h
//  NC DNS Updater
//
//  Created by Spencer Müller Diniz on 7/23/14.
//  Copyright (c) 2014 SPENCER. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface NCUNamecheapDomain : NSManagedObject

@property (nonatomic, retain) NSString * domain;
@property (nonatomic, retain) NSNumber * enabled;
@property (nonatomic, retain) NSString * host;
@property (nonatomic, retain) NSString * identifier;
@property (nonatomic, retain) NSNumber * interval;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * password;

@end
