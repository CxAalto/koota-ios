//
//  ScreenMonitor.m
//  ActivityTracking
//
//  Created by Badie Modiri Arash on 02/03/16.
//  Copyright © 2016 Badie Modiri Arash. All rights reserved.
//

#import "ScreenMonitor.h"

#import <CoreData/CoreData.h>
#import <notify.h>
#import "AppDelegate.h"


@interface ScreenMonitor ()

@property int notifyToken;

@end

@implementation ScreenMonitor

static ScreenMonitor* currentInstance;

+(instancetype)defaultMonitor {
    @synchronized(self) {
        if (!currentInstance) {
            currentInstance = [ScreenMonitor new];
        }
    }
    return currentInstance;
}


-(instancetype)init {
    self = [super init];
    return self;
}

-(void)startRecording {
    NSLog(@"enabling screen because of tracking config");
    int status = notify_register_dispatch("com.apple.springboard.hasBlankedScreen",
                                          &_notifyToken,
                                          dispatch_get_main_queue(), ^(int t) {
                                              uint64_t state;
                                              int result = notify_get_state(self.notifyToken, &state);
                                              NSLog(@"lock state change = %llu", state);
                                              NSManagedObject* event = [NSEntityDescription insertNewObjectForEntityForName:@"Event" inManagedObjectContext:[(AppDelegate*)[[UIApplication sharedApplication] delegate] managedObjectContext]];
                                              [event setValue:[NSDate date] forKey:@"timestamp"];
                                              [event setValue:@"Screen" forKey:@"probe"];
                                              [event setValue:@{@"state": [NSNumber numberWithInt:state]} forKey:@"payload"];
                                              [(AppDelegate*)[[UIApplication sharedApplication] delegate] saveContext];
                                              if (result != NOTIFY_STATUS_OK) {
                                                  NSLog(@"notify_get_state() not returning NOTIFY_STATUS_OK");
                                              }
                                          });
    if (status != NOTIFY_STATUS_OK) {
        NSLog(@"notify_register_dispatch() not returning NOTIFY_STATUS_OK");
    } else {
        self.recording = true;
    }

}

-(void)stopRecording {
    int status = notify_cancel(self.notifyToken);
    if (status == NOTIFY_STATUS_OK)
        self.recording = NO;
}
@end
