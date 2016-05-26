//
//  FSSuggestionStubController.h
//  FastStub
//
//  Created by gao feng on 16/5/18.
//  Copyright © 2016年 music4kid. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import <AppKit/AppKit.h>

@protocol FSSuggestionStubControllerDelegate <NSObject>

- (void)onStubItemSelected:(NSArray*)items;

@end

@interface FSSuggestionStubController : NSViewController <NSPopoverDelegate>

+ (instancetype)sharedInstance;

@property (nonatomic, weak) id<FSSuggestionStubControllerDelegate>                 delegate;

- (void)configWithContentView:(NSView*)view withItems:(NSArray*)items; 

@end
