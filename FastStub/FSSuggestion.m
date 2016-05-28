//
//  FSSuggestion.m
//  FastStub
//
//  Created by gao feng on 16/5/16.
//  Copyright © 2016年 music4kid. All rights reserved.
//

#import "FSSuggestion.h"
#import <Cocoa/Cocoa.h>
#import <AppKit/AppKit.h>

@interface FSSuggestion () <NSTableViewDelegate>
@property (nonatomic, strong) NSDictionary*              generalStubMap;
@end

@implementation FSSuggestion

- (instancetype)init
{
    self = [super init];
    if (self) {
        
    }
    return self;
}

- (NSDictionary*)getGeneralStubs
{
    if (self.generalStubMap == nil) {
        self.generalStubMap = @{@(GeneralStubSingleton):@"singleton",
                                @(GeneralStubExtension):@"interface-extension",
                                @(GeneralStubInitWith):@"initWith",
                                @(GeneralStubGetterSetter):@"getter-setter"};
    }
    return _generalStubMap;
}

@end
