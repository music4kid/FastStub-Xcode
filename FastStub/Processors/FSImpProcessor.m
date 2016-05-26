//
//  FSImpProcessor.m
//  FastStub
//
//  Created by gao feng on 16/5/16.
//  Copyright © 2016年 music4kid. All rights reserved.
//

#import "FSImpProcessor.h"
#import "FSElementCache.h"

@implementation FSImpProcessor

- (NSString *)pattern {
    return @"(@implementation)\\s+([a-z][a-z0-9_\()]+)(.*?)(@end+?)";
}

- (FSElementCacheType)getElementType
{
    return FSElementCacheImp;
}

@end
