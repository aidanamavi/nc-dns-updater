//
//  NWLMultiLogger.h
//  NWLogging
//
//  Copyright (c) 2012 noodlewerk. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol NWLPrinter;

@interface NWLMultiLogger : NSObject

@property (nonatomic, readonly) NSUInteger count;

- (void)addPrinter:(id<NWLPrinter>)printer;
- (void)removePrinter:(id<NWLPrinter>)printer;
- (void)removeAllPrinters;

+ (NWLMultiLogger *)shared;

@end
