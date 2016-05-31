//
//  FSCategoryProcessor.m
//  FastStub
//
//  Created by gao feng on 16/5/31.
//  Copyright © 2016年 music4kid. All rights reserved.
//

#import "FSCategoryProcessor.h"

@implementation FSCategoryProcessor

- (NSString *)pattern {
    return @"(@interface)\\s+([a-z][a-z0-9_\\s*\()]+)\\s*\\(\\s*(?:[a-z][a-z0-9_\()]+)\\s*\\)(.*?)(@end+?)";
}

- (FSElementCacheType)getElementType
{
    return FSElementCacheCategory;
}


@end
