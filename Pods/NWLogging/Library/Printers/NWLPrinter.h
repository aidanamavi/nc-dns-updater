//
//  NWLPrinter.h
//  NWLogging
//
//  Copyright (c) 2012 noodlewerk. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol NWLPrinter <NSObject>

@required
- (void)printWithTag:(NSString *)tag lib:(NSString *)lib file:(NSString *)file line:(NSUInteger)line function:(NSString *)function date:(NSDate *)date message:(NSString *)message;

@optional
- (NSString *)printerName;

@end
