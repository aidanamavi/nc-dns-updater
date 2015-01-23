//
//  NCUAppSetting.h
//  NC DNS Updater
//
//  Created by Spencer Müller Diniz on 23/01/15.
//  Copyright (c) 2015 SPENCER. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface NCUAppSetting : NSManagedObject

@property (nonatomic, retain) NSString * settingName;
@property (nonatomic, retain) NSString * settingValue;

- (void)setBoolValue:(BOOL)value;

@end
