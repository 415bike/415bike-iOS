// GoogleMapsAPIClient.m
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

#import "GoogleMapsAPIClient.h"
#import "AFJSONRequestOperation.h"

NSString * const GoogleMapsBikeTravelMode = @"bicycling";

static NSString * const kGoogleMapsAPIBaseURLString = @"http://maps.googleapis.com/maps/api/";

@interface GoogleMapsDirectionsRoute ()
- (id)initWithDictionary:(NSDictionary *)dictionary;
@end

@interface GoogleMapsDirectionsStep ()
- (id)initWithDictionary:(NSDictionary *)dictionary;
@end

#pragma mark -

@implementation GoogleMapsAPIClient

+ (GoogleMapsAPIClient *)sharedClient {
    static GoogleMapsAPIClient *_sharedClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedClient = [[GoogleMapsAPIClient alloc] initWithBaseURL:[NSURL URLWithString:kGoogleMapsAPIBaseURLString]];
    });
    
    return _sharedClient;
}

- (id)initWithBaseURL:(NSURL *)url {
    self = [super initWithBaseURL:url];
    if (!self) {
        return nil;
    }
    
    [self registerHTTPOperationClass:[AFJSONRequestOperation class]];
    [self setDefaultHeader:@"Accept" value:@"application/json"];
    
    return self;
}

- (void)directionsWithTravelMode:(NSString *)travelMode
                    fromLocation:(id)fromLocation
                      toLocation:(id)toLocation
                         success:(void (^)(NSArray *routes))success
                         failure:(void (^)(NSError *error))failure
{
    NSParameterAssert(travelMode);
    NSParameterAssert(fromLocation);
    NSParameterAssert(toLocation);
    
    NSMutableDictionary *mutableParameters = [NSMutableDictionary dictionary];
    [mutableParameters setValue:@"true" forKey:@"sensor"];
    [mutableParameters setValue:travelMode forKey:@"mode"];
    [mutableParameters setValue:fromLocation forKey:@"origin"];
    [mutableParameters setValue:toLocation forKey:@"destination"];
    
    [self getPath:@"directions/json" parameters:mutableParameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"REQUEST: %@", operation.request);
        NSMutableArray *mutableRoutes = [NSMutableArray arrayWithCapacity:[[responseObject valueForKey:@"routes"] count]];
        for (NSDictionary *routeDictionary in [responseObject valueForKey:@"routes"]) {
            GoogleMapsDirectionsRoute *route = [[GoogleMapsDirectionsRoute alloc] initWithDictionary:routeDictionary];
            [mutableRoutes addObject:route];
        }
        
        if (success) {
            success(mutableRoutes);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(error);
        }
    }];
}

@end

#pragma mark -

@implementation GoogleMapsDirectionsRoute

- (id)initWithDictionary:(NSDictionary *)dictionary {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    self.summary = [dictionary valueForKey:@"summary"];
    self.copyright = [dictionary valueForKey:@"copyrights"];
    self.warnings = [dictionary valueForKey:@"warnings"];
    
    NSDictionary *legDictionary = [[dictionary valueForKey:@"legs"] lastObject];
    
    self.startLocation = [[CLLocation alloc] initWithLatitude:[[legDictionary valueForKeyPath:@"start_location.lat"] doubleValue] longitude:[[legDictionary valueForKeyPath:@"start_location.lng"] doubleValue]];
    self.endLocation = [[CLLocation alloc] initWithLatitude:[[legDictionary valueForKeyPath:@"end_location.lat"] doubleValue] longitude:[[legDictionary valueForKeyPath:@"end_location.lng"] doubleValue]];
    
    self.distance = [[legDictionary valueForKeyPath:@"distance.value"] doubleValue];
    self.duration = [[legDictionary valueForKeyPath:@"duration.value"] doubleValue];
    
    NSMutableArray *mutableSteps = [NSMutableArray arrayWithCapacity:[[legDictionary valueForKey:@"steps"] count]];
    for (NSDictionary *stepDictionary in [legDictionary valueForKey:@"steps"]) {
        GoogleMapsDirectionsStep *step = [[GoogleMapsDirectionsStep alloc] initWithDictionary:stepDictionary];
        [mutableSteps addObject:step];
    }
    self.steps = mutableSteps;
    
    return self;
}

@end

@implementation GoogleMapsDirectionsStep

- (id)initWithDictionary:(NSDictionary *)dictionary {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    self.distance = [[dictionary valueForKeyPath:@"distance.value"] doubleValue];
    self.duration = [[dictionary valueForKeyPath:@"duration.value"] doubleValue];
    
    self.startLocation = [[CLLocation alloc] initWithLatitude:[[dictionary valueForKeyPath:@"start_location.lat"] doubleValue] longitude:[[dictionary valueForKeyPath:@"start_location.lng"] doubleValue]];
    self.endLocation = [[CLLocation alloc] initWithLatitude:[[dictionary valueForKeyPath:@"end_location.lat"] doubleValue] longitude:[[dictionary valueForKeyPath:@"end_location.lng"] doubleValue]];
    
    self.instructions = [dictionary valueForKey:@"html_instructions"];
    
    return self;
}

@end
