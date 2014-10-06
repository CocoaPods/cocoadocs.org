class SpecMetadataGenerator
  include HashInit
  attr_accessor :spec, :docset_path, :versions

  def generate
    vputs "Generating the Specs version metadata and all that"

    trunk_spec = REST.get("https://trunk.cocoapods.org/api/v1/pods/" + @spec.name).body
    versions = JSON.parse(trunk_spec)["versions"].map { |version| version['name'] }
    versions = versions.map { |version| Pod::Version.new(version) }

    versions = versions.keep_if do |version|
      return true if version == @spec.version
      REST.head('http://cocoadocs.org/docsets/' + @spec.name + "/" + version.to_s + "/index.html").ok?
    end

    @versions = versions.sort.map { |semver| semver.version }
    @versions
  end

  def save
    hash_string = {
      :name => @spec.name,
      :versions => @versions
    }.to_json.to_s

    json_filepath = @docset_path + "../metadata.json"

    File.open(json_filepath, "wb") { |f| f.write hash_string }
  end

end
