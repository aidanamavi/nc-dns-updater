//
//  NCUMainViewController.h
//  NC DNS Updater
//
//  Created by Spencer Müller Diniz on 7/23/14.
//  Copyright (c) 2014 SPENCER. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NCUNamecheapDomain.h"

@class NOSwitchButton;

@interface NCUMainViewController : NSViewController <NSTableViewDataSource, NSTableViewDelegate, NSTextFieldDelegate, NSComboBoxDelegate>

@property NSMutableArray *namecheapDomains;
@property NSMutableDictionary *updateTimers;
@property NCUNamecheapDomain *selectedNamecheapDomain;
@property BOOL masterSwitchState;
@property BOOL activityLoggingState;

@property IBOutlet NSTableView *domainsTableView;
@property IBOutlet NSView *formView;
@property IBOutlet NSTextField *domainNameTextField;
@property IBOutlet NSTextField *domainHostTextField;
@property IBOutlet NSTextField *domainDomainTextField;
@property IBOutlet NSTextField *domainPasswordTextField;
@property IBOutlet NSTextField *domainIntervalTextField;
@property IBOutlet NSComboBox *domainIpSourceComboBox;
@property IBOutlet NSButton *domainEnabledButton;
@property IBOutlet NSTextField *domainCurrentIPTextField;
@property IBOutlet NSTextField *domainComments;

@property IBOutlet NOSwitchButton *masterSwitchButton;
@property IBOutlet NOSwitchButton *loggingSwitchButton;

@property IBOutlet NSTextField *messageTextField;

- (IBAction)addDomain_Clicked:(id)sender;
- (IBAction)removeDomain_Clicked:(id)sender;
- (IBAction)masterSwitch_Clicked:(id)sender;
- (IBAction)activityLogging_Clicked:(id)sender;
- (IBAction)enabledSwitch_Clicked:(id)sender;
- (IBAction)updateNow_Clicked:(id)sender;
- (IBAction)viewLogs_Clicked:(id)sender;

- (void)updateDnsWithNamecheapDomain:(NCUNamecheapDomain *)namecheapDomain;

@end
