//
//  DescriptionViewController.m
//  Rezzo
//
//  Created by Rego on 6/1/13.
//  Copyright (c) 2013 Regaip Sen. All rights reserved.
//

#import "DescriptionViewController.h"
#import "Brain.h"
#import <QuartzCore/QuartzCore.h>

@implementation DescriptionViewController

- (void) viewDidLoad
{
    self.notesField.layer.borderWidth = 2.0f;
    self.notesField.layer.cornerRadius = 10.0f;
    self.notesField.layer.borderColor = [[UIColor lightGrayColor] CGColor];
}

- (void) viewWillAppear:(BOOL)animated {
    [self updateView];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidHide:) name:UIKeyboardDidHideNotification object:nil];
}

- (void) viewWillDisappear:(BOOL)animated {
    // register hiding of keyboard when "Back" button pressed
    [self keyboardDidHide:nil];
}

- (void) updateView
{
    PhotoInfo* photo = [[Brain get] selectedPhoto];
    self.titleField.text = photo.title;
    self.notesField.text = photo.notes;
    
}

- (void) keyboardDidHide:(id)sender
{
    PhotoInfo* photo = [[Brain get] selectedPhoto];
    photo.title = self.titleField.text;
    photo.notes = self.notesField.text;
}
    
- (BOOL)textFieldShouldReturn:(UITextField *)theTextField {
    if (theTextField == self.titleField)
    {
        [theTextField resignFirstResponder];
    }
    return YES;
}

- (BOOL)textView:(UITextView *)txtView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    if( [text rangeOfCharacterFromSet:[NSCharacterSet newlineCharacterSet]].location == NSNotFound ) {
        return YES;
    }
    [txtView resignFirstResponder];
    return NO;
}

@end
