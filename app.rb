require 'cocoapods-downloader'
require 'ostruct'
require 'yaml'
require 'aws/s3'

puts ""

current_dir = File.dirname(File.expand_path(__FILE__)) 
podfile_file_path = current_dir + "/example/AFNetworking.podspec"

module Pod
  class Spec < OpenStruct
    def initialize(&block)
        super
        self.ios = OpenStruct.new
        self.osx = OpenStruct.new
        
        block.call(self)
    end
  end
end

def create_docset_for_spec spec, location  
  docset_command = []
  docset_command << %Q[appledoc  --create-html --keep-intermediate-files]
  docset_command << "--project-name #{spec.name}"
  docset_command << "--project-company test"
  docset_command << "--no-install-docset"
  docset_command << "--company-id com.#{spec.name.downcase}.#{spec.version.downcase}"
  docset_command << "--output #{ location.clone.sub "download", "docset" }"
  docset_command << location
  system docset_command.join(' ')
end

def upload_docset_to_s3 location
  upload_command = []
  upload_command << "ruby s3_upload.rb"
  upload_command << "--key " + ENV["S3_KEY"]
  upload_command << "--secret " + ENV["S3_SECRET"]
  upload_command << "--bucket cocoadocs.org"
  upload_command << "--public-read --recursive"
  upload_command << "docset"
  system docset_command.join(' ')
end


spec = eval( File.open(podfile_file_path).read )
download_location = current_dir + "/download/#{spec.name}/#{spec.version}/"
docset_location = current_dir + "/docset/#{spec.name}/#{spec.version}/"

unless File.exists? download_location
  downloader = Pod::Downloader.for_target(download_location, spec.source)
  downloader.cache_root = current_dir + "download_cache"
  downloader.download
end

created_docset = create_docset_for_spec spec, download_location
if created_docset
  upload_docset_to_s3 docset_location
end


puts "done"