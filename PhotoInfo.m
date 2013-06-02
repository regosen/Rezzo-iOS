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
        self.naturalResources = [[NSArray alloc] init];
        self.infrastructureResources = [[NSArray alloc] init];
        self.skilledResources = [[NSArray alloc] init];
    }
    return self;
}

- (NSString *) categoryString
{
    NSMutableArray* descArray = [[NSMutableArray alloc] init];
    
    if (self.naturalResources.count > 0)
    {
        [descArray addObject:[self.naturalResources componentsJoinedByString:@", "]];
    }
    if (self.infrastructureResources.count > 0)
    {
        [descArray addObject:[self.infrastructureResources componentsJoinedByString:@", "]];
    }
    if (self.skilledResources.count > 0)
    {
        [descArray addObject:[self.skilledResources componentsJoinedByString:@", "]];
    }
    
    return (descArray.count == 0) ? @"(no categories)" : [descArray componentsJoinedByString:@", "];
}

- (NSString *) jsonString
{
    NSMutableDictionary* dict = [[NSMutableDictionary alloc] init];
    [dict setObject:self.title forKey:@"title"];
    [dict setObject:self.notes forKey:@"notes"];
    [dict setObject:self.naturalResources forKey:@"naturalResources"];
    [dict setObject:self.infrastructureResources forKey:@"infrastructureResources"];
    [dict setObject:self.skilledResources forKey:@"skilledResources"];
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
