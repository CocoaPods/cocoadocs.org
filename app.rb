require 'cocoapods-downloader'
require 'cocoapods-core'
require 'cocoapods'

require 'ostruct'
require 'yaml'
require 'json'
require "fileutils"
require "shellwords"
require "colored"

require 'tilt'
require "slim"

require_relative "classes/utils.rb"
require_relative "classes/spec_extensions.rb"
require_relative "classes/website_generator.rb"

@short_test_webhook = true
@verbose = true
@log_all_terminal_commands = true
@upload_to_s3 = false

@fetch_specs = false

@current_dir = File.dirname(File.expand_path(__FILE__)) 

#constrain all downloads etc into one subfolder
@active_folder_name = "activity"
@active_folder = @current_dir + "/" + @active_folder_name

# A rough function for getting the contributors

# Create a docset based on the spec

def create_docset_for_spec spec, from, to
  vputs "Creating docset"
  
  version = spec.version.to_s.downcase
  id = spec.name.downcase
  cocoadocs_id = "cocoadocs"
  
  headers = headers_for_spec_at_location spec
  headers.map! { |header| Shellwords.escape header }
  vputs "Found #{headers.count} header files"
  
  docset_command = [
    "appledoc",
    "--project-name #{spec.name}",                         # name in top left
    "--project-company '#{spec.or_contributors_to_spec}'",   # name in top right
    "--project-version #{version}",                        # project version
    "--no-install-docset",                                 # don't make a duplicate

    "--company-id #{cocoadocs_id}",                        # the id for the 
    "--templates ./appledoc_templates",                    # use the custom template
    "--verbose 3",                                         # give some useful logs

    "--keep-intermediate-files",                           # space for now is OK
    "--create-html",                                       # eh, nice to have
    "--publish-docset",                                    # this should create atom
    
#    "--docset-atom-filename '#{to}../#{spec.name}.atom' ",
#    "--docset-feed-url http://cocoadocs.org/docsets/#{spec.name}/#{spec.name}.xml",
   "--docset-feed-name #{spec.name}",                    

    "--keep-undocumented-objects",                         # not everyone will be documenting
    "--keep-undocumented-members",                         # so we should at least show something
    "--search-undocumented-doc",                           # uh? ( no idea what this does... )
    
    "--output #{to}",                                      # where should we throw stuff
    *headers
  ]

  readme = readme_path spec
  if readme
    docset_command.insert(3, "--index-desc #{readme_path spec}")
  end


  command docset_command.join(' ')

  # Move the html out of the Documents folder into one called html
#  docset_location = "#{to}/#{cocoadocs_id}.#{spec.name}.docset"
 # `cp -R #{docset_location}/Contents/Resources/Documents #{to}html`

  #remove to add back docsets
  #`rm -Rf #{docset_location}`
end

# Use CocoaPods Downloader to download to the download folder

def download_podfile_files spec, filepath, cache_path
  vputs "Downloading files for podspec #{spec.name} v #{spec.version}"
  downloader = Pod::Downloader.for_target(filepath, spec.source)
  downloader.cache_root = cache_path
  downloader.download
end

# Take a spec path and download details, create the docset
# then upload to s3

def create_and_document_spec filepath
  spec = eval File.open(filepath).read 
  
  puts "\n ----------------------"
  puts "\n Looking at #{spec.name} #{spec.version} \n".bold.blue

  
  download_location = @active_folder + "/download/#{spec.name}/#{spec.version}/#{spec.name}"
  docset_location = @active_folder + "/docsets/#{spec.name}/#{spec.version}/"
  cache_path = @active_folder + "/download_cache"
  
  unless File.exists? download_location
    download_podfile_files spec, download_location, cache_path
  end
  
  create_docset_for_spec spec, download_location, docset_location
  puts "\n\n\n"
end

# Use cocoapods to get the header files for a specific spec

def headers_for_spec_at_location spec
  download_location = @active_folder + "/download/#{spec.name}/#{spec.version}/"
    
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

def readme_path spec
  download_location = @active_folder + "/download/#{spec.name}/#{spec.version}/#{spec.name}"
  ["README.md", "README.markdown", "README.mdown"].each do |potential_name|
    potential_path = download_location + "/" + potential_name
    if File.exists? potential_path
      return potential_path
    end
  end
  nil
end

# Update or clone Cocoapods/Specs

def update_specs_repo
  repo = @active_folder + "/Specs"
  unless File.exists? repo
    vputs "Creating Specs Repo"
    command "git clone git@github.com:CocoaPods/Specs.git #{repo}"
  else
    if @fetch_specs
      vputs "Updating Specs Repo"
      run_git_command_in_specs "stash"
      run_git_command_in_specs "pull origin master"
    end
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
  Dir.chdir("#{@active_folder_name}/Specs") do
   `git #{git_command}`  
  end
end

# get started from a webhook

def handle_webhook webhook_payload
  before = webhook_payload["before"]
  after = webhook_payload["after"]
  vputs "Got a webhook notification for #{before} to #{after}"
  
  update_specs_repo
  updated_specs = specs_for_git_diff before, after
  vputs "Looking at #{updated_specs.lines.count}"
  
  updated_specs.lines.each_with_index do |spec_filepath, index|
    spec_path = @active_folder + "/Specs/" + spec_filepath.strip
    next unless spec_filepath.include? ".podspec" and File.exists? spec_path
    
    begin
      create_and_document_spec spec_path
    rescue
    
    end
  end
end

# allow logging of terminal commands

def command command_to_run
  if @log_all_terminal_commands 
    puts command_to_run.yellow
  end
  
  system command_to_run
end

def vputs text
  puts text.green if @verbose 
end

# -------------------------------------------------------------------------------------------------
# App example data. Instead of using the webhook, here's two 

puts "\n - It starts. "

if @short_test_webhook
  handle_webhook({ "before" => "dbaa76f854357f73934ec609965dbd77022c30ac", "after" => "f09ff7dcb2ef3265f1560563583442f99d5383de" })
else
  handle_webhook({ "before" => "d5355543f7693409564eec237c2082b73f2260f8", "after" => "e30ed9b1346700b2164e40f9744bed22d621dba5" })
end

# choo choo

@generator = WebsiteGenerator.new
@generator.active_folder = @active_folder
@generator.generate

@generator.upload if @upload_to_s3
  
puts "- It Ends. "