//
//  Brain.h
//  Rezzo
//
//  Created by Rego on 5/17/13.
//  Copyright (c) 2013 Regaip Sen. All rights reserved.
//

#ifndef Rezzo_Brain_h
#define Rezzo_Brain_h

#define USING_CUSTOM_CATEGORIES 1

@class PhotoInfo;

@protocol UploadControllerDelegate <NSObject>

- (void) doneUploading:(BOOL)success errorMessage:(NSString*)message;

@end

@interface Brain : NSObject


+ (Brain*)get;
+ (NSDictionary*) getResources:(BOOL)all;

+ (void) selectPhoto:(PhotoInfo*)photo;
+ (void) addAndSelectPhoto:(PhotoInfo*)photo;
+ (void) deselectPhoto;

+ (void) uploadPhotos:(id <UploadControllerDelegate>)delegate;

@property (nonatomic, strong) NSArray* photos;
@property (nonatomic, strong) PhotoInfo* selectedPhoto;

@end


#endif
