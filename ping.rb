#!/usr/bin/env ruby

gem 'nap'
require 'rest'
require 'net/http'
require 'json'
require 'httparty'


def send_stats(number, metric_id)
  api_key = ENV['STATUS_IO_API_KEY']
  page_id = ENV['STATUS_IO_PAGE_ID']
  api_base = 'https://api.statuspage.io/v1'

  dhash = {
    :timestamp => Time.now.to_i,
    :value => number.to_i
  }

  response = HTTParty.post("#{api_base}/pages/#{page_id}/metrics/#{metric_id}/data.json",  :headers => { 'Authorization' => "OAuth #{api_key}" }, :body => { :data => dhash } )
  puts response.to_s
end


number = REST.get("http://localhost:4567/recent_pods_count").body
puts "Sending #{number} pods to Status.io"

# Send CocoaDocs stats
cd_metric_id = ENV['STATUS_IO_METRIC_ID']
send_stats(number, cd_metric_id)

get_url = "http://stats.cocoapods.org/api/v1/recent_requests_count"
reset_url = "http://stats.cocoapods.org/api/v1/reset_requests_count"

number = REST.get(get_url).body
puts "Sending #{number} of stats to Status.io"

# Send stats.cocoapods.org stats
stats_metric_id = ENV['STATUS_IO_STATS_METRIC_ID']
send_stats(number, stats_metric_id)

# Reset stats.cocoapods.org stats
REST.post(reset_url, {}.to_json)

sleep 1
