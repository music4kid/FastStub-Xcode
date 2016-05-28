//
//  FSPopTableView.h
//  FastStub
//
//  Created by gao feng on 16/5/27.
//  Copyright © 2016年 music4kid. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import "FSPopTableViewTable.h"

@interface FSPopTableView : NSView

@property (nonatomic, strong) IBOutlet FSPopTableViewTable*                 tableView;

@end
