//
//  NWLMultiLogger.m
//  NWLogging
//
//  Copyright (c) 2012 noodlewerk. All rights reserved.
//

#import "NWLMultiLogger.h"
#import "NWLCore.h"
#import "NWLPrinter.h"
#import "NWLTools.h"


@interface NWLPrinterEntry : NSObject
@property (nonatomic, strong) id<NWLPrinter> printer;
@property (nonatomic, readonly) char *copy;
@property (nonatomic, readonly) id key;
- (instancetype)initWithPrinter:(id<NWLPrinter>)printer;
+ (NSString *)keyWithPrinter:(id<NWLPrinter>)printer;
@end


@implementation NWLMultiLogger {
    NSMutableDictionary *_printerEntries;
    dispatch_queue_t _serial;
}


#pragma mark - Object life cycle

- (instancetype)init
{
    return nil;
}

- (instancetype)initPrivate
{
    self = [super init];
    if (self) {
        _serial = dispatch_queue_create("NWLMultiLogger", DISPATCH_QUEUE_SERIAL);
        _printerEntries = [[NSMutableDictionary alloc] init];
    }
    return self;
}

static NWLMultiLogger *NWLMultiLoggerShared = nil;
+ (NWLMultiLogger *)shared
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NWLMultiLoggerShared = [[NWLMultiLogger alloc] initPrivate];
    });
    return NWLMultiLoggerShared;
}


#pragma mark - Configuration

- (void)addPrinter:(id<NWLPrinter>)printer
{
    if (printer) {
        dispatch_sync(_serial, ^{
            [self unsafeRemovePrinter:printer];
            NWLPrinterEntry *entry = [[NWLPrinterEntry alloc] initWithPrinter:printer];
            NSString *key = entry.key;
            [_printerEntries setObject:entry forKey:key];
            NWLAddPrinter(entry.copy, NWLMultiLoggerPrinter, (__bridge void *)key);
        });
    }
}

- (void)unsafeRemovePrinter:(id<NWLPrinter>)printer
{
    NSString *key = [NWLPrinterEntry keyWithPrinter:printer];
    NWLPrinterEntry *entry = [_printerEntries objectForKey:key];
    if (entry) {
        NWLRemovePrinter(entry.copy);
        [_printerEntries removeObjectForKey:key];
    }
}


- (void)removePrinter:(id<NWLPrinter>)printer
{
    if (printer) {
        dispatch_sync(_serial, ^{
            [self unsafeRemovePrinter:printer];
        });
    }
}

- (void)removeAllPrinters
{
    dispatch_sync(_serial, ^{
        NSArray *printers = [_printerEntries.allValues valueForKey:@"printer"];
        for (id<NWLPrinter> printer in printers) {
            [self unsafeRemovePrinter:printer];
        }
    });
}

- (NSUInteger)count
{
    __block NSUInteger result = 0;
    dispatch_sync(_serial, ^{
        result = _printerEntries.count;
    });
    return result;
}


#pragma mark - Printing

- (void)printWithTag:(NSString *)tag lib:(NSString *)lib file:(NSString *)file line:(NSUInteger)line function:(NSString *)function date:(NSDate *)date message:(NSString *)message name:(NSString *)name
{
    dispatch_async(_serial, ^{
        if (name) {
            id<NWLPrinter> printer = [(NWLPrinterEntry *)[_printerEntries objectForKey:name] printer];
            [printer printWithTag:tag lib:lib file:file line:line function:function date:date message:message];
        }
    });
}

- (NSString *)printerName
{
    return @"multi-logger";
}


static void NWLMultiLoggerPrinter(NWLContext context, CFStringRef message, void *info) {
    NSString *tagString = context.tag ? [NSString stringWithCString:context.tag encoding:NSUTF8StringEncoding] : nil;
    NSString *libString = context.lib ? [NSString stringWithCString:context.lib encoding:NSUTF8StringEncoding] : nil;
    NSString *fileString = context.file ? [NSString stringWithCString:context.file encoding:NSUTF8StringEncoding] : nil;
    NSString *functionString = context.function ? [NSString stringWithCString:context.function encoding:NSUTF8StringEncoding] : nil;
    NSDate *date = context.time ? [NSDate dateWithTimeIntervalSince1970:context.time] : nil;
    NSString *messageString = (__bridge NSString *)message;
    NSString *name = (__bridge NSString *)info;
    [NWLMultiLoggerShared printWithTag:tagString lib:libString file:fileString line:context.line function:functionString date:date message:messageString name:name];
}


@end



@implementation NWLPrinterEntry

- (instancetype)initWithPrinter:(id<NWLPrinter>)printer
{
    self = [super init];
    if (self) {
        NSString *key = [self.class keyWithPrinter:printer];
        const char *utf8 = key.UTF8String;
        size_t length = strlen(utf8) + 1;
        char *copy = calloc(length, sizeof(char));
        memcpy(copy, utf8, length);
        _printer = printer;
        _key = key;
        _copy = copy;
    }
    return self;
}

- (void)dealloc
{
    if (_copy) {
        free(_copy); _copy = NULL;
    }
}

+ (NSString *)keyWithPrinter:(id<NWLPrinter>)printer
{
    if (printer) {
        NSString *name = nil;
        if ([printer respondsToSelector:@selector(name)]) {
            name = [NWLTools nameForPrinter:printer];
        } else {
            name = NSStringFromClass(printer.class);
        }
        NSString *result = [NSString stringWithFormat:@"multi-logger>%@", name];
        return result;
    }
    return nil;
}

@end
