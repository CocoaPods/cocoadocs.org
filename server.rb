#!/usr/bin/env ruby

require 'sinatra'
require 'json'

if ARGV.length == 0
  puts "You need to give a Trunk webhook URL"
end

post "/hooks/trunk/" + ARGV[0] do
  data = JSON.parse(params["message"])
  puts "Got a webhook notification: " + data["type"] + " - " + data["action"]
    
  process_url data["data_url"]
  "{ success: true }"
end

get "/error/:pod/:version" do
  # get error info for a pod
   error_json_path = "errors/#{params[:pod]}/#{params[:version]}/error.json"
   if File.exists? error_json_path
     return "report_error(" + File.read(error_json_path) + ")"
   end
   return "{}"
end

get "/redeploy/:pod/:version" do
  repo_path = $active_folder + "/#{$cocoadocs_specs_name}/"
  podspec_path = repo_path + "/#{params[:pod]}/#{params[:version]}/#{params[:pod]}.podspec"

   if File.exists? podspec_path
     vputs "Generating docs for #{podspec_path}"
     process_path podspec_path
     
     return "{ parsing: true }"
   end

   return "{ parsing: false }"
end

get "/" do
  "Hi"
end

private

def process_path path
  this_folder = File.expand_path(File.dirname(__FILE__))
  pid = Process.spawn( File.join(this_folder, "./cocoadocs.rb"), "cocoadocs", "doc", path, { :chdir => this_folder })
  Process.detach pid
end

def process_url url
  this_folder = File.expand_path(File.dirname(__FILE__))
  pid = Process.spawn(File.join(this_folder, "./cocoadocs.rb"), "cocoadocs", "url", url, { :chdir => this_folder })
  Process.detach pid
end
