class SpecMetadataGenerator
  include HashInit
  attr_accessor :spec, :docset_path

  def generate
    vputs "Generating the Specs version metadata and all that"
    begin
      trunk_spec = Net::HTTP.get(URI("https://trunk.cocoapods.org/api/v1/pods/" + @spec.name))
      versions = JSON.parse(trunk_spec)["versions"]
      versions = versions.map { |s| Pod::Version.new(s["name"]) }.sort.map { |semver| semver.version }

      hash_string = {
        :versions => versions,
      }.to_json.to_s

      json_filepath = @docset_path + "../metadata.json"

      File.open(json_filepath, "wb") { |f| f.write hash_string }

    rescue Exception => e
      puts "Error generating Spec metadata: " + e
    end
  end

end
