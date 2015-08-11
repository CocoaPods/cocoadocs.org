require File.expand_path('../spec_helper', __FILE__)
require '_utils'
require 'testing_idealist'

describe 'Counting test expectations' do

  def testingness_for file_path
	tester = TestingIdealist.new()
	tester.estimate_testingness_in_file file_path
  end

  it 'should properly count XCTest assertions' do
    testingness = testingness_for "spec/fixtures/specs/XCTest.m"
    testingness.should.equal ({ has_tests: true,  expectations: 3 })
  end

  it 'should properly count Specta expectations' do
    testingness = testingness_for "spec/fixtures/specs/ExpectaSpec.m"
    testingness.should.equal ({ has_tests: true,  expectations: 3 })
  end

  it 'should properly count Nimble expectations' do
  	testingness = testingness_for "spec/fixtures/specs/NimbleSpec.swift"
    testingness.should.equal ({ has_tests: true,  expectations: 3 })
  end

  it 'should properly count Kiwi expectations' do
  	testingness = testingness_for "spec/fixtures/specs/KiwiSpec.m"
    testingness.should.equal ({ has_tests: true,  expectations: 3 })
  end

  it 'should properly count Cedar expectations' do
  	testingness = testingness_for "spec/fixtures/specs/CedarSpec.mm"
    testingness.should.equal ({ has_tests: true,  expectations: 5 })
  end

  it 'should properly count OCHamcrest assertions' do
    testingness = testingness_for "spec/fixtures/specs/OCHamcrest.m"
    testingness.should.equal ({ has_tests: true,  expectations: 3 })
  end

  it 'should properly count FBSnapshotTestCase assertions' do
  	testingness = testingness_for "spec/fixtures/specs/FBSnapshotTests.m"
    testingness.should.equal ({ has_tests: true,  expectations: 2 })
  end
end
