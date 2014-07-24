//
//  NCUOnlyIntegerValueFormatter.m
//  NC DNS Updater
//
//  Created by Spencer Müller Diniz on 7/24/14.
//  Copyright (c) 2014 SPENCER. All rights reserved.
//

#import "NCUOnlyIntegerValueFormatter.h"

@implementation NCUOnlyIntegerValueFormatter

- (BOOL)isPartialStringValid:(NSString*)partialString newEditingString:(NSString**)newString errorDescription:(NSString**)error
{
    if([partialString length] == 0) {
        return YES;
    }
    
    NSScanner* scanner = [NSScanner scannerWithString:partialString];
    
    if(!([scanner scanInt:0] && [scanner isAtEnd])) {
        NSBeep();
        return NO;
    }
    
    return YES;
}

@end
