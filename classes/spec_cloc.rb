require 'yaml'
class Cloc
  def initialize(source_files, *options)
    @source_files = source_files
    @options = options.push('--yaml', '--quiet')
  end

  def generate
    yaml = `cloc #{@options.join(' ')} #{@source_files.join(' ')}`
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

