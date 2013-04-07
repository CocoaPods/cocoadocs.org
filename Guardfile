guard :shell, :cli => "bundle exec ruby app.rb" do 
  
  watch(/app.rb/)do |m|
    `bundle exec ruby app.rb`
  end
  
  watch(/views/) do |m|
    `bundle exec ruby app.rb`
  end
  
  watch(/public/) do |m|
    `bundle exec ruby app.rb`
  end
  
end
