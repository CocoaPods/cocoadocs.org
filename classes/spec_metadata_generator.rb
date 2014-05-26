class SpecMetadataGenerator
  include HashInit
  attr_accessor :spec, :docset_path

  def generate
    vputs "Generating the Specs version metadata and all that"

    trunk_spec = REST.get("https://trunk.cocoapods.org/api/v1/pods/" + @spec.name).body
    versions = JSON.parse(trunk_spec)["versions"]

    versions = versions.keep_if do |version|
      return true if version == @spec.version
      REST.head('http://cocoadocs.org/docsets/' + @spec.name + "/" + version["name"] + "/index.html").ok?
    end


    versions = versions.map { |s| Pod::Version.new(s["name"]) }.sort.map { |semver| semver.version }

    hash_string = {
      :versions => versions,
    }.to_json.to_s

    json_filepath = @docset_path + "../metadata.json"

    File.open(json_filepath, "wb") { |f| f.write hash_string }

  end

end
