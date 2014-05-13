class AppleJSONParser
  include HashInit
  attr_accessor :json_filepath

  def generate
    vputs "Downloading Apple Library JSON"

    json_path = "#{$active_folder}/html/apple_documents.jsonp"
    ios_response = Net::HTTP.get_response("developer.apple.com","/library/ios/navigation/library.json")
    json = JSON.parse(ios_response.body)

    column_index_framework = json["columns"]["framework"]
    column_index_name = json["columns"]["name"]
    column_index_url = json["columns"]["url"]
    column_index_type = json["columns"]["type"]

    @frameworks_array = json["topics"].select do |topic|
      topic["name"] == "Frameworks"
    end.first["contents"]

    @topics_array = json["topics"].select do |topic|
      topic["name"] == "Resource Types"
    end.first["contents"]

    cocoadocs_json = json["documents"].map do |document|
      {
        "url" => apple_url(document[column_index_url]),
        "name" => document[column_index_name],
        "framework" => framework_with_id(document[column_index_framework]),
        "type" => type_with_id(document[column_index_type])
      }
    end

    cocoadocs_json = cocoadocs_json.reject do |document|
      document["framework"].length < 1
    end

    array_string = cocoadocs_json.to_json.to_s
    function_wrapped = "var appledocs = #{array_string}; searchTermChanged()"

    File.open(json_path, 'wb') { |f| f.write(function_wrapped) }
  end

  def apple_url url
    return url if url.start_with? "http"
    return "https://developer.apple.com/library/ios/navigation/" + url
  end

  def framework_with_id id
    item = @frameworks_array.select do |framework|
      framework["key"] == id.to_s
    end.first

    item["name"]
  end

  def type_with_id id
    item = @topics_array.select do |topic|
      topic["key"] == id.to_s
    end.first

    item["name"]
  end

end
