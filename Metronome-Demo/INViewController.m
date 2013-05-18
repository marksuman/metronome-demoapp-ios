//
//  INViewController.m
//  Metronome-Demo
//
//  Created by Mark Suman on 5/17/13.
//  Copyright (c) 2013 Mark Suman. All rights reserved.
//

#import "INViewController.h"
#import <PebbleKit/PebbleKit.h>

@interface INViewController () <UIWebViewDelegate, PBPebbleCentralDelegate>

@property IBOutlet UIBarButtonItem *quiz1Button;
@property IBOutlet UIBarButtonItem *quiz2Button;
@property IBOutlet UIBarButtonItem *loginButton;
@property IBOutlet UIBarButtonItem *logoutButton;
@property IBOutlet UIWebView *webView;
@property IBOutlet UILabel *timerLabel;
@property PBWatch *targetWatch;
@property NSTimer *timerTimerYo;

@end

@implementation INViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    self.timerTimerYo = [NSTimer timerWithTimeInterval:1 target:self selector:@selector(updateTimerLabel) userInfo:nil repeats:YES];
    
    // We'd like to get called when Pebbles connect and disconnect, so become the delegate of PBPebbleCentral:
    [[PBPebbleCentral defaultCentral] setDelegate:self];
    
    // Initialize with the last connected watch:
    [self setTheTargetWatch:[[PBPebbleCentral defaultCentral] lastConnectedWatch]];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark -
#pragma mark Watch Communication

- (void)setTheTargetWatch:(PBWatch *)watch {
    _targetWatch = watch;
    
    // NOTE:
    // For demonstration purposes, we start communicating with the watch immediately upon connection,
    // because we are calling -appMessagesGetIsSupported: here, which implicitely opens the communication session.
    // Real world apps should communicate only if the user is actively using the app, because there
    // is one communication session that is shared between all 3rd party iOS apps.
    
    // Test if the Pebble's firmware supports AppMessages / Quiz Metronome:
    [watch appMessagesGetIsSupported:^(PBWatch *watch, BOOL isAppMessagesSupported) {
        if (isAppMessagesSupported) {
            // Configure our communications channel to target the quiz metronome app:
            // See https://github.com/marksuman/metronome for the same definition on the watch's end:
            uint8_t bytes[] = {0x8D, 0x22, 0x23, 0x1C, 0xC1, 0x7F, 0x43, 0x29, 0xAF, 0xF5, 0x87, 0x7F, 0x30, 0xBF, 0x65, 0xA0};
            NSData *uuid = [NSData dataWithBytes:bytes length:sizeof(bytes)];
            [watch appMessagesSetUUID:uuid];
            
            NSString *message = [NSString stringWithFormat:@"Yay! %@ supports AppMessages :D", [watch name]];
            [[[UIAlertView alloc] initWithTitle:@"Connected!" message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        } else {
            
            NSString *message = [NSString stringWithFormat:@"Blegh... %@ does NOT support AppMessages :'(", [watch name]];
            [[[UIAlertView alloc] initWithTitle:@"Connected..." message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        }
    }];
}

/*
 *  PBPebbleCentral delegate methods
 */

- (void)pebbleCentral:(PBPebbleCentral*)central watchDidConnect:(PBWatch*)watch isNew:(BOOL)isNew {
    [self setTheTargetWatch:watch];
}

- (void)pebbleCentral:(PBPebbleCentral*)central watchDidDisconnect:(PBWatch*)watch {
    [[[UIAlertView alloc] initWithTitle:@"Disconnected!" message:[watch name] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
    if (_targetWatch == watch || [watch isEqual:_targetWatch]) {
        [self setTheTargetWatch:nil];
    }
}

#pragma mark -
#pragma mark Quiz and Web View Methods

- (void)loadQuizWithURL:(NSURL *)quizURL
{
    //[self.timerTimerYo invalidate];
    [self.webView loadRequest:[NSURLRequest requestWithURL:quizURL]];
    [[NSRunLoop currentRunLoop] addTimer:self.timerTimerYo forMode:NSDefaultRunLoopMode];
}

- (IBAction)loadQuiz1:(id)sender
{
    [self loadQuizWithURL:[NSURL URLWithString:@"https://mobiledev.instructure.com/courses/24219/quizzes/1154713?force_user=1&persist_headless=1"]];
}


- (void)updateTimerLabel
{
    NSString *currentTimerValue = [self.webView stringByEvaluatingJavaScriptFromString:@"$(\".time_running\").text()"];
    [self.timerLabel setText:currentTimerValue];
}





#pragma mark -
#pragma mark Authentication


- (IBAction)login:(id)sender
{
    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"https://mobiledev.instructure.com/login?mobile=1"]]];
    
    // Send data to watch:
    // See demos/feature_app_messages/weather.c in the native watch app SDK for the same definitions on the watch's end:
//    NSNumber *iconKey = @(0); // This is our custom-defined key for the icon ID, which is of type uint8_t.
    NSNumber *timerKey = @(0); // This is our custom-defined key for the temperature string.
    NSDictionary *update = @{ timerKey:@"Newtime" };
    [_targetWatch appMessagesPushUpdate:update onSent:^(PBWatch *watch, NSDictionary *update, NSError *error) {
        NSString *message = error ? [error localizedDescription] : @"Update sent!";
        [[[UIAlertView alloc] initWithTitle:nil message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
    }];
    
//    NSNumber *iconKey = @(0); // This is our custom-defined key for the icon ID, which is of type uint8_t.
//    NSNumber *temperatureKey = @(1); // This is our custom-defined key for the temperature string.
//    NSDictionary *update = @{ iconKey:[NSNumber numberWithUint8:weatherIconID],
//                              temperatureKey:[NSString stringWithFormat:@"%d\u00B0C", temperature] };
//    [_targetWatch appMessagesPushUpdate:update onSent:^(PBWatch *watch, NSDictionary *update, NSError *error) {
//        NSString *message = error ? [error localizedDescription] : @"Update sent!";
//        [[[UIAlertView alloc] initWithTitle:nil message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
//    }];
}

- (IBAction)logout:(id)sender
{
    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"https://mobiledev.instructure.com/logout"]]];
}



@end
