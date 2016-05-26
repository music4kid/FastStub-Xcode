//
//  FSSuggestionCellModel.h
//  FastStub
//
//  Created by gao feng on 16/5/17.
//  Copyright © 2016年 music4kid. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum : NSUInteger {
    FSSuggestionCellTitleHeader = 0,
    FSSuggestionCellTitleSuperClass,
    FSSuggestionCellTitleProtocol,
    FSSuggestionCellMethod,
    FSSuggestionCellGeneralStub
} FSSuggestionCellType;

@interface FSSuggestionCellModel : NSObject

@property (nonatomic, strong) NSString*                             cellText;
@property (nonatomic, assign) FSSuggestionCellType                  cellType;
@property (nonatomic, strong) NSMutableArray*                       stubs;


@end


@interface FSSuggestionStub : NSObject
@property (nonatomic, strong) NSNumber*                 stubKey;
@property (nonatomic, strong) NSString*                 cellText;
@end