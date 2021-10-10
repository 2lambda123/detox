//
//  DTXDetoxApplication.h
//  DetoxTestRunner
//
//  Created by Alon Haiut on 10/10/2021.
//  Copyright © 2021 Wix. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "DetoxIPCAPI.h"

NS_ASSUME_NONNULL_BEGIN

@class DTXDetoxApplication;

@protocol DTXDetoxApplicationDelegate <NSObject>

- (void)application:(DTXDetoxApplication*)application didCrashWithDetails:(NSDictionary*)details;

@end

@interface DTXDetoxApplication : XCUIApplication

@property (nonatomic, weak) id<DTXDetoxApplicationDelegate> delegate;
@property (nonatomic, strong, readonly) id<DetoxHelper> detoxHelper;

@property (nonatomic) NSUInteger launchWaitForDebugger;
@property (nonatomic, strong, nullable) NSURL* launchRecordingPath;
@property (nonatomic, strong, nullable) NSDictionary* launchUserNotification;
@property (nonatomic, strong, nullable) NSDictionary* launchUserActivity;
@property (nonatomic, strong, nullable) NSURL* launchOpenURL;
@property (nonatomic, strong, nullable) NSString* launchSourceApp;

- (BOOL)waitForIdleWithTimeout:(NSTimeInterval)timeout;

@end

NS_ASSUME_NONNULL_END
