//
//  FSInterfaceProcessor.m
//  FastStub
//
//  Created by gao feng on 16/5/20.
//  Copyright © 2016年 music4kid. All rights reserved.
//

#import "FSInterfaceProcessor.h"
#import "FSElementPool.h"
#import "FSElementCache.h"

@implementation FSInterfaceProcessor


- (NSString *)pattern {
    return @"(@interface)\\s+([a-z][a-z0-9_\\s*\()]+)\\s+:?\\s+([a-z][a-z0-9_\()]+)(.*?)(@end+?)";
}

- (FSElementCacheType)getElementType
{
    return FSElementCacheInterface;
}




@end
