//
//  NCUMainViewController.m
//  NC DNS Updater
//
//  Created by Spencer Müller Diniz on 7/23/14.
//  Copyright (c) 2014 SPENCER. All rights reserved.
//

#import "NCUMainViewController.h"
#import "NCUMainTableCellView.h"
#import "NCUAppDelegate.h"
#import "NCUOnlyIntegerValueFormatter.h"
#import "NCUIPService.h"
#import "NCULogViewerWindowController.h"

@interface NCUMainViewController ()

@property NCULogViewerWindowController *logViewerWindow;

@end

@implementation NCUMainViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.masterSwitchState = [[NSUserDefaults standardUserDefaults] boolForKey:@"MASTER_SWITCH"];

        self.activityLoggingState = [[NSUserDefaults standardUserDefaults] boolForKey:@"ACTIVITY_LOGGING"];
        NWLog(@"Master switch state is %@.", self.masterSwitchState ? @"ON" : @"OFF");
        
        [self loadDomains];
    }
    return self;
}

- (void)loadView {
    [super loadView];
    
    [self.formView setHidden:YES];
    
    self.domainNameTextField.nextKeyView = self.domainHostTextField;
    self.domainHostTextField.nextKeyView = self.domainDomainTextField;
    self.domainDomainTextField.nextKeyView = self.domainPasswordTextField;
    self.domainPasswordTextField.nextKeyView = self.domainIntervalTextField;
    self.domainIntervalTextField.nextKeyView = self.domainsTableView;
    self.domainsTableView.nextKeyView = self.domainNameTextField;
    
    [self updateActivityLoggingPosition];
    [self updateMasterSwitchPosition];
    self.domainIntervalTextField.formatter = [[NCUOnlyIntegerValueFormatter alloc] init];
    
    NCUAppDelegate *appDelegate = (NCUAppDelegate *)[NSApplication sharedApplication].delegate;

    if ([self.namecheapDomains count] && !self.selectedNamecheapDomain) {
        [self.domainsTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
    }
    
    [appDelegate.window makeFirstResponder:self.domainsTableView];
    
    [self setLoggingEnabledTo:self.activityLoggingState];
    if (self.masterSwitchState) {
        [self loadUpdateTimers];
    }
}

- (void)loadDomains {
    NWLog(@"Loading domain configuration.");
    
    self.namecheapDomains = [NSMutableArray array];
    NCUAppDelegate *appDelegate = (NCUAppDelegate *)[NSApplication sharedApplication].delegate;
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"NCUNamecheapDomain"];
    NSError *error;

    [self.namecheapDomains addObjectsFromArray:[appDelegate.managedObjectContext executeFetchRequest:fetchRequest error:&error]];
    
    if (error) {
        NWLog(@"ERROR FETCHING DATA: %@", [error localizedDescription]);
    } else {
        NWLog(@"Domain configuration loaded successfully.");
    }
}

- (void)loadUpdateTimers {
    NWLog(@"Loading update timers.");
    [self resetUpdateTimers];
    
    for (NCUNamecheapDomain *namecheapDomain in self.namecheapDomains) {
        if ([namecheapDomain.enabled boolValue]) {
            [self createTimerForNamecheapDomain:namecheapDomain];
        }
    }
    
    NWLog(@"Update timers loaded successfully.");
}

- (void)timer_Ticked:(NSTimer *)timer {
    NCUNamecheapDomain *namecheapDomain = (NCUNamecheapDomain *)timer.userInfo;
    
    if (namecheapDomain) {
        NWLog(@"Update timer ticked for %@.", namecheapDomain.name);
        [self updateDnsWithNamecheapDomain:namecheapDomain];
    }
}

- (void)updateDnsWithNamecheapDomain:(NCUNamecheapDomain *)namecheapDomain {
    NWLog(@"Updating %@.%@.", namecheapDomain.host, namecheapDomain.domain);
    NWLog(@"Fetching current IP address.");
    [NCUIPService getExternalIPAddressWithCompletionBlock:^(NSString *ipAddress, NSError *error) {
        if (error) {
            NWLog(@"ERROR FETCHING CURRENT IP ADDRESS: %@", error.localizedDescription);
        }
        else {
            if (ipAddress) {
                if ([NCUIPService isStringAnIP:ipAddress] && ![ipAddress isEqualToString:namecheapDomain.currentIP]) {
                    NWLog(@"Current IP address is %@.", ipAddress);
                    namecheapDomain.currentIP = ipAddress;
                    NSError *error;
                    [[self getDataContext] save:&error];
                    [NCUIPService updateNamecheapDomain:namecheapDomain withIP:ipAddress];
                    
                    if (self.selectedNamecheapDomain == namecheapDomain) {
                        [self.domainCurrentIPTextField setStringValue:ipAddress];
                    }
                }
                else {
                    NWLog(@"%@ is not a valid IP address or IP address did not change.", ipAddress);
                }
            }
        }
    }];
}

- (void)resetUpdateTimers {
    if (!self.updateTimers) {
        self.updateTimers = [NSMutableDictionary dictionary];
    }
    
    for (NSTimer *updateTimer in self.updateTimers.objectEnumerator) {
        [updateTimer invalidate];
    }
    
    [self.updateTimers removeAllObjects];
}

- (NSTimer *)createTimerForNamecheapDomain:(NCUNamecheapDomain *)namecheapDomain {
    NSTimer *timer;
    
    if ([namecheapDomain.enabled boolValue]) {
        timer = [NSTimer scheduledTimerWithTimeInterval:namecheapDomain.interval.integerValue * 60 target:self selector:@selector(timer_Ticked:) userInfo:namecheapDomain repeats:YES];
        
        [self.updateTimers setObject:timer forKey:namecheapDomain.identifier];
    }
    
    return timer;
}

- (void)removeTimerForNamecheapDomain:(NCUNamecheapDomain *)namecheapDomain {
    NSTimer *timer = [self.updateTimers objectForKey:namecheapDomain.identifier];
    
    if (timer) {
        [timer invalidate];
        [self.updateTimers removeObjectForKey:namecheapDomain];
    }
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return [self.namecheapDomains count];
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    NCUMainTableCellView *cell = [tableView makeViewWithIdentifier:@"MainTableCellView" owner:self];
    NCUNamecheapDomain *namecheapDomain = [self.namecheapDomains objectAtIndex:row];
    cell.domainEnabled = [namecheapDomain.enabled boolValue];
    cell.showDisclosureArrow = (namecheapDomain == self.selectedNamecheapDomain);
    cell.textField.stringValue = namecheapDomain.name;
    cell.detailTextField.stringValue = [NSString stringWithFormat:@"%@.%@", namecheapDomain.host, namecheapDomain.domain];
    return cell;
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
    NSTableView *tableView = (NSTableView *)notification.object;
    
    [self saveChanges];
    
    if (self.selectedNamecheapDomain) {
        NSInteger previousSelectedIndex = [self.namecheapDomains indexOfObject:self.selectedNamecheapDomain];
        NCUMainTableCellView *previousSelectedCell = [tableView viewAtColumn:0 row:previousSelectedIndex makeIfNecessary:NO];
        
        previousSelectedCell.showDisclosureArrow = NO;
    }
    
    NCUMainTableCellView *selectedCell = [tableView viewAtColumn:0 row:tableView.selectedRow makeIfNecessary:YES];
    selectedCell.showDisclosureArrow = YES;
    self.selectedNamecheapDomain = [self.namecheapDomains objectAtIndex:tableView.selectedRow];

    [self loadForm];
}

- (IBAction)addDomain_Clicked:(id)sender {
    NCUNamecheapDomain *namecheapDomain = [NSEntityDescription insertNewObjectForEntityForName:@"NCUNamecheapDomain" inManagedObjectContext:[self getDataContext]];
    
    namecheapDomain.identifier = [[NSUUID UUID] UUIDString];
    namecheapDomain.name = @"new domain";
    namecheapDomain.host = @"";
    namecheapDomain.domain = @"";
    namecheapDomain.password = @"";
    namecheapDomain.interval = @5;
    namecheapDomain.enabled = @NO;
    namecheapDomain.currentIP = @"";
    
    [self.namecheapDomains addObject:namecheapDomain];
    [self.domainsTableView reloadData];
    [self.domainsTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:[self.namecheapDomains indexOfObject:namecheapDomain]] byExtendingSelection:NO];
    [self loadForm];
}

- (void)loadForm {
    if (self.selectedNamecheapDomain) {
        [self.formView setHidden:NO];
        [self.domainNameTextField setStringValue:self.selectedNamecheapDomain.name];
        [self.domainHostTextField setStringValue:self.selectedNamecheapDomain.host];
        [self.domainDomainTextField setStringValue:self.selectedNamecheapDomain.domain];
        [self.domainPasswordTextField setStringValue:self.selectedNamecheapDomain.password];
        [self.domainIntervalTextField setStringValue:[NSString stringWithFormat:@"%@", self.selectedNamecheapDomain.interval]];
        [self.domainEnabledButton setState:[self.selectedNamecheapDomain.enabled integerValue]];
        [self.domainCurrentIPTextField setStringValue:self.selectedNamecheapDomain.currentIP];
    }
    else {
        [self.formView setHidden:YES];
    }
}

- (IBAction)activityLogging_Clicked:(id)sender {
    self.activityLoggingState = !self.activityLoggingState;
    [[NSUserDefaults standardUserDefaults] setBool:self.activityLoggingState forKey:@"ACTIVITY_LOGGING"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [NSAnimationContext beginGrouping];
    [self updateActivityLoggingPosition];
    [NSAnimationContext endGrouping];
    
    [self setLoggingEnabledTo:self.activityLoggingState];
}

- (IBAction)masterSwitch_Clicked:(id)sender {
    self.masterSwitchState = !self.masterSwitchState;
    [[NSUserDefaults standardUserDefaults] setBool:self.masterSwitchState forKey:@"MASTER_SWITCH"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [NSAnimationContext beginGrouping];
    [self updateMasterSwitchPosition];
    [NSAnimationContext endGrouping];
    
    if (self.masterSwitchState) {
        [self loadUpdateTimers];
    }
    else {
        [self resetUpdateTimers];
    }
}

- (IBAction)enabledSwitch_Clicked:(id)sender {
    
    if (self.domainEnabledButton.state == NSOnState) {
        if (![self isDomainInfoValid]) {
            self.domainEnabledButton.state = NSOffState;
        }
    }
    
    if (self.selectedNamecheapDomain) {
        self.selectedNamecheapDomain.enabled = @(self.domainEnabledButton.state);
        [self.domainsTableView reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:[self.namecheapDomains indexOfObject:self.selectedNamecheapDomain]] columnIndexes:[NSIndexSet indexSetWithIndex:0]];
    }
    
    [self saveChanges];
    
    if ([self.selectedNamecheapDomain.enabled boolValue]) {
        [self createTimerForNamecheapDomain:self.selectedNamecheapDomain];
    }
    else {
        [self removeTimerForNamecheapDomain:self.selectedNamecheapDomain];
    }
}

- (BOOL)isDomainInfoValid {
    BOOL isValid = YES;
    NSMutableArray *missingInfo = [NSMutableArray array];
    
    if (self.domainHostTextField.stringValue.length <= 0) {
        [missingInfo addObject:@"  - HOST"];
        isValid = NO;
    }
    
    if (self.domainDomainTextField.stringValue.length <=0) {
        [missingInfo addObject:@"  - DOMAIN"];
        isValid = NO;
    }
    
    if (self.domainPasswordTextField.stringValue.length <= 0) {
        [missingInfo addObject:@"  - PASSWORD"];
        isValid = NO;
    }
    
    if (self.domainIntervalTextField.stringValue.length <= 0) {
        [missingInfo addObject:@"  - INTERVAL"];
        isValid = NO;
    }
    
    if (!isValid) {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert addButtonWithTitle:@"OK"];
        [alert setMessageText:@"Cannot enable this domain for updates."];
        [alert setInformativeText:[NSString stringWithFormat:@"Required information missing:\n%@", [missingInfo componentsJoinedByString:@"\n"]]];
        [alert runModal];
    }
    
    return isValid;
}

- (void)updateActivityLoggingPosition {
    if (self.activityLoggingState) {
        NSRect newFrame = self.activityLoggingButtonImageView.frame;
        newFrame.origin.x = CGRectGetMaxX(self.activityLoggingBackgroundButton.frame) - self.activityLoggingButtonImageView.frame.size.width;
        self.activityLoggingButtonImageView.animator.frame = newFrame;
    }
    else {
        NSRect newFrame = self.activityLoggingButtonImageView.frame;
        newFrame.origin = self.activityLoggingBackgroundButton.frame.origin;
        self.activityLoggingButtonImageView.animator.frame = newFrame;
    }
}

- (void)updateMasterSwitchPosition {
    if (self.masterSwitchState) {
        NSRect newFrame = self.masterSwitchButtonImageView.frame;
        newFrame.origin.x = CGRectGetMaxX(self.masterSwitchBackgroundButton.frame) - self.masterSwitchButtonImageView.frame.size.width;
        self.masterSwitchButtonImageView.animator.frame = newFrame;
    }
    else {
        NSRect newFrame = self.masterSwitchButtonImageView.frame;
        newFrame.origin = self.masterSwitchBackgroundButton.frame.origin;
        self.masterSwitchButtonImageView.animator.frame = newFrame;
    }
}

- (void)saveChanges {
    if (self.selectedNamecheapDomain) {
        if (self.domainNameTextField.stringValue.length == 0) {
            self.domainNameTextField.stringValue = @"<< NO NAME >>";
        }
        
        if (self.domainIntervalTextField.stringValue.length == 0) {
            self.domainIntervalTextField.stringValue = @"5";
        }
        
        self.selectedNamecheapDomain.name = self.domainNameTextField.stringValue;
        self.selectedNamecheapDomain.host = self.domainHostTextField.stringValue;
        self.selectedNamecheapDomain.domain = self.domainDomainTextField.stringValue;
        self.selectedNamecheapDomain.password = self.domainPasswordTextField.stringValue;
        self.selectedNamecheapDomain.interval = @(self.domainIntervalTextField.integerValue);
        self.selectedNamecheapDomain.enabled = @(self.domainEnabledButton.state);
        self.selectedNamecheapDomain.currentIP = self.domainCurrentIPTextField.stringValue;
        
        NSError *error;
        if (![[self getDataContext] save:&error]) {
            NSLog(@"ERROR SAVING IN DATABASE: %@", [error localizedDescription]);
        }
    }
}

- (void)controlTextDidChange:(NSNotification *)notification {
    NSTextField *textField = [notification object];
    
    if (textField == self.domainNameTextField) {
        self.selectedNamecheapDomain.name = [self.domainNameTextField stringValue];
        [self.domainsTableView reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:[self.namecheapDomains indexOfObject:self.selectedNamecheapDomain]] columnIndexes:[NSIndexSet indexSetWithIndex:0]];
    }
    else if (textField == self.domainHostTextField || textField == self.domainDomainTextField) {
        self.selectedNamecheapDomain.host = [self.domainHostTextField stringValue];
        self.selectedNamecheapDomain.domain = [self.domainDomainTextField stringValue];
        [self.domainsTableView reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:[self.namecheapDomains indexOfObject:self.selectedNamecheapDomain]] columnIndexes:[NSIndexSet indexSetWithIndex:0]];
    }
    
    self.domainEnabledButton.state = NSOffState;
    [self enabledSwitch_Clicked:self.domainEnabledButton];
}

- (IBAction)removeDomain_Clicked:(id)sender {
    if (self.selectedNamecheapDomain) {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert addButtonWithTitle:@"OK"];
        [alert addButtonWithTitle:@"Cancel"];
        [alert setMessageText:@"Delete domain?"];
        [alert setInformativeText:@"Deleted domains cannot be restored."];
        
        if ([alert runModal] == NSAlertFirstButtonReturn) {
            [self removeTimerForNamecheapDomain:self.selectedNamecheapDomain];
            [[self getDataContext] deleteObject:self.selectedNamecheapDomain];
            self.selectedNamecheapDomain = nil;
            [self loadDomains];
            [self.domainsTableView reloadData];
            if ([self.namecheapDomains count] && !self.selectedNamecheapDomain) {
                [self.domainsTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
            }
            [self loadForm];
        }
    }
}

- (NSManagedObjectContext *)getDataContext {
    NCUAppDelegate *appDelegate = (NCUAppDelegate *)[NSApplication sharedApplication].delegate;
    NSManagedObjectContext *context = appDelegate.managedObjectContext;
    return context;
}

- (IBAction)updateNow_Clicked:(id)sender {
    if (self.selectedNamecheapDomain && [self isDomainInfoValid]) {
        [self updateDnsWithNamecheapDomain:self.selectedNamecheapDomain];
    }
}

- (IBAction)viewLogs_Clicked:(id)sender {
    self.logViewerWindow = [[NCULogViewerWindowController alloc] initWithWindowNibName:@"NCULogViewerWindowController"];
    
    [self.logViewerWindow showWindow:self];
}

- (void)setLoggingEnabledTo:(BOOL)state {
    NCUAppDelegate *appDelegate = (NCUAppDelegate *)[NSApplication sharedApplication].delegate;
    
    if (state) {
        [[NWLMultiLogger shared] addPrinter:appDelegate.logFilePrinter];
    }
    else {
        [[NWLMultiLogger shared] removePrinter:appDelegate.logFilePrinter];
    }
    
    NSLog(@"LOGGING IS %@", state ? @"enabled" : @"disabled");
}

@end
