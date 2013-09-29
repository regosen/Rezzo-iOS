//
//  RezzoAppDelegate.m
//  Rezzo
//
//  Created by Rego on 5/16/13.
//  Copyright (c) 2013 Regaip Sen. All rights reserved.
//

#import "RezzoAppDelegate.h"
#import "MainViewController.h"
#import "Brain.h"

#import "SSKeychain.h"
#import <Security/Security.h>

@implementation RezzoAppDelegate

// from http://stackoverflow.com/questions/12570799/uinavigationcontroller-popviewcontrolleranimated-crash-in-ios-6
- (NSString *)getUUID
{
    // getting the unique key (if present ) from keychain , assuming "your app identifier" as a key
    NSString *uuid = [SSKeychain passwordForService:@"Doblet" account:@"user"];
    if (uuid == nil)
    {
        // if this is the first time app lunching, create key for device
        CFUUIDRef theUUID = CFUUIDCreate(NULL);
        CFStringRef string = CFUUIDCreateString(NULL, theUUID);
        CFRelease(theUUID);
        uuid = (__bridge NSString *)string;
        
        // save newly created key to Keychain
        [SSKeychain setPassword:uuid forService:@"Doblet" account:@"user"];
        // this is the one time process
    }
    return uuid;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [TestFlight setDeviceIdentifier:[self getUUID]];
    [TestFlight takeOff:@"ccd159bd-fc2f-44df-94c4-351b16798217"];
    // Override point for customization after application launch.
    [Brain get];
    UITabBarController *tabController = (UITabBarController *)self.window.rootViewController;
    tabController.delegate = self;
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
