#!/usr/bin/env ruby

require 'sinatra'
require 'json'
require 'cocoapods'

gem 'nap'
require 'rest'

trunk_notification_path = ENV['TRUNK_NOTIFICATION_PATH']
trunk_notification_path ||= ARGV[0]
abort "You need to give a Trunk webhook URL" unless trunk_notification_path

post "/hooks/trunk/" + trunk_notification_path do
  data = JSON.parse(request.body.read)
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
    trunk_spec = REST.get("https://trunk.cocoapods.org/api/v1/pods/" + params[:pod]).body
    versions = JSON.parse(trunk_spec)["versions"]
    versions = versions.map { |s| Pod::Version.new(s["name"]) }.sort.map { |semver| semver.version }

    process_url "https://raw.githubusercontent.com/CocoaPods/Specs/master/Specs/#{ params[:pod] }/#{ versions[-1] }/#{ params[:pod] }.podspec.json"
    return "{ parsing: true }"

  rescue Exception => e
    p e.message
    return "{ parsing: false }"
  end
end

get "/redeploy/:pod/:version" do
    process_url "https://raw.githubusercontent.com/CocoaPods/Specs/master/Specs/#{ params[:pod] }/#{ params[:version] }/#{ params[:pod] }.podspec.json"

   return "{ parsing: true }"
end

get "/" do
  "Hi"
end

private

def process_url url
  this_folder = File.expand_path(File.dirname(__FILE__))
  pid = Process.spawn(File.join(this_folder, "./cocoadocs.rb"), "cocoadocs", "url", url, { :chdir => this_folder })
  Process.detach pid
end

