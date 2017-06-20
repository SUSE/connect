#!/usr/bin/ruby

require 'rest-client'
require 'net/http'
require 'pp'
require 'json'
require 'base64'

USERNAME = ARGV[0]
PASSWORD = ARGV[1]

AUTH_HEADER = { Authorization: 'Basic ' + Base64.encode64("#{USERNAME}:#{PASSWORD}").chomp }
URL = 'https://scc.suse.com/connect/organizations/products/unscoped'

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

resp = get(URL)
@entities = []

@page = 1
loop do
  links = process_rels(resp)
  @entities += JSON.parse(resp)
  break unless links[:next]
  @page += 1
  resp = get(links[:next])
end

@entities.each do |entity|
  puts "#{entity['name']}"
end
