//
//  NCUMainTableCellView.m
//  NC DNS Updater
//
//  Created by Spencer Müller Diniz on 7/22/14.
//  Copyright (c) 2014 SPENCER. All rights reserved.
//

#import "NCUMainTableCellView.h"

@implementation NCUMainTableCellView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

- (void)setStatus:(NCUMainTableCellViewStatus)status {
    _status = status;
    
    switch (status) {
        case NCUMainTableCellViewStatusDisabled:
            self.imageView.image = [NSImage imageNamed:NSImageNameStatusUnavailable];
            break;
        case NCUMainTableCellViewStatusUpdated:
            self.imageView.image = [NSImage imageNamed:NSImageNameStatusAvailable];
            break;
        case NCUMainTableCellViewStatusOutdated:
            self.imageView.image = [NSImage imageNamed:NSImageNameStatusPartiallyAvailable];
            break;
        default:
            self.imageView.image = [NSImage imageNamed:NSImageNameStatusNone];
            break;
            
    }
}

- (void)setShowDisclosureArrow:(BOOL)showDisclosureArrow {
    _showDisclosureArrow = showDisclosureArrow;
    
    [self.disclosureArrowImageView setHidden:!_showDisclosureArrow];
}

@end
