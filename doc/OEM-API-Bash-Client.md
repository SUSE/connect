```bash
#!/bin/bash
# Author: https://github.com/wstephenson
# This script is to demonstrate the use of the SCC OEM partner order API
# It is not intended for production use!
host="https://scc.suse.com"
path="/api/oem/partner_orders"

username="example"
secret="secret"

# As a RESTful interface,
# GET the above path to read existing orders,
# POST to add new orders
http_verb="POST"

# data is used for POSTING new OEM orders
# leave empty for GET
# data JSON schema is given in API documentation
# oem_token MUST be unique
data='{"partner_order":{"oem_token":"some_unique_foo3","purchased_at":"2016-07-15","partner_order_items_attributes":[{"sku":"877-008014-I","system_limit":2},{"sku":"874-007161","system_limit":4}]}}'

# Don't change anything below this line.
## RFC 7321, because it is used in the HTTP Date: header
## Generate Date header
timestamp=$(date -u "+%a, %d %b %Y %T GMT")
h_date="Date:$timestamp"
## Content-Type header
content_type="application/json"
h_content_type="Content-Type:$content_type"
## Generate Content-MD5 header
content_md5=$(printf '%s' "$data" | openssl md5 -binary | base64)
h_content_md5="Content-MD5:$content_md5"
## HMAC Authorization header
hmac_in="$http_verb,$content_type,$content_md5,$path,$timestamp"
echo $hmac_in
hmac=$(printf '%s' "$hmac_in" | openssl sha256 -hmac "$secret" -binary | base64)
h_authorization="Authorization:APIAuth-HMAC-SHA256 $username:$hmac"

if [ $http_verb = "POST" ]; then
  data_opt="-d $data"
else
  data_opt=""
fi

# Make the api call
curl "$host$path" -H "$h_content_type" -H "$h_date" -H "$h_content_md5" -H "$h_authorization" $data_opt
```