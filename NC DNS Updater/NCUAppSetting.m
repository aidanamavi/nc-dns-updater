//
//  NCUAppSetting.m
//  NC DNS Updater
//
//  Created by Spencer Müller Diniz on 23/01/15.
//  Copyright (c) 2015 SPENCER. All rights reserved.
//

#import "NCUAppSetting.h"


@implementation NCUAppSetting

@dynamic settingName;
@dynamic settingValue;

- (void)setBoolValue:(BOOL)value {
    self.settingValue = value ? @"YES" : @"NO";
}

@end
