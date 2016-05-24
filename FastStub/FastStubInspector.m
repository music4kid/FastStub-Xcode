//
//  FastStubInspector.m
//  FastStub
//
//  Created by gao feng on 16/5/16.
//  Copyright © 2016年 music4kid. All rights reserved.
//

#import "FastStubInspector.h"
#import "FSIDESourceEditor.h"
#import "FSElementPool.h"
#import "XCFXcodePrivate.h"
#import "NSTextView+Operations.h"
#import "FSSuggestion.h"
#import "FSSuggestionController.h"
#import "FSSuggestionCellModel.h"
#import "FSStub.h"

@interface FastStubInspector () <FSSuggestionControllerDelegate>
@property (nonatomic, strong) NSMapTable*                           projectsByWorkspace;
@property (nonatomic, strong) FSIDESourceEditor*                    editor;
@property (nonatomic, assign) BOOL                                  loading;


@property (nonatomic, strong) NSMutableArray*                       customSuperClasses;
@property (nonatomic, strong) NSMutableArray*                       customProtocols;
@end


@implementation FastStubInspector

+ (instancetype)sharedInstance
{
    static FastStubInspector* instance = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [FastStubInspector new];
    });
    
    return instance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(detectShowSuggestion) name:@"FSShowSuggestion" object:nil];
        
        _projectsByWorkspace = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsStrongMemory
                                                     valueOptions:NSPointerFunctionsStrongMemory];
        
        _editor = [[FSIDESourceEditor alloc] init];
    }
    return self;
}

- (void)detectShowSuggestion
{
    if (_loading) {
        NSString *text = [NSString stringWithFormat:@"indexing project files, please try later..."];
        NSColor *color = [NSColor colorWithRed:0.7 green:0.8 blue:1.0 alpha:1.0];
        [_editor showAboveCaret:text color:color];
    }
    else
    {
        [self showSuggestion];
    }
    
}

- (void)showSuggestion
{
    FSElementCache* impElement = [_editor getCurrentElement];
    if (impElement == nil) {
        return;
    }
    
    NSMutableArray* suggestions = @[].mutableCopy;
    
    //general suggestion
    FSSuggestion* s = [FSSuggestion new];
    s.stype = FSSuggestionGeneral;
    s.title = @"[General]->[press enter]";
    [suggestions addObject:s];
    
    //compare with .h file
    FSElementCache* hElement = [_Pool getElementFromCache:impElement.elementName];
    if (hElement == nil) {
        NSLog(@"missing .h file, may be a bug");
        return;
    }
    
    s = [self buildSuggestion:hElement withTargetElement:impElement];
    if (s.methodList.count > 0) {
        [suggestions addObject:s];
        s.stype = FSSuggestionHeader;
    }
    
    //compare with protocols in header file
    for (NSString* protocol in hElement.protocols) {
        
        FSElementCache* protocolElement = [_Pool getElementFromCache:protocol];
        
        if (protocolElement != nil) {
            FSSuggestion* s = [self buildSuggestion:protocolElement withTargetElement:impElement];
            if (s.methodList.count > 0) {
                [suggestions addObject:s];
                s.stype = FSSuggestionProtocol;
            }
        }
    }
    
    //compare with protocols in extension
    for (NSString* protocol in impElement.protocols) {
        
        FSElementCache* protocolElement = [_Pool getElementFromCache:protocol];
        
        if (protocolElement != nil) {
            FSSuggestion* s = [self buildSuggestion:protocolElement withTargetElement:impElement];
            if (s.methodList.count > 0) {
                [suggestions addObject:s];
                s.stype = FSSuggestionProtocol;
            }
        }
    }
    
    //compare with super class
    for (NSString* superClass in hElement.superClasses) {
        
        FSElementCache* superElement = [_Pool getElementFromCache:superClass];
        
        if (superElement != nil) {
            FSSuggestion* s = [self buildSuggestion:superElement withTargetElement:impElement];
            if (s.methodList.count > 0) {
                [suggestions addObject:s];
                s.stype = FSSuggestionSuperClass;
            }
        }
    }
    
    //ready to go
    if (suggestions.count > 0) {
        [self showSuggestionList:suggestions];
    }
}

- (void)showSuggestionList:(NSArray*)suggestions
{
    [FSSuggestionController sharedInstance].delegate = self;
    [[FSSuggestionController sharedInstance] showSuggestionsInView:[_editor view] withItems:suggestions];
}

- (FSSuggestion*)buildSuggestion:(FSElementCache*)srcElement withTargetElement:(FSElementCache*)impElement
{
    FSSuggestion* s = [FSSuggestion new];
    
    NSMutableSet* srcMethodList = [NSMutableSet setWithSet:srcElement.methodList];
//    [srcMethodList minusSet:impElement.methodList];
    
    NSMutableSet* allMethods = srcElement.methodList.mutableCopy;
    for (NSString* method in allMethods) {
        NSString* trimedMethod = [method stringByReplacingOccurrencesOfString:@" " withString:@""];
        trimedMethod = [trimedMethod stringByReplacingOccurrencesOfString:@"\n" withString:@""];
        
        for (NSString* impMethod in impElement.methodList) {
            NSString* trimedImpMethod = [impMethod stringByReplacingOccurrencesOfString:@" " withString:@""];
            trimedImpMethod = [trimedImpMethod stringByReplacingOccurrencesOfString:@"\n" withString:@""];
            
            if ([trimedMethod isEqualToString:trimedImpMethod]) {
                [srcMethodList removeObject:method];
            }
        }
    }
    
    if (srcMethodList.count > 0) {
        s.methodList = [NSMutableSet setWithSet:srcMethodList];
        s.title = srcElement.elementName;
    }
    
    return s;
}

- (void)updateHeader:(NSString *)headerPath
{
    [_Pool parseHeaderFile:headerPath];
}

- (void)updateProject:(NSString *)projectPath completeBlock:(dispatch_block_t)completeBlock {
    
    if(![[NSFileManager defaultManager] fileExistsAtPath:projectPath]) {
        NSLog(@"project path does not exists.");
        return;
    }
    
    _loading = true;
    [_Pool parseElementFromProjectFile:projectPath complete:^{
        _loading = false;
        if (completeBlock) {
            completeBlock();
        }
    }];
}

- (void)loadCustomElement
{
    NSArray* customHeaders = @[@"FSTableView", @"FSTextView", @"FSScrollView", @"FSActionSheetDelegate", @"FSAlertViewDelegate"];
    NSBundle* bundle = [NSBundle bundleForClass:[self class]];
    
    for (NSString* header in customHeaders) {
        NSString* filePath = [bundle pathForResource:header ofType:@"txt"];
        if (filePath.length > 0) {
            [self updateHeader:filePath];
        }
    }
}

- (void)onItemSelected:(NSArray*)items
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        BOOL isMethodImp = false;
        for (id item in items) {
            
            //for method imp
            if ([item isKindOfClass:[FSSuggestionCellModel class]]) {
                FSSuggestionCellModel* model = item;
                if (model.cellType == FSSuggestionCellMethod) {
                    [_editor insertMethodImp:model.cellText];
                    isMethodImp = true;
                }
            }
            
            //for general stub
            if ([item isKindOfClass:[FSSuggestionStub class]]) {
                FSSuggestionStub* stub = item;
                [self insertStubByKey:stub.stubKey];
            }
        }
        
        if (isMethodImp) {
            [_editor offsetSelectedRange:-4];
        }
    });
    
    
}

- (void)insertStubByKey:(NSNumber*)stubKey
{
    FSElementCache* impElement = [_editor getCurrentElement];
    if (stubKey.intValue == GeneralStubSingleton) {
        
        //insert .m part
        NSRange contentRange = impElement.contentBeginRange;
        contentRange.length = 0;
        
        NSString* mpart = kSingletonImp;
        mpart = [mpart stringByReplacingOccurrencesOfString:@"FSPlaceHolder" withString:impElement.elementName];
        [_editor insertText:mpart withRange:contentRange];
        
        //insert .h part
        FSElementCache* hElement = [_Pool getElementFromCache:impElement.elementName];
        if (hElement != nil) {
            contentRange = hElement.contentBeginRange;
            contentRange.length = 0;
            [_editor insertText:kSingletonHeader withRange:contentRange withFilePath:hElement.filePath];
        }
        
    }
    else if(stubKey.intValue == GeneralStubExtension) {
        //insert .m part
        NSRange elementRange = impElement.elementBeginRange;
        elementRange.length = 0;
        
        NSString* mpart = kExtenionImp;
        mpart = [mpart stringByReplacingOccurrencesOfString:@"FSPlaceHolder" withString:impElement.elementName];
        [_editor insertText:mpart withRange:elementRange];
    }
    
    
}

@end
