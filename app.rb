require 'cocoapods-downloader'
require 'cocoapods-core'
require 'cocoapods'

require 'ostruct'
require 'yaml'
require 'json'
require "fileutils"
require "octokit"
require "shellwords"
require "colored"

require 'tilt'
require "slim"
require 'sinatra'

$verbose = true
$log_all_terminal_commands = true
$start_sinatra_server = false

# these are built to be all true when
# the app is doing everything

# Kick start everything from webhooks
@use_webhook = true
@short_test_webhook = true

# Download and document
@fetch_specs = false
@run_docset_commands = false
@overwrite_existing_source_files = false

# Generate site site & json
@generate_website = true
@generate_json = false

# Upload html / docsets
@upload_docsets_to_s3 = false
@upload_site_to_s3 = true

@delete_activity_folder = false

require_relative "classes/utils.rb"
require_relative "classes/spec_extensions.rb"
require_relative "classes/website_generator.rb"
require_relative "classes/docset_generator.rb"
require_relative "classes/docset_fixer.rb"
require_relative "classes/readme_generator.rb"
require_relative "classes/source_downloader.rb"

@current_dir = File.dirname(File.expand_path(__FILE__)) 

#constrain all downloads etc into one subfolder
@active_folder_name = "activity"
@active_folder = @current_dir + "/" + @active_folder_name

# Take a spec path and download details, create the docset
# then upload to s3

def generate_json_metadata_for_spec spec
  filepath = @active_folder + "/docsets/" + spec.name

  versions = []
  Dir.foreach filepath do |version|
    next if version[0] == '.'
    next if version == "metadata.json"
    versions << version
  end
  
  hash_string = {
    
    :spec_homepage => spec.homepage,
    :versions => versions,
    :license => spec.or_license
    
  }.to_json.to_s
  
  function_wrapped = "setup(#{hash_string})"
  json_filepath = @active_folder + "/docsets/" + spec.name + "/metadata.json"

  File.open(json_filepath, "wb") { |f| f.write function_wrapped }
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
      spec = eval(File.open(spec_path).read)
      
      download_location = @active_folder + "/download/#{spec.name}/#{spec.version}/#{spec.name}"
      docset_location = @active_folder + "/docsets/#{spec.name}/#{spec.version}/"
      readme_location = @active_folder + "/readme/#{spec.name}/#{spec.version}/index.html"
  
      if @run_docset_commands
        
        downloader = SourceDownloader.new ({ :spec => spec, :download_location => download_location, :active_folder => @active_folder, :overwrite => @overwrite_existing_source_files})
        downloader.download_pod_source_files
        
        readme = ReadmeGenerator.new ({ :spec => spec, :readme_location => readme_location, :active_folder => @active_folder })
        readme.create_readme

        generator = DocsetGenerator.new({ :spec => spec, :to => docset_location, :from => download_location, :readme_location => readme_location,  :active_folder => @active_folder  })
        generator.create_docset
        
        fixer = DocsetFixer.new({ :docset_path => docset_location, :readme_path => readme_location })
        fixer.fix
      end
  
      generate_json_metadata_for_spec spec
      
    rescue Exception => e
      
      open('error_log.txt', 'a') { |f|
        f.puts "\n\n\n\n\n--------------#{spec_path}-------------"
        f.puts e.message
        f.puts "------"
        f.puts e.backtrace.inspect
      }

      puts "--------------#{spec_path}-------------".red
      puts e.message.red
      puts "------"
      puts e.backtrace.inspect.red
      
    end
  end

  @generator = WebsiteGenerator.new(:active_folder => @active_folder, :generate_json => @generate_json)

  @generator.generate if @generate_website
  @generator.upload_docset if @upload_docsets_to_s3
  @generator.upload_site if @upload_site_to_s3
end

# App example data. Instead of using the webhook, here's two 


if @use_webhook and !$start_sinatra_server
  puts "\n - It starts. "
  
  if @short_test_webhook
    handle_webhook({ "before" => "b20c7bf50407a9d21ada700d262ec88a89a405ac", "after" => "d9403181ad800bfac95fcb889c8129cc5dc033e5" })
  else
    handle_webhook({ "before" => "d5355543f7693409564eec237c2082b73f2260f8", "after" => "ff2988950bedeef6809d525078986900cdd3f093" })
  end
  
  puts "- It Ends. "
end

# --------------------------
# Sinatra stuff
# we want the script to launch a webhook responding sinatra app

set :run, $start_sinatra_server

post "/webhook" do
  handle_webhook JSON.parse(params[:payload])
end