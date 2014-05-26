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

get "/redeploy/:pod/latest" do
  begin
    trunk_spec = Net::HTTP.get(URI("https://trunk.cocoapods.org/api/v1/pods/" + @spec.name))
    versions = JSON.parse(trunk_spec)["versions"]
    versions = versions.map { |s| Pod::Version.new(s["name"]) }.sort.map { |semver| semver.version }

    process_url "https://raw.githubusercontent.com/CocoaPods/Specs/master/Specs/#{ params[:pod] }/#{ versions[-1] }/#{ params[:pod] }.podspec.json"

  rescue Exception => e
    return "{ parsing: false }"
  end
end

get "/redeploy/:pod/:version" do
    process_url "https://raw.githubusercontent.com/CocoaPods/Specs/master/Specs/#{ params[:pod] }/#{ params[:pod] }/#{ params[:pod] }.podspec.json"

   return "{ parsing: true }"
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
