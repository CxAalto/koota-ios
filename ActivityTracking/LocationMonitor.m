//
//  LocationMonitor.m
//  ActivityTracking
//
//  Created by Badie Modiri Arash on 02/03/16.
//  Copyright © 2016 Badie Modiri Arash. All rights reserved.
//

#import "LocationMonitor.h"

#import <CoreData/CoreData.h>
#import "AppDelegate.h"

@interface LocationMonitor ()

@property (nonatomic, strong) CLLocationManager *locationManager;

@end

@implementation LocationMonitor

static LocationMonitor* currentInstance;

+(instancetype)defaultMonitor {
    @synchronized(self) {
        if (!currentInstance) {
            currentInstance = [LocationMonitor new];
        }
    }
    return currentInstance;
}


-(instancetype)init {
    self = [super init];
    
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    self.locationManager.delegate = self;
    self.recording = NO;
    return self;
}

-(void)startRecording {
    NSLog(@"enabling location because of tracking config");
    switch ([CLLocationManager authorizationStatus]) {
        case kCLAuthorizationStatusNotDetermined:
            NSLog(@"app will now request location authorization. we need it to operate properly");
            [self.locationManager requestAlwaysAuthorization];
            break;
        case kCLAuthorizationStatusDenied:
            NSLog(@"please authorize our app for location in settings page");
            break;
        case kCLAuthorizationStatusRestricted:
            NSLog(@"You cannot allow our app to gather info because of some external reason such as parential control or cooprate policy");
            break;
        default:
            [self.locationManager setAllowsBackgroundLocationUpdates:YES];
            [self.locationManager setPausesLocationUpdatesAutomatically:NO];
            [self.locationManager setActivityType:CLActivityTypeOther];
            [self.locationManager startUpdatingLocation];
            self.recording = YES;
            break;
    }
}

-(void)stopRecording {
    [self.locationManager stopUpdatingLocation];
    self.recording = NO;
}

- (void) locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    NSDictionary *config = [[NSUserDefaults standardUserDefaults] valueForKey:@"config"];
    switch (status) {
        case kCLAuthorizationStatusAuthorizedAlways:
            // triger KVO observers
            [[NSUserDefaults standardUserDefaults] setValue:config forKey:@"config"];
            break;
        default:
#warning actual alert dialogue
            NSLog(@"please authorize our app for location in settings page");
            break;
    }
}

- (void) locationManager:(CLLocationManager *)manager didUpdateLocations:(nonnull NSArray<CLLocation *> *)locations {
    // TODO: store in data
    for (CLLocation* location in locations) {
        NSManagedObject* event = [NSEntityDescription insertNewObjectForEntityForName:@"Event" inManagedObjectContext:[(AppDelegate*)[[UIApplication sharedApplication] delegate] managedObjectContext]];
        [event setValue:[NSDate date] forKey:@"timestamp"];
        [event setValue:@"Location" forKey:@"probe"];
        [event setValue:@{@"lat": [NSNumber numberWithDouble:location.coordinate.latitude],
                          @"lon": [NSNumber numberWithDouble:location.coordinate.longitude],
                          @"speed": [NSNumber numberWithFloat:location.speed],
                          @"alt": [NSNumber numberWithDouble:location.altitude]} forKey:@"payload"];
    }
    [(AppDelegate*)[[UIApplication sharedApplication] delegate] saveContext];
    NSLog(@"location logged");
}


-(void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    NSLog(@"location manager did fail with error: %@", error);
}

-(void)locationManagerDidPauseLocationUpdates:(CLLocationManager *)manager {
    NSLog(@"Location manager paused location updates");
}

@end
