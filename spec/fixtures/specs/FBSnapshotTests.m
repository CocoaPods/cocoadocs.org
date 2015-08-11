#import <XCTest/XCTest.h>
#import <FBSnapshotTestCase/FBSnapshotTestCase.h>

@interface FBSnapshotTests : FBSnapshotTestCase
@end

@implementation FBSnapshotTests

- (void)testVerification {
    FBSnapshotVerifyView([[UIView alloc] init], nil);
    FBSnapshotVerifyLayer([[CALayer alloc] init], nil);
}

@end
