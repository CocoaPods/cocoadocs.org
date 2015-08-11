#import "Specta.h"
#import <Expecta/Expecta.h>

SpecBegin(Expecta)

describe(@"Expecta Expectations", ^{
    it(@"should work", ^{
        expect(2).notTo.equal(1);
        expect(@"abc").to.equal(@"abc");
        expect([@"str" containsString"s"]).to.equal(YES);
    });
});

SpecEnd
