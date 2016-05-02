require 'cocoapods'
require 'json'
require 'pathname'
require 'tmpdir'
require 'xcodeproj'

# based on https://github.com/neonichu/pod-utils/blob/master/has_tests.rb
# thanks Boris!

class TestingIdealist
  include HashInit
  attr_accessor :spec, :download_location

  def testimate

		get_projects_in_download.reduce(0) do |expectations, project_path|
      next 0 unless File.exist?(project_path)
      project = nil
      begin
        # Sometimes we get weird characters in the plists
        # that crash the idealist, see ATInternet-iOS-Swift-SDK v2.0.8.2
        project = path_to_project project_path
      rescue => e
        next
      end
      expectations + find_test_target(project).reduce(0) do |target_expectations, target|
        files = get_source_files_for_target target

        target_estimate = files.map do |file|
          estimate_testingness_in_file file
        end.select do |estimate_hash|
          estimate_hash[:has_tests]
        end.reduce(0) do |num, hash|
          num + hash[:expectations]
        end

        puts "Found #{target_estimate} for #{target}"

        target_expectations + target_estimate
      end
    end
  end

  # returns a hash of a testing estimate for the file at the path

  def estimate_testingness_in_file file_path
    content = File.read file_path
    line_count = content.lines.length

    has_no_tests = { has_tests: false,  expectations: 0 }

    # Is it the default pod-template still?
    if content.include?('describe(@"these will fail') || content.include?('context(@"will fail')
      return has_no_tests
    end

    # Is it the default xcode file?
    # 40 = XC6 + ObjC, 36 = XC6 + Swift,
    if line_count == 40 || line_count == 36
      if content.include?("- (void)testExample") || content.include?("func testExample() {")
        return has_no_tests
      end
    end

    # XC5 + ObjC
    if line_count == 36 && content.include?('XCTFail(@"No implementation for \"%s\"", __PRETTY_FUNCTION__)');
      return has_no_tests
    end

    regexes = [/XCTAssert|XCTFail/,                 # XCTest
               /expect\(/,                          # Expecta, Nimble
               /should\]|shouldNot\]/,              # Kiwi
               /assertThat/,                        # OCHamcrest
               / should .*;| should_not |expect\(/, # Cedar
               /FBSnapshotVerify/,                  # FBSnapshotTestCase
               /property\(/                         # SwiftCheck
             ]

    expectation_count = regexes.map do |expectation_regex|
      content.scan(expectation_regex).length
    end.sort.last

   return has_no_tests if expectation_count == 0
   return { has_tests: true, expectations:expectation_count }
  end

  # gets the (.swift or .m files for the test target)
  def get_source_files_for_target target
    target.source_build_phase.files.to_a.map do |pbx_build_file|
      pbx_build_file.file_ref.real_path.to_s

    end.select do |path|
      path.end_with?(".m", ".mm", ".swift")

    end.select do |path|
      File.exists? path
    end
  end

  def path_to_project path
    Xcodeproj::Project.open path
  end

  def get_projects_in_download
  	Dir.glob(@download_location + "/**/**/**/**/**/**/*.xcodeproj")
  end

  def find_test_target(project)
  	project.targets.select do |target|
  		product_type = nil
      begin
  			product_type = target.product_type.to_s
      rescue
        next
      end
      is_test_bundle = %w(bundle.ui-testing bundle.unit-test).any? do |testing_type|
        product_type.end_with?(testing_type)
      end

      is_test_bundle || target.name.downcase.scan(/specs|tests/).length > 0
    end
  end

end
