//
//  FSElementCache.h
//  FastStub
//
//  Created by gao feng on 16/5/16.
//  Copyright © 2016年 music4kid. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum : NSUInteger {
    FSElementCacheInterface,
    FSElementCacheProtocol,
    FSElementCacheImp,
    FSElementCacheExtension,
    FSElementCacheCategory,
} FSElementCacheType;

@interface FSElementCache : NSObject
@property (nonatomic, strong) NSString*                         filePath;
@property (nonatomic, strong) NSString*                         elementName;
@property (nonatomic, strong) NSMutableSet*                     methodList;
@property (nonatomic, strong) NSMutableSet*                     propertyList;
@property (nonatomic, assign) FSElementCacheType                elementType;
@property (nonatomic, assign) NSRange                           contentRange;
@property (nonatomic, assign) NSRange                           contentBeginRange;
@property (nonatomic, assign) NSRange                           elementBeginRange;

@property (nonatomic, strong) NSMutableSet*                     superClasses;
@property (nonatomic, strong) NSMutableSet*                     protocols;

@end