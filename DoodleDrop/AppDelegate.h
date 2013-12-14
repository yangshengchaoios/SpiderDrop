//
//  AppDelegate.h
//  DoodleDrop
//
//  Created by mac hb on 13-4-9.
//  Copyright  2013年. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RootViewController;

@interface AppDelegate : NSObject <UIApplicationDelegate> {
	UIWindow			*window;
	RootViewController	*viewController;
}

@property (nonatomic, retain) UIWindow *window;

@end
