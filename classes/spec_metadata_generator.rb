class SpecMetadataGenerator
  include HashInit
  attr_accessor :spec
  
  def generate
    filepath = $active_folder + "/docsets/" + @spec.name

    versions = []
    Dir.foreach filepath do |version|
      next if version[0] == '.'
      next if version == "metadata.json"
      next if version == "index.html"
      versions << version
    end

    #semantically order them as they're in unix's order ATM
    # we convert them to Versions, then back to strings
    versions = versions.map { |s| Pod::Version.new(s) }.sort.map { |semver| semver.version }

    hash_string = {
    
      :spec_homepage => @spec.homepage,
      :versions => versions,
      :license => @spec.or_license
    
    }.to_json.to_s
  
    function_wrapped = "setup(#{hash_string})"
    json_filepath = $active_folder + "/docsets/" + @spec.name + "/metadata.json"

    File.open(json_filepath, "wb") { |f| f.write function_wrapped }
  end

end