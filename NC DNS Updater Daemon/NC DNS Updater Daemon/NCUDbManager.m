//
//  NCUDbManager.m
//  NC DNS Updater Daemon
//
//  Created by Spencer Müller Diniz on 21/01/15.
//  Copyright (c) 2015 LARATECH. All rights reserved.
//

#import "NCUDbManager.h"
#import "NCUAppSetting.h"

@implementation NCUDbManager

@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize managedObjectContext = _managedObjectContext;

// Returns the directory the application uses to store the Core Data store file. This code uses a directory named "com.laratech.NC_DNS_Updater" in the user's Application Support directory.
- (NSURL *)databaseFilesDirectory
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *appSupportURL = [[fileManager URLsForDirectory:NSApplicationSupportDirectory inDomains:NSLocalDomainMask] lastObject];
    return [appSupportURL URLByAppendingPathComponent:@"com.laratech.NC_DNS_Updater"];
}

// Creates if necessary and returns the managed object model for the application.
- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel) {
        return _managedObjectModel;
    }
    
    NSURL *modelURL = [[self databaseFilesDirectory] URLByAppendingPathComponent:@"NC_DNS_Updater.momd"];
    
    NWLog(@"Model URL: %@", [modelURL absoluteString]);
    
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    
    return _managedObjectModel;
}

// Returns the persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it. (The directory for the store is created, if necessary.)
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    NWLog(@"PERSISTENT STORE COORDINATOR");
    
    if (_persistentStoreCoordinator) {
        return _persistentStoreCoordinator;
    }
    
    NSManagedObjectModel *mom = [self managedObjectModel];
    if (!mom) {
        NWLog(@"%@:%@ No model to generate a store from", [self class], NSStringFromSelector(_cmd));
        return nil;
    }
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *applicationFilesDirectory = [self databaseFilesDirectory];
    NSError *error = nil;
    
    NWLog(@"Database directory path: %@", [applicationFilesDirectory path]);
    
    NSDictionary *properties = [applicationFilesDirectory resourceValuesForKeys:@[NSURLIsDirectoryKey] error:&error];
    
    if (!properties) {
        BOOL ok = NO;
        if ([error code] == NSFileReadNoSuchFileError) {
            ok = [fileManager createDirectoryAtPath:[applicationFilesDirectory path] withIntermediateDirectories:YES attributes:nil error:&error];
        }
        if (!ok) {
            [[NSApplication sharedApplication] presentError:error];
            return nil;
        }
    } else {
        if (![properties[NSURLIsDirectoryKey] boolValue]) {
            // Customize and localize this error.
            NSString *failureDescription = [NSString stringWithFormat:@"Expected a folder to store application data, found a file (%@).", [applicationFilesDirectory path]];
            
            NSMutableDictionary *dict = [NSMutableDictionary dictionary];
            [dict setValue:failureDescription forKey:NSLocalizedDescriptionKey];
            error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:101 userInfo:dict];
            
            [[NSApplication sharedApplication] presentError:error];
            return nil;
        }
    }
    
    NSURL *url = [applicationFilesDirectory URLByAppendingPathComponent:@"NC_DNS_Updater.storedata"];
    
    NWLog(@"Database full path: %@", [url path]);
    
    NSPersistentStoreCoordinator *coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:mom];
    
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
                             [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
    
    if (![coordinator addPersistentStoreWithType:NSXMLStoreType configuration:nil URL:url options:options error:&error]) {
        [[NSApplication sharedApplication] presentError:error];
        return nil;
    }
    _persistentStoreCoordinator = coordinator;
    
    return _persistentStoreCoordinator;
}

// Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.)
- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        [dict setValue:@"Failed to initialize the store" forKey:NSLocalizedDescriptionKey];
        [dict setValue:@"There was an error building up the data file." forKey:NSLocalizedFailureReasonErrorKey];
        NSError *error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        [[NSApplication sharedApplication] presentError:error];
        return nil;
    }
    _managedObjectContext = [[NSManagedObjectContext alloc] init];
    [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    
    return _managedObjectContext;
}

- (void)loadDomains {
    NWLog(@"Loading domain configuration.");
    
    self.namecheapDomains = [NSMutableArray array];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"NCUNamecheapDomain"];
    NSError *error;
    
    [self.namecheapDomains addObjectsFromArray:[self.managedObjectContext executeFetchRequest:fetchRequest error:&error]];
    
    if (error) {
        NWLog(@"ERROR FETCHING DATA: %@", [error localizedDescription]);
    } else {
        NWLog(@"Domain configuration loaded successfully.");
    }
}

- (void)loadAppSettings {
    NWLog(@"Loading app settings.");
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"NCUAppSetting"];
    
    NSError *error;
    NSArray *appSettings = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    
    if (error) {
        NWLog(@"ERROR FETCHING DATA: %@", [error localizedDescription]);
    } else {
        NWLog(@"App settings loaded successfully.");
        
        for (NCUAppSetting *appSetting in appSettings) {
            if ([appSetting.settingName isEqualToString:@"MASTER_SWITCH"]) {
                self.masterSwitchState = appSetting;
            }
            else if ([appSetting.settingName isEqualToString:@"ACTIVITY_LOGGING"]) {
                self.activityLoggingState = appSetting;
            }
        }
        
        if (!self.masterSwitchState) {
            self.masterSwitchState = [[NCUAppSetting alloc] init];
            self.masterSwitchState.settingName = @"MASTER_SWITCH";
            [self.masterSwitchState setBoolValue:NO];
        }
        
        if (!self.activityLoggingState) {
            self.activityLoggingState = [[NCUAppSetting alloc] init];
            self.activityLoggingState.settingName = @"ACTIVITY_LOGGING";
            [self.activityLoggingState setBoolValue:NO];
        }
    }
}




@end
