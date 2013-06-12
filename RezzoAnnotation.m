//
//  RezzoAnnotation
//  Rezzo
//
//  Created by Rego on 6/1/13.
//  Copyright (c) 2013 Regaip Sen. All rights reserved.
//

#import "RezzoAnnotation.h"


@implementation RezzoAnnotation

+ (RezzoAnnotation *)getAnnotation:(PhotoInfo *)photo
{
    RezzoAnnotation *annotation = [[RezzoAnnotation alloc] init];
    annotation.info = photo;
    annotation.coordinate = photo.location;
    return annotation;
}

- (NSString *)title
{
    return (self.info.title && self.info.title.length > 0) ? self.info.title : @"(Untitled)";
}

- (NSString *)subtitle
{
    return self.info.categoryString;
}
@end

