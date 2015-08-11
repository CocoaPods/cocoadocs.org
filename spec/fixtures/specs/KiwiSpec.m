#import <Kiwi/Kiwi.h>

SPEC_BEGIN(KiwiSpec)

describe(@"Kiwi Expectations", ^{
    it(@"should work", ^{
        [[@"a" shouldNot] beNil];
        [[@"b" should] beKindOfClass:[NSString class]];
        [[theValue([@"42" integerValue]) should] equal:theValue(42)];
    });
});

SPEC_END
