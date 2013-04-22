require 'cocoapods-downloader'
require 'cocoapods-core'
require 'cocoapods'

require 'ostruct'
require 'yaml'
require 'json'
require "fileutils"
require "octokit"
require 'open-uri'
require 'net/http'
require "shellwords"
require "colored"

require 'tilt'
require "slim"
require 'sinatra'
require "nokogiri"

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
@overwrite_existing_source_files = true
@delete_source_after_docset_creation = false

# Generate site site & json
@generate_website = true
@generate_docset_json = false
@generate_apple_json = true

# Upload html / docsets
@upload_docsets_to_s3 = false
@upload_redirects_for_spec_index = false
@upload_redirects_for_docsets = false

@upload_site_to_s3 = true

Dir["./classes/*.rb"].each {|file| require_relative file }

#constrain all downloads etc into one subfolder
@active_folder_name = "activity"
@current_dir = File.dirname(File.expand_path(__FILE__)) 
$active_folder = @current_dir + "/" + @active_folder_name


# Update or clone Cocoapods/Specs
def update_specs_repo
  repo = $active_folder + "/Specs"
  unless File.exists? repo
    vputs "Creating Specs Repo"
    command "git clone git://github.com/CocoaPods/Specs.git #{repo}"
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
  Dir.chdir("activity/Specs") do
   `git #{git_command}`  
  end
end

def remote_file_exists?(url)
  url = URI.parse(url)
  Net::HTTP.start(url.host, url.port) do |http|
    return http.head(url.request_uri).code == "200"
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
    spec_path = $active_folder + "/Specs/" + spec_filepath.strip
    next unless spec_filepath.include? ".podspec" and File.exists? spec_path
    
    begin
      spec = eval(File.open(spec_path).read)

      download_location = $active_folder + "/download/#{spec.name}/#{spec.version}/#{spec.name}"
      docset_location   = $active_folder + "/docsets/#{spec.name}/#{spec.version}/"
      readme_location   = $active_folder + "/readme/#{spec.name}/#{spec.version}/index.html"
      pod_root_location = $active_folder + "/docsets/#{spec.name}/"
      if @run_docset_commands
        
        downloader = SourceDownloader.new ({ :spec => spec, :download_location => download_location, :overwrite => @overwrite_existing_source_files })
        downloader.download_pod_source_files
        
        readme = ReadmeGenerator.new ({ :spec => spec, :readme_location => readme_location })
        readme.create_readme

        generator = DocsetGenerator.new({ :spec => spec, :to => docset_location, :from => download_location, :readme_location => readme_location })
        generator.create_docset
        
        fixer = DocsetFixer.new({ :docset_path => docset_location, :readme_path => readme_location, :pod_root => pod_root_location, :spec => spec })
        fixer.fix
        fixer.add_index_redirect_to_latest_to_pod if @upload_redirects_for_spec_index
        fixer.add_docset_redirects if @upload_redirects_for_docsets
        
        spec_metadata = SpecMetadataGenerator.new({ :spec => spec })
        spec_metadata.generate
        
        @generator = WebsiteGenerator.new(:generate_json => @generate_docset_json, :spec => spec)
        @generator.upload_docset if @upload_docsets_to_s3
                
        command "rm -rf #{download_location}" if @delete_source_after_docset_creation

      end
      
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

  @parser = AppleJSONParser.new
  @parser.generate if @generate_apple_json

  @generator = WebsiteGenerator.new(:generate_json => @generate_docset_json)

  @generator.generate if @generate_website
  @generator.upload_site if @upload_site_to_s3
end

# App example data. Instead of using the webhook, here's two 

if @use_webhook and !$start_sinatra_server
  puts "\n - It starts. ".red_on_yellow
  
  if @short_test_webhook
    handle_webhook({ "before" => "70e1a63", "after" => "49a7594b647670b8886466e7643a1556c2ff7889" })
  else
    handle_webhook({ "before" => "d5355543f7693409564eec237c2082b73f2260f8", "after" => "head" })
  end
  
  puts "- It Ends. ".red_on_yellow
end

# --------------------------
# Sinatra stuff
# we want the script to launch a webhook responding sinatra app

set :run, $start_sinatra_server

post "/webhook" do
  handle_webhook JSON.parse(params[:payload])
end