#!/usr/bin/env ruby

# Usage: cocoapods-simple [podspec_url]
#    or: cocoapods-simple [pod name]

# Will generate a README, CHANGELOG, and metrics for CocoaDocs

require 'cocoapods-downloader'
require 'cocoapods-core'
require 'cocoapods'

require 'open-uri'
require "octokit"

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
$active_folder = 'activity_pods'

def run
  active_folder_name = $active_folder
  current_dir = File.dirname(File.expand_path(__FILE__))
  active_folder = File.join(current_dir, active_folder_name)

  # Assume the full url is first arg
  url = ARGV[0]
  spec = nil

  unless url.start_with? "http"
    url = path_for_spec_with_name(url)
  end
  
  # Verify we're working with a CP Spec
  unless url.start_with? 'https://raw.githubusercontent.com/CocoaPods/Specs'
    puts 'Not running non-CocoaPods Spec URL'
    puts 'Needs to be: https://raw.githubusercontent.com/CocoaPods/Specs/XXX'
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
      cloc_top: cloc.get_top_cloc(cloc_results),
      readme_location: readme_location,
      changelog_location: changelog_location,
      download_location: download_location,
      doc_percent: nil,
      test_carthage: false,
      testing_estimate: testing_estimate,
      docset_location: docset_location
    )
    stats.upload
  end

  # Upload the files to S3
  generator = WebsiteGenerator.new(generate_json: false, spec: spec)

  server_folder = "docsets"
  rendered_readme_path = active_folder_name + "/readme/#{spec.name}/#{spec.version}/README.html"
  server_readme_path = "/#{server_folder}/#{spec.name}/#{spec.version}/README.html"
  rendered_changelog_path = active_folder_name +"/changelog/#{spec.name}/#{spec.version}/CHANGELOG.html"
  server_changelog_path = "/#{server_folder}/#{spec.name}/#{spec.version}/README.html"

  generator.upload_file rendered_readme_path, server_readme_path, "cp" if File.exist? rendered_readme_path
  generator.upload_file rendered_changelog_path, server_changelog_path, "cp" if File.exist? rendered_changelog_path

  # Give a clickable link
  puts '* [pods] - ' + "http://cocoapods.org/pods/" + spec.name

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

def path_for_spec_with_name(name)
  update_specs_repo
  
  specs = File.join($active_folder, $cocoadocs_specs_name)
  source = Pod::Source.new(specs)
  set = source.search(Pod::Dependency.new(name))

  if set
    absolute_path = set.highest_version_spec_path.to_s
    path = absolute_path.split(specs).last
    "https://raw.githubusercontent.com/CocoaPods/Specs" + path
  end
end

def update_specs_repo
  repo = File.join($active_folder, $cocoadocs_specs_name)
  unless File.exists? repo
    vputs "Creating Specs Repo for #{$specs_repo}"
    unless repo.include? "://"
      command "git clone git://github.com/#{$specs_repo}.git \"#{repo}\""
    else
      command "git clone \"#{$specs_repo}\" \"#{repo}\""
    end
  else
    vputs "Updating Specs Repo"
    run_git_command_in_specs "pull origin master"
    `pod repo update`
  end
end

# We have to run commands from a different git root if we want to do anything in the Specs repo
def run_git_command_in_specs git_command
  Dir.chdir(File.join($active_folder, $cocoadocs_specs_name)) do
    vputs "git #{git_command}"
    system "git #{git_command}"
  end
end

run
