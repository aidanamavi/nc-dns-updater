//
//  NWLLogView.m
//  NWLogging
//
//  Copyright (c) 2012 noodlewerk. All rights reserved.
//

#import "NWLLogView.h"
#import "NWLTools.h"

@implementation NWLLogView {
    NSMutableString *_buffer;
    BOOL _waitingToPrint;
    dispatch_queue_t _serial;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup
{
    if (!_serial) {
        _serial = dispatch_queue_create("NWLLogViewController-append", DISPATCH_QUEUE_SERIAL);
        _maxLogSize = 100 * 1000; // 100 KB
        _buffer = [[NSMutableString alloc] init];

#if TARGET_OS_IPHONE
        self.backgroundColor = UIColor.blackColor;
        self.textColor = UIColor.whiteColor;
        self.font = [UIFont fontWithName:@"CourierNewPS-BoldMT" size:10];
        self.autocapitalizationType = UITextAutocapitalizationTypeNone;
        self.autocorrectionType = UITextAutocorrectionTypeNo;
        self.text = @"\n";
        if ([self respondsToSelector:@selector(setSpellCheckingType:)]) self.spellCheckingType = UITextSpellCheckingTypeNo;
#else // TARGET_OS_IPHONE
        self.backgroundColor = NSColor.blackColor;
        self.textColor = NSColor.whiteColor;
        self.font = [NSFont fontWithName:@"Courier" size:10];
#endif // TARGET_OS_IPHONE
        self.editable = NO;
    }
}


#pragma mark - Printing

- (void)printWithTag:(NSString *)tag lib:(NSString *)lib file:(NSString *)file line:(NSUInteger)line function:(NSString *)function date:(NSDate *)date message:(NSString *)message
{
    NSString *text = [NWLTools formatTag:tag lib:lib file:file line:line function:function date:date message:message];
    [self safeAppendAndFollowText:text];
}

- (NSString *)printerName
{
    return @"log-view";
}


#pragma mark - Appending

- (void)safeAppendAndFollowText:(NSString *)text
{
    dispatch_async(_serial, ^{
        if (_waitingToPrint) {
            [_buffer appendString:text];
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self appendAndFollowText:text];
            });
            _waitingToPrint = YES;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, .2 * NSEC_PER_SEC), _serial, ^(void){
                NSString *b = _buffer;
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self appendAndFollowText:b];
                });
                _buffer = [[NSMutableString alloc] init];
                _waitingToPrint = NO;
            });
        }
    });
}

- (void)appendAndScrollText:(NSString *)text
{
    [self append:text];
    [self scrollDown];
}

- (void)appendAndFollowText:(NSString *)text
{
    BOOL follow = [self isScrollAtEnd];
    [self append:text];
    if (follow) {
        if ([self respondsToSelector:@selector(textStorage)]) {
            [self scrollDownNow];
        } else {
            [self scrollDown];
        }
    }
}

- (void)append:(NSString *)string
{
#if TARGET_OS_IPHONE
    NSMutableString *text = [self respondsToSelector:@selector(textStorage)] ? self.textStorage.mutableString : self.text.mutableCopy;
#else // TARGET_OS_IPHONE
    NSMutableString *text = self.string.mutableCopy;
#endif // TARGET_OS_IPHONE
    if (string) {
        [text appendString:string];
        if (_maxLogSize && text.length > _maxLogSize) {
            NSUInteger index = text.length - _maxLogSize;
            NSRange r = [text rangeOfCharacterFromSet:NSCharacterSet.newlineCharacterSet options:0 range:NSMakeRange(index, _maxLogSize)];
            if (r.length) {
                index = r.location;
            }
            [text replaceCharactersInRange:NSMakeRange(0, index) withString:@"..."];
        }
    }
#if TARGET_OS_IPHONE
    if (![self respondsToSelector:@selector(textStorage)]) {
        self.text = text;
    }
#else // TARGET_OS_IPHONE
    self.string = text;
#endif // TARGET_OS_IPHONE
}


#pragma mark - Scrolling

- (void)scrollDown
{
    [self performSelector:@selector(scrollDownNow) withObject:nil afterDelay:.1];
}

- (void)scrollDownNow
{
#if TARGET_OS_IPHONE
    if (self.text.length) {
        NSRange bottom = NSMakeRange(self.text.length - 1, 1);
        [self scrollRangeToVisible:bottom];
    }
#else // TARGET_OS_IPHONE
    [self scrollToEndOfDocument:nil];
#endif // TARGET_OS_IPHONE
}

- (BOOL)isScrollAtEnd
{
#if TARGET_OS_IPHONE
    NSUInteger offset = self.contentOffset.y + self.bounds.size.height;
    NSUInteger size = self.contentSize.height;
    BOOL result = offset >= size - 50;
    return result;
#else // TARGET_OS_IPHONE
    return YES;
#endif // TARGET_OS_IPHONE
}

@end
