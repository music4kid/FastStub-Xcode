//
//  FSSuggestionView.h
//  FastStub
//
//  Created by gao feng on 16/5/17.
//  Copyright © 2016年 music4kid. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface FSSuggestionView : NSView

@property (nonatomic, strong) IBOutlet NSTableView*                 tableView;
@property (nonatomic, strong) IBOutlet NSTextField*                 searchField;


@end
