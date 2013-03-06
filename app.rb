require 'cocoapods-downloader'
require 'cocoapods-core'
require 'ostruct'
require 'yaml'
require 'json'
require "fileutils"
require 'aws/s3'


puts "\n started"

@current_dir = File.dirname(File.expand_path(__FILE__)) 
@log_all_terminal_commands = true;

#constrain all downloads etc into one subfolder
@active_folder_name = "activity"
@active_folder = @current_dir + "/" + @active_folder_name

def command command_to_run
  if @log_all_terminal_commands
    puts command_to_run
  end
  
  system command_to_run
end

# A rough function for getting the contributors

def contributors_to_spec spec
  return spec.authors if spec.authors.is_a? String
  return spec.authors.join(" ") if spec.authors.is_a? Array
  return spec.authors.keys.join(" ") if spec.authors.is_a? Hash
end

# Create a docset based on the spec

def create_docset_for_spec spec, from, to  
  version = spec.version.to_s.downcase
  id = spec.name.downcase
  
  docset_command = [
    "appledoc",
    "--create-html --keep-intermediate-files",
    "--project-name #{spec.name}",
    "--project-company '#{contributors_to_spec(spec)}'", 
    "--no-install-docset", 
    "--company-id com.#{id}.#{version}",
    "--output #{to}",
    "--templates ./appledoc_templates",
    "--verbose 3",
    "--docset-feed-url http://cocoadocs.org/docsets/#{spec.name}/#{version}/ATOM.xml",
    "--docset-feed-name #{spec.name}",
    from
  ]

  command docset_command.join(' ')
#  puts docset_command.join(' ')

end

# Upload the docsets folder to s3

def upload_docsets_to_s3
  puts "Uploading docsets folder"
  
  upload_command = []
  upload_command << "s3cmd sync"
  upload_command << "--recursive --skip-existing  --acl-public"
  upload_command << "docsets s3://cocoadocs.org/"
  command upload_command.join(' ')
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
  @spec = eval File.open(@active_folder + filepath).read 
  
  download_location = @active_folder + "/download/#{@spec.name}/#{@spec.version}/"
  docset_location = @active_folder + "/docsets/#{@spec.name}/#{@spec.version}/"
  cache_path = @active_folder + "/download_cache"
  
  unless File.directory? download_location
    download_podfile_files @spec, download_location, cache_path
  end

  unless File.directory? docset_location
    create_docset_for_spec @spec, download_location, docset_location
  end
end

# Update or clone Cocoapods/Specs

def update_specs_repo
  repo = @active_folder + "/Specs"
  unless File.exists? repo
    command "git clone git@github.com:CocoaPods/Specs.git"
  else
    # whilst offline
#    run_git_command_in_specs "pull origin master"
  end  
end

# returns an array from the diff log for the commit changes

def specs_for_git_diff start_commit, end_commit
  diff_log = run_git_command_in_specs "diff --name-status #{start_commit} #{end_commit}"
  diff_log.lines.map do |line|

    line.slice!(0).strip!
    line.gsub! /\t/, ''

  end.join
end

def run_git_command_in_specs git_command
   `git --git-dir=./#{@active_folder_name}/Specs/.git #{git_command}`
end

# get started from a webhook

def handle_webhook webhook_payload
  before = webhook_payload["before"]
  after = webhook_payload["after"]
  get_diff_log before, after
end

puts ""

update_specs_repo
updated_specs = specs_for_git_diff "dbaa76f854357f73934ec609965dbd77022c30ac", "f09ff7dcb2ef3265f1560563583442f99d5383de"

updated_specs.lines.each do |spec_filepath|
  create_and_upload_spec "/Specs/" + spec_filepath.strip
end

# choo choo
# upload_docsets_to_s3

puts "updated ---- \n" + updated_specs