require 'net/http'

class GuidesGenerator
  include HashInit
  attr_accessor :spec, :source_download_location

  def generate_string_for_appledoc
    settings = cocoadocs_settings
    return "" if settings.nil?
    return "" unless settings.key? "additional_guides"

    guides = settings["additional_guides"]
    return "" unless guides.is_a? Array
    return "" if guides.count == 0

    vputs "Grabbing additional programming guides"

    guides_folder = "guides"
    docs_folder = File.join(@source_download_location, guides_folder)
    Dir.mkdir(docs_folder) unless File.exist?(docs_folder)

    guides.each do |guide_path|

      if guide_path.include? "http"

        # Native wiki support
        # from https://github.com/magicalpanda/MagicalRecord/wiki/Installation
        # to   https://raw.githubusercontent.com/wiki/magicalpanda/MagicalRecord/Installation.md

        if guide_path.include?("github.com") && guide_path.include?("/wiki/")
          guide_path = guide_path.gsub "/wiki", ""
          guide_path = guide_path.gsub "github.com", "raw.githubusercontent.com/wiki"
          guide_path = guide_path + ".md"
        end

        vputs " - downloading " + guide_path

        file_contents = REST.get(guide_path).body
        file_path = File.join(docs_folder, File.basename(guide_path))
        file_path = file_path.reverse.sub(".".reverse, "-template.".reverse).reverse
        File.open(file_path, 'w') { |f| f.write file_contents }

      else
        local_path = File.join(@source_download_location, guide_path)

        if File.exist? local_path
          new_path = File.join(docs_folder, File.basename(local_path))
          new_path = new_path.reverse.sub(".".reverse, "-template.".reverse).reverse

          FileUtils.cp local_path, new_path
        end
      end

    end

    " --include " + File.join(@source_download_location, guides_folder)
  end

  def cocoadocs_settings
    cocoadocs_settings = @source_download_location + "/.cocoadocs.yml"
    settings = YAML.load(File.read(Dir.pwd + "/views/cocoadocs.defaults.yml"))

    if File.exist? cocoadocs_settings
      doc_settings = YAML.load(File.read(cocoadocs_settings))
      settings.merge doc_settings
    end
  end
end
