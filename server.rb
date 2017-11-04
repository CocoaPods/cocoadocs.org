#!/usr/bin/env ruby
# frozen_string_literal: true

require "sinatra"
require "json"
require "cocoapods"
gem "nap"
require "rest"

require_relative "classes/_utils.rb"

trunk_notification_path = ENV["TRUNK_NOTIFICATION_PATH"]
trunk_notification_path ||= ARGV[0]
abort "You need to give a Trunk webhook URL" unless trunk_notification_path

set :pod_count, 0
set :bind, "0.0.0.0"

specs_repo = Pod::Source::Metadata.new({ prefix_lengths: [1, 1, 1] })

post "/hooks/trunk/" + trunk_notification_path do
  data = JSON.parse(request.body.read)
  puts "Got a webhook notification: " + data["type"] + " - " + data["action"]

  process_url data["data_url"]
  "{ success: true }"
end

get "/error/:pod/:version" do
  content_type :json
  # get error info for a pod
  error_json_path = "errors/#{params[:pod]}/#{params[:version]}/error.json"
  error_message_for_path error_json_path
end

get "/error/:pod" do
  content_type :json

  # get generic error info for a pod
  error_json_folder = "errors/#{params[:pod]}/"
  if File.directory? error_json_folder
    # return first found
    error_json_path = Dir[error_json_folder + "/*/*.json"].first
    error_message_for_path error_json_path
  end

  error_message_for_path "random_path"
end

get "/redeploy/:pod/latest" do
  content_type :json
  begin
    trunk_spec = REST.get(escape_url("https://trunk.cocoapods.org/api/v1/pods/" + params[:pod])).body
    versions = JSON.parse(trunk_spec)["versions"]
    versions = versions.map { |s| Pod::Version.new(s["name"]) }.sort.map(&:version)
    address = specs_repo.path_fragment(params[:pod], versions[-1])
    process_url "https://raw.githubusercontent.com/CocoaPods/Specs/master/Specs/#{address}/#{params[:pod]}.podspec.json"
    return { parsing: true }.to_json
  rescue Exception => e
    p e.message
    return { parsing: false, error: e.message }.to_json
  end
end

get "/redeploy/:pod/:version" do
  content_type :json
  address = specs_repo.path_fragment(params[:pod], params[:versions])
  process_url "https://raw.githubusercontent.com/CocoaPods/Specs/master/Specs/#{address}/#{params[:pod]}.podspec.json"

  return { parsing: true }.to_json
end

get "/recent_pods_count" do
  old_recent_pods = settings.pod_count
  set :pod_count, 0
  return old_recent_pods.to_s
end

get "/" do
  content_type :text
  "Hi"
end

private

def error_message_for_path(path)
  if File.exist? path
    return "report_error(" + File.read(path) + ")"
  end
  '{"message":"Could not find any errors, perhaps CocoaDocs has not ran the processing?", "trace" :[]}'
end

def process_url(url)
  set :pod_count, settings.pod_count + 1
  this_folder = __dir__

  # Is it the CocoaPods README server?
  if ENV["COCOADOCS_TOKEN"]
    # e.g. handle generating pod stats, README, CHANGELOG etc
    pid = Process.spawn(File.join(this_folder, "./cocoapods-simple.rb"), escape_url(url), { chdir: this_folder })
    Process.detach pid
  else
    # It's actually CocoaDocs, so
    # Spawn off a CocoaDocs specific process (e.g. handle documentation)
    pid = Process.spawn(File.join(this_folder, "./cocoadocs.rb"), "cocoadocs", "url", escape_url(url), { chdir: this_folder })
    Process.detach pid
  end
end
