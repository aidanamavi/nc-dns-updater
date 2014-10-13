//
//  NWLLogView.h
//  NWLogging
//
//  Copyright (c) 2012 noodlewerk. All rights reserved.
//

#import "NWLPrinter.h"
#include "TargetConditionals.h"

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#define NWLTextView UITextView
#else // TARGET_OS_IPHONE
#import <Cocoa/Cocoa.h>
#define NWLTextView NSTextView
#endif // TARGET_OS_IPHONE

@interface NWLLogView : NWLTextView <NWLPrinter>

@property (nonatomic, assign) NSUInteger maxLogSize;

- (void)appendAndFollowText:(NSString *)text;
- (void)appendAndScrollText:(NSString *)text;
- (void)safeAppendAndFollowText:(NSString *)text;

- (void)scrollDown;

@end
