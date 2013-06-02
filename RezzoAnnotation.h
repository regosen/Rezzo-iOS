//
//  RezzoAnnotation
//  Rezzo
//
//  Created by Rego on 6/1/13.
//  Copyright (c) 2013 Regaip Sen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import "PhotoInfo.h"


@interface RezzoAnnotation : NSObject <MKAnnotation>

@property (nonatomic, strong) PhotoInfo *info;
@property (nonatomic,readwrite,assign) CLLocationCoordinate2D   coordinate;

+ (RezzoAnnotation *)getAnnotation:(PhotoInfo *)photo;

@end
