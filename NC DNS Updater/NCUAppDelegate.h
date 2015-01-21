//
//  NCUAppDelegate.h
//  NC DNS Updater
//
//  Created by Spencer Müller Diniz on 7/22/14.
//  Copyright (c) 2014 SPENCER. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class NCUMainViewController;

@interface NCUAppDelegate : NSObject <NSApplicationDelegate, NSTableViewDelegate, NSTableViewDataSource>

@property (strong, nonatomic) NWLFilePrinter *logFilePrinter;
@property NCUMainViewController *mainViewController;
@property (readwrite, retain) NSStatusItem *statusItem;
@property (readwrite, retain) IBOutlet NSMenu *menu;
@property (assign) IBOutlet NSWindow *window;

@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;

- (IBAction)menuActionSettings:(id)sender;
- (IBAction)menuActionQuit:(id)sender;

@end
