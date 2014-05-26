class SpecMetadataGenerator
  include HashInit
  attr_accessor :spec, :docset_path

  def generate
    vputs "Generating the Specs version metadata and all that"
    count = 0;

    begin
      trunk_spec = Net::HTTP.get(URI("https://trunk.cocoapods.org/api/v1/pods/" + @spec.name))
      versions = JSON.parse(trunk_spec)["versions"]
      versions = versions.map { |s| Pod::Version.new(s["name"]) }.sort.map { |semver| semver.version }

      hash_string = {
        :versions => versions,
      }.to_json.to_s

      json_filepath = @docset_path + "../metadata.json"

      File.open(json_filepath, "wb") { |f| f.write hash_string }

    rescue Errno::ECONNRESET => e
      puts "Error generating Spec metadata: " + e.message.red
      
      count += 1
      retry unless count > 3
    end
  end

end
