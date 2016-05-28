//
//  FSTableViewModel.h
//  FastStub
//
//  Created by gao feng on 16/5/27.
//  Copyright © 2016年 music4kid. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum : NSUInteger {
    FSTableViewModelTypePropertyInit,
    FSTableViewModelTypeGetterSetter,
} FSTableViewModelType;

@interface FSTableViewModel : NSObject

@property (nonatomic, assign) FSTableViewModelType                 type;
@property (nonatomic, strong) NSString*                            text;
@property (nonatomic, strong) id                                   customInfo;

@end
