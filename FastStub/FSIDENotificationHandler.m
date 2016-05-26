//
//  FSIDENotificationHandler.m
//  FastStub
//
//  Created by gao feng on 16/5/16.
//  Copyright © 2016年 music4kid. All rights reserved.
//

#import "FSIDENotificationHandler.h"
#import "XCFXcodePrivate.h"
#import "FastStubInspector.h"

@implementation FSIDENotificationHandler

+ (instancetype)sharedInstance
{
    static FSIDENotificationHandler* instance = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [FSIDENotificationHandler new];
    });
    
    return instance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
        
        [notificationCenter addObserver:self
                               selector:@selector(projectDidOpen:)
                                   name:@"PBXProjectDidOpenNotification"
                                 object:nil];
        
        [notificationCenter addObserver:self
                               selector:@selector(projectDidChange:)
                                   name:@"PBXProjectDidChangeNotification"
                                 object:nil];
        
        [notificationCenter addObserver:self
                               selector:@selector(fileDidSave:)
                                   name:@"IDEEditorDocumentDidSaveNotification"
                                 object:nil];
    }
    return self;
}

- (void)fileDidSave:(NSNotification *)notification {
    NSString *path = [[[notification object] fileURL] path];
    if ([path hasSuffix:@".h"]) {
        [[FastStubInspector sharedInstance] updateHeader:path];
    }
}

- (void)projectDidOpen:(NSNotification *)notification {
    [self projectDidChange:notification];
    
    [[FastStubInspector sharedInstance] loadCustomElement];
}

- (void)projectDidChange:(NSNotification *)notification {
    NSString *filePath = [self filePathForProjectFromNotification:notification];
    
    //build cache, avoid parsing the same project more than once
    static NSMutableDictionary* parseMap = nil;
    if (parseMap == nil) {
        parseMap = @{}.mutableCopy;
    }
//    if ([parseMap objectForKey:filePath]) {
//        return;
//    }
//    [parseMap setObject:filePath forKey:filePath];
    
    if (filePath) {
        [[FastStubInspector sharedInstance] updateProject:filePath completeBlock:nil];
    }
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"

- (NSString *)filePathForProjectFromNotification:(NSNotification *)notification {
    if ([notification.object respondsToSelector:@selector(projectFilePath)]) {
        NSString *pbxProjPath = [notification.object performSelector:@selector(projectFilePath)];
        return [pbxProjPath stringByDeletingLastPathComponent];
    }
    return nil;
}

#pragma clang diagnostic pop

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}



@end
