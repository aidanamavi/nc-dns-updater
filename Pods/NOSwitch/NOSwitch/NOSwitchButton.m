//
//  NOMTSwitchButton.m
//  NOMenuTimer
//
//  Created by Yuriy Panfyorov on 25/03/14.
//  Copyright (c) 2014 Yuriy Panfyorov. All rights reserved.
//

#import "NOSwitchButton.h"

#import <objc/runtime.h>

#import "NOSwitchButtonCell.h"

@implementation NOSwitchButton

+ (Class)cellClass {
    return [NOSwitchButtonCell class];
}

- (id)init {
    self = [super init];
    if (self) {
        [self initProperties];
    }
    return self;
}

// thanks to Mike Ash
// https://www.mikeash.com/pyblog/custom-nscells-done-right.html
- (id)initWithCoder:(NSCoder *)aDecoder {
    BOOL sub = YES;
    
    sub = sub && [aDecoder isKindOfClass: [NSKeyedUnarchiver class]]; // no support for 10.1 nibs
    sub = sub && ![self isMemberOfClass: [NSControl class]]; // no raw NSControls
    sub = sub && [[self superclass] cellClass] != nil; // need to have something to substitute
    sub = sub && [[self superclass] cellClass] != [[self class] cellClass]; // pointless if same

    if (!sub) {
        self = [super initWithCoder:aDecoder];
    } else {
        NSKeyedUnarchiver *coder = (id)aDecoder;
		
		// gather info about the superclass's cell and save the archiver's old mapping
		Class superCell = [[self superclass] cellClass];
		NSString *oldClassName = NSStringFromClass( superCell );
		Class oldClass = [coder classForClassName: oldClassName];
		if( !oldClass )
			oldClass = superCell;
		
		// override what comes out of the unarchiver
		[coder setClass: [[self class] cellClass] forClassName: oldClassName];
		
		// unarchive
		self = [super initWithCoder: coder];
		
		// set it back
		[coder setClass: oldClass forClassName: oldClassName];
    }
    if (self) {
        
        [self initProperties];
    }
    return self;
}

- (id)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (self) {
        [self initProperties];
    }
    return self;
}

- (void)initProperties {
    // default color
    self.tintColor = [NSColor colorWithCalibratedRed:76./255. green:217./255. blue:100./255. alpha:1.];
}

- (void)awakeFromNib {
    [[self class] setCellClass:[NOSwitchButtonCell class]];
}

- (BOOL)allowsMixedState {
    return NO;
}

- (void)setAllowsMixedState:(BOOL)flag {
    if (flag) {
        NSLog(@"NOMTSwitchButton does not support mixed state.");
    }
    [super setAllowsMixedState:NO];
}

- (void)setTintColor:(NSColor *)tintColor {
    if ([self.tintColor isEqualTo:tintColor])
        return;
    
    _tintColor = tintColor;
    
    if (self.cell && [self.cell isKindOfClass:[NOSwitchButtonCell class]]) {
        NOSwitchButtonCell *cell = self.cell;
        cell.tintColor = _tintColor;
    }
}

@end
