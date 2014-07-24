//
//  NCUMainViewController.h
//  NC DNS Updater
//
//  Created by Spencer Müller Diniz on 7/23/14.
//  Copyright (c) 2014 SPENCER. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NCUNamecheapDomain.h"

@interface NCUMainViewController : NSViewController <NSTableViewDataSource, NSTableViewDelegate>

@property NSMutableArray *namecheapDomains;
@property NCUNamecheapDomain *selectedNamecheapDomain;
@property BOOL masterSwitchState;

@property IBOutlet NSTableView *domainsTableView;
@property IBOutlet NSView *formView;
@property IBOutlet NSTextField *domainNameTextField;
@property IBOutlet NSTextField *domainHostTextField;
@property IBOutlet NSTextField *domainDomainTextField;
@property IBOutlet NSTextField *domainPasswordTextField;
@property IBOutlet NSTextField *domainIntervalTextField;
@property IBOutlet NSButton *domainEnabledButton;
@property IBOutlet NSImageView *masterSwitchButtonImageView;
@property IBOutlet NSButton *masterSwitchBackgroundButton;

- (IBAction)addDomain_Clicked:(id)sender;
- (IBAction)masterSwitch_Clicked:(id)sender;

@end
