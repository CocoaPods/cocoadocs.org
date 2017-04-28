#!/usr/bin/env ruby

# Usage: cocoadocs-simple [podspec_url]
# Will generate a README, CHANGELOG, and metrics for CocoaDocs

require 'cocoapods-downloader'
require 'cocoapods-core'
require 'cocoapods'

require 'open-uri'

current_dir = File.dirname(File.expand_path(__FILE__))

# Ensure all the class files exist in scope
Dir[File.join(current_dir, 'classes/*.rb')].each do |file|
  require_relative(file)
end

# These all still need to be set, as the rest of the system basically relies on them :D
$specs_repo = 'CocoaPods/Specs'
$s3_bucket = 'cocoadocs.org'
$website_home = 'http://cocoadocs.org/'
$cocoadocs_specs_name = 'cocoadocs_specs'
$active_folder = 'activity'

def run
  specs_repo = 'CocoaPods/Specs'
  s3_bucket = 'cocoadocs.org'
  website_home = 'http://cocoadocs.org/'

  active_folder_name = $active_folder
  current_dir = File.dirname(File.expand_path(__FILE__))
  active_folder = File.join(current_dir, active_folder_name)

  # Assume the full url is first arg
  url = ARGV[0]
  spec = nil

  # Verify we're working with a CP Spec
  unless url.start_with? 'https://raw.githubusercontent.com/CocoaPods/Specs'
    puts 'Not running non-CocoaPods Spec URL'
    return
  end

  # Setup a local copy
  spec_name = url.split('/')[-1]
  podspec_path = active_folder + '/podspecs/' + spec_name

  # Put it in the filesystem
  FileUtils.mkdir_p(File.dirname(podspec_path))
  open(url) { |f| File.open(podspec_path, 'w') { |tmp| tmp.write(f.read) } }

  # Eval it, and process
  spec = Pod::Specification.from_file(podspec_path)

  download_location  = active_folder + "/download/#{spec.name}/#{spec.version}/#{spec.name}"
  docset_location    = active_folder + "/docsets/#{spec.name}/#{spec.version}/"
  readme_location    = active_folder + "/readme/#{spec.name}/#{spec.version}/README.html"
  changelog_location = active_folder + "/changelog/#{spec.name}/#{spec.version}/CHANGELOG.html"
  api_json_location  = active_folder + "/docsets/#{spec.name}/#{spec.version}/stats.json"

  # Download the source code
  downloader = SourceDownloader.new(spec: spec, download_location: download_location, overwrite: true)
  FileUtils.rm_r download_location if File.directory?(download_location)
  downloader.download_pod_source_files

  # Generate a settings object for the downloaded source
  settings = CocoaDocsSettings.settings_at_location download_location

  # Create a README and CHANGELOG
  readme = ReadmeGenerator.new(spec: spec, readme_location: readme_location, changelog_location: changelog_location, settings: settings)
  readme.create_readme
  readme.create_changelog

  # We should only update trunk metrics for the most recent version
  version_metadata = SpecMetadataGenerator.new(spec: spec, docset_path: docset_location)
  version_metadata.generate

  if version_metadata.latest_version?
    # Generate CLOC stats for the metrics
    cloc = ClocStatsGenerator.new(spec: spec, source_download_location: download_location)
    cloc_results = cloc.generate

    # Generate testing info for the downloaded source
    tester = TestingIdealist.new(spec: spec, download_location: download_location)
    testing_estimate = tester.testimate

    # Upload stats
    stats = StatsGenerator.new(
      spec: spec,
      cloc_results: cloc_results,
      readme_location: readme_location,
      changelog_location: changelog_location,
      download_location: download_location,
      doc_percent: nil,
      test_carthage: false,
      testing_estimate: testing_estimate,
      docset_location: docset_location
    )
    stats.upload

    # Update the image for Slack
    SocialImageGenerator.new(spec: spec, output_folder: docset_location, stats_generator: stats).generate
  end

  # Upload the files to S3
  generator = WebsiteGenerator.new(generate_json: false, spec: spec)

  server_folder = "docsets"
  generator.upload_folder "/readme/#{spec.name}/#{spec.version}/README.html", "/#{server_folder}/#{spec.name}/", "put"
  generator.upload_folder "/changelog/#{spec.name}/#{spec.version}/CHANGELOG.html", "/#{server_folder}/#{spec.name}/", "put"

  # Give a clickable link
  puts '* - ' + website_home + 'docsets/' + spec.name + '/' + spec.version.to_s + '/'

rescue StandardError => e
  log_error(spec, e) unless spec.nil?

  open('error_log.txt', 'a') do |f|
    f.puts "\n\n\n --------------#{spec}-------------"
    f.puts e.message
    f.puts '------'
    f.puts e.backtrace.inspect
  end

  puts "--------------#{spec}-------------".red
  puts e.message.red
  puts '------'
  puts e.backtrace.inspect.red
end

def log_error(spec, e)
  error_path = "errors/#{spec.name}/#{spec.version}/error.json"
  FileUtils.mkdir_p(File.dirname(error_path))
  FileUtils.rm(error_path) if File.exist? error_path

  open(error_path, 'a') do |f|
    report = {
      'message' => e.message.encode('utf-8', 'binary', undef: :replace),
      'trace' => e.backtrace
    }
    f.puts report.to_json.to_s
  end
end

run
