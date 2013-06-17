//
//  Brain.m
//  Rezzo
//
//  Created by Rego on 5/17/13.
//  Copyright (c) 2013 Regaip Sen. All rights reserved.
//

#import "Brain.h"
#import "PhotoInfo.h"

@interface Brain() <NSURLConnectionDelegate>

@property (nonatomic, weak) id<UploadControllerDelegate> delegate;
@property (nonatomic, strong) NSDictionary* resources;
@property (nonatomic, strong) NSUserDefaults* userDefs;
@property (nonatomic, strong) NSString* lastRegion;

@end


@implementation Brain

static Brain *sInstance;

#define SERVER_URL @"http://47yf.localtunnel.com"
#define RESOURCES_KEY  @"resources"
#define LAST_REGION_KEY  @"last_region"
#define REGIONS_KEY  @"regions"

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

+ (void) uploadPhotos:(id <UploadControllerDelegate>)delegate
{
    sInstance.delegate = delegate;
    dispatch_queue_t downloadQueue = dispatch_queue_create("flickr downloader", NULL);
    dispatch_async(downloadQueue, ^{
        
#if 0 // for printing instead of uploading data
        for (PhotoInfo* photo in sInstance.photos)
        {
            NSLog(@"%@", [photo jsonString]);
        }
        return;
#endif
        
        
        // following block posted by robhasacamera on stackoverflow: HTTP post of UIImage and params to webserver
        NSMutableURLRequest *uploadRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:SERVER_URL] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:30.0];
        
        [uploadRequest setHTTPMethod:@"POST"];
        
        // just some random text that will never occur in the body
        NSString *stringBoundary = @"0xKhTmLbOuNdArY---This_Is_ThE_BoUnDaRyy---pqo";
        
        // header value
        NSString *headerBoundary = [NSString stringWithFormat:@"multipart/form-data; boundary=%@",
                                    stringBoundary];
        
        // set header
        [uploadRequest addValue:headerBoundary forHTTPHeaderField:@"Content-Type"];
        
        //add body
        NSMutableData *postBody = [NSMutableData data];
        //NSLog(@"body made");
        
        int index=0;
        for (PhotoInfo* photo in sInstance.photos)
        {
            //metadata
            [postBody appendData:[[NSString stringWithFormat:@"--%@\r\n", stringBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
            [postBody appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"rezzo_entry_%d\"\r\n\r\n", index] dataUsingEncoding:NSUTF8StringEncoding]];
            [postBody appendData:[[photo jsonString] dataUsingEncoding:NSUTF8StringEncoding]];
            [postBody appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
            
            /*
             // TODO: upload image
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
            //NSLog(@"entry added");
            
            index++;
        }
        // final boundary
        [postBody appendData:[[NSString stringWithFormat:@"--%@--\r\n", stringBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
        
        // add body to post
        [uploadRequest setHTTPBody:postBody];
        
        //NSLog(@"body set");
        // pointers to some necessary objects
        NSHTTPURLResponse* response =[[NSHTTPURLResponse alloc] init];
        NSError* error = nil;
        
        // synchronous filling of data from HTTP POST response
        NSData *responseData = [NSURLConnection sendSynchronousRequest:uploadRequest returningResponse:&response error:&error];
        //NSLog(@"just sent request");
        
        if (error) {
            [delegate doneUploading:NO errorMessage:error.localizedDescription];
        }
        
        // convert data into string
        NSString *responseString __unused = [[NSString alloc] initWithBytes:[responseData bytes]
                                                             length:[responseData length]
                                                           encoding:NSUTF8StringEncoding];
        //NSLog(@"done");
        // see if we get a welcome result
#if DEBUG
        NSLog(@"%@", responseString);
#endif
        
        // success, clear local photo list
        sInstance.photos = [[NSArray alloc] init];
        [sInstance.delegate doneUploading:YES errorMessage:nil];
    });
}

@end