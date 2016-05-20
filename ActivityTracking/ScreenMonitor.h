//
//  ScreenMonitor.h
//  ActivityTracking
//
//  Created by Badie Modiri Arash on 02/03/16.
//  Copyright © 2016 Badie Modiri Arash. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ScreenMonitor : NSObject

@property (atomic) BOOL recording;

+(instancetype)defaultMonitor;

-(void)startRecording;
-(void)stopRecording;

@end
