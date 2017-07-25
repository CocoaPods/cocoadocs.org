require 'erb'

class WebsiteGenerator
  include HashInit
  attr_accessor :generate_json, :spec

  def generate
    move_public_items
  end

  def move_public_items
    resources_dir = "#{$active_folder}/html/assets/"

    command "rm -rf \"#{resources_dir}\""
    command "mkdir \"#{resources_dir}\""
    command "cp -R public/* \"#{resources_dir}\""
  end

  def upload_docset
    vputs "Uploading docsets folder"
    server_folder = $beta ? "beta" : "docsets"

    upload_folder "docsets/#{@spec.name}/#{@spec.version}/", "/#{server_folder}/#{@spec.name}/#{@spec.version}/", "cp"
    upload_file "docsets/#{@spec.name}/metadata.json", "/#{server_folder}/#{@spec.name}/", "cp"
  end

  def upload_site
    vputs "Uploading site folder"
    upload_folder "html/*", "/", "cp"
  end

  def save_file(file, path)
    FileUtils.mkdir_p(File.dirname(path))
    File.unlink path if File.exist? path

    File.open(path, "wb") { |f| f.write file }
  end

  def save_slim(slim_filepath, to_filepath)
    template = Tilt.new slim_filepath
    html = template.render

    vputs "Writing slim_filepath"
    save_file html, to_filepath
  end

  # Upload a file to s3
  def upload_folder(from, to, command)
    vputs "Uploading #{from} with #{command} on s3"
    verbose = $verbose ? "--verbose" : ""

    upload_command = [
      "aws s3 #{command}",
      "--acl public-read",
      "#{ $active_folder }/#{from} s3://#{ $s3_bucket }#{to}"
    ]

    command upload_command.join(' ')
  end

  # Upload the docsets folder to s3
  def upload_folder(from, to, command)
    vputs "Uploading #{from} with #{command} on s3"
    verbose = $verbose ? "--verbose" : ""

    upload_command = [
      "aws s3 #{command}",
      "--recursive --acl public-read",
      "#{ $active_folder }/#{from} s3://#{ $s3_bucket }#{to}"
    ]

    command upload_command.join(' ')
  end
end
