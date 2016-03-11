//
//  ActivitySyncer.m
//  ActivityTracking
//
//  Created by Badie Modiri Arash on 13/01/16.
//  Copyright © 2016 Badie Modiri Arash. All rights reserved.
//


#import "ActivitySyncer.h"
#import "AppDelegate.h"
@interface ActivitySyncer ()

@end
@implementation ActivitySyncer

static ActivitySyncer* currentInstance;

+ (instancetype)sharedSyncer {
    @synchronized(self) {
        if (!currentInstance) {
            currentInstance = [ActivitySyncer new];
        }
    }
    return currentInstance;
}

- (void)downloadConfigWithSuccess:(void (^)(void))success Error:(void (^)(void))errorHandler {
    NSLog(@"fetching config");
    NSString* configURL = [[NSUserDefaults standardUserDefaults] objectForKey:@"config_get"];
    NSString* userUUID = [[NSUserDefaults standardUserDefaults] objectForKey:@"user_uuid"];

    NSURLComponents* dataURLComp = [NSURLComponents componentsWithString:configURL];
    if (!dataURLComp.queryItems) {
        [dataURLComp setQueryItems:[NSArray array]];
    }
    NSArray* qs = [[dataURLComp queryItems] arrayByAddingObject:[NSURLQueryItem queryItemWithName:@"device_id" value:userUUID]];
    [dataURLComp setQueryItems:qs];
    [[[NSURLSession sharedSession] dataTaskWithURL:dataURLComp.URL completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSError * error2;
        NSDictionary* configDic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error2];
        NSLog(@"Got new config %@", configDic);
        if (error || error2) {
            errorHandler();
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSDictionary* confFake = @{@"location": @{@"enabled": @(YES)}, @"health": @{@"enabled": @(YES)}};
                [[NSUserDefaults standardUserDefaults] setObject:confFake forKey:@"config"];
                [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:@"config_fetch_time"];
                [[NSUserDefaults standardUserDefaults] synchronize];
                success();
            });
        }
    }] resume];
}

- (void)uploadDataWithSuccess:(void (^)(void))success Error:(void (^)(void))errorHandler {
    NSLog(@"uploading data");
    NSString* dataURL = [[NSUserDefaults standardUserDefaults] objectForKey:@"post_url"];
    NSString* userUUID = [[NSUserDefaults standardUserDefaults] objectForKey:@"user_uuid"];

    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"Event"];
    NSBatchDeleteRequest *delete = [[NSBatchDeleteRequest alloc] initWithFetchRequest:request];
    NSError *requestError = nil;
    NSArray* events = [[(AppDelegate*)[[UIApplication sharedApplication] delegate] managedObjectContext] executeFetchRequest:request error:&requestError];
    if (requestError) {
        NSLog(@"Something went wrong while fetching events");
        errorHandler();
    } else {
        NSLog(@"sending %lu events", (unsigned long)[events count]);
        NSURLComponents* dataURLComp = [NSURLComponents componentsWithString:dataURL];
        if (!dataURLComp.queryItems) {
            [dataURLComp setQueryItems:[NSArray array]];
        }
        NSArray* qs = [[dataURLComp queryItems] arrayByAddingObject:[NSURLQueryItem queryItemWithName:@"device_id" value:userUUID]];
        [dataURLComp setQueryItems:qs];
        NSMutableURLRequest* req = [NSMutableURLRequest requestWithURL:[dataURLComp URL]];
        [req setHTTPMethod:@"POST"];
        NSError * error2;
        NSMutableArray* eventsDicts = [NSMutableArray array];
        [events enumerateObjectsUsingBlock:^(NSManagedObject* obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSMutableDictionary* payload = [[obj valueForKey:@"payload"] mutableCopy];
            NSNumber* timestamp = [NSNumber numberWithDouble:[[obj valueForKey:@"timestamp"] timeIntervalSince1970]];
            [payload setObject:timestamp forKey:@"timestamp"];
            [eventsDicts addObject:payload];
        }];
        [req setHTTPBody:[NSJSONSerialization dataWithJSONObject:eventsDicts options:NSJSONWritingPrettyPrinted error:&error2]];
        [[[NSURLSession sharedSession] dataTaskWithRequest:req completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            if (error) {
                errorHandler();
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:@"data_upload_time"];
                    [[NSUserDefaults standardUserDefaults] synchronize];
                    NSError *deleteError = nil;
                    [[(AppDelegate*)[[UIApplication sharedApplication] delegate] persistentStoreCoordinator] executeRequest:delete withContext:[(AppDelegate*)[[UIApplication sharedApplication] delegate] managedObjectContext] error:&deleteError]   ;
                    success();
                });
            }
        }] resume];
    }
}
@end
