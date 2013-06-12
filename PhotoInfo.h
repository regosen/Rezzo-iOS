//
//  PhotoInfo.h
//  Rezzo
//
//  Created by Rego on 6/1/13.
//  Copyright (c) 2013 Regaip Sen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import "Brain.h"

@interface PhotoInfo : NSObject

@property (nonatomic, strong) NSString* title;
@property (nonatomic, strong) NSString* notes;

@property (nonatomic) CLLocationCoordinate2D location;
@property (nonatomic, strong) UIImage* image;

@property (nonatomic, strong) NSMutableDictionary* resources;

#if USING_CUSTOM_CATEGORIES
@property (nonatomic, strong) NSMutableDictionary* customResources;
#endif

- (NSString *) categoryString;
- (NSString *) jsonString;

@end
