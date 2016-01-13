//
//  ViewController.m
//  ActivityTracking
//
//  Created by Badie Modiri Arash on 17/12/15.
//  Copyright © 2015 Badie Modiri Arash. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import <CoreData/CoreData.h>
#import "ViewController.h"
#import "AppDelegate.h"

@interface ViewController ()

@property (nonatomic, strong) CLLocationManager *locationManager;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    self.locationManager.delegate = self;
    
    [defaults addObserver:self forKeyPath:@"config" options:NSKeyValueObservingOptionInitial context:NULL];
    
    if (![self checkRequiredConfig:defaults]) {
        NSLog(@"Not enough settings. sending to settings page");
        [self performSegueWithIdentifier:@"Settings" sender:self];
    } else {
        [self trackingConfigDidChange];
    }
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"config"]) {
        NSLog(@"config updated");
        [self trackingConfigDidChange];
    }
}

-(void) trackingConfigDidChange {
    NSDictionary *config = [[NSUserDefaults standardUserDefaults] valueForKey:@"config"];
    NSString* statusText = @"unknown status";
    if ([config valueForKey:@"location"]) {
        if ([[[config valueForKey:@"location"] valueForKey:@"enabled"] isEqualToValue:@(YES)]) {
            NSLog(@"enabling location because of tracking config");
            statusText = @"Location tracking enabled";
            
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
                    [self.locationManager startUpdatingLocation];
                    break;
            }
        }
    }
    [self.statusLabel setText:statusText];
}

- (void) locationManager:(CLLocationManager *)manager didUpdateLocations:(nonnull NSArray<CLLocation *> *)locations {
    // TODO: store in data
    for (CLLocation* location in locations) {
        NSManagedObject* event = [NSEntityDescription insertNewObjectForEntityForName:@"Event" inManagedObjectContext:[(AppDelegate*)[[UIApplication sharedApplication] delegate] managedObjectContext]];
        [event setValue:[NSDate date] forKey:@"timestamp"];
        [event setValue:@{@"lat": [NSNumber numberWithDouble:location.coordinate.latitude],
                          @"lon": [NSNumber numberWithDouble:location.coordinate.longitude],
                          @"speed": [NSNumber numberWithFloat:location.speed],
                          @"alt": [NSNumber numberWithDouble:location.altitude]} forKey:@"payload"];
    }
    [(AppDelegate*)[[UIApplication sharedApplication] delegate] saveContext];
    NSLog(@"location logged");
}

- (void) locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    switch (status) {
        case kCLAuthorizationStatusAuthorizedAlways:
            [self trackingConfigDidChange];
            break;
        default:
            NSLog(@"please authorize our app for location in settings page");
            break;
    }
}

- (BOOL) checkRequiredConfig:(NSUserDefaults *)defaults {
    return [defaults objectForKey:@"post_url"] && [defaults objectForKey:@"config_get"] && [defaults objectForKey:@"user_uuid"];
}


- (void) didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
@end
