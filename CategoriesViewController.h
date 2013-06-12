//
//  CategoriesViewController.h
//  Rezzo
//
//  Created by Rego on 6/1/13.
//  Copyright (c) 2013 Regaip Sen. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CategoriesViewController : UITableViewController

- (void) setActiveCustomCell:(UITableViewCell*)cell;

@property (nonatomic, strong) NSString* currentCustomText;

@end
