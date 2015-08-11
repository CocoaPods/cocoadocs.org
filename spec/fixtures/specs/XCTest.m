#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>

@interface ExampleTests : XCTestCase

@end

@implementation ExampleTests

- (void)testOne {
    XCTAssert(YES);
    XCTAssertEqualObjects(@1, [NSNumber numberWithInteger:1]);
}

- (void)testFail {
    XCTFail("No good");
}

@end
