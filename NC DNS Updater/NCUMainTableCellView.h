//
//  NCUMainTableCellView.h
//  NC DNS Updater
//
//  Created by Spencer Müller Diniz on 7/22/14.
//  Copyright (c) 2014 SPENCER. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NCUMainTableCellView : NSTableCellView

@property IBOutlet NSTextField *detailTextField;
@property IBOutlet NSImageView *disclosureArrowImageView;

@property (nonatomic) BOOL domainEnabled;
@property (nonatomic) BOOL showDisclosureArrow;

@end
