class CocoaDocsSettings

  def self.settings_at_location download_location
    cocoadocs_settings = download_location + "/.cocoadocs.yml"
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

end
