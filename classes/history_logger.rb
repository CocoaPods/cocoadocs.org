class HistoryLogger
  include HashInit
  attr_accessor :spec, :download_location, :source_download_location

  def append_state(state)
    
    log_folder = $active_folder  + "/logs"
    log_file = log_folder + "/log.csv"
    
    Dir.mkdir(log_folder) unless File.exist?(log_folder)
    `touch #{log_file}` unless File.exist? log_file
    
    docs_folder = File.join(@source_download_location, "guides")
    guides = File.exist?(docs_folder) ? "has_guides" : "no_guides"
    
    cocoadocs_settings = @source_download_location + "/.cocoadocs.yml"
    settings = File.exist?(cocoadocs_settings) ? "has_settings" : "no_settings"
    
    
    appledoc = `vendor/appledoc --version`.strip.gsub("appledoc version: ", "")
    git_sha = `git rev-parse HEAD`.strip
    
    open(log_file, 'a') do |f|
      f.puts [Time.new, @spec.name, @spec.version, state, git_sha, appledoc, guides, settings].join(",")
    end
    
  end
end
