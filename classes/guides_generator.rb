require 'net/http'

class GuidesGenerator
	include HashInit
	attr_accessor :spec, :source_download_location

	def generate_string_for_appledoc
		guides = cocoadocs_settings["additional_guides"];
		return "" unless guides.is_a? Array
		return "" unless guides.count == 0
		
		vputs "Grabbing additional programming guides"
		command = " "
		
		guides.each do |guide_path|
			
			if guide_path.include? "http"
				vputs " - downloading " + guide_path
				file_contents = Net::HTTP.get(URI(guide_path))
				file_path = File.join(@source_download_location, File.basename(guide_path))
				File.open(file_path, 'w') { |f| f.write file_contents }
				command << " --include " + file_path
				
			else
				if verify_file_path guide_path
					command << " --include " + guide_path
				end
			end
	
			command
		end
		
		
		def verify_file_path path
			return false if path.include? "../"
			return false if path.include? "&"
			return false if path.include? ";"
			return false if path.include? ";"
			
			File.exists? path
		end

		def cocoadocs_settings
			cocoadocs_settings = @source_download_location + "/.cocoadocs.yml"
			settings = YAML::load(File.open(Dir.pwd + "/views/cocoadocs.defaults.yml").read)
		
			if File.exists? cocoadocs_settings
				doc_settings = YAML::load(File.open(cocoadocs_settings).read)
				settings.merge doc_settings
			end
		end 

end
