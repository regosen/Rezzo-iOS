//
//  CategoriesViewController.m
//  Rezzo
//
//  Created by Rego on 6/1/13.
//  Copyright (c) 2013 Regaip Sen. All rights reserved.
//

#import "CategoriesViewController.h"
#import "Brain.h"
#import "PhotoInfo.h"
#import "CategoriesCustomCell.h"

@interface CategoriesViewController()

@property (nonatomic) NSInteger* customRowsPerSection;
@property (nonatomic, strong) NSIndexPath* currentCustomCell;

@end

@implementation CategoriesViewController


#pragma mark - delegate calls

- (void) setActiveCustomCell:(UITableViewCell*)cell
{
    self.currentCustomCell = [self.tableView indexPathForCell:cell];
}


#pragma mark - data helpers

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSArray* sortedSections = [[Brain getResources:YES].allKeys sortedArrayUsingComparator:^(NSString* obj1, NSString* obj2) {
        return [obj1 compare: obj2];
    }];
    
    return sortedSections[section];
}

- (NSArray*) listForSection:(NSInteger)section all:(BOOL)all
{
    NSString* key = [self tableView:nil titleForHeaderInSection:section];
    return [[Brain getResources:all] objectForKey:key];
}

- (NSString*) textForIndexPath:(NSIndexPath*)indexPath
{
    NSArray* list = [self listForSection:indexPath.section all:YES];
    list = [list sortedArrayUsingComparator:^(NSString* obj1, NSString* obj2) {
        return [obj1 compare: obj2];
    }];
    return list[indexPath.row];
}


#pragma mark - UI callbacks and helpers

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (!self.customRowsPerSection)
    {
        PhotoInfo* photo = [[Brain get] selectedPhoto];
        
        NSUInteger sections = [Brain getResources:YES].allKeys.count;
        self.customRowsPerSection = calloc(sections, sizeof(NSInteger));
        for (int i=0; i<sections; i++)
        {
#if USING_CUSTOM_CATEGORIES
            NSString* sectionName = [self tableView:nil titleForHeaderInSection:i];
            NSArray* categories = [photo.customResources objectForKey:sectionName];
            
            self.customRowsPerSection[i] = categories ? categories.count + 1 : 1;
#else
            self.customRowsPerSection[i] = 0;
#endif
        }
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)sender
{
    NSUInteger sections = [Brain getResources:YES].allKeys.count;
    return sections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self listForSection:section all:YES].count + self.customRowsPerSection[section]; // extra cells for typing custom values
}

- (void)updateCustomCell:(CategoriesCustomCell*)cell tableView:(UITableView *)tableView atIndexPath:(NSIndexPath*)indexPath
{
#if USING_CUSTOM_CATEGORIES
    PhotoInfo* photo = [[Brain get] selectedPhoto];
    
    cell.delegate = (UITableView*)self;
    NSString* sectionName = [self tableView:nil titleForHeaderInSection:indexPath.section];
    NSArray* categories = [photo.customResources objectForKey:sectionName];
    
    NSInteger customIndex = (indexPath.row - [self listForSection:indexPath.section all:YES].count);
    if (customIndex < categories.count)
    {
        cell.customText.text = [categories objectAtIndex:customIndex];
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    else
    {
        if ((self.currentCustomCell.row == indexPath.row)
            && (self.currentCustomCell.section == indexPath.section))
        {
            cell.customText.text = self.currentCustomText;
        }
        else
        {
            cell.customText.text = @"";
        }
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
#endif // USING_CUSTOM_CATEGORIES
}

- (void)updateRegularCell:(UITableViewCell*)cell tableView:(UITableView *)tableView atIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCellAccessoryType checkType = UITableViewCellAccessoryNone;
    cell.textLabel.text = [self textForIndexPath:indexPath];
    NSArray* categories = [self listForSection:indexPath.section all:NO];
    
    for (NSString* category in categories)
    {
        if ([category isEqualToString:cell.textLabel.text])
        {
            checkType = UITableViewCellAccessoryCheckmark;
            break;
        }
    }
    cell.accessoryType = checkType;
}
    
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    BOOL isCustomCell = (indexPath.row >= [self listForSection:indexPath.section all:YES].count);
    NSString *CellIdentifier = (isCustomCell) ? @"Custom" : @"Category";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    if (isCustomCell)
    {
        [self updateCustomCell:(CategoriesCustomCell*)cell tableView:tableView atIndexPath:indexPath];
    }
    else
    {
        [self updateRegularCell:cell tableView:tableView atIndexPath:indexPath];
    }
    
    return cell;
}

- (void)customCell:(CategoriesCustomCell*)cell tableView:(UITableView *)tableView atIndexPath:(NSIndexPath*)indexPath check:(BOOL)check
{
#if USING_CUSTOM_CATEGORIES
    PhotoInfo* photo = [[Brain get] selectedPhoto];
    NSString* cellText = cell.customText.text;
    if (cellText.length == 0)
    {
        return;
    }
    
    NSString* sectionName = [self tableView:nil titleForHeaderInSection:indexPath.section];
    
    NSArray* oldList = [photo.customResources objectForKey:sectionName];
    NSMutableArray* newList = nil;
    
    if (!check)
    {
        cell.accessoryType = UITableViewCellAccessoryNone;
        
        // recreate list without unchecked category
        newList = [[NSMutableArray alloc] init];
        for (NSString* curCategory in oldList)
        {
            if (![curCategory isEqualToString:cellText])
            {
                [newList addObject:curCategory];
            }
        }
        [photo.customResources setObject:newList forKey:[self tableView:nil titleForHeaderInSection:indexPath.section]];
        
        // update data
        cell.customText.text = @"";
        self.customRowsPerSection[indexPath.section] -= 1;
        self.currentCustomCell = nil;
        
        // update view
        [tableView beginUpdates];
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];
        [tableView endUpdates];
    }
    else
    {
        // check cell
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        
        // recreate list with unchecked category
        newList = oldList ? [oldList mutableCopy] : [[NSMutableArray alloc] init];
        [newList addObject:cellText];
        [photo.customResources setObject:newList forKey:[self tableView:nil titleForHeaderInSection:indexPath.section]];
        
        // update data
        self.customRowsPerSection[indexPath.section] += 1;
        NSAssert(self.currentCustomCell, @"currentCustomCell was nil");
        [cell.customText resignFirstResponder];
        self.currentCustomCell = nil;

        // update view
        NSIndexPath* nextPath = [NSIndexPath indexPathForRow:indexPath.row + 1 inSection:indexPath.section];
        [tableView beginUpdates];
        [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:nextPath] withRowAnimation:YES];
        [tableView endUpdates];
    }
#endif // USING_CUSTOM_CATEGORIES
}

- (void)regularCell:(UITableViewCell*)cell tableView:(UITableView *)tableView atIndexPath:(NSIndexPath*)indexPath check:(BOOL)check
{
    PhotoInfo* photo = [[Brain get] selectedPhoto];
    NSString* cellText = cell.textLabel.text;
    
    NSArray* oldList = [self listForSection:indexPath.section all:NO];
    NSMutableArray* newList = nil;
    
    if (!check)
    {
        // uncheck cell
        cell.accessoryType = UITableViewCellAccessoryNone;
        
        // recreate list without unchecked category
        newList = [[NSMutableArray alloc] init];
        for (NSString* curCategory in oldList)
        {
            if (![curCategory isEqualToString:cellText])
            {
                [newList addObject:curCategory];
            }
        }
    }
    else
    {
        // check cell
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        
        // recreate list with unchecked category
        newList = oldList ? [oldList mutableCopy] : [[NSMutableArray alloc] init];
        [newList addObject:cellText];
    }
    
    if (newList)
    {
        [photo.resources setObject:newList forKey:[self tableView:nil titleForHeaderInSection:indexPath.section]];
    }
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    BOOL wasChecked = ([tableView cellForRowAtIndexPath:indexPath].accessoryType == UITableViewCellAccessoryCheckmark);
    if (indexPath.row >= [self listForSection:indexPath.section all:YES].count)
    {
        [self customCell:(CategoriesCustomCell*)cell tableView:tableView atIndexPath:indexPath check:!wasChecked];
    }
    else
    {
        [self regularCell:cell tableView:tableView atIndexPath:indexPath check:!wasChecked];
    }
}

@end
