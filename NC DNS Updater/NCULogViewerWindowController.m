//
//  NCULogViewerWindowController.m
//  NC DNS Updater
//
//  Created by Spencer Müller Diniz on 13/10/14.
//  Copyright (c) 2014 SPENCER. All rights reserved.
//

#import "NCULogViewerWindowController.h"
#import "NCUAppDelegate.h"

@interface NCULogViewerWindowController ()

@property (strong, nonatomic) NSString *logContents;
@property (strong, nonatomic) NSSavePanel *savePanel;

@end

@implementation NCULogViewerWindowController

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];

    NCUAppDelegate *appDelegate = (NCUAppDelegate *)[NSApplication sharedApplication].delegate;
    
    NSError *error;
    self.logContents = [NSString stringWithContentsOfFile:appDelegate.logFilePrinter.path encoding:NSUTF8StringEncoding error:&error];
    
    [self.textView setString:self.logContents];

    self.savePanel = [NSSavePanel savePanel];
    [self.savePanel setAllowedFileTypes:@[@"log"]];
    [self.savePanel setNameFieldStringValue:@"NCDNSUpdater"];
}

- (IBAction)clearLog_Clicked:(id)sender {
    NCUAppDelegate *appDelegate = (NCUAppDelegate *)[NSApplication sharedApplication].delegate;
    [appDelegate.logFilePrinter clear];
    
    self.logContents = @"";
    [self.textView setString:@""];
}

- (IBAction)saveToFile_Clicked:(id)sender {
    
    if ([self.savePanel runModal] == NSOKButton) {
        
        NSError *error;
        [self.logContents writeToFile:self.savePanel.URL.path atomically:YES encoding:NSUTF8StringEncoding error:&error];
        
        if (error) {
            NSLog(@"ERROR: %@", error.localizedDescription);
        }
    }
}

@end
