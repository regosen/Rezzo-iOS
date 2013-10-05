//
//  DescriptionViewController.m
//  Rezzo
//
//  Created by Rego on 6/1/13.
//  Copyright (c) 2013 Regaip Sen. All rights reserved.
//

#import "DescriptionViewController.h"
#import "Brain.h"
#import "PhotoInfo.h"
#import <QuartzCore/QuartzCore.h>

@implementation DescriptionViewController

#pragma mark - UIPickerView delegates

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent: (NSInteger)component
{
    return [[Brain get].regions count];
}

-(NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row   forComponent:(NSInteger)component
{
    return [[Brain get].regions objectAtIndex:row];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row   inComponent:(NSInteger)component
{
    PhotoInfo* photo = [[Brain get] selectedPhoto];
    photo.region = [[Brain get].regions objectAtIndex:row];
    [Brain setLastRegion:photo.region];
}

#pragma mark - UI callbacks

- (void) viewDidLoad
{
    self.notesField.layer.borderWidth = 2.0f;
    self.notesField.layer.cornerRadius = 10.0f;
    self.notesField.layer.borderColor = [[UIColor lightGrayColor] CGColor];
}

- (void) viewWillAppear:(BOOL)animated {
    self.navigationController.navigationBar.translucent = NO;
    [self updateView];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidHide:) name:UIKeyboardDidHideNotification object:nil];
}


- (void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    // register hiding of keyboard when "Back" button pressed
    [self keyboardDidHide:nil];
}

- (void) updateView
{
    PhotoInfo* photo = [[Brain get] selectedPhoto];
    self.titleField.text = [photo.title isEqualToString:DEFAULT_TITLE] ? @"" : photo.title;
    
    if ([self.regionField numberOfComponents] > 0)
    {
        NSArray* regions = [Brain get].regions;
        NSString* selRegion = (photo.region.length > 0) ? photo.region : [Brain getLastRegion];
        for (int i=0; i<regions.count; i++)
        {
            NSString* region = [regions objectAtIndex:i];
            if ([region isEqualToString:selRegion])
            {
                [self.regionField selectRow:i inComponent:0 animated:NO];
                break;
            }
        }
    }
    self.notesField.text = photo.notes;
}

- (void) keyboardDidHide:(id)sender
{
    PhotoInfo* photo = [[Brain get] selectedPhoto];
    photo.title = ([self.titleField.text length] == 0) ? DEFAULT_TITLE : self.titleField.text;
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
