//
//  FSElementProcessor.h
//  FastStub
//
//  Created by gao feng on 16/5/16.
//  Copyright © 2016年 music4kid. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FSElementCache.h"

typedef void (^processorResultBlock)(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop);

@interface FSElementProcessor : NSObject

// must override by subclass
- (NSString *)pattern;
- (FSElementCacheType)getElementType;

// must override by subclass
- (NSArray *)createElements:(NSString *)content;

- (NSMutableSet*)buildMethodList:(NSString*)content;

- (void)processContent:(NSString *)content resultBlock:(processorResultBlock)resultBlock;

- (void)processContent:(NSString *)content withPatternStr:(NSString*)pattern resultBlock:(processorResultBlock)resultBlock;

@end