//
//  FSElementPool.m
//  FastStub
//
//  Created by gao feng on 16/5/17.
//  Copyright © 2016年 music4kid. All rights reserved.
//

#import "FSElementPool.h"
#import "XCProject.h"
#import "XCSourceFile.h"
#import "XCSourceFile+Path.h"

#import "FSInterfaceProcessor.h"
#import "FSProtocolProcessor.h"
#import "FSElementCache.h"

@interface FSElementPool ()
@property (nonatomic, strong) NSOperationQueue*         parseQueue;
@end

@implementation FSElementPool

+ (instancetype)sharedInstance
{
    static FSElementPool* instance = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [FSElementPool new];
    });
    
    return instance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _elementMap = @{}.mutableCopy;
        
        _parseQueue = [NSOperationQueue new];
        _parseQueue.maxConcurrentOperationCount = 1;
    }
    return self;
}

- (FSElementCache*)getElementFromCache:(NSString*)elementName
{
    FSElementCache* match = [_elementMap objectForKey:elementName];
    return match;
}
- (void)parseElementFromProjectFile:(NSString*)filePath complete:(dispatch_block_t)completeBlock
{
    XCProject *project = [XCProject projectWithFilePath:filePath];
    [_parseQueue addOperationWithBlock:^{
        [self parseProject:project];
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            completeBlock();
        }];
    }];
}

- (void)parseHeaderFile:(NSString*)filePath
{
    [self processHeaderPath:filePath];
}

- (void)parseProject:(XCProject *)project
{
    NSDate *start = [NSDate date];
    NSMutableSet *missingFiles = [NSMutableSet set];
    for (XCSourceFile *header in project.headerFiles) {
        if (![self processHeaderPath:[header fullPath]]) {
            NSString *file = [[header pathRelativeToProjectRoot] lastPathComponent];
            if (file) {
                [missingFiles addObject:file];
            }
        }
    }
    
    NSString *projectDir = [[project filePath] stringByDeletingLastPathComponent];
    NSArray *missingHeaderFullPaths = [self fullPathsForFiles:missingFiles inDirectory:projectDir];
    
    for (NSString *headerMissingFullpath in missingHeaderFullPaths) {
        [self processHeaderPath:headerMissingFullpath]; 
    }
    
    NSDate *methodFinish = [NSDate date];
    NSTimeInterval executionTime = [methodFinish timeIntervalSinceDate:start];
    
    NSLog(@"project %@ - parse time: %f", [[project filePath] lastPathComponent], executionTime);
}

- (BOOL)processHeaderPath:(NSString *)headerPath {
    @autoreleasepool {
        NSError *error = nil;
        NSString *content = [NSString stringWithContentsOfFile:headerPath encoding:NSUTF8StringEncoding error:&error];
        if (error) {
            return NO;
        }
        
        NSArray *processors = @[[FSInterfaceProcessor new], [FSProtocolProcessor new]];
        
        for (FSElementProcessor *processor in processors) {
            NSArray *elements = [processor createElements:content];
            
            for (FSElementCache* ele in elements) {
                ele.filePath = headerPath;
                [_elementMap setObject:ele forKey:ele.elementName];
            }
        }
        
        return YES;
    }
}

- (NSArray *)fullPathsForFiles:(NSSet *)fileNames inDirectory:(NSString *)directoryPath {
    NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtPath:directoryPath];
    
    NSMutableArray *fullPaths = [NSMutableArray array];
    
    NSString *filePath = nil;
    while ( (filePath = [enumerator nextObject] ) != nil ){
        if ([fileNames containsObject:[filePath lastPathComponent]]) {
            [fullPaths addObject:[directoryPath stringByAppendingPathComponent:filePath]];
        }
    }
    
    return fullPaths;
}



@end
