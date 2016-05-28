//
//  FSIDESourceEditor.h
//  FastStub
//
//  Created by gao feng on 16/5/16.
//  Copyright © 2016年 music4kid. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import "FSElementPool.h"
#import "FSElementCache.h"

@interface FSIDESourceEditor : NSObject

- (void)showAboveCaret:(NSString *)text color:(NSColor *)color;

- (FSElementCache*)getCurrentElement;
- (FSElementCache*)getCurrentElementHeader;

- (void)insertText:(NSString*)text;
- (void)insertText:(NSString*)text withRange:(NSRange)range;
- (void)insertText:(NSString*)text withRange:(NSRange)range withFilePath:(NSString*)filePath;

- (void)setSelectedRange:(NSRange)range;
- (void)offsetSelectedRange:(int)offset;
- (void)insertMethodImp:(NSString*)method;
- (void)saveCodeChanges;

- (NSView *)view;

@end
