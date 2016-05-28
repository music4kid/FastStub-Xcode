//
//  FSSuggestionController.m
//  FastStub
//
//  Created by gao feng on 16/5/17.
//  Copyright © 2016年 music4kid. All rights reserved.
//

#import "FSSuggestionController.h"
#import "FSSuggestionView.h"
#import "NSTextView+Operations.h"
#import "FSSuggestionCellModel.h"
#import "FSSuggestion.h"
#import "FSSuggestionStubController.h"
#import "FSConst.h"

#define kSuggestionCellHeight 30

@interface FSSuggestionController () <NSPopoverDelegate, NSTableViewDelegate, NSTableViewDataSource, NSSearchFieldDelegate, FSSuggestionStubControllerDelegate>
@property (nonatomic, strong) NSPopover*                            popover;
@property (nonatomic, strong) NSMutableArray*                       srcItems;
@property (nonatomic, strong) NSMutableArray*                       filteredItems;

@property (nonatomic, strong) FSSuggestionView*                     suggestView;
@property (nonatomic, strong) NSPopover*                            nextPopover;
@end

@implementation FSSuggestionController

+ (instancetype)sharedInstance
{
    static FSSuggestionController* instance = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [FSSuggestionController new];
    });
    
    return instance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.ctype = SuggestionControllerRoot;
        
        self.filteredItems = @[].mutableCopy;
        
        self.popover = [NSPopover new];
        _popover.delegate = self;
        _popover.behavior = NSPopoverBehaviorTransient;
        _popover.appearance = NSPopoverAppearanceMinimal;
        _popover.animates = NO;
        
        [Notif addObserver:self selector:@selector(detectStubHide) name:Notif_SuggestionStubHide object:nil];
    }
    return self;
}

- (void)showSuggestionsInView:(NSView*)view withItems:(NSArray*)items
{
    if (!view) {
        return;
    }
    
    if (!self.popover.isShown) {
        
        self.srcItems = [items mutableCopy];
        
        [self buildDataSource:items withKeyword:@""];
        
        [self buildSuggestionUI];
        
        NSRect displayFrame = view.frame;
        if([view isKindOfClass:[NSTextView class]]) {
            displayFrame = [(NSTextView*)view mhFrameForCaret];
        }
        [self.popover showRelativeToRect:displayFrame
                                  ofView:view
                           preferredEdge:NSMinYEdge];
        
        [_suggestView.tableView reloadData];
        [_suggestView.tableView scrollRowToVisible:0];
        
        NSIndexSet *set = [NSIndexSet indexSetWithIndex:[self getTopSelectionIndex]];
        [_suggestView.tableView selectRowIndexes:set byExtendingSelection:NO];
    }
}

- (void)buildSuggestionUI
{
    if (self.suggestView == nil) {
        self.suggestView = [FSSuggestionView new];
        _suggestView.frame = CGRectMake(0, 0, 480, 360);
        self.view = self.suggestView;
        
        NSBundle *bundle = [NSBundle bundleForClass:[self class]];
        NSViewController* contentViewController = [[NSViewController alloc] initWithNibName:@"FSSuggestionView" bundle:bundle];
        _popover.contentViewController = contentViewController;
        
        _suggestView = (FSSuggestionView *)_popover.contentViewController.view;
        
        
        //config table view
        _suggestView.tableView.dataSource = self;
        _suggestView.tableView.delegate = self;
        
        _suggestView.tableView.target = self;
        _suggestView.tableView.doubleAction = @selector(onItemSelected);
        _suggestView.tableView.selectionHighlightStyle = NSTableViewSelectionHighlightStyleNone;
        
        
        //config search field
        _suggestView.searchField.backgroundColor = [NSColor whiteColor];
        _suggestView.searchField.delegate = self;
    }
    
}

- (void)buildDataSource:(NSArray*)items withKeyword:(NSString*)keyword
{
    NSMutableArray* models = @[].mutableCopy;
    for (id item in items) {
        FSSuggestion* s = item;
        FSSuggestionCellModel* model = [FSSuggestionCellModel new];
        model.cellText = s.title;
        
        if (s.stype == FSSuggestionGeneral) {
            model.cellType = FSSuggestionCellGeneralStub;
            
            NSDictionary* stubMap = s.getGeneralStubs;
            NSArray* keys = stubMap.allKeys;
            keys = [keys sortedArrayUsingComparator:^(id a, id b) {
                return [a compare:b];
            }];
            
            for (NSNumber* key in keys) {
                FSSuggestionStub* stub = [FSSuggestionStub new];
                stub.stubKey = key;
                stub.cellText = stubMap[key];
                [model.stubs addObject:stub];
            }
            
            [models addObject:model];
            continue;
        }
        else if (s.stype == FSSuggestionProtocol) {
            model.cellType = FSSuggestionCellTitleProtocol;
        }
        else if(s.stype == FSSuggestionHeader)
        {
            model.cellType = FSSuggestionCellTitleHeader;
        }
        else if(s.stype == FSSuggestionSuperClass)
        {
            model.cellType = FSSuggestionCellTitleSuperClass;
        }
        
        [models addObject:model];
        
        for (NSString* method in s.methodList) {
            FSSuggestionCellModel* model = [FSSuggestionCellModel new];
            model.cellText = method;
            model.cellType = FSSuggestionCellMethod;
            [models addObject:model];
        }
    }
    
    if (keyword.length == 0) {
        _filteredItems = models;
    } else {
        _filteredItems = [models filteredArrayUsingPredicate:
                          [NSPredicate predicateWithFormat:@"SELF.cellText CONTAINS[cd] %@", keyword]].mutableCopy;
    }
}


#pragma mark- NSTableViewDelegate

#pragma mark- NSTableViewDataSource
- (BOOL)tableView:(NSTableView *)aTableView shouldEditTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
    return NO;
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return _filteredItems.count;
}

- (nullable id)tableView:(NSTableView *)tableView objectValueForTableColumn:(nullable NSTableColumn *)tableColumn row:(NSInteger)row
{
    if (row > _filteredItems.count-1) {
        return nil;
    }
    
    FSSuggestionCellModel* model = _filteredItems[row];
    NSString* text = model.cellText;
    
    if (model.cellType == FSSuggestionCellGeneralStub) {
        text = [NSString stringWithFormat:@"%@", text];
    }
    else if (model.cellType == FSSuggestionCellTitleHeader) {
        text = [NSString stringWithFormat:@"[Header] %@", text];
    }
    else if(model.cellType == FSSuggestionCellTitleSuperClass)
    {
        text = [NSString stringWithFormat:@"[Super] %@", text];
    }
    else if(model.cellType == FSSuggestionCellTitleProtocol)
    {
        text = [NSString stringWithFormat:@"[Protocol] %@", text];
    }
    else
    {
        text = [NSString stringWithFormat:@"    %@", text];
    }
    
    return text;
}

- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
    
    if (rowIndex > _filteredItems.count-1) {
        return;
    }
    
    FSSuggestionCellModel* model = _filteredItems[rowIndex];
    
    NSTextFieldCell *cell = aCell;
    
    if (model.cellType == FSSuggestionCellGeneralStub) {
        [cell setTextColor:[NSColor colorWithRed:75.0/255 green:139.0/255 blue:221.0/255 alpha:1.0]];
    }
    else if(model.cellType == FSSuggestionCellMethod)
    {
        [cell setTextColor:[NSColor colorWithWhite:6.0/255 alpha:1.0]];
    }
    else
    {
        [cell setTextColor:[NSColor grayColor]];
    }
    
    
    id c = [aTableColumn dataCell];
    [c setFont:[NSFont systemFontOfSize:12]];
    
    
    if ([[aTableView selectedRowIndexes] containsIndex:rowIndex])
    {
        [aCell setBackgroundColor:[NSColor colorWithRed:13.0/255 green:83.0/255 blue:209.0/255 alpha:0.8]];
        [cell setTextColor:[NSColor whiteColor]];
    }
    else
    {
        [aCell setBackgroundColor: [NSColor whiteColor]];
    }
    [aCell setDrawsBackground:YES];
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row
{
    return 18;
}



#pragma mark - NSTextFieldDelegate

- (void)controlTextDidChange:(NSNotification *)notification {
    NSString* input = [_suggestView.searchField stringValue];
    [self buildDataSource:self.srcItems withKeyword:input];
    
    [_suggestView.tableView reloadData];
    [_suggestView.tableView scrollRowToVisible:0];
    
    NSIndexSet *set = [NSIndexSet indexSetWithIndex:[self getTopSelectionIndex]];
    [_suggestView.tableView selectRowIndexes:set byExtendingSelection:NO];
}


- (BOOL)control:(NSControl *)control textView:(NSTextView *)fieldEditor doCommandBySelector:(SEL)commandSelector {
    
    NSIndexSet *indexes = [_suggestView.tableView selectedRowIndexes];
    int index = -1;
    BOOL scrollToTop = false;
    BOOL shouldExtend = [self isShiftKeyPressed];

    BOOL ret = NO;
    if (commandSelector == @selector(moveRight:))
    {
        if (_suggestView.searchField.stringValue.length == 0) {
            [self onItemSelected];
        }
    }
    else if (commandSelector == @selector(moveDown:)) {
        int nextIndex = [self getNextAvailableSelectionIndex:(int)[indexes lastIndex]];
        if (nextIndex >= 0) {
            index = nextIndex;
        }
        else
        {
            index = [self getBottomSelectionIndex];
        }
        ret = YES;
    }
    else if (commandSelector == @selector(moveUp:)) {
        int prevIndex = [self getPreviousAvailableSelectionIndex:(int)[indexes firstIndex]];
        if (prevIndex >= 0) {
            index = prevIndex;
        }
        else
        {
            index = [self getTopSelectionIndex];
            scrollToTop = true;
        }
        ret = YES;
    }
    else if (commandSelector == @selector(cancelOperation:)) {
        [self.popover close];
    }
    else if (commandSelector == @selector(insertNewline:)) {
        [self onItemSelected];
    }
    else if (commandSelector == @selector(moveDownAndModifySelection:))
    {
        int nextIndex = [self getNextAvailableSelectionIndex:(int)[indexes lastIndex]];
        if (nextIndex >= 0) {
            index = nextIndex;
        }
        
        ret = YES;
        
    }
    else if (commandSelector == @selector(moveUpAndModifySelection:))
    {
        int prevIndex = [self getPreviousAvailableSelectionIndex:(int)[indexes firstIndex]];
        if (prevIndex >= 0) {
            index = prevIndex;
        }
        
        ret = YES;
    }
    
    //check if it's valid selection
    if ([self isValidSelection:index]) {
        [_suggestView.tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:index] byExtendingSelection:shouldExtend];
        
        if (scrollToTop) {
            [_suggestView.tableView scrollRowToVisible:0];
        }
        else
        {
            [_suggestView.tableView scrollRowToVisible:index];
        }
    }
    
    return ret;
}

- (void)controlTextDidEndEditing:(NSNotification *)notification
{
    if ( [[[notification userInfo] objectForKey:@"NSTextMovement"] intValue] == NSReturnTextMovement ) {
        [self onItemSelected];
    }
}


- (BOOL)isShiftKeyPressed
{
    BOOL pressed = false;
    
    NSUInteger flags = [[NSApp currentEvent] modifierFlags];
    if (flags & NSShiftKeyMask) {
        pressed = true;
    }
    
    return pressed;
}

#pragma mark- Text Selection Logic
- (BOOL)isValidSelection:(int)index
{
    if (index < 0 || index > _filteredItems.count-1) {
        return false;
    }
    
    FSSuggestionCellModel* model = _filteredItems[index];
    if (model.cellType == FSSuggestionCellMethod || model.cellType == FSSuggestionCellGeneralStub) {
        return true;
    }
    else
    {
        return false;
    }
}

- (int)getTopSelectionIndex
{
    return 0;
}

- (int)getBottomSelectionIndex
{
    return (int)(_filteredItems.count-1);
}

- (int)getNextAvailableSelectionIndex:(int)curIndex
{
    int nextIndex = -1;
    if (curIndex < _filteredItems.count-1) {
        for (int i = curIndex+1; i <= _filteredItems.count-1; i ++) {
            FSSuggestionCellModel* model = _filteredItems[i];
            if (model.cellType == FSSuggestionCellMethod || model.cellType == FSSuggestionCellGeneralStub) {
                nextIndex = i;
                break;
            }
        }
    }
    return nextIndex;
}

- (int)getPreviousAvailableSelectionIndex:(int)curIndex
{
    int prevIndex = -1;
    if (curIndex > 0) {
        for (int i = curIndex-1; i >= 0; i --) {
            FSSuggestionCellModel* model = _filteredItems[i];
            if (model.cellType == FSSuggestionCellMethod || model.cellType == FSSuggestionCellGeneralStub) {
                prevIndex = i;
                break;
            }
        }
    }
    return prevIndex;
}

- (void)onItemSelected
{
    NSIndexSet *indexes = [_suggestView.tableView selectedRowIndexes];
    
    if (indexes.count == 1) {
        FSSuggestionCellModel* model = _filteredItems[[indexes firstIndex]];
        if (model.cellType == FSSuggestionCellGeneralStub) {
            
            [self showNextPopover];
            //show stubs
//            FSSuggestionController* stubController = [FSSuggestionController new];
//            stubController = self;
//            stubController.ctype = SuggestionControllerGeneral;
//            [stubController showSuggestionsInView:_suggestView.tableView withItems:model.stubs];
            
            return;
        }
    }
    
    if ([indexes count] > 0) {
        
        NSMutableArray* items = @[].mutableCopy;
        [indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
            
            if (idx <= _filteredItems.count -1) {
                FSSuggestionCellModel* model = _filteredItems[idx];
                [items addObject:model];
            }
            
        }];
        if (_delegate != nil) {
            [_delegate onItemSelected:items];
        }
        
        [self.popover close];
    }
}


- (void)showNextPopover
{
    if (self.nextPopover == nil) {
        _nextPopover = [[NSPopover alloc] init];
        self.nextPopover.appearance = NSPopoverAppearanceMinimal;
        self.nextPopover.animates = false;
        self.nextPopover.behavior = NSPopoverBehaviorTransient;
        self.nextPopover.delegate = [FSSuggestionStubController sharedInstance];
    }
    
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSViewController* contentViewController = [[NSViewController alloc] initWithNibName:@"FSSuggestionStubView" bundle:bundle];
    self.nextPopover.contentViewController = contentViewController;
    [FSSuggestionStubController sharedInstance].delegate = self;
    
    //prepare data
    NSIndexSet *indexes = [_suggestView.tableView selectedRowIndexes];
    FSSuggestionCellModel* model = _filteredItems[[indexes firstIndex]];
    [[FSSuggestionStubController sharedInstance] configWithContentView:self.nextPopover.contentViewController.view withItems:model.stubs];
    
    NSRect positionRect = _suggestView.tableView.bounds;
    positionRect.size.height = 18;
    [self.nextPopover showRelativeToRect:positionRect ofView:_suggestView.tableView preferredEdge:NSRectEdgeMaxX];
}

- (void)detectStubHide
{
    [self.nextPopover close];
}

- (void)onStubItemSelected:(NSArray*)items
{
    [self.nextPopover close];
    [self.popover close];
    
    if (_delegate != nil) {
        [_delegate onItemSelected:items];
    }
}


@end
