//
//  MainTableViewController.m
//  ActivityTracking
//
//  Created by Badie Modiri Arash on 22/01/16.
//  Copyright © 2016 Badie Modiri Arash. All rights reserved.
//
#import <CoreData/CoreData.h>

#import "MainTableViewController.h"
#import "AppDelegate.h"
#import "ActivitySyncer.h"

@interface MainTableViewController ()

@property (weak, nonatomic) IBOutlet UITableViewCell *lastUploadCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *locationSensorCell;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *uploadActivityIndicator;
@property (weak, nonatomic) IBOutlet UITableViewCell *uploadDataCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *checkConfigurationCell;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *configActivityIndicator;
@property (weak, nonatomic) IBOutlet UITableViewCell *lastConfigCell;

@end

@implementation MainTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];


    [[NSUserDefaults standardUserDefaults] addObserver:self forKeyPath:@"config" options:NSKeyValueObservingOptionInitial context:NULL];
    [[NSUserDefaults standardUserDefaults] addObserver:self forKeyPath:@"data_upload_time" options:NSKeyValueObservingOptionInitial context:NULL];
    [[NSUserDefaults standardUserDefaults] addObserver:self forKeyPath:@"config_fetch_time" options:NSKeyValueObservingOptionInitial context:NULL];

    if (![self checkRequiredConfig:defaults]) {
        NSLog(@"Not enough settings. sending to settings page");
        [self performSegueWithIdentifier:@"Settings" sender:self];
    } else {
        [self trackingConfigDidChange];
    }
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *theCellClicked = [self.tableView cellForRowAtIndexPath:indexPath];
    if (theCellClicked == self.uploadDataCell) {
        [self.uploadActivityIndicator startAnimating];
        [[ActivitySyncer sharedSyncer] uploadDataWithSuccess:^{
            [self.uploadActivityIndicator stopAnimating];
            [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
        } Error:^{
            [self.uploadActivityIndicator stopAnimating];
            [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
        }];
    } else if (theCellClicked == self.checkConfigurationCell) {
        [self.configActivityIndicator startAnimating];
        [[ActivitySyncer sharedSyncer] downloadConfigWithSuccess:^{
            [self.configActivityIndicator stopAnimating];
            [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
        } Error:^{
            [self.configActivityIndicator stopAnimating];
            [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
        }];
    } else [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"config"]) {
        NSLog(@"config updated");
        [self trackingConfigDidChange];
    } else if ([keyPath isEqualToString:@"data_upload_time"]) {
        NSString* date= [NSDateFormatter localizedStringFromDate:[[NSUserDefaults standardUserDefaults] objectForKey:keyPath] dateStyle:NSDateFormatterMediumStyle timeStyle:NSDateFormatterMediumStyle];
        [self.lastUploadCell.detailTextLabel setText:date];
    } else if ([keyPath isEqualToString:@"config_fetch_time"]) {
        NSString* date= [NSDateFormatter localizedStringFromDate:[[NSUserDefaults standardUserDefaults] objectForKey:keyPath] dateStyle:NSDateFormatterMediumStyle timeStyle:NSDateFormatterMediumStyle];
        [self.lastConfigCell.detailTextLabel setText:date];
    }
}

-(void) trackingConfigDidChange {
    NSDictionary *config = [[NSUserDefaults standardUserDefaults] valueForKey:@"config"];
    NSString* locationStatus = @"Disabled";
    if ([config valueForKey:@"location"]) {
        if ([[[config valueForKey:@"location"] valueForKey:@"enabled"] isEqualToValue:@(YES)]) {
            NSLog(@"enabling location because of tracking config");
            locationStatus = @"Enabled";
        }
    }
    [self.locationSensorCell.detailTextLabel setText:locationStatus];
}



- (BOOL) checkRequiredConfig:(NSUserDefaults *)defaults {
    return [defaults objectForKey:@"post_url"] && [defaults objectForKey:@"config_get"] && [defaults objectForKey:@"user_uuid"];
}

-(void)dealloc {
    [[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:@"config"];
    [[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:@"data_upload_time"];
    [[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:@"config_fetch_time"];
}

@end
