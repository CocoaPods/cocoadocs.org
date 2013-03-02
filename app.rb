require 'cocoapods-downloader'
require 'ostruct'
require 'yaml'
require 'aws/s3'

# stub a podfile so we can have the eval'd podspec accessible

module Pod
  class Spec < OpenStruct
    def initialize(&block)
        super

        # ios & osx can have things done to them
        self.ios = OpenStruct.new
        self.osx = OpenStruct.new
        
        block.call(self)
    end
  end
end

# Create a docset based on the spec

def create_docset_for_spec spec, location  
  docset_command = []
  docset_command << %Q[appledoc  --create-html --keep-intermediate-files]
  docset_command << "--project-name #{spec.name}"
  docset_command << "--project-company test"
  docset_command << "--no-install-docset"
  docset_command << "--company-id com.#{spec.name.downcase}.#{spec.version.downcase}"
  docset_command << "--output #{ location.clone.sub "download", "docsets" }"
  docset_command << location
  system docset_command.join(' ')
end

# Upload the docsets folder to s3

def upload_docset_to_s3 location
  upload_command = []
  upload_command << "ruby s3_upload.rb"
  upload_command << "--key " + ENV["S3_KEY"]
  upload_command << "--secret " + ENV["S3_SECRET"]
  upload_command << "--bucket cocoadocs.org"
  upload_command << "--public-read --recursive"
  upload_command << "docsets"
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
  @spec = eval( File.open(filepath).read )

  current_dir = File.dirname(File.expand_path(__FILE__)) 
  download_location = current_dir + "/download/#{@spec.name}/#{@spec.version}/"
  docset_location = current_dir + "/docsets/#{@spec.name}/#{@spec.version}/"
  cache_path = current_dir + "/download_cache"

  
  download_podfile_files @spec, download_location, cache_path

  create_docset_for_spec @spec, download_location
  upload_docset_to_s3 docset_location
end

puts ""

current_dir = File.dirname(File.expand_path(__FILE__)) 
podfile_file_path = current_dir + "/example/AFNetworking.podspec"

create_and_upload_spec podfile_file_path

puts "done"