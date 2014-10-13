//
//  NWLLineLogger.m
//  NWLogging
//
//  Copyright (c) 2012 noodlewerk. All rights reserved.
//

#import "NWLLineLogger.h"
#import "NWLogging.h"


const char *NWLLineLoggerMessage = NULL;
const char *NWLLineLoggerAscii = NULL;


@interface NWLLogLine : NSObject
@property (nonatomic, strong) NSString *tag;
@property (nonatomic, strong) NSString *lib;
@property (nonatomic, strong) NSString *file;
@property (nonatomic, assign) NSUInteger line;
@property (nonatomic, strong) NSString *function;
@property (nonatomic, strong) NSDate *date;
@property (nonatomic, strong) NSString *message;
@property (nonatomic, assign) NSUInteger info;
@property (nonatomic, strong) NSString *ascii;
@end

@implementation NWLLogLine
@end



@interface NWLLineLogger ()
+ (NWLLogLine *)data;
@end

@implementation NWLLineLogger

- (instancetype)init
{
    return nil;
}

+ (NWLLogLine *)data
{
    static NWLLogLine *result = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        result = [[NWLLogLine alloc] init];
    });
    return result;
}

+ (void)start
{
    [self start:0];
}

+ (void)start:(NSUInteger)info
{
    NWLAddPrinter("line-logger", NWLLineLoggerPrinter, (void *)info);
}

+ (void)stop
{
    NWLRemovePrinter("line-logger");
}

+ (NSString *)tag
{
    return self.data.tag;
}

+ (NSString *)lib
{
    return self.data.lib;
}

+ (NSString *)file
{
    return self.data.file;
}

+ (NSUInteger)line
{
    return self.data.line;
}

+ (NSString *)function
{
    return self.data.function;
}

+ (NSDate *)date
{
    return self.data.date;
}

+ (NSString *)message
{
    return self.data.message;
}

+ (NSString *)ascii
{
    return self.data.ascii;
}

+ (NSUInteger)info
{
    return self.data.info;
}

+ (NSString *)ascii:(NSString *)s
{
    NSData *data = [s dataUsingEncoding:NSNonLossyASCIIStringEncoding];
    NSString *result = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    result = [result stringByReplacingOccurrencesOfString:@"\\u" withString:@"U"];
    result = [result stringByReplacingOccurrencesOfString:@"\\" withString:@"U"];
    return result;
}

static void NWLLineLoggerPrinter(NWLContext context, CFStringRef message, void *info) {
    NWLLogLine *data = NWLLineLogger.data;
    data.tag = context.tag ? [NSString stringWithCString:context.tag encoding:NSUTF8StringEncoding] : nil;
    data.lib = context.lib ? [NSString stringWithCString:context.lib encoding:NSUTF8StringEncoding] : nil;
    data.file = context.file ? [NSString stringWithCString:context.file encoding:NSUTF8StringEncoding] : nil;
    data.line = context.line;
    data.function = context.function ? [NSString stringWithCString:context.function encoding:NSUTF8StringEncoding] : nil;
    data.date = context.time ? [NSDate dateWithTimeIntervalSince1970:context.time] : nil;
    data.info = (NSUInteger)info;

    NSString *m = (__bridge NSString *)message;
    NSString *a = [NWLLineLogger ascii:m];
    NWLLineLoggerMessage = m.UTF8String;
    NWLLineLoggerAscii = a.UTF8String;
    data.message = m;
    data.ascii = a;
}

@end

