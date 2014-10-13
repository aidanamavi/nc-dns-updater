//
//  NWLFilePrinter.m
//  NWLogging
//
//  Copyright (c) 2012 noodlewerk. All rights reserved.
//

#import "NWLFilePrinter.h"
#import "NWLogging.h"
#import "NWLTools.h"


@implementation NWLFilePrinter {
    NSFileHandle *_handle;
    dispatch_queue_t _serial;
    unsigned long long _size;
}

#pragma mark - Object life cycle

- (instancetype)init
{
    self = [super init];
    if (self) {
        _maxLogSize = 100 * 1000; // 100 KB
        _serial = dispatch_queue_create("NWLFilePrinter", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (instancetype)initForTesting
{
    self = [self init];
    _serial = nil;
    return self;
}

- (instancetype)initAndOpenName:(NSString *)name
{
    self = [self init];
    NSString *path = [self.class pathForName:name];
    [self unsafeOpenPath:path];
    return self;
}

- (instancetype)initAndOpenPath:(NSString *)path
{
    self = [self init];
    [self unsafeOpenPath:path];
    return self;
}


#pragma mark - Helpers

+ (NSString *)pathForName:(NSString *)name
{
    NSString *result = nil;
    NSArray *cachePaths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    if (cachePaths.count) {
        NSString *file = [NSString stringWithFormat:@"%@.log", name];
        result = [[cachePaths objectAtIndex:0] stringByAppendingPathComponent:file];
    }
    return result;
}

+ (NSFileHandle *)handleForPath:(NSString *)path
{
    NSFileHandle *result = [NSFileHandle fileHandleForWritingAtPath:path];
    if (!result) {
        [[NSData data] writeToFile:path atomically:NO];
        result = [NSFileHandle fileHandleForWritingAtPath:path];
    }
    return result;
}

+ (NSData *)utf8SubdataFromIndex:(NSUInteger)index data:(NSData *)data
{
    if (index < data.length) {
        NSUInteger length = data.length < index + 6 ? data.length - index : 6;
        unsigned char buffer[6] = {0, 0, 0, 0, 0, 0};
        [data getBytes:buffer range:NSMakeRange(index, length)];
        for (NSUInteger i = 0; i < length; i++) {
            BOOL isBeginUTF8Char = (buffer[i] & 0xC0) != 0x80;
            if (isBeginUTF8Char) {
                NSRange range = NSMakeRange(index + i, data.length - index - i);
                NSData *result = [data subdataWithRange:range];
                return result;
            }
        }
        NSData *result = [data subdataWithRange:NSMakeRange(index, data.length - index)];
        return result;
    }
    return [NSData data];
}

- (void)trimForAppendingLength:(NSUInteger)length
{
    if (_maxLogSize && _size + length > _maxLogSize) {
        [_handle synchronizeFile];
        NSData *data = [NSData dataWithContentsOfFile:_path options:0 error:nil]; // no logging on purpose
        NSUInteger keep = _maxLogSize / 2 > length ? _maxLogSize / 2 : (_maxLogSize > length ? _maxLogSize - length : 0);
        NSUInteger index = data.length > keep ? data.length - keep : 0;
        if (index) {
            data = [self.class utf8SubdataFromIndex:index data:data];
        }
        [data writeToFile:_path atomically:NO];
        _handle = [NSFileHandle fileHandleForWritingAtPath:_path];
        _size = [_handle seekToEndOfFile];
    }
}


#pragma mark - Logging control

- (BOOL)openPath:(NSString *)path
{
    __block BOOL result = NO;
    void(^b)(void) = ^{
        result = [self unsafeOpenPath:path];
    };
    if (_serial) dispatch_sync(_serial, b); else b();
    return result;
}

- (BOOL)unsafeOpenPath:(NSString *)path
{
    _path = path;
    _handle = [self.class handleForPath:_path];
    _size = [_handle seekToEndOfFile];
    BOOL result = !!_handle;
    return result;
}

- (void)close
{
    void(^b)(void) = ^{
        [_handle synchronizeFile];
        _handle = nil;
        _path = nil;
        _size = 0;
    };
    if (_serial) dispatch_sync(_serial, b); else b();
}

- (void)sync
{
    void(^b)(void) = ^{
        [_handle synchronizeFile];
    };
    if (_serial) dispatch_sync(_serial, b); else b();
}

- (void)clear
{
    void(^b)(void) = ^{
        [[NSData data] writeToFile:_path atomically:NO];
        _handle = [NSFileHandle fileHandleForWritingAtPath:_path];
        _size = [_handle seekToEndOfFile];
    };
    if (_serial) dispatch_sync(_serial, b); else b();
}

- (NSString *)content
{
    __block NSString *result = nil;
    void(^b)(void) = ^{
        [_handle synchronizeFile];
        result = [NSString stringWithContentsOfFile:_path encoding:NSUTF8StringEncoding error:nil]; // no logging on purpose
    };
    if (_serial) dispatch_sync(_serial, b); else b();
    return result;
}

- (NSData *)contentData
{
    __block NSData *result = nil;
    void(^b)(void) = ^{
        [_handle synchronizeFile];
        result = [NSData dataWithContentsOfFile:_path];
    };
    if (_serial) dispatch_sync(_serial, b); else b();
    return result;
}

#pragma mark - Logging callbacks

- (void)printWithTag:(NSString *)tag lib:(NSString *)lib file:(NSString *)file line:(NSUInteger)line function:(NSString *)function date:(NSDate *)date message:(NSString *)message
{
    NSString *s = [NWLTools formatTag:tag lib:lib file:file line:line function:function date:date message:message];
    [self appendAsync:s];
}

- (NSString *)printerName
{
    return @"file-printer";
}

- (void)append:(NSString *)string
{
    void(^b)(void) = ^{
        NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
        [self unsafeAppend:data];
    };
    if (_serial) dispatch_sync(_serial, b); else b();
}

- (void)appendAsync:(NSString *)string
{
    void(^b)(void) = ^{
        NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
        [self unsafeAppend:data];
    };
    if (_serial) dispatch_async(_serial, b); else b();
}

- (void)appendData:(NSData *)data
{
    void(^b)(void) = ^{
        [self unsafeAppend:data];
    };
    if (_serial) dispatch_sync(_serial, b); else b();
}

- (void)appendDataAsync:(NSData *)data
{
    void(^b)(void) = ^{
        [self unsafeAppend:data];
    };
    if (_serial) dispatch_async(_serial, b); else b();
}

- (void)unsafeAppend:(NSData *)data
{
    [self trimForAppendingLength:data.length];
    NSUInteger remaining = (NSUInteger)(_maxLogSize > _size ? _maxLogSize - _size : 0);
    if (_maxLogSize && data.length > remaining) {
        data = [self.class utf8SubdataFromIndex:data.length - remaining data:data];
    }
    [_handle writeData:data];
    _size += data.length;
}

@end
