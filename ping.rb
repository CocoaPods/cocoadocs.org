#!/usr/bin/env ruby

require 'rubygems'
require 'httparty'
require 'timeout'

begin
  number.to_s = HTTParty.get "http://localhost:4567/recent_pods_count"
  puts "Sending #{number} pods to Status.io"

  api_key = ENV['STATUS_IO_API_KEY']
  page_id = ENV['STATUS_IO_PAGE_ID']
  metric_id = ENV['STATUS_IO_METRIC_ID']
  api_base = 'https://api.statuspage.io/v1'

  dhash = {
    :timestamp => Time.now.to_i,
    :value => number.to_i
  }

  HTTParty.post("#{api_base}/pages/#{page_id}/metrics/#{metric_id}/data.json",  :headers => { 'Authorization' => "OAuth #{api_key}" }, :body => { :data => dhash } )

  sleep 1
rescue
end
