//
//  FastStubInspector.h
//  FastStub
//
//  Created by gao feng on 16/5/16.
//  Copyright © 2016年 music4kid. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FastStubInspector : NSObject

+ (instancetype)sharedInstance;

- (void)updateHeader:(NSString *)headerPath;
- (void)updateProject:(NSString *)projectPath completeBlock:(dispatch_block_t)completeBlock;

- (void)loadCustomElement;

@end
