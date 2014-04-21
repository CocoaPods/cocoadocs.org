class ApiController < ApplicationController
  def index
    render :text => "CocoaDocs server v2"
  end

  def webhook
    specs_path = "vendor/cocoadocs.org/activity/cocoadocs_specs"
    
    specs = specs_from_webhook specs_path, params    
    specs.each_with_index do |spec_filepath, index|
      spec_path = specs_path + "/" + spec_filepath.strip
      next unless spec_filepath.end_with? ".podspec" and File.exists? spec_path

      document_spec_at_path spec_path
    end
    

    render json: { specs: specs }
  end
  
  def error
    render json: { error: "Yes" } 
  end
  
  def reparse
    Resque.enqueue(CocoaDoccer, "AFNetworking", "2.0.0")
    render :text => "started"
  end

  private

  def document_spec_at_path path
    p path
    
    cocoadocs_path = "vendor/cocoadocs.org"
    command = ["bundle", "exec", "ruby", "app.rb", "cocoadocs", "doc", path.gsub(cocoadocs_path, "")].join " "
    
    p command
    Dir.chdir cocoadocs_path do
      Process.spawn command
    end
    
    # Resque.enqueue(CocoaDoccer, path)
  end
  
  def specs_from_webhook specs_path, params
    Dir.chdir specs_path do
     specs = `git diff --name-status #{ params["before"] } #{ params["after"] }`.lines.map do |line|

       line.slice!(0).strip!
       line.gsub! /\t/, ''
       line.gsub! /\n/, ''
     end
    end
    
  end
end
