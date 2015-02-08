require 'yaml'
require 'shellwords'

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
      if source_files.empty?
        vputs "No Source files found."
        return {}
      end

      yaml =  `vendor/cloc-1.62.pl #{@options.join(' ')} #{source_files.map(&:shellescape).join(' ')}`
      vputs "vendor/cloc-1.62.pl #{@options.join(' ')} #{source_files.map(&:shellescape).join(' ')}"

      if yaml.strip.length == 0
        puts "Got nothing from CLOC, are you on a version of cloc with swift support? ( 1.6.2+)".red
      end
      vputs yaml
      yaml.sub!(/.*^---/m, '---')

      hash = YAML.load yaml
      hash.delete 'header'
      hash.map { |l, r| Results.new(l, r).to_h }
    rescue => e
      puts "CLOC Crashed :#{e}".red
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
      { language: @language, files: @nFiles, comments: @comment, lines_of_code: @code }
    end
  end
end
