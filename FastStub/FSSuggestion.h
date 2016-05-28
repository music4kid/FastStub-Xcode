//
//  FSSuggestion.h
//  FastStub
//
//  Created by gao feng on 16/5/16.
//  Copyright © 2016年 music4kid. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum : NSUInteger {
    FSSuggestionProtocol,
    FSSuggestionSuperClass,
    FSSuggestionHeader,
    FSSuggestionGeneral,
    FSSuggestionGeneralStub,
} FSSuggestionType;

typedef enum : NSUInteger {
    GeneralStubSingleton = 0,
    GeneralStubExtension,
    GeneralStubInitWith,
    GeneralStubGetterSetter,
    GeneralStubCount
} GeneralStubType;

@interface FSSuggestion : NSObject

@property (nonatomic, strong) NSString*                         title;
@property (nonatomic, strong) NSMutableSet*                     methodList;
@property (nonatomic, assign) FSSuggestionType                  stype;

- (NSDictionary*)getGeneralStubs;

@end
