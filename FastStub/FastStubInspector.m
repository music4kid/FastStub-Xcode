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
#import "FSPopTableViewController.h"
#import "FSElementProperty.h"
#import "FSTableViewModel.h"

@interface FastStubInspector () <FSSuggestionControllerDelegate, FSPopTableViewControllerDelegate>
@property (nonatomic, strong) NSMapTable*                           projectsByWorkspace;
@property (nonatomic, strong) FSIDESourceEditor*                    editor;
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
    if ([self isStillLoading]) {
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
    FSElementCache* hElement = [_editor getCurrentElementHeader];
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

static NSMutableDictionary* projectMap = nil;
- (void)updateProject:(NSString *)projectPath completeBlock:(dispatch_block_t)completeBlock {
    
    if(![[NSFileManager defaultManager] fileExistsAtPath:projectPath]) {
        NSLog(@"project path does not exists.");
        return;
    }
    
    @synchronized (self) {
        if (projectMap == nil) {
            projectMap = @{}.mutableCopy;
        }
        
        if ([projectMap objectForKey:projectPath] != nil) {
            return;
        }
        
        [projectMap setObject:projectPath forKey:projectPath];
    }
    
    [_Pool parseElementFromProjectFile:projectPath complete:^{
        
        @synchronized (self) {
            [projectMap removeObjectForKey:projectPath];
        }
        
        if (completeBlock) {
            completeBlock();
        }
    }];
}

- (BOOL)isStillLoading
{
    BOOL isLoading = false;
    @synchronized (self) {
        isLoading = projectMap.allKeys.count > 0;
    }
    return isLoading;
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
        
        impElement = [_editor getCurrentElement];
        [_editor setSelectedRange:NSMakeRange(impElement.elementBeginRange.location-7, 0)];
    }
    else if(stubKey.intValue == GeneralStubInitWith ||
            stubKey.intValue == GeneralStubGetterSetter) {
        NSMutableArray* properties = @[].mutableCopy;
        
        FSElementCache* hElement = [_editor getCurrentElementHeader];
        
        if (hElement.propertyList.count == 0) {
            return;
        }
        
        for (FSElementProperty* p in hElement.propertyList) {
            FSTableViewModel* m = [FSTableViewModel new];
            m.text = p.propertyName;
            m.type = FSTableViewModelTypePropertyInit;
            if (stubKey.intValue == GeneralStubGetterSetter) {
                m.type = FSTableViewModelTypeGetterSetter;
            }
            m.customInfo = p;
            [properties addObject:m];
        }
        
        FSPopTableViewController* c =[FSPopTableViewController showPopWithinView:[_editor view] withItems:properties];
        c.delegate = self;
    }
    
    
}

- (void)onPopTableViewItemsSelected:(NSArray*)items {
    if (items.count == 0) {
        return;
    }
    
    FSTableViewModel* m = items[0];
    if (m.type == FSTableViewModelTypePropertyInit) {
        [self createInitMethodWithItems:items];
    }
    else if (m.type == FSTableViewModelTypeGetterSetter) {
        [self createGetterSetterWithItems:items];
    }
    
}

- (void)createInitMethodWithItems:(NSArray*)items;
{
    NSMutableString* initMethod = @"- (void)init".mutableCopy;
    for (int i = 0; i < items.count; i ++) {
        FSTableViewModel* m = items[i];
        FSElementProperty* p = m.customInfo;
        
        NSString* nameStr = p.propertyName;
        if (i == 0) {
            nameStr = [p.propertyName stringByReplacingCharactersInRange:NSMakeRange(0,1)
                                                              withString:[[p.propertyName substringToIndex:1] capitalizedString]];
            [initMethod appendFormat:@"With%@", nameStr];
        }
        else
        {
            [initMethod appendFormat:@"%@", nameStr];
        }
        
        [initMethod appendFormat:@":(%@)%@ ", p.propertyType, p.propertyName];
    }
    [initMethod appendFormat:@"\n{\n"];
    
    for (int i = 0; i < items.count; i ++) {
        FSTableViewModel* m = items[i];
        FSElementProperty* p = m.customInfo;
        
        [initMethod appendFormat:@"\tself.%@ = %@;\n", p.propertyName, p.propertyName];
    }
    
    
    [initMethod appendFormat:@"}\n"];
    
    [_editor insertText:initMethod];
}

- (void)createGetterSetterWithItems:(NSArray*)items;
{
    FSElementCache* impElement = [_editor getCurrentElement];
    for (int i = 0; i < items.count; i ++) {
        FSTableViewModel* m = items[i];
        FSElementProperty* p = m.customInfo;
        
        NSString* nameStr = p.propertyName;
        NSString* upNameStr = [p.propertyName stringByReplacingCharactersInRange:NSMakeRange(0,1)
                                                                      withString:[[p.propertyName substringToIndex:1] capitalizedString]];
        
        //insert @synthesize
        NSRange contentRange = impElement.contentBeginRange;
        contentRange.length = 0;
        NSString* synStr = [NSString stringWithFormat:@"@synthesize %@ = _%@;\n", nameStr, nameStr];
        [_editor insertText:synStr withRange:contentRange];
        
        //insert getter
        NSMutableString* getter = @"".mutableCopy;
        [getter appendFormat:@"- (%@)%@\n{\n\treturn _%@;\n}\n\n", p.propertyType, nameStr, nameStr];
        [_editor insertText:getter];
        
        //insert setter
        NSMutableString* setter = @"".mutableCopy;
        [setter appendFormat:@"- (void)set%@:(%@)%@\n{\n\t_%@ = %@;\n}\n\n", upNameStr, p.propertyType, nameStr, nameStr, nameStr];
        [_editor insertText:setter];
    }
}

@end
