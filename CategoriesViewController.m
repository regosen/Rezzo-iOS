//
//  CategoriesViewController.m
//  Rezzo
//
//  Created by Rego on 6/1/13.
//  Copyright (c) 2013 Regaip Sen. All rights reserved.
//

#import "CategoriesViewController.h"
#import "Brain.h"

@implementation CategoriesViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)sender
{
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section)
    {
        case 0:
            return [[[Brain get] naturalResources] count];
            
        case 1:
            return [[[Brain get] infrastructureResources] count];
            
        case 2:
        default:
            return [[[Brain get] skilledResources] count];
            
    }
}

- (NSArray*) categoriesForIndexPath:(NSIndexPath*)indexPath
{
    NSArray* categories = nil;
    switch (indexPath.section)
    {
        case 0:
            categories = [[Brain get] naturalResources];
            break;
            
        case 1:
            categories = [[Brain get] infrastructureResources];
            break;
            
        case 2:
        default:
            categories = [[Brain get] skilledResources];
            break;
    }
    
    return categories;
}

- (NSString*) textForIndexPath:(NSIndexPath*)indexPath
{
    return [self categoriesForIndexPath:indexPath][indexPath.row];
}



- (NSArray*) selectedCategoriesForIndexPath:(NSIndexPath*)indexPath
{
    NSArray* categories = [[NSArray alloc] init];
    PhotoInfo* photoInfo = [[Brain get] selectedPhoto];
    switch (indexPath.section)
    {
        case 0:
            categories = photoInfo.naturalResources;
            break;
            
        case 1:
            categories = photoInfo.infrastructureResources;
            break;
            
        case 2:
        default:
            categories = photoInfo.skilledResources;
            break;
    }
    
    return categories;
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString* title = @"(Error)";
    switch (section)
    {
        case 0:
            title = @"Natural Resources";
            break;
            
        case 1:
            title = @"Infrastructure Resources";
            break;
            
        case 2:
        default:
            title = @"Skilled Resources";
            break;
    }
    return title;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Category";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    cell.textLabel.text = [self textForIndexPath:indexPath];
    UITableViewCellAccessoryType checkType = UITableViewCellAccessoryNone;
    NSArray* categories = [self selectedCategoriesForIndexPath:indexPath];
    for (NSString* category in categories)
    {
        if ([category isEqualToString:cell.textLabel.text])
        {
            checkType = UITableViewCellAccessoryCheckmark;
            break;
        }
    }
    cell.accessoryType = checkType;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    PhotoInfo* photo = [[Brain get] selectedPhoto];
    NSString* category = [self textForIndexPath:indexPath];
    NSArray* oldList = [self selectedCategoriesForIndexPath:indexPath];
    NSMutableArray* newList = nil;
    

    if([tableView cellForRowAtIndexPath:indexPath].accessoryType == UITableViewCellAccessoryCheckmark)
    {
        [tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryNone;
        
        newList = [[NSMutableArray alloc] init];
        for (NSString* curCategory in oldList)
        {
            if (![curCategory isEqualToString:category])
            {
                [newList addObject:curCategory];
            }
        }
    }
    else
    {
        [tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryCheckmark;
        
        newList = [oldList mutableCopy];
        [newList addObject:category];
    }
    
    switch (indexPath.section)
    {
        case 0:
            photo.naturalResources = newList;
            break;
            
        case 1:
            photo.infrastructureResources = newList;
            break;
            
        case 2:
        default:
            photo.skilledResources = newList;
            break;
    }
}

@end
