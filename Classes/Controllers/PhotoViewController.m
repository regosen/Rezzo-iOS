//
//  PictureViewController.m
//  Rezzo
//
//  Created by Rego on 6/1/13.
//  Copyright (c) 2013 Regaip Sen. All rights reserved.
//

#import "PhotoViewController.h"
#import "Brain.h"

@interface PhotoViewController() <UIScrollViewDelegate>
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (strong, nonatomic) UIImageView *imageView;

@property (nonatomic, strong) PhotoInfo* photoInfo;

@end

@implementation PhotoViewController


#pragma mark - helper methods

- (void)update:(PhotoInfo *)photoInfo
{
    if (self.photoInfo != photoInfo)
    {
        self.photoInfo = photoInfo;
        [self resetImage];
    }
}

- (void)resetImage
{
    if (self.scrollView) {
        self.scrollView.contentSize = CGSizeZero;
        
        if (self.photoInfo.image) {
            self.imageView.image = self.photoInfo.image;
            CGSize imageSize = self.imageView.image.size;
            self.scrollView.contentSize = imageSize;
            self.imageView.frame = CGRectMake(0, 0, imageSize.width, self.imageView.image.size.height);
                    
            // determine scale necessary to fill screen with photo (like AspectFill)
            CGSize screenSize = self.view.bounds.size;
            CGFloat zoomScale = MAX(screenSize.width/imageSize.width, screenSize.height/imageSize.height);
            self.scrollView.zoomScale = zoomScale;
        }
    }
}

- (UIImageView *)imageView
{
    if (!_imageView) _imageView = [[UIImageView alloc] initWithFrame:CGRectZero];
    return _imageView;
}

#pragma mark - UI callbacks

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.scrollView addSubview:self.imageView];
    self.scrollView.delegate = self;
    self.scrollView.minimumZoomScale = 0.2;
    self.scrollView.maximumZoomScale = 5.0;
    [self update:[[Brain get] selectedPhoto]];
    [self resetImage];
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return self.imageView;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
    {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.translucent = NO;
}

- (void)viewDidUnload
{
    [self setImageView:nil];
    [self setScrollView:nil];
    [super viewDidUnload];
}

@end
