//
//  FSImpProcessor.m
//  FastStub
//
//  Created by gao feng on 16/5/16.
//  Copyright © 2016年 music4kid. All rights reserved.
//

#import "FSImpProcessor.h"
#import "FSElementCache.h"
#import "NSString+PDRegex.h"

@implementation FSImpProcessor

- (NSString *)pattern {
    return @"(@implementation)\\s+([a-z][a-z0-9_\()]+)(.*?)(@end+?)";
}

- (FSElementCacheType)getElementType
{
    return FSElementCacheImp;
}

- (NSMutableSet*)buildSelectorList:(NSString*)content
{
    NSMutableSet* selectors = [NSMutableSet new];
    
    
    //parse based on file type, better accuracy
    NSArray* matchedMethods = nil;
    
    //only support notification selector
    NSString* regex = regex = @"selector:@selector\\((.*?)\\)";
    
    matchedMethods = [content vv_stringsByExtractingGroupsUsingRegexPattern:regex caseInsensitive:false treatAsOneLine:true];
    for (int i = 0; i < matchedMethods.count; i++) {
        NSString* selector = [NSString stringWithFormat:@"%@", matchedMethods[i]];
        [selectors addObject:selector];
    }
    
    return selectors;
}


@end
