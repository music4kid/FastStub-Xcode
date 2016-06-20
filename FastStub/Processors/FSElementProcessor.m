//
//  FSElementProcessor.m
//  FastStub
//
//  Created by gao feng on 16/5/16.
//  Copyright © 2016年 music4kid. All rights reserved.
//

#define MethodPattern @"(\\-)\\s*\\([<?\\w>?\\s]+(\\s*\\*)?\\)\
\\w+(:\\([\\w\\s]+(\\s*\\*)?\\)\\w+\\s? *)?\
( *\\w+:\\([\\w\\s]+(\\s*\\*)?\\)\\w+\\s? *)*"

#import "FSElementProcessor.h"
#import "NSString+PDRegex.h"
#import "FSElementProperty.h"

@implementation FSElementProcessor

- (NSString *)pattern {
    return nil;
}

- (FSElementCacheType)getElementType
{
    return FSElementCacheInterface;
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

- (void)processContent:(NSString *)content resultBlock:(processorResultBlock)resultBlock {
    [self processContent:content withPatternStr:[self pattern] resultBlock:resultBlock];
}

- (void)processContent:(NSString *)content withPatternStr:(NSString*)pattern resultBlock:(processorResultBlock)resultBlock {
    NSError *error = nil;
    NSString *classRegExp = pattern;
    NSRegularExpression *regex = [NSRegularExpression
                                  regularExpressionWithPattern:classRegExp
                                  options:NSRegularExpressionCaseInsensitive|NSRegularExpressionDotMatchesLineSeparators|NSRegularExpressionAnchorsMatchLines
                                  error:&error];
    
    if (error) {
        NSLog(@"processing header path error: %@", error);
        return;
    }
    
    [regex enumerateMatchesInString:content options:0 range:NSMakeRange(0, [content length]) usingBlock:^(NSTextCheckingResult *match, NSMatchingFlags flags, BOOL *stop){
        resultBlock(match, flags, stop);
    }];
}


- (FSElementCache *)createClassElement:(NSTextCheckingResult *)match from:(NSString *)content {
    NSRange matchRange = [match rangeAtIndex:2];
    NSString *matchString = [content substringWithRange:matchRange];
    NSString *matchTrim = [matchString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if ([matchTrim rangeOfString:@"("].location == NSNotFound)
    {
        int rangeIndex = 2;
        FSElementCache *element = [FSElementCache new];
        element.elementType = [self getElementType];
        
        //element begin range
        NSRange eRange = [match rangeAtIndex:1];
        eRange.length = 0;
        element.elementBeginRange = eRange;
        
        //parse class name
        NSRange matchRange = [match rangeAtIndex:rangeIndex];
        NSString *matchString = [content substringWithRange:matchRange];
        NSString *matchTrim = [matchString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
        element.elementName = matchTrim;
        rangeIndex++;
        
        
        //parse super class
        matchRange = [match rangeAtIndex:rangeIndex];
        if (matchRange.location != NSNotFound && element.elementType != FSElementCacheImp
            && element.elementType != FSElementCacheExtension
            && element.elementType != FSElementCacheCategory)
        {
            matchString = [content substringWithRange:matchRange];
            matchTrim = [matchString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            if (matchTrim.length > 0) {
                [element.superClasses addObject:matchTrim];
                rangeIndex++;
            }
        }
        
        
        //parse protocols
        matchRange = [match rangeAtIndex:rangeIndex];
        if (matchRange.location != NSNotFound && element.elementType != FSElementCacheCategory)
        {
            matchString = [content substringWithRange:matchRange];
            
            NSString* newContent = [matchString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            if ([newContent hasPrefix:@"()"]) {
                newContent = [newContent stringByReplacingCharactersInRange:NSMakeRange(0, 2) withString:@""];
                newContent = [newContent stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            }
            
            if ([newContent hasPrefix:@"<"]) //possible protocols
            {
                [self processContent:newContent withPatternStr:@"<?(.*?)>" resultBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
                    NSRange protocolRange = [result rangeAtIndex:1];
                    NSString *protocolString = [newContent substringWithRange:protocolRange];
                    
                    NSArray* protocols = [protocolString componentsSeparatedByString:@","];
                    for (NSString* pstr in protocols) {
                        NSString* protocolName = [pstr stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                        [element.protocols addObject:protocolName];
                    }
                }];
            }
        }
        
        
        //parse method list
        NSRange matchInterfaceRange = [match rangeAtIndex:rangeIndex];
        if (matchInterfaceRange.location != NSNotFound) {
            NSString* matchInterfaceString = [content substringWithRange:matchInterfaceRange];
            element.methodList = [self buildMethodList:matchInterfaceString].mutableCopy;
            element.contentRange = matchInterfaceRange;
            
            NSRange beginRange = [matchInterfaceString rangeOfString:@"\n"];
            beginRange.location = matchInterfaceRange.location + beginRange.location + 1;
            beginRange.length = 0;
            element.contentBeginRange = beginRange;
        }
        
        
        //parse property list
        if (element.elementType == FSElementCacheInterface) {
            NSRange matchInterfaceRange = [match rangeAtIndex:rangeIndex];
            if (matchInterfaceRange.location != NSNotFound) {
                NSString* matchInterfaceString = [content substringWithRange:matchInterfaceRange];
                element.propertyList = [self buildPropertyList:matchInterfaceString].mutableCopy;
            }
        }
        
        
        return element;
    }
    
    return nil;
}


- (NSMutableSet*)buildMethodList:(NSString*)content
{
    __block NSMutableSet* methods = [NSMutableSet new];
    
    //parse based on file type, better accuracy
    NSArray* matchedMethods = nil;
    
    FSElementCacheType etype = [self getElementType];
    NSString* regex = nil;
    if(etype == FSElementCacheInterface
       || etype == FSElementCacheExtension
       || etype == FSElementCacheProtocol
       || etype == FSElementCacheCategory)
    {
        regex = @"(?:^|\\r|\\n|\\r\\n)\\s*([-+])(.*?);";
    }
    else if(etype == FSElementCacheImp) {
        regex = @"(?:^|\\r|\\n|\\r\\n)\\s*([-+])(.*?)\\{";
    }
    
    matchedMethods = [content vv_stringsByExtractingGroupsUsingRegexPattern:regex caseInsensitive:false treatAsOneLine:true];
    for (int i = 0; i < matchedMethods.count; i+=2) {
        NSString* fullMethod = [NSString stringWithFormat:@"%@%@", matchedMethods[i], matchedMethods[i+1]];
        [methods addObject:fullMethod];
    }
    
    return methods;
}

- (NSMutableSet*)buildPropertyList:(NSString*)content
{
    __block NSMutableSet* properties = [NSMutableSet new];
    
    //parse based on file type, better accuracy
    NSArray* matchedProperties = nil;
    
    NSString* regex = @"(?:^|\\r|\\n|\\r\\n)\\s*(?:@property)\\s*(?:\\\([^\\(^\\).]*\\\))?(.*?);";
    
    matchedProperties = [content vv_stringsByExtractingGroupsUsingRegexPattern:regex caseInsensitive:false treatAsOneLine:true];
    for (int i = 0; i < matchedProperties.count; i++) {
        NSString* propertyStr = [NSString stringWithFormat:@"%@", matchedProperties[i]];
        NSString* propertyStrTrim = [propertyStr stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
        FSElementProperty* p = [FSElementProperty new];
        if ([propertyStr rangeOfString:@"*"].location != NSNotFound) {
            propertyStrTrim = [propertyStrTrim stringByReplacingOccurrencesOfString:@"*" withString:@" "];
            NSString* re = @"^(.*)\\s+(?=(\\S*+)$)";
            NSArray* matches = [propertyStrTrim vv_stringsByExtractingGroupsUsingRegexPattern:re caseInsensitive:false treatAsOneLine:true];
            if (matches.count == 2) {
                NSString* typeStr = [matches[0] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                p.propertyType = [NSString stringWithFormat:@"%@ *", typeStr];
                p.propertyName = [NSString stringWithFormat:@"%@", matches[1]];
                p.propertyName = [p.propertyName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            }
        }
        else {
            NSString* re = @"^(.*)\\s+(?=(\\S*+)$)";
            NSArray* matches = [propertyStrTrim vv_stringsByExtractingGroupsUsingRegexPattern:re caseInsensitive:false treatAsOneLine:true];
            if (matches.count == 2) {
                NSString* typeStr = [matches[0] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                
                NSArray *structTypes = @[@"CGRect", @"CGSize", @"CGPoint", @"CGFloat"];
                if ([structTypes containsObject:typeStr]) {
                    p.propertyType = [NSString stringWithFormat:@"%@", typeStr];
                } else {
                    p.propertyType = [NSString stringWithFormat:@"%@ *", typeStr];
                }
                p.propertyName = [NSString stringWithFormat:@"%@", matches[1]];
                p.propertyName = [p.propertyName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            }
        }
        
        if (p.propertyType.length >0 && p.propertyName.length > 0) {
            [properties addObject:p];
        }
    }
    
    return properties;
}

@end
