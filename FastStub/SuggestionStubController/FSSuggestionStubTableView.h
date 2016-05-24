//
//  FSSuggestionStubTableView.h
//  FastStub
//
//  Created by gao feng on 16/5/20.
//  Copyright © 2016年 music4kid. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol FSSuggestionStubTableViewDelegate <NSObject>

- (void)onKeyEvent:(NSEvent *)theEvent;

@end

@interface FSSuggestionStubTableView : NSTableView

@property (nonatomic, strong) id<FSSuggestionStubTableViewDelegate>                 suggestionDelegate;


@end
