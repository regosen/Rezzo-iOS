//
//  Brain.h
//  Rezzo
//
//  Created by Rego on 5/17/13.
//  Copyright (c) 2013 Regaip Sen. All rights reserved.
//

#ifndef Rezzo_Brain_h
#define Rezzo_Brain_h

#include "TestFlight.h"

#define NSLog TFLog
#define USING_CUSTOM_CATEGORIES 0

@class PhotoInfo;

@protocol UploadControllerDelegate <NSObject>

- (void) onRequestComplete:(NSData*)response;

@end

@interface Brain : NSObject

+ (Brain*)get;

+ (NSDictionary*) getResources:(BOOL)all;

+ (void) selectPhoto:(PhotoInfo*)photo;
+ (void) addAndSelectPhoto:(PhotoInfo*)photo;
+ (void) deselectPhoto;

+ (NSString*) getLastRegion;
+ (void) setLastRegion:(NSString*)region;

+ (void) uploadPhotos:(id <UploadControllerDelegate>)delegate;
+ (NSString*) parseServerResponse:(NSData*)response;

@property (nonatomic, strong) NSArray* regions;
@property (nonatomic, strong) NSArray* photos;
@property (nonatomic, strong) PhotoInfo* selectedPhoto;

@end


#endif
