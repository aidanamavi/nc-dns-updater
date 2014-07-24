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

- (void)setDomainEnabled:(BOOL)domainEnabled {
    _domainEnabled = domainEnabled;
    
    if (_domainEnabled) {
        self.imageView.image = [NSImage imageNamed:NSImageNameStatusAvailable];
    }
    else {
        self.imageView.image = [NSImage imageNamed:NSImageNameStatusUnavailable];
    }    
}

- (void)setShowDisclosureArrow:(BOOL)showDisclosureArrow {
    NSLog(@"showDisclosureArrow: %hhd", showDisclosureArrow);
    
    _showDisclosureArrow = showDisclosureArrow;
    
    [self.disclosureArrowImageView setHidden:!_showDisclosureArrow];
}

@end
