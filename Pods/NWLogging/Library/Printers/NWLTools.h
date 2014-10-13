//
//  NWLTools.h
//  NWLogging
//
//  Copyright (c) 2012 noodlewerk. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol NWLPrinter;

@interface NWLTools : NSObject

+ (NSString *)dateMark;
+ (NSString *)bundleInfo;
+ (NSString *)formatTag:(NSString *)tag lib:(NSString *)lib file:(NSString *)file line:(NSUInteger)line function:(NSString *)function date:(NSDate *)date message:(NSString *)message;

+ (NSString *)nameForPrinter:(id<NWLPrinter>)printer;

@end
