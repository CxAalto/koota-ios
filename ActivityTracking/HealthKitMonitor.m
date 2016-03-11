//
//  HealthKitMonitor.m
//  ActivityTracking
//
//  Created by Badie Modiri Arash on 23/02/16.
//  Copyright © 2016 Badie Modiri Arash. All rights reserved.
//

#import "HealthKitMonitor.h"

#import <HealthKit/HealthKit.h>

@interface HealthKitMonitor ()
@property (strong, nonatomic) HKHealthStore* health;
@property (strong, nonatomic) HKSampleType* step;
@property (strong, nonatomic) HKObserverQuery* query;
@end

@implementation HealthKitMonitor

static HealthKitMonitor* currentInstance;

+(instancetype)defaultMonitor {
    @synchronized(self) {
        if (!currentInstance) {
            currentInstance = [HealthKitMonitor new];
        }
    }
    return currentInstance;
}

-(instancetype)init {
    self = [super init];
    if ([HKHealthStore isHealthDataAvailable]) {
        self.health = [HKHealthStore new];
        self.step = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
        self.recording = NO;
    }
    return self;
}

-(void)startRecording {
    [self authorizationWithCompletion:^(BOOL success, NSError *error) {
        if (error) {
            self.recording = NO;
        } else {
            self.query = [[HKObserverQuery alloc] initWithSampleType:self.step predicate:nil updateHandler:^(HKObserverQuery * _Nonnull query, HKObserverQueryCompletionHandler  _Nonnull completionHandler, NSError * _Nullable error) {
                completionHandler();
                if (error) {
                    // Perform Proper Error Handling Here...
                    NSLog(@"*** An error occured while setting up the stepCount observer. %@ ***",
                          error.localizedDescription);
                    self.recording = NO;
                    // todo: error handling
                } else {
                    NSLog(@"Steps logged");
                }
            }];
            [self.health executeQuery:self.query];
        }
        [self.health enableBackgroundDeliveryForType:self.step frequency:HKUpdateFrequencyImmediate withCompletion:^(BOOL success, NSError * _Nullable error) {
            if (success) {
                self.recording = YES;
            } else if (error) {
                NSLog(@"*** An error occured while setting up the background delivery. %@ ***",
                      error.localizedDescription);
            }
        }];


    }];
}

-(void)stopRecording {
    if (self.query) [self.health stopQuery:self.query];
    [self.health disableAllBackgroundDeliveryWithCompletion:^(BOOL success, NSError * _Nullable error) {
        if (success) {
            self.recording = NO;
        } else if (error) {
            NSLog(@"*** An error occured while disabling background delivery. %@ ***",
                  error.localizedDescription);
        }
    }];

}

-(void)authorizationWithCompletion:(void (^)(BOOL success, NSError *error))completion {
    NSSet* readSet = [NSSet setWithObjects:[HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount], nil];
    [self.health requestAuthorizationToShareTypes:nil readTypes:readSet completion:completion];
}

@end
