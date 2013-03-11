guard :ruby do
  # run any benchmarking files
  watch(/app.rb/)
end

guard :shell, :cli => "bundle exec ruby app.rb" do 
  watch(/views/) do |m|
    `bundle exec ruby app.rb`
  end
  watch(/public/) do |m|
    `bundle exec ruby app.rb`
  end
  
end
