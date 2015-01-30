//
//  ORHeadlineTransformer.m
//  Headliner
//
//  Created by Orta on 1/30/15.
//  Copyright (c) 2015 Orta. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "ORHeadlineTransformer.h"

@implementation ORHeadlineTransformer

- (void)awakeFromNib
{

    NSArray *arguments = [[NSProcessInfo processInfo] arguments];

    // Only for running with cmd + r
    if (arguments.count == 3){
        arguments = @[@"", @"AFNetworking", @"A delightful iOS and OS X networking framework, A delightful iOS and OS X networking framework A delightful iOS and OS X networking framework", @"pod 'HockeySDK', '3.5.4'", @"1", @"232", @"MIT", @"@£"];
    }

    [self.title setStringValue:arguments[1]];
    [self.body setStringValue:arguments[2]];
    [self.podfile setStringValue:arguments[3]];
    [self.one setStringValue:arguments[4]];
    [self.two setStringValue:arguments[5]];
    [self.three setStringValue:arguments[6]];
    [self.four setStringValue:arguments[7]];
}

@end
