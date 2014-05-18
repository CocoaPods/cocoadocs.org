#!/usr/bin/env ruby

require 'sinatra'

post "/webhook" do
  before = webhook_payload["before"]
  after = webhook_payload["after"]
  vputs "Got a webhook notification for #{before} to #{after}"

  update_specs_repo
  updated_specs = specs_for_git_diff before, after
  vputs "Looking at #{ updated_specs.lines.count }"

  updated_specs.lines.each_with_index do |spec_filepath, index|
    spec_path = $active_folder + "/" + $cocoadocs_specs_name + "/" + spec_filepath.strip
    next unless spec_filepath.end_with? ".podspec" and File.exists? spec_path
    process_path params[:pod]
    
  end
  "{ success: true, triggered: #{ updated_specs.lines.count } }"
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

get "/redeploy/:pod" do
  spec = docs.spec_with_name(params[:pod])

  if spec
    vputs "Generating docs for #{spec.name}"
    process_path params[:pod]
    
    "{ parsing: true }"
  else
    "{ parsing: false }"
  end
end


private

def process_path path
  pid = Process.spawn("ruby", File.join($current_dir, "app.rb"), "cocoadocs", "doc", podspec_path, { :chdir => File.expand_path(File.dirname(__FILE__)) })
  Process.detach pid
end

def specs_for_git_diff start_commit, end_commit
  diff_log = run_git_command_in_specs "diff --name-status #{start_commit} #{end_commit}"
  cleanup_git_logs diff_log
end