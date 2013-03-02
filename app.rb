require 'cocoapods-downloader'
require 'cocoapods-core'
require 'ostruct'
require 'yaml'
require 'json'
require "fileutils"
require 'aws/s3'

puts "\n started"

@current_dir = File.dirname(File.expand_path(__FILE__)) 

# Create a docset based on the spec

def create_docset_for_spec spec, location  
  docset_command = []
  docset_command << %Q[appledoc  --create-html --keep-intermediate-files]
  docset_command << "--project-name #{spec.name}"
  docset_command << "--project-company test"
  docset_command << "--no-install-docset"
  docset_command << "--company-id com.#{spec.name.downcase}.#{spec.version.to_s.downcase}"
  docset_command << "--output #{ location.clone.sub "download", "docsets" }"
  docset_command << location
  system docset_command.join(' ')
end

# Upload the docsets folder to s3

def upload_docsets_to_s3
  puts "Uploading docsets folder"
  
  upload_command = []
  upload_command << "s3cmd sync"
  upload_command << "--recursive --skip-existing  --acl-public"
  upload_command << "docsets s3://cocoadocs.org/"
  system upload_command.join(' ')
end

# Use CocoaPods Downloader to download to the download folder

def download_podfile_files spec, filepath, cache_path
  downloader = Pod::Downloader.for_target(filepath, spec.source)
  downloader.cache_root = cache_path
  downloader.download
end

# Take a spec path and download details, create the docset
# then upload to s3

def create_and_upload_spec filepath
  @spec = eval File.open(@current_dir + filepath).read 
  
  download_location = @current_dir + "/download/#{@spec.name}/#{@spec.version}/"
  docset_location = @current_dir + "/docsets/#{@spec.name}/#{@spec.version}/"
  cache_path = @current_dir + "/download_cache"
  
  unless File.directory? download_location
    download_podfile_files @spec, download_location, cache_path
  end

  unless File.directory? docset_location
    create_docset_for_spec @spec, download_location
  end
end

# Update or clone  

def update_specs_repo
  repo = @current_dir + "/Specs"
  unless File.exists? repo
    `git clone git@github.com:CocoaPods/Specs.git`
  else
    `git --git-dir=./Specs/.git pull origin master;`
  end  
end

# returns an array from the diff log for the commit changes

def get_diff_log start_commit, end_commit
  diff_log = `git --git-dir=./Specs/.git diff --name-status #{start_commit} #{end_commit}`
  diff_log.lines.map do |line|

    line.slice!(0).strip!
    line.gsub! /\t/, ''

  end.join
end

# get started from a webhook

def handle_webhook webhook_payload
  before = webhook_payload["before"]
  after = webhook_payload["after"]
  get_diff_log before, after
end

puts ""

podfile_file_path = @current_dir + "/example/AFNetworking.podspec"

# create_and_upload_spec podfile_file_path
update_specs_repo
updated_specs = get_diff_log "dbaa76f854357f73934ec609965dbd77022c30ac", "f09ff7dcb2ef3265f1560563583442f99d5383de"

updated_specs.lines.each do |spec_filepath|
  create_and_upload_spec "/Specs/" + spec_filepath.strip
end

upload_docsets_to_s3

puts updated_specs
puts "done"