#!/usr/bin/env ruby

require 'rubygems'
require 'httparty'

api_key = ENV['STATUS_IO_API_KEY']
page_id = ENV['STATUS_IO_PAGE_ID']
metric_id = ENV['STATUS_IO_METRIC_ID']
api_base = 'https://api.statuspage.io/v1'

interval = 60 * 5.0

numbers = Hash.new { 0 }

# Returns the same time for all times in a 5 minute interval.
#
def slot_for current_seconds, interval
  (current_seconds / interval).floor * interval
end

loop do
  begin
    # Remember current time.
    #
    current_seconds = Time.now.to_i
    
    # Get current count.
    #
    number = HTTParty.get "http://cocoadocs.org/recent_pods_count"
    
    # Find slot for count and add.
    #
    slot = slot_for current_seconds, interval
    numbers[slot] += number

    # If a time slot is finished.
    #
    while numbers.size > 1
      # Remove the one that's finished.
      #
      time, value = numbers.shift

      puts "Sending #{value} pods to statuspage.io."

      data = {
        :timestamp => time,
        :value => value
      }
      
      # And send to statuspage.io.
      #
      HTTParty.post("#{api_base}/pages/#{page_id}/metrics/#{metric_id}/data.json",  :headers => { 'Authorization' => "OAuth #{api_key}" }, :body => { :data => data } )
    end
  rescue StandardError => e
    puts e
  end

  sleep interval / 5
end