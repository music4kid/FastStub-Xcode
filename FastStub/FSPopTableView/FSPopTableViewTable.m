//
//  FSPopTableViewTable.m
//  FastStub
//
//  Created by gao feng on 16/5/27.
//  Copyright © 2016年 music4kid. All rights reserved.
//

#import "FSPopTableViewTable.h"

@implementation FSPopTableViewTable

- (void)keyDown:(NSEvent *)event
{
    unichar u = [[event charactersIgnoringModifiers] characterAtIndex:0];
    
    if (u == 13 || u == 3)
    {
        if (_keyDelegate != nil) {
            [_keyDelegate onEnterKeyClicked];
        }
    }
    else
    {
        [super keyDown:event];  // all other keys
    }
}


@end
