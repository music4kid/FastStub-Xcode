//
//  NSObject_Extension.m
//  FastStub
//
//  Created by gao feng on 16/5/7.
//  Copyright © 2016年 music4kid. All rights reserved.
//


#import "NSObject_Extension.h"
#import "FastStub.h"

@implementation NSObject (Xcode_Plugin_Template_Extension)

+ (void)pluginDidLoad:(NSBundle *)plugin
{
    static dispatch_once_t onceToken;
    NSString *currentApplicationName = [[NSBundle mainBundle] infoDictionary][@"CFBundleName"];
    if ([currentApplicationName isEqual:@"Xcode"]) {
        dispatch_once(&onceToken, ^{
            sharedPlugin = [[FastStub alloc] initWithBundle:plugin];
        });
    }
}
@end
