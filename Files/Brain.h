//
//  Brain.h
//  Rezzo
//
//  Created by Rego on 5/17/13.
//  Copyright (c) 2013 Regaip Sen. All rights reserved.
//

#ifndef Rezzo_Brain_h
#define Rezzo_Brain_h

#import "PhotoInfo.h"

@protocol UploadControllerDelegate <NSObject>

- (void) doneUploading:(BOOL)success errorMessage:(NSString*)message;

@end

@interface Brain : NSObject

+ (Brain*)get;

+ (void) selectPhoto:(PhotoInfo*)photo;
+ (void) addAndSelectPhoto:(PhotoInfo*)photo;
+ (void) deselectPhoto;

+ (void) uploadPhotos:(id <UploadControllerDelegate>)delegate;

@property (nonatomic, strong) NSArray* photos;
@property (nonatomic, strong) PhotoInfo* selectedPhoto;

@property (nonatomic, strong) NSArray* naturalResources;
@property (nonatomic, strong) NSArray* infrastructureResources;
@property (nonatomic, strong) NSArray* skilledResources;

@end


#endif
