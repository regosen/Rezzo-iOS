//
//  CategoriesViewController.h
//  Rezzo
//
//  Created by Rego on 6/1/13.
//  Copyright (c) 2013 Regaip Sen. All rights reserved.
//

#import <Foundation/Foundation.h>
#include "CategoriesCustomCell.h"


@protocol CustomCellControllerDelegate <NSObject>

- (void) beginEditingCustomCell:(CategoriesCustomCell*)cell;
- (void) endEditingCustomCell:(CategoriesCustomCell*)cell text:(NSString*)text;

@end

@interface CategoriesViewController : UITableViewController <CustomCellControllerDelegate>

@end
