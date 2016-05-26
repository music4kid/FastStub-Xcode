//
//  FSSuggestionController.h
//  FastStub
//
//  Created by gao feng on 16/5/17.
//  Copyright © 2016年 music4kid. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import <AppKit/AppKit.h>

typedef enum : NSUInteger {
    SuggestionControllerRoot,
    SuggestionControllerGeneral,
} SuggestionControllerType;

@protocol FSSuggestionControllerDelegate <NSObject>

- (void)onItemSelected:(NSArray*)items;

@end

@interface FSSuggestionController : NSViewController

+ (instancetype)sharedInstance;

@property (nonatomic, weak) id<FSSuggestionControllerDelegate>                 delegate;
@property (nonatomic, assign) SuggestionControllerType                         ctype;


- (void)showSuggestionsInView:(NSView*)view withItems:(NSArray*)items;

@end
