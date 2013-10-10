//
//  Brain.m
//  Rezzo
//
//  Created by Rego on 5/17/13.
//  Copyright (c) 2013 Regaip Sen. All rights reserved.
//

#import "Brain.h"
#import "PhotoInfo.h"

#import "CustomIOS7AlertView.h"

@interface Brain() <NSURLConnectionDelegate>

@property (nonatomic, weak) id<UploadControllerDelegate> delegate;
@property (nonatomic, strong) NSDictionary* resources;
@property (nonatomic, strong) NSUserDefaults* userDefs;
@property (nonatomic, strong) NSString* lastRegion;

@end


@implementation Brain

static Brain *sInstance;

#define SERVER_URL @"http://rezzo.herokuapp.com/ios"
#define RESOURCES_KEY  @"resources"
#define LAST_REGION_KEY  @"last_region"
#define REGIONS_KEY  @"regions"


+ (void) alertWebView:(UIView*)view message:(NSString*)message title:(NSString*)title
{
    if ([[UIDevice currentDevice].systemVersion floatValue] < 7.0)
    {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title message:@"\n\n\n\n\n\n\n\n\n\n" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        UIWebView* webView = [[UIWebView alloc] init];
        [webView setFrame:CGRectMake(12,75,260,200)];
        [webView loadHTMLString:message baseURL:nil];
        
        [alertView addSubview:webView];
        [alertView show];
    }
    else
    {
        NSString* messageWithTitle = [[NSMutableString alloc] initWithFormat:@"<p><b>%@</b></p>%@", title, message];
        
        CustomIOS7AlertView *alertView = [[CustomIOS7AlertView alloc] initWithParentView:view];
        
        UIWebView* webView = [[UIWebView alloc] init];
        [webView setFrame:CGRectMake(0,0,260,200)];
        [webView loadHTMLString:messageWithTitle baseURL:nil];
        [alertView setContainerView:webView];
        [alertView show];
    }
}


+ (void)initialize
{
    static BOOL initialized = NO;
    if(!initialized)
    {
        initialized = YES;
        sInstance = [[Brain alloc] init];
        sInstance.photos = [[NSArray alloc] init];
        sInstance.userDefs = [NSUserDefaults standardUserDefaults];
        
        // 1. get resource list from cache (if exists)
        NSDictionary* resources = [sInstance.userDefs objectForKey:RESOURCES_KEY];
        NSArray* regions = [sInstance.userDefs objectForKey:REGIONS_KEY];
        NSString* lastRegion = [sInstance.userDefs objectForKey:LAST_REGION_KEY];
        if (resources && regions && lastRegion)
        {
            sInstance.resources = resources;
            sInstance.regions = regions;
            sInstance.lastRegion = lastRegion;
        }
        else
        {
            // 2. otherwise, get static list that was bundled with app
            NSBundle *bundle = [NSBundle mainBundle];
            NSString *pListPath = [bundle pathForResource:@"Info" ofType:@"plist"];
            NSDictionary *dictionary = [[NSDictionary alloc] initWithContentsOfFile:pListPath];
            sInstance.regions = [dictionary objectForKey:@"Regions"];
            sInstance.resources = [dictionary objectForKey:@"Resources"];
            sInstance.lastRegion = [sInstance.regions objectAtIndex:0];
            NSRange tRange = [sInstance.lastRegion rangeOfString:@"\t"];
            if (tRange.location != NSNotFound)
            {
                sInstance.lastRegion = [sInstance.lastRegion substringToIndex:tRange.location];
                NSMutableArray *fixedRegions = [sInstance.regions mutableCopy];
                [fixedRegions setObject:sInstance.lastRegion atIndexedSubscript:0];
                sInstance.regions = fixedRegions;
            }
            [sInstance.userDefs setObject:sInstance.resources forKey:RESOURCES_KEY];
            [sInstance.userDefs setObject:sInstance.regions forKey:REGIONS_KEY];
            [sInstance.userDefs synchronize];
        }
        
        // 3. (TODO): query latest list from server (asychronously) to update list and cache
    }
}

+ (Brain*)get
{
    return sInstance;
}

#pragma mark - API

+ (NSDictionary*) getResources:(BOOL)all
{
    return (all) ? sInstance.resources : sInstance.selectedPhoto.resources;
}

+ (void) selectPhoto:(PhotoInfo*)photo
{
    sInstance.selectedPhoto = photo;
}

+ (void) addAndSelectPhoto:(PhotoInfo*)photo
{
    NSMutableArray* newList = [sInstance.photos mutableCopy];
    [newList addObject:photo];
    sInstance.photos = newList;
    sInstance.selectedPhoto = photo;
}

+ (void) deselectPhoto
{
    sInstance.selectedPhoto = nil;
}

+ (NSString*) getLastRegion
{
    return sInstance.lastRegion;
}

+ (void) setLastRegion:(NSString*)region
{
    sInstance.lastRegion = region;
    [sInstance.userDefs setObject:region forKey:LAST_REGION_KEY];
}

+ (NSString*) parseServerResponse:(NSData*)response
{
    NSError *error = nil;
    id object = [NSJSONSerialization
                 JSONObjectWithData:response
                 options:0
                 error:&error];
    
    if (error || ![object isKindOfClass:[NSDictionary class]])
    {
        return [[NSString alloc] initWithBytes:[response bytes] length:[response length] encoding:NSUTF8StringEncoding];
    }
    else
    {
        NSDictionary *results = object;
        NSDictionary* errors = [results objectForKey:@"errors"];
        if (errors)
        {
            NSMutableArray* errorList = [[NSMutableArray alloc] init];
            for (NSString* key in errors) {
                NSArray* values = [errors objectForKey:key];
                if (values)
                {
                    for (NSString* value in values)
                    {
                        [errorList addObject:[NSString stringWithFormat:@"%@ %@", key, value]];
                    }
                }
            }
            return [errorList componentsJoinedByString:@"\n"];
        }
        else if ([results objectForKey:@"user"] == nil)
        {
            return [[NSString alloc] initWithBytes:[response bytes] length:[response length] encoding:NSUTF8StringEncoding];
        }
    }
    return nil; // no error
}


+ (void) uploadPhotos:(id <UploadControllerDelegate>)delegate
{
    [TestFlight passCheckpoint:[NSString stringWithFormat:@"Uploading %d photos", sInstance.photos.count]];
    
    sInstance.delegate = delegate;
    dispatch_queue_t downloadQueue = dispatch_queue_create("resource uploader", NULL);
    dispatch_async(downloadQueue, ^{
        
        for (PhotoInfo* photo in sInstance.photos)
        {
            NSLog(@"%@", [photo jsonString]);
        }        
        // following block posted by robhasacamera on stackoverflow: HTTP post of UIImage and params to webserver
        NSMutableURLRequest *uploadRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:SERVER_URL] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:30.0];
        
        [uploadRequest setHTTPMethod:@"POST"];
        NSString *stringBoundary = @"0xKhTmLbOuNdArY---This_Is_ThE_BoUnDaRyy---pqo";
        NSString *headerBoundary = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", stringBoundary];
        [uploadRequest addValue:headerBoundary forHTTPHeaderField:@"Content-Type"];
        NSMutableData *postBody = [NSMutableData data];
        
        int index=0;
        for (PhotoInfo* photo in sInstance.photos)
        {
            //metadata
            [postBody appendData:[[NSString stringWithFormat:@"--%@\r\n", stringBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
            [postBody appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"rezzo_entry_%d\"\r\n\r\n", index] dataUsingEncoding:NSUTF8StringEncoding]];
            [postBody appendData:[[photo jsonString] dataUsingEncoding:NSUTF8StringEncoding]];
            [postBody appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
            
            /*
             // TODO: We might consider uploading the image as well in the future, but not for now.
            //image
            [postBody appendData:[[NSString stringWithFormat:@"--%@\r\n", stringBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
            [postBody appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"rezzo_item_image_%d\"; filename=\"image%d.jpg\"\r\n", index, index] dataUsingEncoding:NSUTF8StringEncoding]];
            [postBody appendData:[@"Content-Type: image/jpeg\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
            [postBody appendData:[@"Content-Transfer-Encoding: binary\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
            
            // get the image data from main bundle directly into NSData object
            NSData *imgData = UIImageJPEGRepresentation(photo.image, 1.0);
            // add it to body
            [postBody appendData:imgData];
            [postBody appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
             */
            
            index++;
        }
        // final boundary
        [postBody appendData:[[NSString stringWithFormat:@"--%@--\r\n", stringBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [uploadRequest setHTTPBody:postBody];
        NSHTTPURLResponse* response =[[NSHTTPURLResponse alloc] init];
        NSError* error = nil;
        
        // synchronous filling of data from HTTP POST response
        NSData *responseData = [NSURLConnection sendSynchronousRequest:uploadRequest returningResponse:&response error:&error];
        NSLog(@"just sent request");
        
        if (error) {
            responseData = [error.localizedDescription dataUsingEncoding:NSUTF8StringEncoding];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [sInstance.delegate onRequestComplete:responseData];
        });
    });
}

@end