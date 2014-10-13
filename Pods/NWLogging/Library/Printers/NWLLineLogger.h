//
//  NWLLineLogger.h
//  NWLogging
//
//  Copyright (c) 2012 noodlewerk. All rights reserved.
//


extern const char *NWLLineLoggerMessage;
extern const char *NWLLineLoggerAscii;

#ifdef __OBJC__
#import <Foundation/Foundation.h>

@interface NWLLineLogger : NSObject

+ (void)start:(NSUInteger)info;
+ (void)start;
+ (void)stop;

+ (NSString *)tag;
+ (NSString *)lib;
+ (NSString *)file;
+ (NSUInteger)line;
+ (NSString *)function;
+ (NSDate *)date;
+ (NSString *)message;
+ (NSString *)ascii;
+ (NSUInteger)info;

@end

#endif // __OBJC__
