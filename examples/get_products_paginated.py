#!/usr/bin/env python

import httplib2
import re
import json
import sys
 
h = httplib2.Http(".cache", disable_ssl_certificate_validation=True)
h.add_credentials(sys.argv[1], sys.argv[2])
 
products = []
 
def process_rels(response):
  links = response["link"].split(',')
  regex = re.compile(r'<(.*?)>; rel="(\w+)"')
  hash_refs = {}
  for link in links:
    href, name = regex.findall(link)[0]
    hash_refs[name] = href
  return hash_refs
  
(resp, content) = h.request("https://scc.suse.com/connect/organizations/products/unscoped", "GET")
 
while True:
  products.extend(json.loads(content))
  rels = process_rels(resp)
  if not 'next' in rels:
    break
  (resp, content) = h.request(rels['next'], "GET")

for product in products:
  print product['name']
