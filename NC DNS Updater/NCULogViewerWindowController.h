//
//  NCULogViewerWindowController.h
//  NC DNS Updater
//
//  Created by Spencer Müller Diniz on 13/10/14.
//  Copyright (c) 2014 SPENCER. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NCULogViewerWindowController : NSWindowController

@property (strong, nonatomic) IBOutlet NSTextView *textView;

- (IBAction)clearLog_Clicked:(id)sender;
- (IBAction)saveToFile_Clicked:(id)sender;

@end
