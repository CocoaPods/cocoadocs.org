//
//  AppDelegate.h
//  Headliner
//
//  Created by Orta on 1/30/15.
//  Copyright (c) 2015 Orta. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <AppKit/AppKit.h>

@class ORWhiteView;

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (weak) IBOutlet ORWhiteView *theView;

@end

