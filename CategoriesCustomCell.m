//
//  CategoriesCustomCell.m
//  Rezzo
//
//  Created by Rego on 6/6/13.
//  Copyright (c) 2013 Regaip Sen. All rights reserved.
//

#import "CategoriesCustomCell.h"
#import "CategoriesViewController.h"

@implementation CategoriesCustomCell

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    CategoriesViewController* vc = (CategoriesViewController*)self.delegate;
    [vc beginEditingCustomCell:self];
}

- (BOOL)textFieldShouldReturn:(UITextField *)theTextField {
    [theTextField resignFirstResponder];
     
    CategoriesViewController* vc = (CategoriesViewController*)self.delegate;
    [vc endEditingCustomCell:self text:theTextField.text];
    return YES;
}

@end
