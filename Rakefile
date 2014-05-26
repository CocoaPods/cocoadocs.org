# Deploy to CocoaDocs
#-----------------------------------------------------------------------------#

desc "Deploy the site"
task :deploy do
    upload_command = [
      "s3cmd put ",
      "--acl-public",
      "--no-check-md5",
      "--verbose --human-readable-sizes --reduced-redundancy",
      "index.html s3://cocoadocs.org/readme/"

    ].join(' ')

    puts upload_command
    system upload_command
end
