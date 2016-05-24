//
//  FastStub.h
//  FastStub
//
//  Created by gao feng on 16/5/7.
//  Copyright © 2016年 music4kid. All rights reserved.
//

#import <AppKit/AppKit.h>

@class FastStub;

static FastStub *sharedPlugin;

@interface FastStub : NSObject

+ (instancetype)sharedPlugin;
- (id)initWithBundle:(NSBundle *)plugin;

@property (nonatomic, strong, readonly) NSBundle* bundle;
@end