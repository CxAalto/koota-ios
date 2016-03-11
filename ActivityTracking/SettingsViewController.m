//
//  SettingsViewController.m
//  ActivityTracking
//
//  Created by Badie Modiri Arash on 03/01/16.
//  Copyright © 2016 Badie Modiri Arash. All rights reserved.
//

#import "SettingsViewController.h"

#import "ActivitySyncer.h"

#import <AFNetworking/AFNetworking.h>
#import <AudioToolbox/AudioToolbox.h>

@interface SettingsViewController ()

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UITextField* dataURL;
@property (weak, nonatomic) IBOutlet UITextField* configURL;
@property (weak, nonatomic) IBOutlet UITextField* fingerPrint;
@property (weak, nonatomic) IBOutlet UITextField* userUUID;

@property (strong, nonatomic) QRCodeReader* reader;
@property (strong, nonatomic) QRCodeReaderViewController* qrvc;

@end

@implementation SettingsViewController

- (void)viewDidLoad {
    
    // QRReader stuff
    self.reader = [QRCodeReader readerWithMetadataObjectTypes:@[AVMetadataObjectTypeQRCode]];
    self.qrvc = [QRCodeReaderViewController readerWithCancelButtonTitle:@"Cancel" codeReader:self.reader startScanningAtLoad:YES showSwitchCameraButton:YES showTorchButton:YES];
    self.qrvc.modalPresentationStyle = UIModalPresentationFormSheet;
    self.qrvc.delegate = self;
    
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    [defaults addObserver:self forKeyPath:@"config_get" options:NSKeyValueObservingOptionInitial context:NULL];
    [defaults addObserver:self forKeyPath:@"user_uuid" options:NSKeyValueObservingOptionInitial context:NULL];
    [defaults addObserver:self forKeyPath:@"post_url" options:NSKeyValueObservingOptionInitial context:NULL];
}

-(void)dealloc {
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObserver:self forKeyPath:@"config_get"];
    [defaults removeObserver:self forKeyPath:@"user_uuid"];
    [defaults removeObserver:self forKeyPath:@"post_url"];
}

- (IBAction)qrCodeButtonPressed:(id)sender {
    [self presentViewController:self.qrvc animated:YES completion:NULL];
}

- (void)reader:(QRCodeReaderViewController *)reader didScanResult:(NSString *)URLResult
{
    AudioServicesPlayAlertSound(kSystemSoundID_Vibrate);
    [self dismissViewControllerAnimated:YES completion:^{
        NSLog(@"%@", URLResult);
        NSURLComponents* url = [NSURLComponents componentsWithString:URLResult];
        if (url && [url.scheme isEqualToString:@"koota"]) {
            for (NSURLQueryItem* q in url.queryItems) {
                if ([q.name isEqualToString:@"post"]) {
                    [self.dataURL setText:q.value];
                } else if ([q.name isEqualToString:@"config"]) {
                    [self.configURL setText:q.value];
                } else if ([q.name isEqualToString:@"device_id"]) {
                    [self.userUUID setText:q.value];
                }
            }
        }
    }];
}

- (void)readerDidCancel:(QRCodeReaderViewController *)reader
{
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (IBAction)ValidateAndSavePressed:(id)sender {
    // get config
    // if error -> show error
    [self.activityIndicator startAnimating];
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    NSString* configOrig = [defaults stringForKey:@"config_get"];
    [defaults setObject:self.configURL.text forKey:@"config_get"];
    
    [[ActivitySyncer sharedSyncer] downloadConfigWithSuccess:^{
        [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
            [self.activityIndicator stopAnimating];
            [defaults setObject:[NSDate date] forKey:@"config_fetch_time"];
            [defaults setObject:self.configURL.text forKey:@"config_get"];
            [defaults setObject:self.dataURL.text forKey:@"post_url"];
            [defaults setObject:self.userUUID.text forKey:@"user_uuid"];
            [defaults synchronize];
            [self.navigationController popViewControllerAnimated:YES];
        }];
    } Error:^{
        NSLog(@"failed to get config");
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Configuration failed" message:@"Requesting config failed. Try again or check the config URL." preferredStyle:UIAlertControllerStyleAlert];
        [self presentViewController:alert animated:YES completion:nil];
        [defaults setObject:configOrig forKey:@"config_get"];
    }];    
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    NSLog(@"urls updated");
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    if ([keyPath isEqualToString:@"user_uuid"]) {
        [self.userUUID setText:[defaults stringForKey:@"user_uuid"]];
    } else if ([keyPath isEqualToString:@"config_get"]) {
        [self.configURL setText:[defaults stringForKey:@"config_get"]];
    } else if ([keyPath isEqualToString:@"post_url"]) {
        [self.dataURL setText:[defaults stringForKey:@"post_url"]];
    }
}

@end
