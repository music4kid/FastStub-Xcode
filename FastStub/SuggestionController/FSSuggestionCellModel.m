//
//  FSSuggestionCellModel.m
//  FastStub
//
//  Created by gao feng on 16/5/17.
//  Copyright © 2016年 music4kid. All rights reserved.
//

#import "FSSuggestionCellModel.h"

@implementation FSSuggestionCellModel
- (instancetype)init
{
    self = [super init];
    if (self) {
        self.stubs = @[].mutableCopy;
    }
    return self;
}
@end

@implementation FSSuggestionStub

@end