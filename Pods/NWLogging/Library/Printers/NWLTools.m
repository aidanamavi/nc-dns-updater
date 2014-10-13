//
//  NWLTools.m
//  NWLogging
//
//  Copyright (c) 2012 noodlewerk. All rights reserved.
//

#import "NWLTools.h"
#import "NWLPrinter.h"


@implementation NWLTools

+ (NSString *)dateMark
{
    NSString *result = [NSString stringWithFormat:@"==== %@ ====", NSDate.date];
    return result;
}

+ (NSString *)bundleInfo
{
    NSDictionary *info = NSBundle.mainBundle.infoDictionary;
    NSString *name = [info valueForKey:@"CFBundleName"];
    NSString *version = [info valueForKey:@"CFBundleShortVersionString"];
    NSString *build = [info valueForKey:@"CFBundleVersion"];
    NSString *identifier = [info valueForKey:@"CFBundleIdentifier"];
    NSString *result = [NSString stringWithFormat:@"%@ %@b%@ (%@)", name, version, build, identifier];
    return result;
}

+ (NSString *)formatTag:(NSString *)tag lib:(NSString *)lib file:(NSString *)file line:(NSUInteger)line function:(NSString *)function date:(NSDate *)date message:(NSString *)message
{
    static NSCalendar *calendar = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        calendar = NSCalendar.currentCalendar;
    });
    NSDateComponents *components = [calendar components:(NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit) fromDate:date];
    int hour = (int)[components hour];
    int minute = (int)[components minute];
    int second = (int)[components second];
    NSTimeInterval time = date.timeIntervalSince1970;
    int centi = (int)((time - floor(time)) * 100) % 100;
    NSString *result = nil;
    if (tag.length && ![tag isEqualToString:@"info"]) {
        result = [NSString stringWithFormat:@"[%02i:%02i:%02i.%02i] [%@] %@\n", hour, minute, second, centi, tag, message];
    } else {
        result = [NSString stringWithFormat:@"[%02i:%02i:%02i.%02i] %@\n", hour, minute, second, centi, message];
    }
    return result;
}

+ (NSString *)nameForPrinter:(id<NWLPrinter>)printer
{
    if ([printer respondsToSelector:@selector(printerName)]) {
        return [printer printerName];
    }
    return NSStringFromClass(printer.class);
}

@end
