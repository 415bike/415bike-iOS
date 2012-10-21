// OpenMapViewController.m
// 
// Copyright (c) 2012 415Bike
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// 
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "MapViewController.h"
#import "GoogleMapsAPIClient.h"

static NSURL * MapBoxReferenceURL() {
    return [NSURL URLWithString:@"http://a.tiles.mapbox.com/v3/sikelianos.415tiles.json"];
}

@interface MapViewController () <RMMapViewDelegate>
@end

@implementation MapViewController

- (id)init {
    self = [super initWithNibName:@"MapView_iPhone" bundle:nil];
    if (!self) {
        return nil;
    }
    
    return self;
}

- (void)addAnnotationsFromRoute:(GoogleMapsDirectionsRoute *)route {    
    NSMutableArray *mutableAnnotations = [NSMutableArray array];
    
    for (GoogleMapsDirectionsStep *step in route.steps) {
        RMAnnotation *annotation = [[RMAnnotation alloc] initWithMapView:self.mapView coordinate:step.startLocation.coordinate andTitle:nil];
        annotation.annotationType = @"step";
        annotation.userInfo = @{ @"step": step };
        [annotation setBoundingBoxFromLocations:@[step.startLocation, step.endLocation]];
        [mutableAnnotations addObject:annotation];
    }
    
    [UIView animateWithDuration:1.0f animations:^{
        CGRect directionsFrame = self.directionSearchView.frame;
        [self.directionSearchView setHidden:YES animated:YES];
        
        directionsFrame.size.height -= 10.0f;
        
        self.directionStepsView = [[DirectionStepsView alloc] initWithFrame:directionsFrame];
        [self.directionStepsView addTarget:self action:@selector(directionStepsValueDidChange:) forControlEvents:UIControlEventValueChanged];
        self.directionStepsView.route = route;
        [[self.directionSearchView superview] addSubview:self.directionStepsView];
        [self.mapView bringSubviewToFront:self.directionStepsView];
    
        [self.routeButton setImage:nil forState:UIControlStateNormal];
        [self.routeButton setTitle:NSLocalizedString(@"  Cancel  ", nil) forState:UIControlStateNormal];
    }];
    
    [self.routeButton removeTarget:self action:@selector(showDirectionSearch:) forControlEvents:UIControlEventTouchUpInside];
    [self.routeButton addTarget:self action:@selector(cancel:) forControlEvents:UIControlEventTouchUpInside];

    
    [self.mapView addAnnotations:mutableAnnotations];
}

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
        
    self.currentLocationButton.color = [UIColor darkGrayColor];
    self.routeButton.color = [UIColor darkGrayColor];
    
    [self.directionSearchView setHidden:YES animated:NO];
    
    self.mapView.tileSource = [[RMMapBoxSource alloc] initWithReferenceURL:MapBoxReferenceURL()];
    self.mapView.delegate = self;
    self.mapView.zoom = 11;
    self.mapView.adjustTilesForRetinaDisplay = YES;
    self.mapView.showsUserLocation = YES;
//  self.mapView.viewControllerPresentingAttribution = self;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC), dispatch_get_main_queue(), ^(void) {
        float degreeRadius = 4000.f / 110000.f;
        CLLocationCoordinate2D centerCoordinate = [((RMMapBoxSource *)self.mapView.tileSource) centerCoordinate];
        
        RMSphericalTrapezium zoomBounds = {
            .southWest = {
                .latitude  = centerCoordinate.latitude  - degreeRadius,
                .longitude = centerCoordinate.longitude - degreeRadius
            },
            .northEast = {
                .latitude  = centerCoordinate.latitude  + degreeRadius,
                .longitude = centerCoordinate.longitude + degreeRadius
            }
        };
        
        [self.mapView zoomWithLatitudeLongitudeBoundsSouthWest:zoomBounds.southWest northEast:zoomBounds.northEast animated:YES];
    });
    
    [self.view addSubview:self.mapView];
}

- (void)viewDidUnload {
    [super viewDidUnload];
    _mapView = nil;
}

#pragma mark - IBAction


- (IBAction)centerMapOnCurrentLocation:(id)sender {
    [self.mapView setCenterCoordinate:self.mapView.userLocation.coordinate];
}

- (IBAction)showDirectionSearch:(id)sender {
    NSLog(@"%@ %@", [self class], NSStringFromSelector(_cmd));
    [self.directionSearchView setHidden:NO animated:YES];
    [self.directionSearchView becomeFirstResponder];
}

- (IBAction)directionStepsValueDidChange:(id)sender {
    NSLog(@"%@ %@", [self class], NSStringFromSelector(_cmd));
    DirectionStepsView *stepsView = (DirectionStepsView *)sender;
    
    CLLocationCoordinate2D c0 = stepsView.currentStep.startLocation.coordinate;
    CLLocationCoordinate2D c1 = stepsView.currentStep.endLocation.coordinate;
    
    RMSphericalTrapezium zoomBounds = {
        .southWest = {
            .latitude  = fminf(c0.latitude, c1.latitude),
            .longitude = fminf(c0.longitude, c1.longitude)
        },
        .northEast = {
            .latitude  = fmaxf(c0.latitude, c1.latitude),
            .longitude = fmaxf(c0.longitude, c1.longitude)
        }
    };
    
    NSMutableArray *mutableAnnotationsToBeRemoved = [NSMutableArray array];
    for (RMAnnotation *annotation in self.mapView.annotations) {
        if ([annotation.annotationType isEqualToString:@"cap"]) {
            [mutableAnnotationsToBeRemoved addObject:annotation];
        }
    }
    [self.mapView removeAnnotations:mutableAnnotationsToBeRemoved];
    
    RMAnnotation *startAnnotation = [[RMAnnotation alloc] initWithMapView:self.mapView coordinate:stepsView.currentStep.startLocation.coordinate andTitle:nil];
    startAnnotation.annotationType = @"cap";
//    RMAnnotation *endAnnotation = [[RMAnnotation alloc] initWithMapView:self.mapView coordinate:stepsView.currentStep.endLocation.coordinate andTitle:nil];
//    endAnnotation.annotationType = @"cap";
    
    [self.mapView zoomWithLatitudeLongitudeBoundsSouthWest:zoomBounds.southWest northEast:zoomBounds.northEast animated:YES];
    [self.mapView addAnnotations:@[startAnnotation]];

}

- (IBAction)cancel:(id)sender {
    [self.mapView removeAllAnnotations];
    [self.directionStepsView removeFromSuperview];
    [UIView animateWithDuration:1.0f animations:^{
        [self.routeButton setImage:[UIImage imageNamed:@"route"] forState:UIControlStateNormal];
        [self.routeButton setTitle:nil forState:UIControlStateNormal];
    }];
    [self.routeButton removeTarget:self action:@selector(cancel:) forControlEvents:UIControlEventTouchUpInside];
    [self.routeButton addTarget:self action:@selector(showDirectionSearch:) forControlEvents:UIControlEventTouchUpInside];
}

#pragma mark - RMMapViewDelegate

- (RMMapLayer *)mapView:(RMMapView *)mapView
     layerForAnnotation:(RMAnnotation *)annotation
{
    if ([annotation.annotationType isEqualToString:@"step"]) {
        GoogleMapsDirectionsStep *step = [annotation.userInfo valueForKey:@"step"];
        RMShape *stepLineShape = [[RMShape alloc] initWithView:self.mapView];
        [stepLineShape moveToCoordinate:step.startLocation.coordinate];
        [stepLineShape addLineToCoordinate:step.endLocation.coordinate];
        stepLineShape.lineWidth = 6.0;
        stepLineShape.lineColor = [UIColor colorWithRed:1.0f green:0.6f blue:0.2f alpha:0.6f];
        
        return stepLineShape;
    } else if ([annotation.annotationType isEqualToString:@"cap"]) {
        RMCircle *capShape = [[RMCircle alloc] initWithView:self.mapView radiusInMeters:30.0f];
        capShape.fillColor = [UIColor colorWithRed:1.0f green:0.6f blue:0.2f alpha:0.6f];
        capShape.lineColor = [UIColor whiteColor];
        capShape.lineWidthInPixels = 2.0f;
        capShape.annotation = annotation;
        
        return capShape;
    }
    
    return nil;
}

#pragma mark - DirectionSearchViewDelegate

-(void)searchViewDidRoute:(DirectionSearchView *)searchView {
    NSString *fromLocation = searchView.fromTextField.text;
    if ([searchView.fromTextField.text isEqualToString:NSLocalizedString(@"Current Location", nil)]) {
        fromLocation = @"414 Brannan Street, San Francisco, CA";
    }
    
    NSString *toLocation = searchView.toTextField.text;
    if (![toLocation hasPrefix:@"CA"]) {
        toLocation = [toLocation stringByAppendingString:@" San Francisco, CA"];
    }
        
    [[GoogleMapsAPIClient sharedClient] directionsWithTravelMode:GoogleMapsBikeTravelMode fromLocation:fromLocation toLocation:toLocation success:^(NSArray *routes) {
        [self.mapView removeAllAnnotations];
        [self addAnnotationsFromRoute:[routes lastObject]];
    } failure:^(NSError *error) {
        NSLog(@"Error: %@", error);
    }];
}

@end
