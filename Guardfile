command = "bundle exec ruby app.rb create_assets"
guard :shell, :cli => command do

  watch(/app.rb/)do |m|
    system command
  end

  watch(/views/) do |m|
    system command
  end

  watch(/public/) do |m|
    system command
  end
end
