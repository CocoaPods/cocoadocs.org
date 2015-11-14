//
//  main.m
//  Headliner
//
//  Created by Orta on 1/30/15.
//  Copyright (c) 2015 Orta. All rights reserved.
//

#import <Cocoa/Cocoa.h>

int main(int argc, const char * argv[]) {

    NSArray *arguments = [[NSProcessInfo processInfo] arguments];
    NSNib *nib = [[NSNib alloc] initWithNibNamed:@"HeadlineView" bundle:nil];

    NSArray *views = nil;
    [nib instantiateWithOwner:nil topLevelObjects:&views];

    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"className == %@", [NSView className]];
    NSView *rootView = [[views filteredArrayUsingPredicate:predicate] firstObject];
    NSView *actualView = [[rootView subviews] firstObject];

    NSBitmapImageRep* rep = [actualView bitmapImageRepForCachingDisplayInRect:actualView.bounds];
    [actualView cacheDisplayInRect:actualView.bounds toBitmapImageRep:rep];

    NSData *data = [rep representationUsingType:NSPNGFileType properties:@{}];
    [data writeToFile:arguments[8] atomically:YES];
    exit(0);

}
