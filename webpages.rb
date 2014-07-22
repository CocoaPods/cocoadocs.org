#!/usr/bin/env ruby

require 'tilt'
require 'slim'
require 'colored'
require 'fileutils'
require_relative "classes/_utils"

@prefix = File.expand_path File.dirname(__FILE__)

def save_slim slim_filepath, to_filepath

  template = Tilt.new @prefix + "/" + slim_filepath
  html = template.render

  vputs "Writing slim_filepath"
  save_file html, @prefix + "/" + to_filepath
end

def save_file file, path
  FileUtils.mkdir_p(File.dirname(path))
  File.unlink path if File.exists? path

  File.open(path, "wb") { |f| f.write file }
end

def copy_folder from, to
  command "cp -R #{ @prefix }/#{from}/* #{ @prefix }/#{to}"
end

save_slim "views/404.slim", "activity/website/404.html"
save_slim "views/index.slim", "activity/website/index.html"
copy_folder "views/images", "activity/website/images"
copy_folder "views/assets", "activity/website/assets"

puts "done"
