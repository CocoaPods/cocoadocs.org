class CocoaDocsSettings

  def self.settings_at_location download_location
    cocoadocs_settings = download_location + "/.cocoadocs.yml"
    cocoadocs_settings = download_location + "/.cocoapods.yml" unless File.exist? cocoadocs_settings

    settings = YAML.load(File.read(Dir.pwd + "/views/cocoadocs.defaults.yml"))

    if File.exist? cocoadocs_settings
      vputs "- found custom CocoaDocs settings"
      begin
        settings = settings.merge YAML.load(File.read(cocoadocs_settings))
      rescue
        puts "CocoaDocs yaml file is malformed"
      end
    end

    settings || {}
  end

  def self.jazzy_config_at_location download_location
    [".jazzy.yml", ".jazzy.yaml", ".jazzy.json"].each do |config|
      config_file = download_location + "/" + config
      return config_file if File.exist? config_file
    end

    nil
  end
end
