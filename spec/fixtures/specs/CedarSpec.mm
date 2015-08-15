#import <Cedar/Cedar.h>

using namespace Cedar::Matchers;

SPEC_BEGIN(CedarSpec)

describe(@"Cedar Expectations", ^{
    // Words in the comments should not contribute to the total count
    it(@"should work", ^{
        @"abc" should equal(@"abc");
        @"str" should contain(@"s"); // This line has a comment
        2 should_not equal(1);
        NO should_not be_truthy;
        expect(@"cat").to_not(equal(@"dog")); // Alternate matcher syntax
    });
});

SPEC_END
