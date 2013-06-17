//
//  PhotoInfo.m
//  Rezzo
//
//  Created by Rego on 6/1/13.
//  Copyright (c) 2013 Regaip Sen. All rights reserved.
//

#import "PhotoInfo.h"

@implementation PhotoInfo

- (id)init {
    self = [super init];
    if (self) {
        self.title = DEFAULT_TITLE;
        self.region = [[NSString alloc] init];
        self.notes = [[NSString alloc] init];
        self.resources = [[NSMutableDictionary alloc] init];
#if USING_CUSTOM_CATEGORIES
        self.customResources = [[NSMutableDictionary alloc] init];
#endif
    }
    return self;
}

- (NSString *) categoryString
{
    NSMutableArray* descArray = [[NSMutableArray alloc] init];
    
    for (NSArray* categories in self.resources.allValues)
    {
        if (categories.count > 0)
        {
            [descArray addObject:[categories componentsJoinedByString:@", "]];
        }
    }
    
#if USING_CUSTOM_CATEGORIES
    for (NSArray* categories in self.customResources.allValues)
    {
        [descArray addObject:[categories componentsJoinedByString:@", "]];
    }
#endif
    
    return (descArray.count == 0) ? @"(no categories)" : [descArray componentsJoinedByString:@", "];
}

- (NSString *) jsonString
{
    NSMutableDictionary* dict = [[NSMutableDictionary alloc] init];
    [dict setObject:self.title forKey:@"title"];
    [dict setObject:self.region forKey:@"region"];
    [dict setObject:self.notes forKey:@"notes"];
    [dict setObject:self.resources forKey:@"resources"];
#if USING_CUSTOM_CATEGORIES
    [dict setObject:self.customResources forKey:@"customResources"];
#endif
    [dict setObject:[NSNumber numberWithDouble:self.location.latitude] forKey:@"latitude"];
    [dict setObject:[NSNumber numberWithDouble:self.location.longitude] forKey:@"longitude"];
    
    NSError *error;
    // options:NSJSONWritingPrettyPrinted
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict options:0 error:&error];
    
    if (!jsonData)
    {
        NSLog(@"JSON Failure: %@", error);
        return @"";
    }
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

@end
