//
//  FSElementPool.h
//  FastStub
//
//  Created by gao feng on 16/5/17.
//  Copyright © 2016年 music4kid. All rights reserved.
//

#import <Foundation/Foundation.h>

#define _Pool [FSElementPool sharedInstance]

@class FSElementCache;

@interface FSElementPool : NSObject

+ (instancetype)sharedInstance;

@property (nonatomic, strong) NSMutableDictionary*                  elementMap;

- (void)parseElementFromProjectFile:(NSString*)filePath complete:(dispatch_block_t)completeBlock;
- (void)parseHeaderFile:(NSString*)filePath;

- (FSElementCache*)getElementFromCache:(NSString*)elementName;

@end
