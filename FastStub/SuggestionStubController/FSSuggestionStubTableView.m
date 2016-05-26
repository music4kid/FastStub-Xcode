//
//  FSSuggestionStubTableView.m
//  FastStub
//
//  Created by gao feng on 16/5/20.
//  Copyright © 2016年 music4kid. All rights reserved.
//

#import "FSSuggestionStubTableView.h"
#import "FSConst.h"


@implementation FSSuggestionStubTableView

- (void)keyDown:(NSEvent *)theEvent
{
    if (self.suggestionDelegate != nil) {
        [self.suggestionDelegate onKeyEvent:theEvent];
    }
    
    if(theEvent.keyCode == 123)
    {
        [Notif postNotificationName:Notif_SuggestionStubHide object:nil];
    }
    [super keyDown:theEvent];
}

@end
