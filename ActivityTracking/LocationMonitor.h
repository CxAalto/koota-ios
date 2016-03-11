//
//  LocationMonitor.h
//  ActivityTracking
//
//  Created by Badie Modiri Arash on 02/03/16.
//  Copyright © 2016 Badie Modiri Arash. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <CoreLocation/CoreLocation.h>

@interface LocationMonitor : NSObject <CLLocationManagerDelegate>

@property (atomic) BOOL recording;

+(instancetype)defaultMonitor;

-(void)startRecording;
-(void)stopRecording;

@end
