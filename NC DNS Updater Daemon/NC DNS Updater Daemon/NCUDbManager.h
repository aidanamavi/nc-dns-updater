//
//  NCUDbManager.h
//  NC DNS Updater Daemon
//
//  Created by Spencer Müller Diniz on 21/01/15.
//  Copyright (c) 2015 LARATECH. All rights reserved.
//

#import <Foundation/Foundation.h>

@class NCUAppSetting;

@interface NCUDbManager : NSObject

@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) NSMutableArray *namecheapDomains;
@property (strong, nonatomic) NCUAppSetting *masterSwitchState;
@property (strong, nonatomic) NCUAppSetting *activityLoggingState;

- (NSURL *)databaseFilesDirectory;
- (void)loadDomains;
- (void)loadAppSettings;

@end
