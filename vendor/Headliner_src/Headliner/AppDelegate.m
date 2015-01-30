//
//  AppDelegate.m
//  Headliner
//
//  Created by Orta on 1/30/15.
//  Copyright (c) 2015 Orta. All rights reserved.
//

#import "AppDelegate.h"
#import "ORWhiteView.h"


@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    NSArray *arguments = [[NSProcessInfo processInfo] arguments];

    [self.theView lockFocus];
    NSBitmapImageRep *rep = [[NSBitmapImageRep alloc] initWithFocusedViewRect:self.theView.bounds];
    [self.theView unlockFocus];

    NSData *data = [rep representationUsingType:NSPNGFileType properties:nil];
    [data writeToFile:arguments[8] atomically:YES];
    exit(0);
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

@end
