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
require "nokogiri"

class CocoaDocs < Object

  $specs_repo = "CocoaPods/Specs"
  $s3_bucket = "cocoadocs.org"
  $website_home = "http://cocoadocs.org/"
  $cocoadocs_specs_name = ".cocoadocs_specs"

  $verbose = false
  $log_all_terminal_commands = false
  $start_sinatra_server = false

  # Download and document
  $fetch_specs = true
  $run_docset_commands = true
  $overwrite_existing_source_files = true
  $delete_source_after_docset_creation = true

  # Generate site site & json
  $generate_website = false
  $generate_docset_json = false
  $generate_apple_json = false

  # Upload html / docsets
  $upload_docsets_to_s3 = false
  $upload_redirects_for_spec_index = false
  $upload_redirects_for_docsets = false

  $upload_site_to_s3 = false

  Dir["./classes/*.rb"].each {|file| require_relative file }

  # Constrain all downloads and data into one subfolder
  $active_folder_name = "activity"
  $current_dir = File.dirname(File.expand_path(__FILE__)) 
  $active_folder = $current_dir + "/" + $active_folder_name

  # command line parsing

  def initialize(args)

    if ARGV.length > 0
      setup_options ARGV
    
      command = ARGV[0].gsub(/-/, '_').to_sym rescue :help
      @params = ARGV[1..-1]
      commands.include?(command.to_sym) ? send(command.to_sym) : help
    else
      help
    end
  end

  #    parse all docs and upload to s3
  #    cocoadocs all --create-website http://cocoadocs.org --upload-s3 cocoadocs.org
  def all
    update_specs_repo
    filepath = $active_folder + "/#{$cocoadocs_specs_name}/"

    Dir.foreach filepath do |pod|
      next if pod[0] == '.'
      next unless File.directory? "#{filepath}/#{pod}/"
      
      Dir.foreach filepath + "/#{pod}" do |version|
        next if version[0] == '.'
        next unless File.directory? "#{filepath}/#{pod}/#{version}/"
        
        document_spec_at_path("#{filepath}/#{pod}/#{version}/#{pod}.podspec")
        
      end
    end
  end
  
  #    start webhook server for incremental building
  #    cocoadocs webhook "CocoaPods/Specs" --create-website http://cocoadocs.org --upload-s3 cocoadocs.org
  
  def webhook
    $upload_docsets_to_s3 = true
    $upload_redirects_for_spec_index = true
    $upload_redirects_for_docsets = true
    $upload_site_to_s3 = true
    
    $generate_website = true
    $generate_docset_json = true
    $generate_apple_json = true

    $start_sinatra_server = true
  end

  #    just parse ARAnalytics and put the docset in the activity folder
  #    cocoadocs doc "CocoaPods/Specs" "ARAnalytics"
  
  def doc
    name = @params[0]
    spec_path = $active_folder + "/#{$cocoadocs_specs_name}/" + name
    update_specs_repo
    
    
    if Dir.exists? spec_path
      version = Dir.entries(spec_path).last
      document_spec_at_path("#{spec_path}/#{version}/#{name}.podspec")
      Process.exit
    else
      puts "Could not find #{name} at #{spec_path}"
    end
  end

  def help
    puts "\n" +                                                                  
    "    CocoaDocs command line                                                    \n" +
    "                                                                              \n" +
    "     app.rb all                                                               \n" +
    "     app.rb doc                                                               \n" +
    "     app.rb webhook                                                           \n" +
    "                                                                              \n" +
    "     Options:                                                                 \n" +
    "                                                                              \n" +
    "       --verbose                                                              \n" +
    "       --skip-fetch                                                           \n" +
    "       --dont-delete-source                                                   \n" +
    "       --create-website \"http://example.com/\"                               \n" +
    "       --specs-repo \"name/repo\" or \"http://u:p@server.com/git/specs.git\"  \n" +
    "       --data-folder \"activity\"                                             \n" +
    "       --upload-s3 \"bucketname\"                                             \n" +
    "                                                                              \n" +
    "     CocoaDocs Command Examples:                                              \n" +
    "                                                                              \n" +
    "      Start webhook server for incremental building                           \n" +
    "      app.rb webhook                                                          \n" +
    "                                                                              \n" +
    "      Parse all docs and upload to s3 on the cocoapods.org bucket             \n" +
    "      app.rb all --upload-s3 cocoapods.org                                    \n" +
    "                                                                              \n" +
    "      just parse ARAnalytics and put the docset in the activity folder        \n" +
    "      app.rb doc ARAnalytics                                                  \n\n"
  end
  
  # Take a webhook, look at the commits inbetween the before & after
  # and then document each spec.

  def handle_webhook webhook_payload
    before = webhook_payload["before"]
    after = webhook_payload["after"]
    vputs "Got a webhook notification for #{before} to #{after}"
  
    update_specs_repo
    updated_specs = specs_for_git_diff before, after
    vputs "Looking at #{updated_specs.lines.count}"
  
    updated_specs.lines.each_with_index do |spec_filepath, index|
      spec_path = $active_folder + "/" + $cocoadocs_specs_name + "/" + spec_filepath.strip
      next unless spec_filepath.include? ".podspec" and File.exists? spec_path
    
        document_spec_at_path spec_path
        
    end
  end
  
  private

  def setup_options options
    
    if options.find_index("--verbose") != nil
      $verbose = true
      $log_all_terminal_commands = true
    end
    
    if options.find_index("--skip-fetch") != nil
      $fetch_specs = false
    end

    if options.find_index("--dont-delete-source") != nil
      puts "Turning off deleting source "
      $delete_source_after_docset_creation = false
    end

    index = options.find_index "--create-website"
    if index != nil
      $generate_website = true
      $generate_docset_json = true
      $generate_apple_json = true
      $website_home = options[index + 1]
    end
  
    index = options.find_index("--upload-s3")
    if index != nil
      $upload_docsets_to_s3 = true
      $upload_redirects_for_spec_index = true
      $upload_redirects_for_docsets = true
      $upload_site_to_s3 = true
      $s3_bucket = options[index + 1]
    end

    index = options.find_index "--specs-repo"    
    $specs_repo = options[index + 1] if index != nil
    
    index = options.find_index "--data-folder"    
    $active_folder_name = options[index + 1] if index != nil
    
    $active_folder = $current_dir + "/" + $active_folder_name
  end

  # Update or clone Cocoapods/Specs
  def update_specs_repo
    repo = $active_folder + "/" + $cocoadocs_specs_name
    unless File.exists? repo
      vputs "Creating Specs Repo for #{$specs_repo}"
      if repo.include? ".git"
        command "git clone git://github.com/#{$specs_repo}.git #{repo}"
      else
        command "git clone #{$specs_repo} #{repo}"
      end
    else
      if $fetch_specs
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
    Dir.chdir($active_folder_name + "/" + $cocoadocs_specs_name) do
     `git #{git_command}`  
    end
  end



  # generate the documentation for the pod

  def document_spec_at_path spec_path
    spec = nil
    begin 
      spec = eval(File.open(spec_path).read)

      download_location = $active_folder + "/download/#{spec.name}/#{spec.version}/#{spec.name}"
      docset_location   = $active_folder + "/docsets/#{spec.name}/#{spec.version}/"
      readme_location   = $active_folder + "/readme/#{spec.name}/#{spec.version}/index.html"
      pod_root_location = $active_folder + "/docsets/#{spec.name}/"
      
      if $run_docset_commands
    
        downloader = SourceDownloader.new ({ :spec => spec, :download_location => download_location, :overwrite => $overwrite_existing_source_files })
        downloader.download_pod_source_files
    
        readme = ReadmeGenerator.new ({ :spec => spec, :readme_location => readme_location })
        readme.create_readme

        generator = DocsetGenerator.new({ :spec => spec, :to => docset_location, :from => download_location, :readme_location => readme_location })
        generator.create_docset
    
        fixer = DocsetFixer.new({ :docset_path => docset_location, :readme_path => readme_location, :pod_root => pod_root_location, :spec => spec })
        fixer.fix
        fixer.add_index_redirect_to_latest_to_pod if $upload_redirects_for_spec_index
        fixer.add_docset_redirects if $upload_redirects_for_docsets
    
        spec_metadata = SpecMetadataGenerator.new({ :spec => spec })
        spec_metadata.generate
    
        if $delete_source_after_docset_creation       
          vputs "Deleting source files"
          command "rm -rf #{download_location}" 
        end
      end
  
 #     $parser = AppleJSONParser.new
 #     $parser.generate if $generate_apple_json

      $generator = WebsiteGenerator.new(:generate_json => $generate_docset_json, :spec => spec)
      $generator.upload_docset if $upload_docsets_to_s3
      
      $generator.generate if $generate_website
      $generator.upload_site if $upload_site_to_s3
    end 
  
  rescue Exception => e
    if spec != nil
      error_path = "errors/#{spec.name}/#{spec.version}/error.json"
      FileUtils.mkdir_p(File.dirname(error_path))
      FileUtils.rm(error_path) if File.exists? error_path
     
      open(error_path, 'a'){ |f| 
        report = { "message" => e.message , "trace" => e.backtrace }
        f.puts report.to_json.to_s
      }
    end

    open('error_log.txt', 'a') { |f|
      f.puts "\n\n\n --------------#{spec_path}-------------"
      f.puts e.message
      f.puts "------"
      f.puts e.backtrace.inspect
    }

    puts "--------------#{spec_path}-------------".red
    puts e.message.red
    puts "------"
    puts e.backtrace.inspect.red
  
  end

  def commands
    (public_methods - Object.public_methods).map{ |c| c.to_sym}
  end
end

docs = CocoaDocs.new(ARGV)

# --------------------------
# Sinatra stuff
# Sinatra hooks into Kernel for the run setting, so it should be done post CocoaDocs.new

if $start_sinatra_server
  require 'sinatra'
  
  post "/webhook" do
    docs.handle_webhook JSON.parse(params[:payload])
  end
  
  get "/error/:pod/:version" do
    # get error info for a pod
     error_json_path = "errors/#{params[:pod]}/#{params[:version]}/error.json"
     if File.exists? error_json_path
       return "report_error(" + File.read(error_json_path) + ")"
     end
     return "{}"
  end
  
end