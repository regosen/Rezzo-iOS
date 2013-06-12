//
//  CategoriesCustomCell.h
//  Rezzo
//
//  Created by Rego on 6/6/13.
//  Copyright (c) 2013 Regaip Sen. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CategoriesCustomCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UITextField *customText;

@property (weak, nonatomic) UITableView* delegate;

@end
