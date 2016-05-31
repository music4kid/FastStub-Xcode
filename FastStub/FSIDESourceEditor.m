//
//  FSIDESourceEditor.m
//  FastStub
//
//  Created by gao feng on 16/5/16.
//  Copyright © 2016年 music4kid. All rights reserved.
//

#import "FSIDESourceEditor.h"
#import "MHXcodeDocumentNavigator.h"
#import "DVTSourceTextStorage+Operations.h"
#import "NSTextView+Operations.h"
#import "NSString+Extensions.h"
#import "FSImpProcessor.h"
#import "FSElementCache.h"
#import "FSExtensionProcessor.h"
#import "FSCategoryProcessor.h"

@implementation FSIDESourceEditor

- (DVTSourceTextStorage *)currentTextStorage {
    if (![[MHXcodeDocumentNavigator currentEditor] isKindOfClass:NSClassFromString(@"IDESourceCodeEditor")]) {
        return nil;
    }
    NSTextView *textView = [MHXcodeDocumentNavigator currentSourceCodeTextView];
    return (DVTSourceTextStorage*)textView.textStorage;
}


- (void)showAboveCaret:(NSString *)text color:(NSColor *)color {
    NSTextView *currentTextView = [MHXcodeDocumentNavigator currentSourceCodeTextView];
    
    NSRect keyRectOnTextView = [currentTextView mhFrameForCaret];
    
    NSTextField *field = [[NSTextField alloc] initWithFrame:CGRectMake(keyRectOnTextView.origin.x, keyRectOnTextView.origin.y, 0, 0)];
    [field setBackgroundColor:color];
    [field setFont:currentTextView.font];
    [field setTextColor:[NSColor colorWithCalibratedWhite:0.2 alpha:1.0]];
    [field setStringValue:text];
    [field sizeToFit];
    [field setBordered:NO];
    [field setEditable:NO];
    field.frame = CGRectOffset(field.frame, 0, - field.bounds.size.height - 3);
    [field setWantsLayer:YES];
    [field.layer setCornerRadius:5.0f];
    
    [currentTextView addSubview:field];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [NSAnimationContext beginGrouping];
        [[NSAnimationContext currentContext] setCompletionHandler:^{
            [field removeFromSuperview];
        }];
        [[NSAnimationContext currentContext] setDuration:1.0];
        [[field animator] setAlphaValue:0.0];
        [NSAnimationContext endGrouping];
    });
}

- (FSElementCache*)getCurrentElement
{
    FSElementCache* element = nil;
    
    NSString* currentFilePath = [MHXcodeDocumentNavigator currentFilePath];
    if ([currentFilePath containsString:@".m"] == false && [currentFilePath containsString:@".mm"] == false) {
        return nil;
    }
    NSError *error = nil;
    NSString *impContent = [MHXcodeDocumentNavigator currentSourceCodeTextView].string;
    if (error) {
        return NO;
    }
    
    NSTextView *textView = [MHXcodeDocumentNavigator currentSourceCodeTextView];
    NSRange curRange = textView.selectedRange;
    
    //parse .m file for implementation
    FSImpProcessor* p = [FSImpProcessor new];
    NSArray* elementsInFile = [p createElements:impContent];
    for (FSElementCache* e in elementsInFile) {
        if (NSLocationInRange(curRange.location, e.contentRange)) {
            //element match
            NSLog(@"get a match");
            element = e;
            break;
        }
    }
    
    
    if (element != nil) {
        //parse .m file for extension
        FSExtensionProcessor* cp = [FSExtensionProcessor new];
        NSArray* elements = [cp createElements:impContent];
        for (FSElementCache* e in elements) {
            if ([e.elementName isEqualToString:element.elementName]) {
                [element.protocols addObjectsFromArray:e.protocols.allObjects];
                break;
            }
        }
    }
   

    return element;
}

- (FSElementCache*)getCurrentElementHeader {
    FSElementCache* element = nil;
    
    NSString* currentFilePath = [MHXcodeDocumentNavigator currentFilePath];
    NSString* currentHeaderPath = nil;
    if ([currentFilePath rangeOfString:@".mm"].location != NSNotFound) {
        currentHeaderPath = [currentFilePath stringByReplacingOccurrencesOfString:@".mm" withString:@".h"];
    }
    else if ([currentFilePath rangeOfString:@".m"].location != NSNotFound) {
        currentHeaderPath = [currentFilePath stringByReplacingOccurrencesOfString:@".m" withString:@".h"];
    }
    if (currentHeaderPath.length == 0) {
        return nil;
    }
    
    NSError* error = nil;
    NSString* content = [NSString stringWithContentsOfFile:currentHeaderPath encoding:NSUTF8StringEncoding error:&error];
    if (error) {
        return NO;
    }
    
    FSElementCache* impElement = [self getCurrentElement];
    if (impElement == nil) {
        return nil;
    }
    
    //try interface
    FSInterfaceProcessor* p = [FSInterfaceProcessor new];
    NSArray* elementsInFile = [p createElements:content];
    for (FSElementCache* e in elementsInFile) {
        if ([e.elementName isEqualToString:impElement.elementName]) {
            element = e;
            break;
        }
    }
    
    if (element == nil) {
        //try category
        FSCategoryProcessor* p = [FSCategoryProcessor new];
        elementsInFile = [p createElements:content];
        for (FSElementCache* e in elementsInFile) {
            if ([e.elementName isEqualToString:impElement.elementName]) {
                element = e;
                break;
            }
        }
    }
    
 
    return element;
}



- (NSView *)view {
    return [MHXcodeDocumentNavigator currentSourceCodeTextView];
}

- (void)setSelectedRange:(NSRange)range
{
    NSTextView *textView = [MHXcodeDocumentNavigator currentSourceCodeTextView];
    [textView setSelectedRange:range];
}

- (void)offsetSelectedRange:(int)offset
{
    NSTextView *textView = [MHXcodeDocumentNavigator currentSourceCodeTextView];
    NSRange range = textView.selectedRange;
    range.location += offset;
    [textView setSelectedRange:range];
}

- (void)insertMethodImp:(NSString*)method
{
    NSString* methodImp = [NSString stringWithFormat:@"%@ {\n\t\n}\n\n", method];
    
    NSTextView *textView = [MHXcodeDocumentNavigator currentSourceCodeTextView];
    NSRange range = textView.selectedRange;
    
    [textView insertText:methodImp replacementRange:range];
}

- (void)insertText:(NSString*)text
{
    NSTextView *textView = [MHXcodeDocumentNavigator currentSourceCodeTextView];
    NSRange range = textView.selectedRange;
    
    [textView insertText:text replacementRange:range];
}

- (void)insertText:(NSString*)text withRange:(NSRange)range
{
    NSTextView *textView = [MHXcodeDocumentNavigator currentSourceCodeTextView];
    [textView insertText:text replacementRange:range];
}

- (void)insertText:(NSString*)text withRange:(NSRange)range withFilePath:(NSString*)filePath
{
    NSError* err;
    NSString *contents = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:&err];
    if(!contents) {
        NSLog(@"file does not exist");
        return;
    }
    NSTextView* textView = [NSTextView new];
    [textView setString:contents];
    [textView insertText:text replacementRange:range];
    
    if(![textView.string writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:&err]) {
        NSLog(@"write back failed");
    }

}

- (void)saveCodeChanges
{
    NSDocument* doc = [MHXcodeDocumentNavigator currentSourceCodeDocument];
    [doc saveDocument:nil];
}

@end
