//
//  FSPopTableViewController.m
//  FastStub
//
//  Created by gao feng on 16/5/27.
//  Copyright © 2016年 music4kid. All rights reserved.
//

#import "FSPopTableViewController.h"
#import "FSPopTableView.h"
#import "FSTableViewModel.h"
#import "NSTextView+Operations.h"

#define _PopMgr [FSPopManager sharedInstance]

@interface FSPopManager : NSObject <NSPopoverDelegate>

+ (instancetype)sharedInstance;

@property (nonatomic, strong) NSMutableArray*                 pops;
@property (nonatomic, strong) NSMutableArray*                 popCtrls;


@end

@implementation FSPopManager

+ (instancetype)sharedInstance
{
    static FSPopManager* instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [FSPopManager new];
    });
    return instance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.pops = @[].mutableCopy;
        self.popCtrls = @[].mutableCopy;
    }
    return self;
}

- (NSPopover*)getAnotherPop
{
    NSPopover* pop;
    
    pop = [[NSPopover alloc] init];
    pop.appearance = NSPopoverAppearanceMinimal;
    pop.animates = false;
    pop.behavior = NSPopoverBehaviorTransient;
    pop.delegate = self;
    
    [self.pops addObject:pop];
    
    return pop;
}

@end


@interface FSPopTableViewController () <NSTableViewDelegate, NSTableViewDataSource, FSPopTableViewTableDelegate>
@property (nonatomic, strong) NSMutableArray*                       items;
@property (nonatomic, strong) FSPopTableView*                       customView;
@property (nonatomic, weak)   NSPopover*                            popHolder;

@end

@implementation FSPopTableViewController

+ (instancetype)showPopWithinView:(NSView*)view withItems:(NSArray*)items {
    FSPopTableViewController* c = [FSPopTableViewController new];
    
    NSPopover* pop = [_PopMgr getAnotherPop];
    
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSViewController* contentViewController = [[NSViewController alloc] initWithNibName:@"FSTableView" bundle:bundle];
    pop.contentViewController = contentViewController;
    
    c.popHolder = pop;
    [c configWithView:pop.contentViewController.view withItems:items];
    
    if (!pop.isShown) {
        NSRect displayFrame = view.frame;
        if([view isKindOfClass:[NSTextView class]]) {
            displayFrame = [(NSTextView*)view mhFrameForCaret];
        }
        [pop showRelativeToRect:displayFrame
                                  ofView:view
                           preferredEdge:NSMinYEdge];
    }
    
    [_PopMgr.popCtrls addObject:c];
    
    return c;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        
    }
    return self;
}


- (void)configWithView:(NSView*)view withItems:(NSArray*)items
{
    self.items = items.mutableCopy;
    _customView = (FSPopTableView*)view;
    
    //config table view
    _customView.tableView.dataSource = self;
    _customView.tableView.delegate = self;
    _customView.tableView.allowsMultipleSelection = true;
    
    _customView.tableView.target = self;
    _customView.tableView.doubleAction = @selector(onEnterKeyClicked);
    _customView.tableView.selectionHighlightStyle = NSTableViewSelectionHighlightStyleNone;
    _customView.tableView.keyDelegate = self;
    
    [_customView.tableView reloadData];
    [_customView.tableView scrollRowToVisible:0];
    
    NSIndexSet *set = [NSIndexSet indexSetWithIndex:0];
    [_customView.tableView selectRowIndexes:set byExtendingSelection:NO];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

#pragma mark- NSTableViewDataSource
- (BOOL)tableView:(NSTableView *)aTableView shouldEditTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
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
    
    FSTableViewModel* model = _items[row];
    NSString* text = model.text;
    
    text = [NSString stringWithFormat:@"    %@", text];
    
    return text;
}

- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
    
    if (rowIndex > _items.count-1) {
        return;
    }
    
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

- (void)onEnterKeyClicked
{
    NSIndexSet *indexes = [_customView.tableView selectedRowIndexes];
    
    if ([indexes count] > 0) {
        
        NSMutableArray* items = @[].mutableCopy;
        [indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
            
            if (idx <= _items.count -1) {
                [items addObject:_items[idx]];
            }
        }];
        
        [self.popHolder close];
        
//        [_PopMgr.popCtrls removeObject:self];
        
        if (_delegate != nil) {
            [_delegate onPopTableViewItemsSelected:items];
        }
    }
}

@end
