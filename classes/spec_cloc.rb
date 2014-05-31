require 'yaml'

class Cloc
  def initialize(spec, source_download_location, *options)
    @spec = spec
    @source_download_location = source_download_location
    @options = options.push('--yaml', '--quiet')
  end

  def source_files
    pathlist = Pod::Sandbox::PathList.new( Pathname.new(@source_download_location) )

    [@spec, *@spec.recursive_subspecs].reduce([]) do |memo, internal_spec|
      internal_spec.available_platforms.each do |platform|
        consumer = Pod::Specification::Consumer.new(internal_spec, platform)
        accessor = Pod::Sandbox::FileAccessor.new(pathlist, consumer)

        if accessor.source_files
          memo += accessor.source_files.map{ |filepath| filepath.to_s }
        else
          puts "Skipping source_files for #{internal_spec} on platform #{platform} (no source_files found).".blue
        end
      end
      memo
    end.uniq
  end

  def generate
    yaml = `cloc #{@options.join(' ')} #{source_files.join(' ')}`
    hash = YAML.load yaml
    hash.delete 'header'
    hash.map {|l, r| Results.new(l, r)}
  end

  class Results
    attr_accessor :language, :nFiles, :comment, :code
    def initialize(language, hash = {})
      self.language = language
      %w{nFiles comment code}.each do |key|
        self.send("#{key}=", hash[key])
      end
    end
  end
end
