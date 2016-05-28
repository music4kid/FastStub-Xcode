//
//  FSPopTableViewTable.h
//  FastStub
//
//  Created by gao feng on 16/5/27.
//  Copyright © 2016年 music4kid. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol FSPopTableViewTableDelegate <NSObject>

- (void)onEnterKeyClicked;

@end

@interface FSPopTableViewTable : NSTableView
@property (nonatomic, weak) id<FSPopTableViewTableDelegate>                 keyDelegate;

@end
