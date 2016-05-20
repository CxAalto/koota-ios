//
//  AppDelegate.m
//  ActivityTracking
//
//  Created by Badie Modiri Arash on 17/12/15.
//  Copyright © 2015 Badie Modiri Arash. All rights reserved.
//

#import "AppDelegate.h"

#import "ActivitySyncer.h"
#import "HealthKitMonitor.h"
#import "LocationMonitor.h"
#import "ScreenMonitor.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

-(instancetype)init {
    self = [super init];

    [[NSUserDefaults standardUserDefaults] addObserver:self forKeyPath:@"config" options:NSKeyValueObservingOptionInitial context:NULL];

    return self;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    [NewRelicAgent startWithApplicationToken:@"AAd9124e2155d397a7716be7a4338a2467c847c4a6"];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    // Saves changes in the application's managed object context before the application terminates.
    [self saveContext];
}

- (void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    // fetch config or upload if nessecery
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    NSDate* lastConfigFetch = [defaults valueForKey:@"config_fetch_time"];
    NSDate* lastDataUpload = [defaults valueForKey:@"data_upload_time"];
#warning magic number!
    if (!lastConfigFetch || -[lastConfigFetch timeIntervalSinceNow] > 10*60) {
        [[ActivitySyncer sharedSyncer] downloadConfigWithSuccess:^{
            completionHandler(UIBackgroundFetchResultNewData);
        } Error:^{
            completionHandler(UIBackgroundFetchResultNewData);
        }];
    } else if (!lastDataUpload || -[lastDataUpload timeIntervalSinceNow] > 1*60) {
        [[ActivitySyncer sharedSyncer] uploadDataWithSuccess:^{
            completionHandler(UIBackgroundFetchResultNewData);
        } Error:^{
            completionHandler(UIBackgroundFetchResultNewData);
        }];
    } else completionHandler(UIBackgroundFetchResultNoData);
}

#pragma mark - Core Data stack

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

- (NSURL *)applicationDocumentsDirectory {
    // The directory the application uses to store the Core Data store file. This code uses a directory named "fi.aalto.ActivityTracking" in the application's documents directory.
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (NSManagedObjectModel *)managedObjectModel {
    // The managed object model for the application. It is a fatal error for the application not to be able to find and load its model.
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"ActivityTracking" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    // The persistent store coordinator for the application. This implementation creates and returns a coordinator, having added the store for the application to it.
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    // Create the coordinator and store
    
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"ActivityTracking.sqlite"];
    NSError *error = nil;
    NSString *failureReason = @"There was an error creating or loading the application's saved data.";
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        // Report any error we got.
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        dict[NSLocalizedDescriptionKey] = @"Failed to initialize the application's saved data";
        dict[NSLocalizedFailureReasonErrorKey] = failureReason;
        dict[NSUnderlyingErrorKey] = error;
        error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        // Replace this with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return _persistentStoreCoordinator;
}


- (NSManagedObjectContext *)managedObjectContext {
    // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.)
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        return nil;
    }
    _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    return _managedObjectContext;
}

#pragma mark - Core Data Saving support

- (void)saveContext {
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        NSError *error = nil;
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}


#pragma KVO
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"config"]) {
        [self trackingConfigDidChange];
    }
}

-(void)trackingConfigDidChange {
    NSDictionary *config = [[NSUserDefaults standardUserDefaults] valueForKey:@"config"];
    if ([config valueForKey:@"location"]) {
        if ([[[config valueForKey:@"location"] valueForKey:@"enabled"] isEqualToValue:@(YES)]) {
            [[LocationMonitor defaultMonitor] startRecording];
        }
        else {
            [[LocationMonitor defaultMonitor] stopRecording];
        }
    } else {
        [[LocationMonitor defaultMonitor] stopRecording];
    }
    if ([config valueForKey:@"health"]) {
        if ([[[config valueForKey:@"health"] valueForKey:@"enabled"] isEqualToValue:@(YES)]) {
            [[HealthKitMonitor defaultMonitor] startRecording];
        } else {
            [[HealthKitMonitor defaultMonitor] stopRecording];
        }
    } else {
        [[HealthKitMonitor defaultMonitor] stopRecording];
    }
    if ([config valueForKey:@"screen"]) {
        if ([[[config valueForKey:@"screen"] valueForKey:@"enabled"] isEqualToValue:@(YES)]) {
            [[ScreenMonitor defaultMonitor] startRecording];
        } else {
            [[ScreenMonitor defaultMonitor] stopRecording];
        }
    } else {
        [[ScreenMonitor defaultMonitor] stopRecording];
    }

}

# pragma locationManager


-(void)dealloc {
    [[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:@"config"];
}
@end
