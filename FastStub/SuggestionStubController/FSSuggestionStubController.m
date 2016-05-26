//
//  FSSuggestionStubController.m
//  FastStub
//
//  Created by gao feng on 16/5/18.
//  Copyright © 2016年 music4kid. All rights reserved.
//

#import "FSSuggestionStubController.h"
#import "FSSuggestionStubView.h"
#import "FSSuggestionCellModel.h"

@interface FSSuggestionStubController () <NSTableViewDelegate, NSTableViewDataSource>

@property (nonatomic, strong) NSMutableArray*                       items;
@property (nonatomic, strong) FSSuggestionStubView*                 stubView;


@end

@implementation FSSuggestionStubController

+ (instancetype)sharedInstance
{
    static FSSuggestionStubController* instance = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [FSSuggestionStubController new];
    });
    
    return instance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        
    }
    return self;
}

- (void)configWithContentView:(NSView*)view withItems:(NSArray*)items
{
    self.items = items.mutableCopy;
    _stubView = (FSSuggestionStubView*)view;
    
    //config table view
    _stubView.tableView.dataSource = self;
    _stubView.tableView.delegate = self;
    
    _stubView.tableView.target = self;
    _stubView.tableView.doubleAction = @selector(onItemSelected);
    _stubView.tableView.selectionHighlightStyle = NSTableViewSelectionHighlightStyleNone;
    
    [_stubView.tableView reloadData];
    [_stubView.tableView scrollRowToVisible:0];
    
    NSIndexSet *set = [NSIndexSet indexSetWithIndex:0];
    [_stubView.tableView selectRowIndexes:set byExtendingSelection:NO];
}


#pragma mark- NSTableViewDataSource
- (BOOL)tableView:(NSTableView *)aTableView shouldEditTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
    [self onItemSelected];
    return NO;
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return _items.count;
}

- (nullable id)tableView:(NSTableView *)tableView objectValueForTableColumn:(nullable NSTableColumn *)tableColumn row:(NSInteger)row
{
    if (row > _items.count-1) {
        return nil;
    }
    
    FSSuggestionStub* model = _items[row];
    NSString* text = model.cellText;
    
    text = [NSString stringWithFormat:@"    %@", text];
    
    return text;
}

- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
    
    if (rowIndex > _items.count-1) {
        return;
    }
    
//    FSSuggestionStub* model = _items[rowIndex];
    
    NSTextFieldCell *cell = aCell;
    [cell setTextColor:[NSColor colorWithWhite:6.0/255 alpha:1.0]];
    
    
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

- (void)onItemSelected
{
    NSIndexSet *indexes = [_stubView.tableView selectedRowIndexes];
    
    if ([indexes count] > 0) {
        
        NSMutableArray* items = @[].mutableCopy;
        [indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
            
            if (idx <= _items.count -1) {
                [items addObject:_items[idx]];
            }
        }];
        if (_delegate != nil) {
            [_delegate onStubItemSelected:items];
        }
    }
}



@end
