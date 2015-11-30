class SpecMetadataGenerator
  include HashInit
  attr_accessor :spec, :docset_path, :versions

  # @return [Array<String>] Returns all the versions
  def generate
    @versions = retrieve_versions_from_trunk.keep_if do |version|
      if version == @spec.version || documentation_for_version_exists?(version)
        true
      else
        REST.head('http://cocoadocs.org/docsets/' + @spec.name + "/" + version.to_s + "/index.html").ok?
      end
    end.sort.map(&:version)
  end

  def save
    hash_string = {
      name: @spec.name,
      versions: @versions
    }.to_json.to_s

    json_filepath = @docset_path + "../metadata.json"

    File.open(json_filepath, "wb") { |f| f.write hash_string }
  end

  def latest_version
    versions.reverse_each.find { |v| !v.prerelease? } || versions.last
  end

  def latest_version?
    latest_version == spec.version
  end

  private

  # @return [Array<Pod::Version>] Returns all versions of the pod found in trunk
  def retrieve_versions_from_trunk
    trunk_spec = REST.get("https://trunk.cocoapods.org/api/v1/pods/" + @spec.name).body
    versions = JSON.parse(trunk_spec)["versions"].map { |version| version['name'] }
    versions.map { |version| Pod::Version.new(version) }
  end

  # @param [Pod::Version] version
  # @return [Bool] Returns true if the version has documentation
  def documentation_for_version_exists?(version)
    REST.head("http://cocoadocs.org/docsets/#{@spec.name}/#{version}/index.html").ok?
  end
end
