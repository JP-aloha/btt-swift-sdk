//
//  AppInitLog.m
//  App
//
//  Created by jaiprakash bokhare on 07/05/24.
//





#import "AppNotificationLogger.h"
#import "NotificationLog.h"

#if TARGET_OS_IOS
#import <UIKit/UIKit.h>
#endif


NSMutableArray<NotificationLog *> *appNotifications;
NSMutableArray *observers;

@interface AppNotificationLogger()

@end

@implementation AppNotificationLogger

+ (void)load {
    
    observers = [[NSMutableArray alloc] init];
    appNotifications = [[NSMutableArray<NotificationLog *> alloc] init];

#if TARGET_OS_IOS
    
    [observers addObject:[NSNotificationCenter.defaultCenter addObserverForName:UIApplicationDidFinishLaunchingNotification object:nil queue:nil usingBlock:^(NSNotification * _Nonnull notification) {
        NotificationLog * notificationLog = [[NotificationLog alloc] initWithNotification:notification time:[NSDate date]];
        [appNotifications addObject:notificationLog];
    }]];
    
    [observers addObject:[NSNotificationCenter.defaultCenter addObserverForName:UIApplicationDidEnterBackgroundNotification object:nil queue:nil usingBlock:^(NSNotification * _Nonnull notification) {
        [appNotifications removeAllObjects];
    }]];
      
    [observers addObject:[NSNotificationCenter.defaultCenter addObserverForName:UIApplicationWillEnterForegroundNotification object:nil queue:nil usingBlock:^(NSNotification * _Nonnull notification) {
        NotificationLog * notificationLog = [[NotificationLog alloc] initWithNotification:notification time:[NSDate date]];
        [appNotifications addObject:notificationLog];
    }]];
    
    [observers addObject:[NSNotificationCenter.defaultCenter addObserverForName:UIApplicationDidBecomeActiveNotification object:nil queue:nil usingBlock:^(NSNotification * _Nonnull notification) {
        NotificationLog * notificationLog = [[NotificationLog alloc] initWithNotification:notification time:[NSDate date]];
        [appNotifications addObject:notificationLog];
    }]];
#endif
}

+(NSMutableArray<NotificationLog *> *)getNotifications{
    return appNotifications;
}

+(void) removeObserver{
    for (id observer in observers) {
        [[NSNotificationCenter defaultCenter] removeObserver:observer];
    }
    observers = nil;
    [appNotifications removeAllObjects];
}

@end

