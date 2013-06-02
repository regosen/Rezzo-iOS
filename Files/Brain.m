//
//  Brain.m
//  Rezzo
//
//  Created by Rego on 5/17/13.
//  Copyright (c) 2013 Regaip Sen. All rights reserved.
//

#import "Brain.h"

@interface Brain() <NSURLConnectionDelegate>

@property (nonatomic, weak) id<UploadControllerDelegate> delegate;

@end


@implementation Brain

static Brain *sInstance;

#define SERVER_URL @"http://47yf.localtunnel.com"

+ (void)initialize
{
    static BOOL initialized = NO;
    if(!initialized)
    {
        initialized = YES;
        sInstance = [[Brain alloc] init];
        sInstance.photos = [[NSArray alloc] init];
        
        NSBundle *bundle = [NSBundle mainBundle];
        NSString *pListPath = [bundle pathForResource:@"Rezzo-Info" ofType:@"plist"];
        NSDictionary *dictionary = [[NSDictionary alloc] initWithContentsOfFile:pListPath];
        
        sInstance.naturalResources = [dictionary objectForKey:@"Natural Resources"];
        sInstance.infrastructureResources = [dictionary objectForKey:@"Infrastructure Resources"];
        sInstance.skilledResources = [dictionary objectForKey:@"Skilled Resources"];
    }
}

+ (Brain*)get
{
    return sInstance;
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

+ (void) uploadPhotos:(id <UploadControllerDelegate>)delegate
{
    sInstance.delegate = delegate;
    dispatch_queue_t downloadQueue = dispatch_queue_create("flickr downloader", NULL);
    dispatch_async(downloadQueue, ^{
        
        // following block posted by robhasacamera on stackoverflow: HTTP post of UIImage and params to webserver
        NSMutableURLRequest *uploadRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:SERVER_URL]
                                                                   cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                               timeoutInterval:30.0];
        
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
        NSString *responseString = [[NSString alloc] initWithBytes:[responseData bytes]
                                                             length:[responseData length]
                                                           encoding:NSUTF8StringEncoding];
        //NSLog(@"done");
        // see if we get a welcome result
        //NSLog(@"%@", responseString);
                
        // success, clear local photo list
        sInstance.photos = [[NSArray alloc] init];
        [sInstance.delegate doneUploading:YES errorMessage:nil];
    });
}

@end