//
//  ORHeadlineTransformer.h
//  Headliner
//
//  Created by Orta on 1/30/15.
//  Copyright (c) 2015 Orta. All rights reserved.
//

#import <Foundation/Foundation.h>

@class NSTextField, ORWhiteView;
@interface ORHeadlineTransformer : NSObject

@property (weak) IBOutlet NSTextField *title;
@property (weak) IBOutlet NSTextField *body;
@property (weak) IBOutlet NSTextField *podfile;

@property (weak) IBOutlet NSTextField *one;
@property (weak) IBOutlet NSTextField *two;
@property (weak) IBOutlet NSTextField *three;
@property (weak) IBOutlet NSTextField *four;


@end
