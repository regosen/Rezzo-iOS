//
//  DescriptionViewController.h
//  Rezzo
//
//  Created by Rego on 6/1/13.
//  Copyright (c) 2013 Regaip Sen. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DescriptionViewController : UIViewController <UITextFieldDelegate, UITextViewDelegate>
@property (weak, nonatomic) IBOutlet UITextField *titleField;
@property (weak, nonatomic) IBOutlet UITextView *notesField;

- (void) updateView;

@end
