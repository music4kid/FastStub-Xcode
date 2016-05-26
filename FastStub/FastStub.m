//
//  FastStub.m
//  FastStub
//
//  Created by gao feng on 16/5/7.
//  Copyright © 2016年 music4kid. All rights reserved.
//

#import "FastStub.h"
#import <Carbon/Carbon.h>
#import "FastStubInspector.h"
#import "FSIDENotificationHandler.h"

@interface FastStub()

@property (nonatomic, strong, readwrite) NSBundle *bundle;
@end

@implementation FastStub

+ (instancetype)sharedPlugin
{
    return sharedPlugin;
}

- (id)initWithBundle:(NSBundle *)plugin
{
    if (self = [super init]) {
        // reference to plugin's bundle, for resource access
        self.bundle = plugin;
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didApplicationFinishLaunchingNotification:)
                                                     name:NSApplicationDidFinishLaunchingNotification
                                                   object:nil];
    }
    return self;
}

- (void)didApplicationFinishLaunchingNotification:(NSNotification*)noti
{
    //removeObserver
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSApplicationDidFinishLaunchingNotification object:nil];
    
    [FastStubInspector sharedInstance];
    [FSIDENotificationHandler sharedInstance];
    
    //add menu item
    [self insertMenuItem];
}

- (void)insertMenuItem
{
    NSMenuItem *menuItem = [[NSApp mainMenu] itemWithTitle:@"Edit"];
    if (menuItem) {
        [[menuItem submenu] addItem:[NSMenuItem separatorItem]];
        NSMenuItem *actionMenuItem = [[NSMenuItem alloc] initWithTitle:@"Suggest Stub" action:@selector(doMenuAction) keyEquivalent:@""];
        
        [actionMenuItem setKeyEquivalent:@"k"];
        [actionMenuItem setKeyEquivalentModifierMask:NSControlKeyMask | NSCommandKeyMask];
        [actionMenuItem setTarget:self];
        [[menuItem submenu] addItem:actionMenuItem];
    }
}

- (void)doMenuAction
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"FSShowSuggestion" object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
