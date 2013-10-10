//
//  MainViewController.m
//  Rezzo
//
//  Created by Rego on 5/16/13.
//  Copyright (c) 2013 Regaip Sen. All rights reserved.
//

#import "MainViewController.h"
#import "DescriptionViewController.h"
#import "Brain.h"
#import <MobileCoreServices/MobileCoreServices.h>

#import <AssetsLibrary/ALAsset.h>
#import <AssetsLibrary/ALAssetRepresentation.h>
#import <ImageIO/CGImageSource.h>
#import <ImageIO/CGImageProperties.h>
#import <ImageIO/CGImageDestination.h>

@interface MainViewController () <UINavigationControllerDelegate, UIImagePickerControllerDelegate, UploadControllerDelegate>

@property (nonatomic, strong) CLLocationManager* locationManager;
@property (nonatomic, weak) DescriptionViewController* dvc;

@property (nonatomic, strong) UIAlertView *alertView;
@property (nonatomic, strong) UIActivityIndicatorView* spinner;

@property (nonatomic, strong) UIPopoverController *iPadPopover;

@end


@implementation MainViewController

#define WEBAPP_URL [NSURL URLWithString:@"http://codeforsanfrancisco.org/Mobile-Fusion-Tables/RezzoTanzania.html"]

#pragma mark - UI callbacks

- (void) viewWillAppear:(BOOL)animated
{
    [self.tableView reloadData];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // show splash screen view at first launch
    NSUserDefaults* userDefs = [NSUserDefaults standardUserDefaults];
    NSNumber* hasLaunched = [userDefs objectForKey:@"FirstLaunch"];
    if (!hasLaunched)
    {
        [self performSegueWithIdentifier:@"Splash" sender:self];
        
        [userDefs setObject:[NSNumber numberWithBool:YES] forKey:@"FirstLaunch"];
        [userDefs synchronize];
    }

    
	// add top bar button items
    
    UIBarButtonItem *searchButton          = [[UIBarButtonItem alloc]
                                              initWithBarButtonSystemItem:UIBarButtonSystemItemSearch
                                              target:self action:@selector(openSearchApp:)];
    
    UIBarButtonItem *uploadButton          = [[UIBarButtonItem alloc]
                                           initWithTitle:@"Upload" style:UIBarButtonItemStylePlain
                                           target:self action:@selector(uploadPhotos:)];
    
    UIBarButtonItem *mapButton          = [[UIBarButtonItem alloc]
                                            initWithTitle:@"Map" style:UIBarButtonItemStylePlain 
                                            target:self action:@selector(mapPhotos:)];
    
    UIBarButtonItem *cameraButton          = [[UIBarButtonItem alloc]
                                           initWithBarButtonSystemItem:UIBarButtonSystemItemCamera
                                           target:self action:@selector(addImageFromCamera:)];
    
    UIBarButtonItem *addButton          = [[UIBarButtonItem alloc]
                                           initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                           target:self action:@selector(addImageFromLibrary:)];
    
    self.navigationItem.leftBarButtonItems =
    [NSArray arrayWithObjects:addButton, cameraButton, nil];
    
    self.navigationItem.rightBarButtonItems =
    [NSArray arrayWithObjects:uploadButton, mapButton, searchButton, nil];
    
    // init locationManager (for camera uploads)
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.distanceFilter = kCLDistanceFilterNone;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters; // 100 m
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"Detail"])
    {
        UITabBarController* tbc = segue.destinationViewController;
        self.dvc = tbc.childViewControllers[0];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - top bar button helpers

- (UIActivityIndicatorView*) startSpinner:(UIView*)view
{
    UIActivityIndicatorView* spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    CGRect frame = spinner.frame;
    frame.origin.x = view.bounds.size.width / 2 - frame.size.width / 2;
    frame.origin.y = view.bounds.size.height / 2 - frame.size.height / 2;
    frame.origin.y += 10; // make room for title
    spinner.frame = frame;
    [view addSubview:spinner];
    [spinner startAnimating];
    return spinner;
}

- (void)uploadPhotos:(id)sender
{
    if ([[Brain get] photos].count == 0)
    {
        // no photos available; pop up alert
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"No pictures available yet" message:@"Please add entries from album or camera before uploading." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        
        [alertView show];
    }
    else
    {
        self.alertView = [[UIAlertView alloc] initWithTitle:@"Uploading..." message:@"" delegate:nil cancelButtonTitle:nil otherButtonTitles:nil, nil];
        
        [self.alertView show];
        self.spinner = [self startSpinner:self.alertView];
        
        [Brain uploadPhotos:self];
    }
}

- (void) onRequestComplete:(NSData*)response
{
    [self.alertView dismissWithClickedButtonIndex:0 animated:YES];
    NSString* errorMessage = [Brain parseServerResponse:response];
    // HACK: ignore server error about converting array into string- it still succeeds
    if (errorMessage == nil || [errorMessage rangeOfString:@"can't convert Array into String"].location != NSNotFound)
    {
        // success
        [TestFlight passCheckpoint:@"Finished uploading"];
        [Brain get].photos = [[NSArray alloc] init];
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Done!" message:@"" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        
        [alertView show];
        [self.tableView reloadData];
    }
    else
    {
        // fail
        NSLog(@"%@", errorMessage);
        
        [Brain alertWebView:self.view message:errorMessage title:@"Couldn't post stats due to the following error:"];
    }
    
    [self.spinner stopAnimating];
    [self.spinner removeFromSuperview];
}

- (void)openSearchApp:(id)sender
{
    [[UIApplication sharedApplication] openURL:WEBAPP_URL];
}

- (void)mapPhotos:(id)sender
{
    [Brain deselectPhoto];
    [self performSegueWithIdentifier:@"Map Photos" sender:self];
}

#pragma mark - Image Picker goodies

- (void)addImageFromSource:(UIImagePickerControllerSourceType)sourceType {
    if ([UIImagePickerController isSourceTypeAvailable:sourceType]) {
        NSArray *mediaTypes = [UIImagePickerController availableMediaTypesForSourceType:sourceType];
        if ([mediaTypes containsObject:(NSString *)kUTTypeImage]) {
            UIImagePickerController *picker = [[UIImagePickerController alloc] init];
            picker.delegate = self;
            
            picker.sourceType = sourceType;
            picker.mediaTypes = [NSArray arrayWithObject:(NSString *)kUTTypeImage];
            picker.allowsEditing = YES;
            picker.navigationBar.opaque = true;
            
            // following block posted by phix23 on stackoverflow: iPad photo album image picker requires popover
            if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
            {
                UIPopoverController *popover = [[UIPopoverController alloc] initWithContentViewController:picker];
                [popover presentPopoverFromRect:CGRectMake(0,0,400.0,400.0) inView:self.view permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
                self.iPadPopover = popover;
            }
            else
            {
                [self presentViewController:picker animated:YES completion:nil];
            }
        }
    }
}

- (void)addImageFromCamera:(UIBarButtonItem *)sender {
#if TARGET_IPHONE_SIMULATOR
    // no camera in simulator, use dummy photo data
    PhotoInfo* newPhoto = [[PhotoInfo alloc] init];
    newPhoto.location = self.locationManager.location.coordinate;
    [Brain addAndSelectPhoto:newPhoto];
    [self performSegueWithIdentifier:@"Detail" sender:self];
#else
    [TestFlight passCheckpoint:@"Using camera"];
    [self.locationManager startUpdatingLocation];
    [self addImageFromSource:UIImagePickerControllerSourceTypeCamera];
    [self.locationManager stopUpdatingLocation];
#endif
}

- (void)addImageFromLibrary:(UIBarButtonItem *)sender {
#if TARGET_IPHONE_SIMULATOR
    // no library in simulator, use dummy photo data
    PhotoInfo* newPhoto = [[PhotoInfo alloc] init];
    newPhoto.location = self.locationManager.location.coordinate;
    [Brain addAndSelectPhoto:newPhoto];
    [self performSegueWithIdentifier:@"Detail" sender:self];
#else
    [TestFlight passCheckpoint:@"Using photo library"];
    [self addImageFromSource:UIImagePickerControllerSourceTypePhotoLibrary];
#endif

}

- (void)dismissImagePicker
{
    if (self.iPadPopover)
    {
        [self.iPadPopover dismissPopoverAnimated:YES];
        self.iPadPopover = nil;
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker
didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *image = [info objectForKey:UIImagePickerControllerEditedImage];
    if (!image) image = [info objectForKey:UIImagePickerControllerOriginalImage];
    if (image) {
        
        // HACK: direct camera images don't have GPS data in their metadata
        // so we have to use locationManager instead
        if (picker.sourceType == UIImagePickerControllerSourceTypeCamera)
        {
            PhotoInfo* newPhoto = [[PhotoInfo alloc] init];
            newPhoto.image = image;
            newPhoto.location = self.locationManager.location.coordinate;
            
            if (newPhoto.location.latitude == 0 && newPhoto.location.longitude == 0)
            {
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Photo is missing GPS data" message:@"Please ensure Location Services is On (under Settings->Privacy for Photo and Rezzo)." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                
                [alertView show];
            }
            else
            {
                [Brain addAndSelectPhoto:newPhoto];
                [self performSegueWithIdentifier:@"Detail" sender:self];
            }
            
            [self dismissImagePicker];
            return;
        }
        
        // following block posted by moosgummi on stackoverflow: extract GPS data from image metadata
        ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
        [library assetForURL:[info objectForKey:UIImagePickerControllerReferenceURL]
                 resultBlock:^(ALAsset *asset) {
                     
                     ALAssetRepresentation *image_representation = [asset defaultRepresentation];
                     
                     // create a buffer to hold image data
                     uint8_t *buffer = (Byte*)malloc(image_representation.size);
                     NSUInteger length = [image_representation getBytes:buffer fromOffset: 0.0  length:image_representation.size error:nil];
                     
                     if (length != 0)  {
                         
                         // buffer -> NSData object; free buffer afterwards
                         NSData *adata = [[NSData alloc] initWithBytesNoCopy:buffer length:image_representation.size freeWhenDone:YES];
                         
                         // identify image type (jpeg, png, RAW file, ...) using UTI hint
                         NSDictionary* sourceOptionsDict = [NSDictionary dictionaryWithObjectsAndKeys:(id)[image_representation UTI] ,kCGImageSourceTypeIdentifierHint,nil];
                         
                         // create CGImageSource with NSData
                         CGImageSourceRef sourceRef = CGImageSourceCreateWithData((__bridge CFDataRef) adata,  (__bridge CFDictionaryRef) sourceOptionsDict);
                         
                         // get imagePropertiesDictionary
                         CFDictionaryRef imagePropertiesDictionary;
                         imagePropertiesDictionary = CGImageSourceCopyPropertiesAtIndex(sourceRef,0, NULL);
                         
                         // get exif data
                         CFDictionaryRef gpsRef = (CFDictionaryRef)CFDictionaryGetValue(imagePropertiesDictionary, kCGImagePropertyGPSDictionary);
                         NSDictionary *gps_dict = (__bridge NSDictionary*)gpsRef;
                         PhotoInfo* newPhoto = [[PhotoInfo alloc] init];
                         newPhoto.image = image;
                         CLLocationCoordinate2D location;
                         
                         location.latitude = [[gps_dict objectForKey:@"Latitude"] doubleValue];
                         if ([[gps_dict objectForKey:@"LatitudeRef"] isEqualToString:@"S"])
                         {
                             location.latitude = -location.latitude;
                         }
                         location.longitude = [[gps_dict objectForKey:@"Longitude"] doubleValue];
                         if ([[gps_dict objectForKey:@"LongitudeRef"] isEqualToString:@"W"])
                         {
                             location.longitude = -location.longitude;
                         }
                         if (location.latitude == 0 && location.longitude == 0)
                         {
                             UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Photo is missing GPS data" message:@"Please ensure Location Services is On (under Settings->Privacy for Photo and Rezzo)." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                             
                             [alertView show];
                         }
                         else
                         {
                             newPhoto.location = location;
                             [Brain addAndSelectPhoto:newPhoto];
                             [self performSegueWithIdentifier:@"Detail" sender:self];
                         }
                         
                         CFRelease(imagePropertiesDictionary);
                         CFRelease(sourceRef);
                     }
                     else {
                         NSLog(@"image_representation buffer length == 0");
                     }
                 }
                failureBlock:^(NSError *error) {
                    NSLog(@"couldn't get asset: %@", error);
                }
         ];
        
    }
    [self dismissImagePicker];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissImagePicker];
}

#pragma mark - Table View callbacks

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[[Brain get] photos] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Picture";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    PhotoInfo* photoInfo = [[[Brain get] photos] objectAtIndex:indexPath.row];
    
    cell.textLabel.text = photoInfo.title;
    cell.detailTextLabel.text = photoInfo.categoryString;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    id photo = [[[Brain get] photos] objectAtIndex:indexPath.row];
    [Brain selectPhoto:photo];
    [self.dvc updateView];
}

@end
