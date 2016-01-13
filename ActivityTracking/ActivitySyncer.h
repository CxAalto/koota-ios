//
//  ActivitySyncer.h
//  ActivityTracking
//
//  Created by Badie Modiri Arash on 13/01/16.
//  Copyright © 2016 Badie Modiri Arash. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ActivitySyncer : NSObject

+ (instancetype)sharedSyncer;

- (void)uploadDataWithSuccess:(void (^)(void))success Error:(void (^)(void))error;
- (void)downloadConfigWithSuccess:(void (^)(void))success Error:(void (^)(void))error;

@end
