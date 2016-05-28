//
//  FSPopTableViewController.h
//  FastStub
//
//  Created by gao feng on 16/5/27.
//  Copyright © 2016年 music4kid. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import <AppKit/AppKit.h>

@protocol FSPopTableViewControllerDelegate

- (void)onPopTableViewItemsSelected:(NSArray*)items;

@end

@interface FSPopTableViewController : NSViewController 

+ (instancetype)showPopWithinView:(NSView*)view withItems:(NSArray*)items;

@property (nonatomic, weak) id<FSPopTableViewControllerDelegate>                 delegate;

@end
