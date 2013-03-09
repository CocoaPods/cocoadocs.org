require 'cocoapods-downloader'
require 'cocoapods-core'
require 'cocoapods'

require 'ostruct'
require 'yaml'
require 'json'
require "fileutils"
require "shellwords"

@current_dir = File.dirname(File.expand_path(__FILE__)) 
@log_all_terminal_commands = false;

#constrain all downloads etc into one subfolder
@active_folder_name = "activity"
@active_folder = @current_dir + "/" + @active_folder_name

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
  
  headers = headers_for_spec_at_location spec, from
  headers.map! { |header| Shellwords.escape header }
  
  docset_command = [
    "appledoc",
    "--project-name #{spec.name}",                         # name in top left
    "--project-company '#{contributors_to_spec(spec)}'",   # name in top right
    "--project-version #{version}",                        # project version
    "--no-install-docset",                                 # don't make a duplicate
    "--publish-docset",                                    # create an ATOM file??
    "--company-id com.#{id}.#{version}",                   # the id for the 
    "--templates ./appledoc_templates",                    # use the custom template
    "--verbose 5",                                         # give some useful logs

    "--docset-atom-filename '#{to}../#{spec.name}.atom' ",
    "--docset-feed-url http://cocoadocs.org/docsets/#{spec.name}/#{spec.name}.xml",
    "--docset-feed-name #{spec.name}",                    

    "--keep-undocumented-objects",                         # not everyone will be documenting
    "--keep-undocumented-members",                         # so we should at least show something
    "--search-undocumented-doc",
    
    "--index-desc #{from}/#{spec.name}/README.md",                      # if there's a readme, throw it in
    "--output #{to}",                                      # where should we throw stuff
    *headers
  ]

  puts docset_command.join(' ')

  system docset_command.join(' ')

  # Move the html out of the Documents folder into one called html
  system `cp -R #{to}docset/Contents/Resources/Documents #{to}html`
  
  puts "\n\n\n"
end

# Upload the docsets folder to s3

def upload_docsets_to_s3
  puts "Uploading docsets folder"
  
  upload_command = []
  upload_command << "s3cmd sync"
  upload_command << "--recursive --skip-existing  --acl-public"
  upload_command << "#{@active_folder_name}/docsets/ s3://cocoadocs.org/"

  puts upload_command.join(' ')
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
  
  puts "----------------------"
  puts "Looking at #{@spec.name}"
  
  download_location = @active_folder + "/download/#{@spec.name}/#{@spec.version}/"
  docset_location = @active_folder + "/docsets/#{@spec.name}/#{@spec.version}/"
  cache_path = @active_folder + "/download_cache"
  
  unless File.directory? download_location
    download_podfile_files @spec, download_location, cache_path
  end

  #unless File.directory? docset_location
    create_docset_for_spec @spec, download_location, docset_location
#  end
end


def headers_for_spec_at_location spec, download_location
  sandbox = Pod::Sandbox.new( download_location )
  pathlist = Pod::Sandbox::PathList.new( Pathname.new(download_location) )  

  headers = []
  
  spec.available_platforms.each do |platform|
    installer = Pod::Installer::PodSourceInstaller.new(sandbox, {platform => [spec]} )
    sources = installer.send(:used_files).delete_if do |path|
        !path.include? ".h"
    end
    headers += sources
  end
  
  headers.uniq
end

# Update or clone Cocoapods/Specs

def update_specs_repo
  repo = @active_folder + "/Specs"
  unless File.exists? repo
    command "git clone git@github.com:CocoaPods/Specs.git"
  else
    run_git_command_in_specs "pull origin master"
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

# We have to run commands from a different git root if we want to do anything in the Specs repo

def run_git_command_in_specs git_command
   `git --git-dir=./#{@active_folder_name}/Specs/.git #{git_command}`
end

# get started from a webhook

def handle_webhook webhook_payload
  before = webhook_payload["before"]
  after = webhook_payload["after"]
  updated_specs = specs_for_git_diff before, after
 

  updated_specs.lines.each_with_index do |spec_filepath, index|
    if index == 2
      create_and_upload_spec "/Specs/" + spec_filepath.strip
    end
  end

 # puts "updated ---- \n" + updated_specs
end

# allow logging of terminal commands

def command command_to_run
  if @log_all_terminal_commands
    puts command_to_run
  end
  
  system command_to_run
end

# -------------------------------------------------------------------------------------------------
# App example data. Instead of using the webhook, here's two 

puts ""
handle_webhook({ "before" => "dbaa76f854357f73934ec609965dbd77022c30ac", "after" => "f09ff7dcb2ef3265f1560563583442f99d5383de" })

# choo choo
upload_docsets_to_s3
