//
//  MapViewController.m
//  Rezzo
//
//  Created by Rego on 6/1/13.
//  Copyright (c) 2013 Regaip Sen. All rights reserved.
//

#import "RezzoAnnotation.h"
#import "PhotoViewController.h"
#import "MapViewController.h"
#import "Brain.h"
#import "PhotoInfo.h"


@interface MapViewController() <MKMapViewDelegate>
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UILabel *latitudeLabel;
@property (weak, nonatomic) IBOutlet UILabel *longitudeLabel;

@end

@implementation MapViewController


- (void)updateMapView
{
    if (self.mapView.annotations) [self.mapView removeAnnotations:self.mapView.annotations];
    if (self.annotations) [self.mapView addAnnotations:self.annotations];
}

- (void)setMapView:(MKMapView *)mapView
{
    _mapView = mapView;
    [self updateMapView];
}

- (void)setAnnotations:(NSArray *)annotations
{
    _annotations = annotations;
    [self updateMapView];
    if (annotations.count > 0)
    {
        RezzoAnnotation* annotation = [annotations objectAtIndex:0];
        self.latitudeLabel.text = [NSString stringWithFormat:@"%g",annotation.info.location.latitude];
        self.longitudeLabel.text = [NSString stringWithFormat:@"%g",annotation.info.location.longitude];
    }
}

// update region to encompass all annotations
// NOTE: region will only expand so much
- (void) updateRegion
{
    if (self.mapView == nil)
    {
        return; // nothing to do yet
    }
    
    // This is needed for first load of view
    self.mapView.frame = self.view.bounds;
    self.mapView.autoresizingMask = self.view.autoresizingMask;
    
    // zoom out a bit if we're just showing one pin
    const double bufferScale = 2;
    CLLocationCoordinate2D minPoint, maxPoint;
    BOOL firstObj = YES;
    for (id annotObj in self.annotations)
    {
        RezzoAnnotation* curAnnot = (RezzoAnnotation*)annotObj;
        if (firstObj)
        {
            minPoint = curAnnot.coordinate;
            maxPoint = curAnnot.coordinate;
            firstObj = NO;
        }
        else
        {
            minPoint.latitude = MIN(minPoint.latitude, curAnnot.coordinate.latitude);
            minPoint.longitude = MIN(minPoint.longitude, curAnnot.coordinate.longitude);
            maxPoint.latitude = MAX(maxPoint.latitude, curAnnot.coordinate.latitude);
            maxPoint.longitude = MAX(maxPoint.longitude, curAnnot.coordinate.longitude);
        }
    }
    // using result of regionThatFits causes crash for large regions
    /*
    MKCoordinateRegion region, adjustedRegion;
    region.center.latitude = (minPoint.latitude + maxPoint.latitude) / 2;
    region.center.longitude = (minPoint.longitude + maxPoint.longitude) / 2;
    region.span.latitudeDelta = (maxPoint.latitude - minPoint.latitude) * bufferScale;
    region.span.longitudeDelta = (maxPoint.longitude - minPoint.longitude) * bufferScale;
    
    adjustedRegion = [self.mapView regionThatFits:region];
    */
    
    // get latitudinal and longitudinal distance in meters
    MKMapPoint minP = MKMapPointForCoordinate(minPoint);
    MKMapPoint maxP = MKMapPointForCoordinate(maxPoint);
    MKMapPoint maxPLat = maxP;
    MKMapPoint maxPLong = maxP;
    maxPLat.y = minP.y;
    maxPLong.x = minP.x;
    
    CLLocationCoordinate2D center;
    center.latitude = (minPoint.latitude + maxPoint.latitude) / 2;
    center.longitude = (minPoint.longitude + maxPoint.longitude) / 2;
    
    CLLocationDistance distLat = MKMetersBetweenMapPoints(minP, maxPLat);
    CLLocationDistance distLong = MKMetersBetweenMapPoints(minP, maxPLong);
    distLat = MAX(distLat, 2000);
    distLong = MAX(distLong, 2000);
    MKCoordinateRegion adjustedRegion = MKCoordinateRegionMakeWithDistance(center, distLat*bufferScale, distLong*bufferScale);
    
    [self.mapView setRegion:adjustedRegion animated:NO];
}

#pragma mark - UI Callbacks

- (void)mapView:(MKMapView *)mapView
 annotationView:(MKAnnotationView *)annotationView
didChangeDragState:(MKAnnotationViewDragState)newState
   fromOldState:(MKAnnotationViewDragState)oldState
{
    if (newState == MKAnnotationViewDragStateEnding)
    {
        [TestFlight passCheckpoint:@"Dragging map point"];
        RezzoAnnotation* annotation = annotationView.annotation;
        annotation.info.location = annotationView.annotation.coordinate;
        self.latitudeLabel.text = [NSString stringWithFormat:@"%g",annotation.info.location.latitude];
        self.longitudeLabel.text = [NSString stringWithFormat:@"%g",annotation.info.location.longitude];
    }
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
    MKPinAnnotationView *aView = (MKPinAnnotationView*)[mapView dequeueReusableAnnotationViewWithIdentifier:@"MapVC"];
    if (!aView) {
        aView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"MapVC"];
        if ([[Brain get] selectedPhoto] == nil)
        {
            aView.canShowCallout = YES;
            aView.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
        }
        aView.animatesDrop = YES;
        aView.draggable = YES;
    }

    aView.annotation = annotation;
    
    return aView;
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control
{
    self.selectedAnnotation = view.annotation;
    RezzoAnnotation* annotation = view.annotation;
    [Brain selectPhoto:annotation.info];
    [self performSegueWithIdentifier: @"Detail" sender: self];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.translucent = NO;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.mapView.delegate = self;
    if ([[Brain get] selectedPhoto])
    {
        self.annotations = [NSArray arrayWithObject:[RezzoAnnotation getAnnotation:[[Brain get] selectedPhoto]]];
    }
    else
    {
        NSMutableArray* annotations = [[NSMutableArray alloc] init];
        
        for (PhotoInfo* photo in [[Brain get] photos])
        {
            [annotations addObject:[RezzoAnnotation getAnnotation:photo]];
        }
        self.annotations = annotations;
    }
    [self updateRegion];
}

/*
// don't update region here- this triggers whenever the user pans
- (void)mapViewDidFinishLoadingMap:(MKMapView *)mapView
{
    [self updateRegion];
}
*/

- (void)viewDidUnload
{
    [self setMapView:nil];
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

@end
