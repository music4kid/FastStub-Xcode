//
//  FSElementCache.m
//  FastStub
//
//  Created by gao feng on 16/5/16.
//  Copyright © 2016年 music4kid. All rights reserved.
//

#import "FSElementCache.h"

@implementation FSElementCache
- (instancetype)init
{
    self = [super init];
    if (self) {
        self.superClasses = [NSMutableSet new];
        self.protocols = [NSMutableSet new];
    }
    return self;
}
@end