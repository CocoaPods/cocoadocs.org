desc 'Setup computer for running the tool'
task :setup do

  if `which brew`.strip.empty?
    puts "Homebrew needs to be installed."
    return
  end
  
  puts "Installing s3cmd"
  `brew install s3cmd`
  
  puts "You will need to configure s3cmd"
  puts "s3cmd --configure"
  
  puts "Installing appledoc"
  `brew install appledoc`
  
  puts "Installing gems"
  `bundle install`
end

