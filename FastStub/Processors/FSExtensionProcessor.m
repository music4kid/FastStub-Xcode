//
//  FSExtensionProcessor.m
//  FastStub
//
//  Created by gao feng on 16/5/18.
//  Copyright © 2016年 music4kid. All rights reserved.
//

#import "FSExtensionProcessor.h"

@implementation FSExtensionProcessor

- (NSString *)pattern {
    return @"(@interface)\\s+([a-z][a-z0-9_\\s*]+)(.*?)(@end+?)";
}

- (FSElementCacheType)getElementType
{
    return FSElementCacheExtension;
}

@end
