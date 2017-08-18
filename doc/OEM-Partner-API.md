The purpose of this document is to describe the way of communication between OEM partners and SUSE Customer Center API.

## Authentication

Authentication for this endpoint is performed using the SHA256 HMAC algorithm. It requires three mandatory headers:

* `Date` - current time and date of request in HTTP Date Header format (RFC 7321) - like `Tue, 06 Jul 2016 04:39:43 GMT`.

  **Important:** this header is used for prevention of repeated-request-attack. Dates older than 15 minutes will be interpreted as authentication failure.
* `Content-MD5` - Base64-encoded MD5 hash of request body (without HTTP verb and Headers) - like `xdcO0PyZn5SIAsIAI2pl7A==`. In case of `GET` requests it can be a hash of empty string.
* `Authorization` - header containing HMAC type, organization credentials and request signature - like `APIAuth-HMAC-SHA256 112233:wvSi7Ach641iUvDTVE5AEVQCwXdH0uSfUQecJTlLSIolxVmqmk7gESkUIi+65R4x6OcDNy6ytVNBbQ5hlLzBpH0V3QolvYFHRgwQqcGhcbSDrUX7nQyVREilfVJ4FYaIirBnfXWYwi9K43bXHcEWj/mBQ1A8c7vpViWpalCdf8M=`.

### Making an `Authorization` header

It consists of 3 main parts.

First part `APIAuth-HMAC-SHA256` - tells the server which algorithm is used. This value is constant, other algorithms are not accepted.

Second part `112233` - is your company's ID provided by SUSE. You can consider it as a login.

Third part is Base64-encoded SHA256-encrypted HMAC signature of the following strings, joined with commas:

* HTTP verb
* Content-Type header
* Content-MD5 header
* URL path
* Date header

For example:

`POST,application/json,xdcO0PyZn5SIAsIAI2pl7A==,/api/oem/partner_orders,Tue, 06 Jul 2016 04:39:43 GMT`

This string is then encrypted by the SHA256 HMAC using the key provided to you with the ID.

Second and third parts are connected with a colon.

### HMAC Implementations

Implementations of HMAC are linked from the footer of https://en.wikipedia.org/wiki/Hash-based_message_authentication_code

We also have reference [implementation](https://github.com/SUSE/connect/wiki/OEM-API-Bash-Client) in Bash

## List of Partner Orders

`GET /api/oem/partner_orders`

This endpoint shows the list of OEM Partner's orders stored before.

### Example

Given your company ID is `112233`, your secret key is `foobar`.

Request:

```
GET https://scc.suse.com/api/oem/partner_orders

Content-Type: application/json
Date: Tue, 06 Jul 2016 04:39:43 GMT
Content-MD5: 1B2M2Y8AsgTpgAmY7PhCfg==
Authorization: APIAuth-HMAC-SHA256 112233:oDUPWnSduVE+DmkqQC7m3CP66ycVhQImHxmdW2COmio=
```

Response:

```json
[
  { "id": 1,
    "purchased_at": "2016-07-06T08:48:22.000Z",
    "oem_token": "987654",
    "created_at": "2016-07-06T08:59:29.568Z",
    "email": null,
    "partner_order_items": [
      { "id": 1,
        "system_limit": 1,
        "sku": "345-67890" },
      { "id": 2,
        "system_limit": 3,
        "sku": "234-56789" }]
  },
  { "id": 2,
    "purchased_at": "2016-07-06T09:48:22.000Z",
    "oem_token": "987655",
    "created_at": "2016-07-06T09:59:29.568Z",
    "email": "john.doe@example.com",
    "partner_order_items": [
      { "id": 3,
        "system_limit": 1,
        "sku": "345-67890" },
      { "id": 4,
        "system_limit": 3,
        "sku": "234-56789" }]
  }
]
```


## Register a Partner Order

`POST /api/oem/partner_orders`

This endpoint stores an OEM Partner order by the token with items represented by SUSE SKUs and their system limit.
Acceptable request `Content-Type`s are `application/json` and `application/x-www-form-urlencoded`.

### Params

* `partner_order` - collection of parameters for the partner_order
  * `partner_order[oem_token]` - token string. Must be unique per partner. Maximum length for the string is 255 characters.
  * `partner_order[purchased_at]` - string representing date and time of partner_order in ISO8601 format
  * `partner_order[email]` - string, optional. Email to be notified when the subscription is ready
  * `partner_order[partner_order_items_attributes]` - collection of parameters of items included in the partner_order
    * `partner_order[partner_order_items_attributes][N][sku]` - SUSE SKU number of purchased item as string
    * `partner_order[partner_order_items_attributes][N][system_limit]` - maximum number (integer) of systems that can use the given SKU

### Example

Given your company ID is `112233`, your secret key is `foobar`.

Request:

```
POST https://scc.suse.com/api/oem/partner_orders

Content-Type: application/json
Date: Tue, 06 Jul 2016 04:39:43 GMT
Content-MD5: q1ysJpf4J5ngXWEs+1M4vg==
Authorization: APIAuth-HMAC-SHA256 112233:2z4Wnoo79RXGPgHGokLv0JD2e2yTshqK1dCO8/99+68=
```

```json
{ "partner_order":
  { "oem_token": "987654",
    "email": "example@example.com",
    "purchased_at": "2016-07-06T08:18:11.053Z",
    "partner_order_items_attributes": [
      { "sku": "345-67890",
        "system_limit": 1 },
      { "sku": "234-56789",
        "system_limit": 3 }
    ]
  }
}
```

Response:

```json
{ "id": 1,
  "purchased_at": "2016-07-06T08:48:22.000Z",
  "oem_token": "987654",
  "created_at": "2016-07-06T08:59:29.568Z",
  "email": null,
  "partner_order_items": [
    { "id": 1,
      "system_limit": 1,
      "sku": "345-67890" },
    { "id": 2,
      "system_limit": 3,
      "sku": "234-56789" }]
}
```
