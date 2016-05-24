//
//  FSProtocolProcessor.m
//  FastStub
//
//  Created by gao feng on 16/5/16.
//  Copyright © 2016年 music4kid. All rights reserved.
//

#import "FSProtocolProcessor.h"
#import "FSElementPool.h"
#import "FSElementCache.h"

@implementation FSProtocolProcessor

- (NSString *)pattern {
    return @"(@protocol)\\s+([a-z][a-z0-9_\\s*\()]+)(.*?)(@end+?)";
}

- (FSElementCacheType)getElementType
{
    return FSElementCacheProtocol;
}

- (NSArray *)createElements:(NSString *)content {
    NSMutableArray *array = [NSMutableArray array];
    [self processContent:content resultBlock:^(NSTextCheckingResult *match, NSMatchingFlags flags, BOOL *stop) {
        FSElementCache* element = [self createClassElement:match from:content];
        if (element) {
            [array addObject:element];
        }
    }];
    
    return array;
}

- (FSElementCache *)createClassElement:(NSTextCheckingResult *)match from:(NSString *)content {
    NSRange matchRange = [match rangeAtIndex:2];
    NSString *matchString = [content substringWithRange:matchRange];
    NSString *matchTrim = [matchString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if ([matchTrim rangeOfString:@"("].location == NSNotFound) {
        NSRange matchRange = [match rangeAtIndex:2];
        NSString *matchString = [content substringWithRange:matchRange];
        NSString *matchTrim = [matchString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
        FSElementCache *element = [FSElementCache new];
        element.elementName = matchTrim;
        element.elementType = FSElementCacheProtocol;
        
        NSRange matchProtocolRange = [match rangeAtIndex:3];
        NSString* matchProtocolString = [content substringWithRange:matchProtocolRange];
        element.methodList = [self buildMethodList:matchProtocolString].mutableCopy;
        
        
        return element;
    }
    
    return nil;
}

@end
