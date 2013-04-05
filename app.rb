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
require 'exceptio-ruby'


@verbose = true
@log_all_terminal_commands = true

# these are built to be all true when
# the app is doing everything

# Kick start everything from webhooks
@short_test_webhook = false
@use_webhook = false

# Download and document
@fetch_specs = false
@run_docset_commands = false

# Generate site site & json
@generate_website = true
@generate_json = false

# Upload html / docsets
@upload_to_s3 = false

require_relative "classes/utils.rb"
require_relative "classes/spec_extensions.rb"
require_relative "classes/website_generator.rb"
require_relative "classes/docset_fixer.rb"

@current_dir = File.dirname(File.expand_path(__FILE__)) 

#constrain all downloads etc into one subfolder
@active_folder_name = "activity"
@active_folder = @current_dir + "/" + @active_folder_name

# Create a docset based on the spec

def create_docset_for_spec spec, from, to, readme_location
  vputs "Creating docset"
  
  FileUtils.rmdir(to) if Dir.exists?(to)
  
  version = spec.version.to_s.downcase
  id = spec.name.downcase
  cocoadocs_id = "cocoadocs"
  
  headers = headers_for_spec_at_location spec
  headers.map! { |header| Shellwords.escape header }
  vputs "Found #{headers.count} header files"
  
  if headers.count == 0
    headers = [from] 
  end
  
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
 #   "--publish-docset",                                    # this should create atom
    
#    "--docset-feed-url http://cocoadocs.org/docsets/#{spec.name}/%DOCSETATOMFILENAME",
 #   "--docset-package-url http://cocoadocs.org/docsets/#{spec.name}/%DOCSETPACKAGEFILENAME",
    
#    "--docset-atom-filename '#{to}../#{spec.name}.atom' ",
#    "--docset-feed-url http://cocoadocs.org/docsets/#{spec.name}/#{spec.name}.xml",
#   "--docset-feed-name #{spec.name}",                    

    "--keep-undocumented-objects",                         # not everyone will be documenting
    "--keep-undocumented-members",                         # so we should at least show something
    "--search-undocumented-doc",                           # uh? ( no idea what this does... )
    
    "--output #{to}",                                      # where should we throw stuff
    *headers
  ]

  if File.exists? readme_location
    docset_command.insert(3, "--index-desc resources/overwritten_index.html")
  end

  command docset_command.join(' ')
  
  fixer = DocsetFixer.new
  fixer.docset_path = to
  fixer.readme_path = readme_location
  fixer.fix
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
  readme_location = @active_folder + "/readme/#{spec.name}/#{spec.version}/index.html"
  cache_path = @active_folder + "/download_cache"
  
  unless File.exists? download_location
    download_podfile_files spec, download_location, cache_path
  end
  
  if @run_docset_commands
    create_gfm_readme spec, readme_location
    create_docset_for_spec spec, download_location, docset_location, readme_location
  end
  
  generate_json_metadata_for_spec spec
  
  puts "\n\n\n"
end

def create_gfm_readme spec, readme_location
    spec_readme = readme_path spec
    return unless spec_readme
    
    readme_folder = readme_location.split("/")[0...-1].join("/")
    `mkdir -p '#{readme_folder}'`

    context = nil
    context = "#{spec.or_user}/#{spec.or_repo}" if spec.or_is_github?
    
    # this is just an empty github app that does nothing
    Octokit.client_id = '52019dadd0bc010084c4'
    Octokit.client_secret = 'c529632d7aa3ceffe3d93b589d8d2599ca7733e8'
    markdown = Octokit.markdown(File.read(spec_readme), :mode => "markdown", :context => context)
    
    File.open(readme_location, 'w') { |f| f.write(markdown) }
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
    rescue Exception => e
      
      open('error_log.txt', 'a') { |f|
        f.puts "\n\n\n\n\n --------------#{spec_path}-------------"
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
end

# App example data. Instead of using the webhook, here's two 

puts "\n - It starts. "

if @use_webhook
  if @short_test_webhook
    handle_webhook({ "before" => "b20c7bf50407a9d21ada700d262ec88a89a405ac", "after" => "d9403181ad800bfac95fcb889c8129cc5dc033e5" })
  else
    handle_webhook({ "before" => "d5355543f7693409564eec237c2082b73f2260f8", "after" => "ff2988950bedeef6809d525078986900cdd3f093" })
  end
end

# choo choo its the exception train
ExceptIO::Client.configure "orta-cocoadocs ", "2abd82e35f6d0140"

@generator = WebsiteGenerator.new(:active_folder => @active_folder, :generate_json => @generate_json, :verbose => @verbose)

@generator.generate if @generate_website
@generator.upload if @upload_to_s3
  
puts "- It Ends. "