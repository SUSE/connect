#!/usr/bin/ruby

require 'rest-client'
require 'net/http'
require 'pp'
require 'json'
require 'base64'

require 'byebug'

USERNAME = ARGV[0]
PASSWORD = ARGV[1]

AUTH_HEADER = { Authorization: 'Basic ' + Base64.encode64("#{USERNAME}:#{PASSWORD}").chomp }.freeze
API_BASE_URL = 'https://scc.suse.com/connect/'.freeze

def process_rels(response)
  links = (response.headers[:link] || '').split(', ').map do |link|
    href, name = link.match(/<(.*?)>; rel="(\w+)"/).captures
    [name.to_sym, href]
  end
  Hash[*links.flatten]
end

def get(url)
  puts "Requesting #{url}"
  res = RestClient.get(url, AUTH_HEADER)
  raise StandardError, "Failed with response code #{res.code}" unless res.code == 200
  res
end

def process_data(data)
  JSON.parse(data).each do |system|
    next if system['last_seen_at'].nil?
    if Time.now - Time.parse(system['last_seen_at']) > 3600 * 24 * 14 # older than 2 weeks
      puts "Deleting system #{system['id']}. Last seen at: #{system['last_seen_at']}"
      RestClient.delete(
        API_BASE_URL + '/systems',
        {
          Authorization: 'Basic ' + Base64.encode64("#{system['login']}:#{system['password']}").delete("\n")
        }
      )
    end
  end
end

resp = get(API_BASE_URL + 'organizations/systems')

@page = 1
loop do
  links = process_rels(resp)
  process_data(resp)
  break unless links[:next]
  @page += 1
  resp = get(links[:next])
end
