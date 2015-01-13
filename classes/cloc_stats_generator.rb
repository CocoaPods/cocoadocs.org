require 'yaml'

class ClocStatsGenerator
  include HashInit
  attr_accessor :spec, :source_download_location, :options, :output_location

  def source_files
    pathlist = Pod::Sandbox::PathList.new(Pathname.new(@source_download_location))

    [@spec, *@spec.recursive_subspecs].reduce([]) do |memo, internal_spec|
      internal_spec.available_platforms.each do |platform|
        consumer = Pod::Specification::Consumer.new(internal_spec, platform)
        accessor = Pod::Sandbox::FileAccessor.new(pathlist, consumer)

        if accessor.source_files
          memo += accessor.source_files.map(&:to_s)
        else
          puts "Skipping source_files for #{internal_spec} on platform #{platform} (no source_files found).".blue
        end
      end
      memo
    end.uniq
  end

  def generate
    vputs "Generating CLOC stats"
    @options = ['--yaml', '--quiet']
    begin
      return {} if source_files.empty?

      yaml = `cloc #{@options.join(' ')} #{source_files.join(' ')}`
      yaml.sub!(/.*^---/m, '---')

      hash = YAML.load yaml
      hash.delete 'header'
      hash.map { |l, r| Results.new(l, r).to_h }
    rescue => e
      {}
    end
  end

  class Results
    attr_accessor :language, :nFiles, :comment, :code
    def initialize(language, hash = {})
      self.language = language
      %w{nFiles comment code}.each do |key|
        send("#{key}=", hash[key])
      end
    end

    def to_h
      { lang: @language, files: @nFiles, comment: @comment, lines_of_code: @code }
    end
  end
end
