//
//  NCUMainTableCellView.h
//  NC DNS Updater
//
//  Created by Spencer Müller Diniz on 7/22/14.
//  Copyright (c) 2014 SPENCER. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef NS_ENUM(NSInteger, NCUMainTableCellViewStatus) {
    NCUMainTableCellViewStatusDisabled = 0,
    NCUMainTableCellViewStatusUpdated = 1,
    NCUMainTableCellViewStatusOutdated = 2
};

@interface NCUMainTableCellView : NSTableCellView

@property IBOutlet NSTextField *detailTextField;
@property IBOutlet NSImageView *disclosureArrowImageView;

@property (nonatomic) NCUMainTableCellViewStatus status;
@property (nonatomic) BOOL showDisclosureArrow;

@end
