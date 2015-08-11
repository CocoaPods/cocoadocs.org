import Quick
import Nimble

class NimbleSpec: QuickSpec {
    override func spec() {
        describe("Nimble Expectations") {
            it("should work") {
                expect(1).toNot(equal(2))
                expect("abc").to(equal("abc"))
                expect("str").to(contain("s"))
            }
        }
    }
}
