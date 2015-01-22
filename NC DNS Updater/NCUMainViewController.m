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
#import "NCUVersionService.h"
#import "NCUVersion.h"
#import <NOSwitch/NOSwitchButton.h>

@interface NCUMainViewController ()

@property NCULogViewerWindowController *logViewerWindow;
@property NSTimer *checkForUpdateTimer;
@property NSTimer *currentIpCheckTimer;
@property BOOL formLoaded;

@end

@implementation NCUMainViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [NCUIPService setAppVersion:[NCUVersionService getCurrentVersion].versionNumber];
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
    self.domainPasswordTextField.nextKeyView = self.domainIpSourceComboBox;
    self.domainIpSourceComboBox.nextKeyView = self.domainEnabledButton;
    self.domainEnabledButton.nextKeyView = self.domainsTableView;
    self.domainsTableView.nextKeyView = self.domainNameTextField;
    
    [self updateActivityLoggingPosition];
    [self updateMasterSwitchPosition];
    
    NCUAppDelegate *appDelegate = (NCUAppDelegate *)[NSApplication sharedApplication].delegate;

    if ([self.namecheapDomains count] && !self.selectedNamecheapDomain) {
        [self.domainsTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
    }
    
    [appDelegate.window makeFirstResponder:self.domainsTableView];
    
    [self setLoggingEnabledTo:self.activityLoggingState];
    [self checkForNewVersion];
    [self createTimerForCurrentIPCheck];
    [self createCheckForUpdateTimer];
    [self updateDomain:nil];
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

- (void)timer_Ticked:(NSTimer *)timer {
    if (timer == self.checkForUpdateTimer) {
        [self checkForNewVersion];
    }
    else if (timer == self.currentIpCheckTimer) {
        [self updateDomain:nil];
    }
    else {
        NCUNamecheapDomain *namecheapDomain = (NCUNamecheapDomain *)timer.userInfo;
        
        if (namecheapDomain) {
            NWLog(@"Update timer ticked for %@.", namecheapDomain.name);
            [self updateDnsWithNamecheapDomain:namecheapDomain];
        }
    }
}

- (void)updateDomain:(NCUNamecheapDomain *)specificDomain {
    [NCUIPService getExternalIPAddressWithCompletionBlock:^(NSString *ipAddress, NSError *error) {
        NSString *internalIP = [NCUIPService getInternalIPAddress];
        
        [self.currentExternalIpTextField setStringValue:[NSString stringWithFormat:@"External IP: %@", ipAddress]];
        [self.currentInternalIpTextField setStringValue:[NSString stringWithFormat:@"Internal IP: %@", internalIP]];
        
        for (NCUNamecheapDomain *namecheapDomain in self.namecheapDomains) {
            if (specificDomain && namecheapDomain != specificDomain) {
                continue;
            }
            
            NSString *currentIP = [NCUIPService getIPAddressForURL:namecheapDomain.httpUrl];
            if ([NCUIPService isStringAnIP:currentIP]) {
                namecheapDomain.currentIP = currentIP;
            }
            else {
                namecheapDomain.currentIP = nil;
            }
            
            NSString *referenceIP;
            
            if ([namecheapDomain.ipSource integerValue] == NCUIpSourceExternal) {
                referenceIP = ipAddress;
            }
            else {
                referenceIP = internalIP;
            }
            
            NCUMainTableCellViewStatus status = NCUMainTableCellViewStatusDisabled;
            
            if ([namecheapDomain.currentIP isEqualToString:referenceIP]) {
                status = NCUMainTableCellViewStatusUpdated;
                namecheapDomain.comment = @"IP is up to date.";
            }
            else {
                status = NCUMainTableCellViewStatusOutdated;
                namecheapDomain.comment = [NSString stringWithFormat:@"Host IP is outdated.%@", [namecheapDomain.enabled boolValue] && self.masterSwitchState ? @" Update request will be issued." : [NSString stringWithFormat:@" Automatic updates are disabled.%@", self.masterSwitchState ? @" Enable this host for automatic updates." : @" Turn on the Master Switch to enable automatic updates."]];
            }
            
            if (![namecheapDomain.enabled boolValue]) {
                status = NCUMainTableCellViewStatusDisabled;
            }

            NCUMainTableCellView *cell = [self.domainsTableView viewAtColumn:0 row:[self.namecheapDomains indexOfObject:namecheapDomain] makeIfNecessary:NO];
            
            if (cell) {
                cell.status = status;
            }
            
            if (![namecheapDomain.currentIP isEqualToString:referenceIP] && [namecheapDomain.enabled boolValue] && self.masterSwitchState) {
                [self updateDnsWithNamecheapDomain:namecheapDomain];
            }
            
            if (self.selectedNamecheapDomain == namecheapDomain) {
                [self loadForm];
            }
        }
    }];
}

- (void)updateDnsWithNamecheapDomain:(NCUNamecheapDomain *)namecheapDomain {
    NWLog(@"Processing %@", [namecheapDomain completeHostName]);

    if ([namecheapDomain.ipSource integerValue] == NCUIpSourceExternal) {
        NWLog(@"Determining external IP address.");
        [NCUIPService getExternalIPAddressWithCompletionBlock:^(NSString *ipAddress, NSError *error) {
            if (error) {
                NWLog(@"ERROR determining external IP address. %@", error.localizedDescription);
            }
            else {
                if (ipAddress) {
                    NWLog(@"External IP address is %@.", ipAddress);
                    if ([NCUIPService isStringAnIP:ipAddress]) {
                        NWLog(@"Requesting IP address update for %@ to %@.", [namecheapDomain completeHostName], ipAddress);
                        [NCUIPService updateNamecheapDomain:namecheapDomain withIP:ipAddress withCompletionBlock:^(NCUNamecheapDomain *namecheapDomain, NSError *error) {
                            namecheapDomain.comment = error ? [error localizedDescription] : @"Update request issued successfully. Please wait for update to propagate.";
                            if (namecheapDomain == self.selectedNamecheapDomain) {
                                [self loadForm];
                            }
                        }];
                    }
                    else {
                        NWLog(@"%@ is not a valid IP address.", ipAddress);
                    }
                }
                else {
                    NWLog(@"Could not determine external IP address.");
                }
            }
        }];
    }
    else {
        NWLog(@"Determining internal IP address.");
        id ipAddress = [NCUIPService getInternalIPAddress];
        if (ipAddress) {
            NWLog(@"Internal IP address is %@.", ipAddress);
            if ([NCUIPService isStringAnIP:ipAddress]) {
                NWLog(@"Requesting IP address update for %@ to %@.", [namecheapDomain completeHostName], ipAddress);
                [NCUIPService updateNamecheapDomain:namecheapDomain withIP:ipAddress withCompletionBlock:^(NCUNamecheapDomain *namecheapDomain, NSError *error) {
                    namecheapDomain.comment = error ? [error localizedDescription] : @"Update request issued successfully. Please wait for update to propagate.";
                    if (namecheapDomain == self.selectedNamecheapDomain) {
                        [self loadForm];
                    }
                }];
            }
            else {
                NWLog(@"%@ is not a valid IP address.", ipAddress);
            }
        }
        else {
            NWLog(@"Could not determine internal IP address.");
        }
    }
}

- (void)removeTimerForNamecheapDomain:(NCUNamecheapDomain *)namecheapDomain {
    NSTimer *timer = [self.updateTimers objectForKey:namecheapDomain.identifier];
    
    if (timer) {
        [timer invalidate];
        [self.updateTimers removeObjectForKey:namecheapDomain];
    }
}

- (void)createTimerForCurrentIPCheck {
    if (self.currentIpCheckTimer) {
        [self.currentIpCheckTimer invalidate];
    }
    
    self.currentIpCheckTimer = [NSTimer scheduledTimerWithTimeInterval:60 target:self selector:@selector(timer_Ticked:) userInfo:nil repeats:YES];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return [self.namecheapDomains count];
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    NCUMainTableCellView *cell = [tableView makeViewWithIdentifier:@"MainTableCellView" owner:self];
    NCUNamecheapDomain *namecheapDomain = [self.namecheapDomains objectAtIndex:row];
    cell.status = [namecheapDomain.enabled boolValue] ? NCUMainTableCellViewStatusOutdated : NCUMainTableCellViewStatusDisabled;
    cell.showDisclosureArrow = (namecheapDomain == self.selectedNamecheapDomain);
    cell.textField.stringValue = namecheapDomain.name;
    cell.detailTextField.stringValue = [NSString stringWithFormat:@"%@", [namecheapDomain completeHostName]];
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
    namecheapDomain.ipSource = NCUIpSourceExternal;
    namecheapDomain.enabled = @NO;
    namecheapDomain.currentIP = @"";
    
    [self.namecheapDomains addObject:namecheapDomain];
    [self.domainsTableView reloadData];
    [self.domainsTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:[self.namecheapDomains indexOfObject:namecheapDomain]] byExtendingSelection:NO];
    [self loadForm];
}

- (void)loadForm {
    self.formLoaded = NO;
    
    if (self.selectedNamecheapDomain) {
        [self.formView setHidden:NO];
        [self.domainNameTextField setStringValue:self.selectedNamecheapDomain.name];
        [self.domainHostTextField setStringValue:self.selectedNamecheapDomain.host];
        [self.domainDomainTextField setStringValue:self.selectedNamecheapDomain.domain];
        [self.domainPasswordTextField setStringValue:self.selectedNamecheapDomain.password];
        [self.domainIpSourceComboBox selectItemAtIndex:[self.selectedNamecheapDomain.ipSource integerValue]];
        [self.domainEnabledButton setState:[self.selectedNamecheapDomain.enabled integerValue]];
        [self.domainCurrentIPTextField setStringValue:self.selectedNamecheapDomain.currentIP ?: @"-"];
        [self.domainComments setStringValue:self.selectedNamecheapDomain.comment ?: @"-"];
    }
    else {
        [self.formView setHidden:YES];
    }
    
    self.formLoaded = YES;
}

- (IBAction)activityLogging_Clicked:(id)sender {
    self.activityLoggingState = !self.activityLoggingState;
    [[NSUserDefaults standardUserDefaults] setBool:self.activityLoggingState forKey:@"ACTIVITY_LOGGING"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self setLoggingEnabledTo:self.activityLoggingState];
}

- (IBAction)masterSwitch_Clicked:(id)sender {
    self.masterSwitchState = !self.masterSwitchState;
    [[NSUserDefaults standardUserDefaults] setBool:self.masterSwitchState forKey:@"MASTER_SWITCH"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    if (self.masterSwitchState) {
        [self createTimerForCurrentIPCheck];
    }
    else {
        [self.currentIpCheckTimer invalidate];
    }

    [self updateDomain:nil];
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
    [self updateDomain:self.selectedNamecheapDomain];
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
        [self.loggingSwitchButton setState:NSOnState];
    }
    else {
        [self.loggingSwitchButton setState:NSOffState];
    }
}

- (void)updateMasterSwitchPosition {
    if (self.masterSwitchState) {
        [self.masterSwitchButton setState:NSOnState];
    }
    else {
        [self.masterSwitchButton setState:NSOffState];
    }
}

- (void)saveChanges {
    if (self.formLoaded) {
        if (self.selectedNamecheapDomain) {
            if (self.domainNameTextField.stringValue.length == 0) {
                self.domainNameTextField.stringValue = @"<< NO NAME >>";
            }
            
            self.selectedNamecheapDomain.name = self.domainNameTextField.stringValue;
            self.selectedNamecheapDomain.host = self.domainHostTextField.stringValue;
            self.selectedNamecheapDomain.domain = self.domainDomainTextField.stringValue;
            self.selectedNamecheapDomain.password = self.domainPasswordTextField.stringValue;
            self.selectedNamecheapDomain.ipSource = @(self.domainIpSourceComboBox.indexOfSelectedItem);
            self.selectedNamecheapDomain.enabled = @(self.domainEnabledButton.state);
            self.selectedNamecheapDomain.currentIP = self.domainCurrentIPTextField.stringValue;
            self.selectedNamecheapDomain.comment = self.domainComments.stringValue;
            
            NSError *error;
            if (![[self getDataContext] save:&error]) {
                NSLog(@"ERROR SAVING IN DATABASE: %@", [error localizedDescription]);
            }
        }
    }
}

- (void)comboBoxWillDismiss:(NSNotification *)notification {
    [self saveChanges];
    [self updateDomain:self.selectedNamecheapDomain];
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
            NSError *error;
            if (![[self getDataContext] save:&error]) {
                NSLog(@"ERROR SAVING IN DATABASE: %@", [error localizedDescription]);
            }
            
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
    [self saveChanges];
    if (self.selectedNamecheapDomain && [self isDomainInfoValid]) {
        [self updateDomain:self.selectedNamecheapDomain];
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

- (void)checkForNewVersion {
    
    NWLog(@"Checking for updates.");
    
    self.messageTextField.textColor = [NSColor blackColor];
    self.messageTextField.stringValue = @"Checking for updates.";
    
    [NCUVersionService getAvailableVersionWithCompletionBlock:^(NCUVersion *availableVersion, NSError *error) {
        NSLog(@"availableVersion: %@", availableVersion.versionNumber);
        
        if (error) {
            NWLog(@"ERROR CHECKING FOR UPDATES: %@", error.localizedDescription);
            
            self.messageTextField.textColor = [NSColor redColor];
            self.messageTextField.stringValue = @"Error checking for updates.";
        }
        else {
            NCUVersion *currentVersion = [NCUVersionService getCurrentVersion];
            
            NWLog(@"Current Version: %@ / Available Version: %@.", currentVersion.versionNumber, availableVersion.versionNumber);

            if ([availableVersion.versionNumber isEqualToString:currentVersion.versionNumber]) {
                NWLog(@"%@ is the latest version.", currentVersion.versionNumber);
                
                self.messageTextField.textColor = [NSColor blackColor];
                self.messageTextField.stringValue = @"You have the latest version of NC DNS Updater.";
            }
            else {
                NWLog(@"New version (%@) is available.", availableVersion.versionNumber);
                
                self.messageTextField.textColor = [NSColor blueColor];
                self.messageTextField.stringValue = @"A new version of NC DNS Updater is available. Get it at http://idb.gosmd.net/.";
            }
        }
    }];
}

- (void)createCheckForUpdateTimer {
    self.checkForUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:86400 target:self selector:@selector(timer_Ticked:) userInfo:nil repeats:YES];
}

@end
