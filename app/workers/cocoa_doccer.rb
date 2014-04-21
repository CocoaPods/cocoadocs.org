require 'resque-lonely_job'

class CocoaDoccer
  extend Resque::Plugins::LonelyJob
  
  @queue = :cocoadocs_queue
  
  def self.perform podspec_path
    cocoadocs_path = "vendor/cocoadocs.org"
    
    p "doing my thing"
    
    Dir.chdir cocoadocs_path do
      # command = ["bundle", "exec", "ruby", "app.rb", "cocoadocs", "doc", podspec_path.gsub(cocoadocs_path, "")]
      # 
      # p command.join " "
      # Process.spawn command
      
      p "Completed?"
    end
  end
  
end