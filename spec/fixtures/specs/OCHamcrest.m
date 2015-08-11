#import <XCTest/XCTest.h>

#define HC_SHORTHAND
#import <OCHamcrest/OCHamcrest.h>

@interface OCHamcrestTest : XCTestCase
@end

@implementation OCHamcrestTest

- (void)testOne {
    assertThat(@"abc", isNot(@"bcd"));
    assertThat(@"str", containsString(@"s"));
    assertThatInt(42, is(@42));
}

@end
