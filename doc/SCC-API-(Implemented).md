[SCC](https://scc.suse.com) provides a RESTful API interface. This essentially means that you can
send an HTTP request (`GET`, `PUT/PATCH`, `POST`, or `DELETE`) to an endpoint,
and you'll get back a JSON representation of the resource(s) (including
children) in return.

## Levels of Authentication
There are various resources which can be queried through the API. Most of them
require identification through HTTP basic authentication (login / password) or
token authentication. Read the respective sections for further instructions.

These several levels of authentication also act as scopes on the queried
resources. Naturally, resource listings on one level will resemble subsets of
the same listings on a higher level.

## API versioning:
By default, the latest available api version is used. Clients are recommended to
hardcode a fixed version in order not to break when the SCC api changes in an incompatible way.
This is done by setting the accept header in the request, for example:

```Accept: application/vnd.scc.suse.com.v4+json```

The current API version is 4. Documentation of older API versions:
* [Version 3](SCC-API-V3.md)

Hint: to get knowledge, with what version SCC just respond - take a look at respond header `scc-api-version`
e.g. following clearly indicates that SCC responded with version 4 of API

```
scc-api-version: v4
```


## Localized response:

To receive translated messages, set the HTTP Accept-Language header to the user's preferred language(s),
comma-separated list if multiple.

```Accept-Language: DE```

## Request compressed data:

If you want to minimize bandwidth usage - it is possible to request compressed representation of data.
E.g. for `https://scc.suse.com/connect/organizations/products` endpoint the compressed data is just 5% of the uncompressed one.
For using that technique - just add `-H "Accept-Encoding: gzip, deflate"` to your request headers, so the
Curl example would be:

```bash
curl -H "Accept-Encoding: gzip, deflate" -u"<login>:<password>" https://scc.suse.com/connect/organizations/products | zcat
```

## Pagination:

SCC API V4 introduces pagination for listing entities. Endpoints which support pagination have a mark in their description.
Some endpoints have different default values for returned entities per page. The amount of entities per page is server driven.

Pagination information is added in two response headers:

* `Link`
  this header contains a link to the next/last page if there is one via rel link.
  Keep in mind that you should always rely on these link relations provided to you. Don’t try to guess or construct your own URL.
* `Total` which represents total amount of entities accessible via this endpoint.

Take a look example headers of the paginated response:

```
Total: 533
Link: <https://scc.suse.com/connect/organizations/products/unscoped?page=11>; rel="last",
  <https://scc.suse.com/connect/organizations/products/unscoped?page=2>; rel="next"
```
In example above new line added for readability.

As you can see - Link header contains a reference URL for the last page in the data set and the next page.
Following the next link will give you second page with reference to the third page and so on. When there is no next reference
that means that there is no more records to fetch. Traversing successfully done. If there is no Link header present
that mean that no pagination traversing required. Either this endpoint is unpaginated, either only one page exist.

Some examples from traversing with pagination for Ruby, Perl and Python are [available](https://github.com/SUSE/connect/tree/master/examples)

NOTE: only GET requests are paginated.

## Error handling

In the event of an error (eg. validation error), SCC *should* respond with a **422: Unprocessable Entity** header and a valid JSON object which *must* the corresponding error messages in the `error` key.

#### Example failure response

```json
{
  "error": "Required parameters are missing or empty: login, password"
}
```

In the event an authorization failure (or some unrecoverable error in the request itself) occurs, SCC *must* respond with a **404: Not found** header.

## ToC:

  - [Organizations](#organizations)
    - [list products](#list-of-products-available-for-organization)
    - [list of all products](#list-of-all-products)
    - [list repositories](#list-of-repositories-available-for-organization)
    - [list subscriptions](#list-of-subscriptions-available-for-organization)
    - [list orders](#list-of-orders-known-by-organization)
    - [list systems](#list-of-systems-known-by-organization)
    - [show system](#show-system-of-organization)
    - [create/update system](#createupdate-system-for-organization)
    - [destroy system](#destroy-system-of-organization)
  - [Subscriptions](#subscriptions)
    - [announce system](#announce-system)
    - [products](#subscription-products)
  - [Systems](#systems)
    - [product](#product)
    - [activate product](#activate-product)
    - [deactivate product](#deactivate-product)
    - [upgrade product](#upgrade-product)
    - [update system](#update-system)
    - [de-register system](#deregister-system)
    - [system online migrations](#list-system-online-migrations)
    - [system offline migrations](#list-system-offline-migrations)
    - [system synchronize products](#synchronize-system-products)
    - [services](#system-services)
    - [subscriptions](#system-subscriptions)
    - [activations](#system-activations)
  - [Public](#public)
    - [Installer-Updates repos](#installer-updates-repositories)
    - [Packages search](#packages-search)

***
***

### <a id="organizations">Organizations</a>
For all endpoints on this level of the organization (mirroring) credentials are used (basic auth)
where webcompanyid is an username and credentials is the password.
All calls will return the list of resources as they are available through the
scope of the specified organization.

#### Registration Proxy identification

Registration Proxy *should* provide its UUID for identification. The UUID *must* be submitted as the only value of the `SMT` or `SMS` HTTP request header (depending on the type of the Registration Proxy). UUID *should* be a valid random-based UUIDv4, in either in compact (without dashes) or canonical form.

If no UUID provided in that header, or it is not a valid UUIDv4, SCC *must* create a registration and set its UUID to nil.

  - [list products](#list-of-products-available-for-organization)
  - [list of all products](#list-of-all-products)
  - [list repositories](#list-of-repositories-available-for-organization)
  - [list subscriptions](#list-of-subscriptions-available-for-organization)
  - [list orders](#list-of-orders-known-by-organization)
  - [list systems](#list-of-systems-known-by-organization)
  - [show system](#show-system-of-organization)
  - [create system](#createupdate-system-for-organization)
  - [destroy system](#destroy-system-of-organization)

##### <a id="list-of-products-available-for-organization">List of Products available for organization</a>
List all available products for an organization. This includes a list of all repositories
for each product.

* Paginated output

```
GET /connect/organizations/products
```

###### Response
```
Status: 200 OK
```

```json
[
  {
    "id": 1117,
    "name": "SUSE Linux Enterprise Server",
    "identifier": "SLES",
    "former_identifier": "SUSE_SLES",
    "version": "12",
    "release_type": null,
    "release_stage": "released", // or "beta"
    "arch": "x86_64",
    "friendly_name": "SUSE Linux Enterprise Server 12 x86_64",
    "product_class": "7261",
    "product_family": "SUSE Linux Enterprise Server",
    "cpe": "cpe:/o:suse:sles:12",
    "free": false,
    "description": "SUSE Linux Enterprise offers a comprehensive suite of products built on a single code base. The platform addresses business needs from the smallest thin-client devices to the world's most powerful high-performance computing and mainframe servers. SUSE Linux Enterprise offers common management tools and technology certifications across the platform, and each product is enterprise-class.",
    "eula_url": "https://updates.suse.com/SUSE/Products/SLE-SERVER/12/x86_64/product.license/",
    "product_type": "base",
    "recommended": false,
    "predecessor_ids": [769, 690, 824, 814, 1300],
    "successor_ids": [1322],
    "shortname": "SLES12",
    "extensions": [
      {
        "id": 1342,
        "name": "SUSE Enterprise Storage",
        "identifier": "ses",
        "former_identifier": "ses",
        "version": "2",
        "release_type": null,
        "release_stage": "released", // or "beta"
        "arch": "x86_64",
        "friendly_name": "SUSE Enterprise Storage 2 x86_64",
        "product_class": "SES",
        "product_family": "sles",
        "cpe": "cpe:/o:suse:ses:2",
        "free": false,
        "description": "SUSE Enterprise Storage 2 for SUSE Linux Enterprise Server 12, powered by Ceph.",
        "eula_url": "https://updates.suse.com/SUSE/Products/Storage/2/x86_64/product.license/",
        "extensions": [ ],
        "product_type": "extension",
        "recommended": false,
        "repositories": [
          {
            "id": 1917,
            "name": "SUSE-Enterprise-Storage-2-Updates",
            "distro_target": "sle-12-x86_64",
            "description": "SUSE-Enterprise-Storage-2-Updates for sle-12-x86_64",
            "url": "https://updates.suse.com/SUSE/Updates/Storage/2/x86_64/update",
            "autorefresh": true,
            "installer_updates":false
          }
        ]
      }
    ],
    "repositories": [     
      {
        "id": 1632,
        "name": "SLES12-Updates",
        "distro_target": "sle-12-x86_64",
        "description": "SLES12-Updates for sle-12-x86_64",
        "url": "https://updates.suse.com/SUSE/Updates/SLE-SERVER/12/x86_64/update",
        "autorefresh": true,
        "installer_updates":false
      }
    ]
  }
]
```

##### <a id="list-of-all-products">List of all Products</a>
List all available products overall. This includes a list of all repositories
for each product. Look at [list products](#list-of-products-available-for-organization) for example output

* Paginated output

```
GET /connect/organizations/products/unscoped
```

##### <a id="organizations-repositories">List of Repositories available for organization</a>
By given credentials determine the organization of interest and output all repositories available for that organization.
Available repositories means - all the repositories you have access on a ground of bought subscription.

```
GET /connect/organizations/repositories
```

###### Curl
```
curl -u '<webcompanyid>:<credentials>' https://scc.suse.com/connect/organizations/repositories
```

###### Response
The response will contain array of repositories.

```
Status: 200 OK
```
```json
[
  {
    "id": 1358,
    "name": "SLE10-SDK-SP4-Online",
    "distro_target": "sles-10-i586",
    "description": "SLE10-SDK-SP4-Online for sles-10-i586",
    "url": "https://nu.novell.com/repo/$RCE/SLE10-SDK-SP4-Online/sles-10-i586",
    "autorefresh": true,
    "installer_updates":false
  }
]
```

***

##### <a >List of Orders known by organization</a>
By given credentials determine the organization of interest and output all orders for that organization.

* Paginated output

```
GET /connect/organizations/orders
```

###### Curl
```
curl -u '<webcompanyid>:<credentials>' https://scc.suse.com/connect/organizations/orders
```

###### Response
The response will contain array of orders.

```
Status: 200 OK
```
```json
[
  {
    "order_number": 14,
    "order_items": [ {
      "id": 4,
      "fulfillid": 8796,
      "subscription_id": 963214,
      "start_date": "2007-12-01",
      "end_date": "2010-12-31",
      "quantity": 6,
      "expired": false,
      "sku": "6A2BC"
    } ]
  }  
]
```

***

##### <a >List of Systems known by organization</a>
By given credentials determine the organization of interest and output all systems for that organization.

* Paginated output

```
GET /connect/organizations/systems
```

###### Curl
```
curl -u '<webcompanyid>:<credentials>' https://scc.suse.com/connect/organizations/systems
```

###### Response
The response will contain array of systems.

```
Status: 200 OK
```
```json
[
  {
    "id": 14,
    "login": "SCC_28445cf5f3a84bfdaa44d4a5e499b4fd",
    "password": "secret"
  }  
]
```

***

##### <a >Show System of Organization</a>
By given credentials determine the organization of interest and output requested system by id.

```
GET /connect/organizations/systems/<id>
```

###### Curl
```
curl -u '<webcompanyid>:<credentials>' https://scc.suse.com/connect/organizations/systems/<id>
```

###### Parameters
  - required
    - `id` - id of the System

###### Response
The response will contain system object.

```
Status: 200 OK
```

```json
{
  "id": 14,
  "login": "SCC_28445cf5f3a84bfdaa44d4a5e499b4fd",
  "password": "secret"
}  
```

***

##### <a>Create/Update System for Organization</a>

Please check the [[Registration-Proxies-API]] page to see the details of this API call.

As SMT servers *may not* distinguish between freshly-created and updated systems under their management, SCC API endpoint *should* treat those two situations equally (and we use verbs *create* and *update* interchangeably in this section).

```
POST /connect/organizations/systems
```

***

##### <a >Destroy System of Organization</a>

Please check the [[Registration-Proxies-API]] page to see the details of this API call.

```
DELETE /connect/organizations/systems/<id>
```

###### Curl
```
curl -u '<webcompanyid>:<credentials>' -X 'DELETE' https://scc.suse.com/connect/organizations/systems/<id>
```

###### Parameters
  - required
    - `id` - id of the System

###### Response
The response will not contain any content

```
Status: 204 No Content
```

##### <a id="organizations-subscriptions">List of Subscriptions available for organization</a>
By given credentials determine the organization of interest and output all subscriptions available for that organization.

* Paginated output

```
GET /connect/organizations/subscriptions
```

###### Curl
```
curl -u '<webcompanyid>:<credentials>' https://scc.suse.com/connect/organizations/subscriptions
```

###### Response
The response will contain array of subscriptions with systems nested.
```
Status: 200 OK
```
```json
[
  {
    "id": 1,
    "regcode": "631dc51f",
    "name": "Subscription 1",
    "type": "FULL",
    "status": "EXPIRED",
    "starts_at": null,
    "expires_at": "2014-03-14T13:10:21.164Z",
    "system_limit": 6,
    "systems_count": 1,
    "virtual_count": null,
    "product_classes": ["SLES"],
    "families": ["sles", "sled"],
    "skus": ["sku1", "sku2"],
    "systems": [{ "id": 1, "login": "login1" }]
  }
]
```

***
### <a id="subscriptions">Subscriptions</a>
For all endpoints on this level of the subscription's token (registration
code) is used for authentication. This should be sent as an authorization header
like:
```
Authorization: Token token="00ff00111abc"
```
All calls will return the list of resources as they are available through the
scope of the specified subscription.

- [announce system](#announce-system)
- [products](#subscription-products)

***
##### <a id="sub_sys_create">Announce System</a>
Announce a system to SCC. This is the typical first
contact of any system with SCC, which triggers a couple of processes:
  - Register the system with SCC, thereby creating and returning the system's
  credentials (`identifier` and `secret`) for further access to this API and
  update repositories.
  - Store the system's information from the payload in SCC to be able to provide
  proper counting and additional functionality through SCC's web page.
  - Validate subscription specified by the `regcode`. E.g. check for expiry date,
  system limit, hardware requirements, etc. Note that this does not consume a `regcode` from that subscription, but only uses the `regcode` to authenticate the caller of this method
  - Associate the system inside SCC with the subscription.

```
POST /connect/subscriptions/systems
```
###### Parameters
  - optional:
    - `hostname` ( *String* ): The system's `hostname` can be arbitrary and does
     not have to be unique. It will show up in SCC and serves as a human
     readable identifier to the user.
    - `hwinfo` ( *Object* ): Hardware information used to evaluate a
    subscription's potential business requirements (e.g. counting `sockets`) and
    to provide additional help (e.g. vendor specific repositories).
    - `parent` ( *String* ): UID of the parent system which can either hold a
    system's SCC identifier or any arbitrary name to group it with other
    virtualized systems in SCC.

###### Payload
```json
{
  "hostname": "virtual-system.domain.net",
  "hwinfo": {
    "cpus": 1,
    "sockets": 2,
    "arch": "x86_64",
    "graphics": "nvidia",
    "uuid": "6A5072A0-311B-430E-8EDE-A8770788B92D",
    "hypervisor": "KVM"
  }
}
```

###### Curl
```
curl https://scc.suse.com/connect/subscriptions/systems -H 'Content-Type:application/json' -H 'Authorization: Token token="04de2262"' -d '{"hostname": "testsled2", "hwinfo": {"arch": "x86_64"}}'
```

###### Response
The response will contain the system credentials (login/password) that will get
stored on the system in `/etc/zypp/credentials.d/SCCcredentials` to authenticate
any subsequent calls to SCC from this system.
```
Status: 200 OK
```

```json
{
  "login" : "SCC_3b336b126db1503a9513a14e92a6a62e",
  "password" : "24f057b7941e80f9cf2d51e16e8af2d6",
}
```

***
##### <a id="subscription-products">Subscription products</a>
List all available subscription products. This includes a list of all repositories for each product.

```
GET /connect/subscriptions/products
```

###### Parameters (Payloads)

  - optional parameters:
    - `identifier` ( *String* ): Product name, e.g. `SLES`.
    - `version` ( *String* ): Product version e.g. `12`, `11-3`
    - `arch` ( *String* ): System architecture, e.g. `x86_64`.
    - `release_type` ( *String* ): Release type, e.q `GA`

###### Curl:
```
curl -H "Authorization: Token token=12345678" https://scc.suse.com/connect/subscriptions/products.json
```

With optional parameters
```
curl -H "Authorization: Token token=12345678" "https://scc.suse.com/connect/subscriptions/products.json?identifier=SUSE_SLES&version=11-3&arch=x86_64

```

###### Response:
```json
[
  {
    "id": 94,
    "name": "SUSE Linux Enterprise Server",
    "identifier": "SUSE_SLES",
    "former_identifier": "SUSE_SLES",
    "version": "11.3",
    "release_type": null,
    "release_stage": "released", // or "beta"
    "arch": "x86_64",
    "friendly_name": "SUSE Linux Enterprise Server 11 SP3 x86_64",
    "product_class": "7261",
    "cpe": null,
    "free": false,
    "description": null,
    "eula_url": "",
    "repositories": [
      {
        "id": 111,
        "name": "SLES11-SP3-Updates",
        "distro_target": "sle-11-x86_64",
        "description": "SLES11-SP3-Updates for sle-11-x86_64",
        "url": "https://updates.suse.com/repo/$RCE/SLES11-SP3-Updates/sle-11-x86_64?a51fa38f33849fbad855bd7e418102d19f71a35d2",
        "enabled": true,
        "autorefresh": true,
        "installer_updates":false
      },
      {
        "id": 110,
        "name": "SLES11-SP3-Pool",
        "distro_target": "sle-11-x86_64",
        "description": "SLES11-SP3-Pool for sle-11-x86_64",
        "url": "https://updates.suse.com/repo/$RCE/SLES11-SP3-Pool/sle-11-x86_64?a51fa38f33849fbad855bd7e418102d19f71a35d2",
        "enabled": true,
        "autorefresh": false,
        "installer_updates":false
      },
    ],
    "product_type": "base",
    "recommended": false,
    "extensions": [
      {
        "id": 238,
        "name": "SUSE WebYaST",
        "identifier": "sle-11-WebYaST",
        "former_identifier": "sle-11-WebYaST",
        "version": "1.3",
        "release_type": null,
        "release_stage": "released", // or "beta"
        "arch": null,
        "friendly_name": "SUSE WebYaST 1.3",
        "product_class": "WEBYAST",
        "cpe": null,
        "free": true,
        "description": null,
        "eula_url": "",
        "repositories": [
          {
            "id": 270,
            "name": "SLE11-SP2-WebYaST-1.3-Pool",
            "distro_target": "sle-11-i586",
            "description": "SLE11-SP2-WebYaST-1.3-Pool for sle-11-i586",
            "url": "https://updates.suse.com/repo/$RCE/SLE11-SP2-WebYaST-1.3-Pool/sle-11-i586?a51fa38f33849fbad855bd7e418102d19f71a35d2",
            "enabled": true,
            "autorefresh": false,
            "installer_updates":false
          },

          {
            "id": 271,
            "name": "SLE11-SP2-WebYaST-1.3-Updates",
            "distro_target": "sle-11-ppc64",
            "description": "SLE11-SP2-WebYaST-1.3-Updates for sle-11-ppc64",
            "url": "https://updates.suse.com/repo/$RCE/SLE11-SP2-WebYaST-1.3-Updates/sle-11-ppc64?a51fa38f33849fbad855bd7e418102d19f71a35d2",
            "enabled": true,
            "autorefresh": true,
            "installer_updates":false
          }
        ],
        "product_type": "extension",
        "recommended": false,
        "extensions": []
      }
    ]
  }
]
```

***
### <a id="systems">Systems</a>
To access this level of authentication's endpoints the system credentials
(former NCC credentials) are used as login and password for HTTP basic
authentication.
All calls will return the list of resources as they are available through the
scope of the specified system.

The typical use cases to access the API on this level
are checking available resources for the system or updating hardware
information.

- [product](#product)
- [activate product](#activate-product)
- [deactivate product](#deactivate-product)
- [upgrade product](#upgrade-product)
- [update system](#update-system)
- [deregister system](#deregister-system)
- [system online migrations](#list-system-online-migrations)
- [system offline migrations](#list-system-offline-migrations)
- [services](#system-services)
- [subscriptions](#system-subscriptions)
- [activations](#system-activations)

##### <a id="system_product">Product</a>
Get the details of a product, including repositories, extensions, eula etc.
The product must be activated on the system.

```
GET /connect/systems/products
```

###### Parameters (Payloads)

  - required:
    - `identifier` ( *String* ): Product name, e.g. `SLES`.
    - `version` ( *String* ): Product version e.g. `12`.
    - `arch` ( *String* ): System architecture, e.g. `x86_64`.

###### Curl:
```
curl https://scc.suse.com/connect/systems/products -u<username>:<password> -d identifier=SLES -d version=11-SP2 -d arch=x86_64 -X GET
```

###### Response:
```json
{
  "id": 42,
  "name": "SUSE Linux Enterprise Server",
  "identifier": "SUSE_SLES",
  "version": "11",
  "release_type": "GA",
  "release_stage": "released", // or "beta"
  "arch": "x86_64",
  "friendly_name": "SUSE Linux Enterprise Server 11 x86_64",
  "enabled_repositories": [1150],
  "product_class": "7261",
  "product_family": "sles",
  "cpe": "cpe:/o:suse:sled-addon:12.0",
  "free": false,
  "product_type": "base",
  "recommended": false,
  "description": null,
  "eula_url": "https://nu.novell.com/SUSE:/Products:/SLE-12/images/repo/SLE-12-Server-POOL-x86_64-Media.license/",
  "extensions": [
    {
      "id": 1145,
      "name": "SUSE Linux Enterprise Server",
      "identifier": "sle-sdk",
      "version": "12",
      "release_type": null,
      "release_stage": "released", // or "beta"
      "arch": "ppc64le",
      "friendly_name": "SUSE Linux Enterprise Software Development Kit 12 ppc64le",
      "enabled_repositories": [1364, 1229],
      "product_class": null,
      "cpe": "cpe:/o:suse:sle-sdk:12.0",
      "free": true,
      "product_type": "extension",
      "recommended": false,
      "description": null,
      "eula_url": "https://nu.novell.com/repo/$RCE/SLE10-SDK-SP4-Online/sles-10-x86_64.license/",
      "extensions": [ ],
      "repositories": [
         {
          "id": 1357,
          "name": "SLE10-SDK-SP4-Online",
          "distro_target": "sles-10-x86_64",
          "description": "SLE10-SDK-SP4-Online for sles-10-x86_64",
          "url": "https://nu.novell.com/repo/$RCE/SLE10-SDK-SP4-Online/sles-10-x86_64",
          "autorefresh": true,
          "installer_updates":false
        }
      ]
    }
  ],
  "repositories": [     
    {
      "id": 1357,
      "name": "SLE10-SDK-SP4-Online",
      "distro_target": "sles-10-x86_64",
      "description": "SLE10-SDK-SP4-Online for sles-10-x86_64",
      "url": "https://nu.novell.com/repo/$RCE/SLE10-SDK-SP4-Online/sles-10-x86_64",
      "autorefresh": true,
      "installer_updates":false
    }
  ]
}
```

`product_type` can be 'base', 'module', or 'extension'

##### Errors:
422: "No product specified"
422: 'The requested product is not activated on this system.'


##### <a id="sys_prod_create">Activate product</a>
Activate a product, consuming a regcode. The response includes the data for the zypper service to be added.

```
POST /connect/systems/products
```
###### Parameters (Payloads)

  - required:
    - `token (regcode)` ( *String* ): opaque string belonging to a subscription
    - `identifier` ( *String* ): Product name, e.g. `SLES`.
    - `version` ( *String* ): Product version e.g. `12`.
    - `arch` ( *String* ): System architecture, e.g. `x86_64`.

  - optional:
    - 'email' ( *String* ): The user of this email will be added to the
    organization if it is known in SCC. (The organization will be evaluated by
    the given token.). Otherwise the user will receive an email that explains
    how to proceed.

###### Curl
```
curl https://scc.suse.com/connect/systems/products -u<username>:<password> -d '{"identifier": "SLES", "version": "11-SP2", "arch": "x86_64", "token": "<token>" }' -H 'Content-Type:application/json'
```

###### Response
```
Status: 200 OK
```

```json
{  
  "id": 42,
  "name": "SUSE_Linux_Enterprise_Server_12_x86_64",
  "url": "https://scc.suse.com/access/services/1106?credentials=SUSE_Linux_Enterprise_Server_12_x86_64",
  "product": {
    "id": 42,
    "name": "SUSE Linux Enterprise Server",
    "identifier": "SUSE_SLES",
    "version": "11",
    "release_type": "GA",
    "release_stage": "released", // or "beta"
    "arch": "x86_64",
    "friendly_name": "SUSE Linux Enterprise Server 11 x86_64",
    "enabled_repositories": [
      1150
    ],
    "product_class": "7261",
    "product_family": "sles",
    "cpe": "cpe:/o:suse:sled-addon:12.0",
    "free": false,
    "description": null,
    "eula_url": "https://nu.novell.com/SUSE:/Products:/SLE-12/images/repo/SLE-12-Server-POOL-x86_64-Media.license/",
    "extensions": [ ],
    "product_type": "base",
    "recommended": false
  }  
}
```

##### Errors:

422: "No product specified"
422: "No token specified"
422: "No valid subscription found"
422: "No repositories found for product"



##### <a id="sys_prod_destroy">Deactivate product</a>
Deactivate a module or extension, freeing a regcode slot on that subscription. The response includes the data for the zypper service for the module or extension to be removed.

```
DELETE /connect/systems/products
```
###### Parameters (Payloads)

  - required:
    - `identifier` ( *String* ): Product name, e.g. `sles-ha`.
    - `version` ( *String* ): Product version e.g. `12`.
    - `arch` ( *String* ): System architecture, e.g. `x86_64`.

###### Curl
```
curl https://scc.suse.com/connect/systems/products -X 'DELETE' -u<username>:<password> -d '{"identifier": "sles-ha", "version": "12", "arch": "x86_64" }' -H 'Content-Type:application/json'
```

###### Response
```
Status: 200 OK
```

```json
{  
  "id": 42,
  "name": "SUSE_Linux_Enterprise_Server_High_Availability_12_x86_64",
  "url": "https://scc.suse.com/access/services/1106?credentials=SUSE_Linux_Enterprise_Server_12_x86_64",
  "product": {
    "id": 42,
    "name": "SUSE Linux Enterprise Server High Availability",
    "identifier": "SUSE_HA",
    "version": "12",
    "release_type": "GA",
    "release_stage": "released", // or "beta"
    "arch": "x86_64",
    "friendly_name": "SUSE Linux Enterprise Server High Availability 12 x86_64",
    "enabled_repositories": [
      1150
    ],
    "product_class": "SLES-HA",
    "product_family": "sles",
    "cpe": "cpe:/o:suse:sles-ha:12.0",
    "free": false,
    "description": null,
    "eula_url": "https://nu.novell.com/SUSE:/Products:/SLE-HA-12/images/repo/SLE-12-HA-POOL-x86_64-Media.license/",
    "extensions": [ ],
    "product_type": "base",
    "recommended": false
  }  
}
```


##### Errors:

422: "Product is a base product and cannot be deactivated"
422: "Dependencies exist on this activation."
422: "Product is not yet activated"



##### <a id="sys_prod_update">Upgrade product</a>
Upgrade a system, for example from SLES12 to SLES12SP1, receiving the service for the new product.  In an upgrade, the existing subscription should entitle the system to use either version of the product, so no registration code is necessary and the server checks that the system is already associated to a subscription covering the requested upgrade, or that the upgrade is to a free product.
```
PUT /connect/systems/products
```
###### Parameters (Payload)

  - required:
    - `identifier` ( *String* ): Product name, e.g. `SLES`.
    - `version` ( *String* ): Product version e.g. `12`.
    - `arch` ( *String* ): System architecture, e.g. `x86_64`.

###### Curl
```
curl https://scc.suse.com/connect/systems/products -X 'PUT' -u<username>:<password> -d '{"identifier": "SLES", "version": "12", "arch": "x86_64" }' -H 'Content-Type:application/json'
```

###### Response
```json
{  
  "id": 42,
  "name": "SUSE_Linux_Enterprise_Server_12_SP1_x86_64",
  "obsoleted_service_name": "SUSE_Linux_Enterprise_Server_12_x86_64",
  "url": "https://scc.suse.com/access/services/1106?credentials=SUSE_Linux_Enterprise_Server_12_x86_64",
  "product": {
    "id": 42,
    "name": "SUSE Linux Enterprise Server",
    "identifier": "SUSE_SLES",
    "version": "11",
    "release_type": "GA",
    "release_stage": "released", // or "beta"
    "arch": "x86_64",
    "friendly_name": "SUSE Linux Enterprise Server 11 x86_64",
    "enabled_repositories": [
      1150
    ],
    "product_class": "7261",
    "product_family": "sles",
    "cpe": "cpe:/o:suse:sled-addon:12.0",
    "free": false,
    "description": null,
    "eula_url": "https://nu.novell.com/SUSE:/Products:/SLE-12/images/repo/SLE-12-Server-POOL-x86_64-Media.license/",
    "extensions": [ ],
    "product_type": "base",
    "recommended": false
  }  
}
```
##### Errors:

422: "No product specified"
422: "No repositories found for product"
422: "No installed product with requested update product found"

##### <a id="update-system">Update system</a>
By given credentials determine the system and update its hardware info and hostname.
```
PUT /connect/systems
```
###### Parameters (Payloads)

  - required:
    - `hostname` ( *String* ): The system's `hostname` can be arbitrary and does
     not have to be unique. It will show up in SCC and serves as a human
     readable identifier to the user.
    - `hwinfo` ( *String* ): Hardware information used to evaluate a
    subscription's potential business requirements (e.g. counting `sockets`) and
    to provide additional help (e.g. vendor specific repositories).

###### Payload
```json
{
  "hostname": "virtual-system.domain.net",
  "hwinfo": {
    "sockets": 2,
    "graphics": "nvidia",
    "UUID": "6A5072A0-311B-430E-8EDE-A8770788B92D"
  }
}
```

###### Curl
```
curl https://scc.suse.com/connect/systems -u '<username>:<password>' -X 'DELETE' -H 'Content-Type:application/json' -d '{"hostname": "testsled2", "hwinfo": {"arch": "x86_64"}}'
```


###### Response
```
Status: 204 No Content
```

##### <a id="deregister-system">Deregister system</a>
By given credentials determine the system and destroy it.
```
DELETE /connect/systems
```
###### Curl
```
curl -u '<username>:<password>' -X 'DELETE' https://scc.suse.com/connect/systems
```

###### Response
```
Status: 204 No Content
```

##### <a>System services</a>

Listing all the services known by system.
TODO: provide proper service definition

```
GET /connect/systems/services
```
###### Curl
```
curl -u '<username>:<password>' https://scc.suse.com/connect/systems/services
```

###### Response
```
Status: 200 OK
```
```json
[
  {
    "id": 237,
    "name": "Base_product_1_12_SP1_s390x",
    "url": "http://Someurl",
    "product": {
      "id": 239,
      "name": "Base product 1",
      "identifier": "sles_base_1",
      "version": "12 SP1",
      "release_type": "GA",
      "release_stage": "released", // or "beta"
      "arch": "s390x",
      "friendly_name": "Base product 1 12 SP1 s390x",
      "product_class": "7260",
      "product_family": "sles",
      "cpe": "cpe:/o:product:4",
      "free": false,
      "description": "Quas atque ratione consequatur labore repellendus perspiciatis assumenda.",
      "eula_url": "https://nu.novell.com/suse/qopjp.license/",
      "enabled_repositories": [ ],
      "extensions": [ ],
      "product_type": "base",
      "recommended": false,
      "repositories": [
        {
          "id": 908,
          "name": "Base product 1 12 SP1-Base",
          "distro_target": "i586",
          "description": "Base product 1 12 SP1-Base for i586",
          "url": "https://nu.novell.com/suse/qopjp",
          "enabled": false,
          "autorefresh": true,
          "installer_updates":false
        },
        {
          "id": 909,
          "name": "Base product 1 12 SP1-Pool",
          "distro_target": "i586",
          "description": "Base product 1 12 SP1-Pool for i586",
          "url": "https://nu.novell.com/suse/qopjp",
          "enabled": false,
          "autorefresh": true,
          "installer_updates":false
        },
        {
          "id": 911,
          "name": "Base product 1 12 SP1-SDK",
          "distro_target": "i586",
          "description": "Base product 1 12 SP1-SDK for i586",
          "url": "https://nu.novell.com/suse/qopjp",
          "enabled": false,
          "autorefresh": true,
          "installer_updates":false
        },
        {
          "id": 910,
          "name": "Base product 1 12 SP1-Updates",
          "distro_target": "i586",
          "description": "Base product 1 12 SP1-Updates for i586",
          "url": "https://nu.novell.com/suse/qopjp",
          "enabled": false,
          "autorefresh": true,
          "installer_updates":false
        }
      ]
    }
  }
]

```

##### List System Online Migrations

Given a list of installed products, return all possible online migration paths.
An "online" migration is one that can be performed without the media being
inserted in the target machine. All new software (RPM packages) will be fetched
by the migration script from the CDN or a repository mirroring tool (SMT or RMT).

A migration path is a list of products.
A system with a set of installed products could be upgraded in different ways.
That is to say, some products must be upgraded, others may optionally be upgraded,
while yet others simply cannot be upgraded.
This endpoint returns all of the possible compatible combinations.

```
POST /connect/systems/products/migrations
```
###### Parameters

- required:
  - `installed_products` (*Array* of *JSON Objects*):
    - `identifier` ( *String* ): Product name, e.g. `SLES`.
    - `version` ( *String* ): Product version e.g. `12`.
    - `arch` ( *String* ): System architecture, e.g. `x86_64`.
    - `release_type` ( optional *String* ): Product release type, e.g. `HP-CNB`

###### Curl
```
curl -X POST -H 'Content-Type:application/json' -u '<username>:<password>' https://scc.suse.com/connect/systems/products/migrations -d'{"installed_products": [{"identifier": "SLES", "version": "12", "arch": "x86_64"}]}'
```

###### Response

```
Status: 200 OK
```

```json
[
  [
    {
      "friendly_name":"SUSE Linux Enterprise Server 12 SP1 x86_64",
      "shortname": "SLES12-SP1",
      "identifier": "SLES",
      "version": "12.1",
      "arch": "x86_64",
      "release_type": null,
      "release_stage": "released", // or "beta"
      "product_type": "base",
      "free": "false"
    },
    {   
      "friendly_name":"SUSE Linux Enterprise Software Development Kit 12 x86_64",
      "shortname": "SLE-SDK12-SP1",
      "identifier": "SLE-SDK",
      "version": "12.1",
      "arch": "x86_64",
      "release_type": null,
      "release_stage": "released", // or "beta"
      "product_type": "extension",
      "free": "true"             
    }
  ]
]
```

**Description:**

- `friendly_name` ( *String* ): Product friendly name, e.g. `SUSE Linux Enterprise Server 12 SP1 x86_64`.
- `identifier` ( *String* ): Product name, e.g. `SLES`.
- `version` ( *String* ): Product version e.g. `12`.
- `arch` ( *String* ): System architecture, e.g. `x86_64`.
- `release_type` ( optional *String* ): Product release type, e.g. `HP-CNB`
- `base` ( *Boolean* ): true for base products and false for extensions
- `product type` ( *String* ): Product type ("base", "extension" or "module")
- `free` ( *Boolean* ): true for free products, false for ones that require their own subscription


##### Errors:
422: "The requested product '%s' is not activated on this system."

##### List System Offline Migrations

Given a list of installed products, return all possible online migration paths.
An "offline" migration is one that requires the target machine to be booted from
the media of the desired product (eg. a system that has SLES 12 SP4 installed
must be booted from the SLES 15 media in order to upgrade it to SLES 15).

```
POST /connect/systems/products/offline_migrations
```

###### Parameters

- Required:
  - `installed_products` (*Array* of *JSON Objects*):
    - `identifier` ( *String* ): Product name, e.g. `SLES`.
    - `version` ( *String* ): Product version e.g. `12`.
    - `arch` ( *String* ): System architecture, e.g. `x86_64`.
    - `release_type` ( optional *String* ): Product release type, e.g. `HP-CNB`
  - `target_base_product` ( *JSON object* )
    - `identifier` ( *String* ): Product name, e.g. `SLES`.
    - `version` ( *String* ): Product version e.g. `12`.
    - `arch` ( *String* ): System architecture, e.g. `x86_64`.
    - `release_type` ( optional *String* ): Product release type, e.g. `HP-CNB`

###### Response

See the response for the [online migrations endpoint](#list-system-online-migrations).
The only difference is that the `target_base_product` parameter allows the possible migration paths
to be filtered to show only those that have `target_base_product` as a base.

##### Errors:
422: "The requested product '%s' is not activated on this system."
422: "The requested upgrade product '%s' is not an upgrade from the installed product."

##### <a id="system_synchronize_products">Synchronize system products</a>
Synchronize activated system products to the registration server.
This will remove obsolete activations on the server after all installed products
have gone through a downgrade().
Returns activated products from the server.

```
POST /connect/systems/products/synchronize
```
###### Parameters
  - required:
    - `products` (*Array* of *JSON Objects*):
      - `identifier` ( *String* ): Product name, e.g. `SLES`.
      - `version` ( *String* ): Product version e.g. `12`.
      - `arch` ( *String* ): System architecture, e.g. `x86_64`.

###### Curl
```
curl -X POST -H 'Content-Type:application/json' -u '<username>:<password>' https://scc.suse.com/connect/systems/products/synchronize -d'{"products": [{"identifier": "SLES", "version": "12", "arch": "x86_64"}]}'
```

###### Response
```
Status: 200 OK
```

```json
[{
  "id": 42,
  "name": "SUSE Linux Enterprise Server",
  "identifier": "SUSE_SLES",
  "version": "11",
  "release_type": "GA",
  "release_stage": "released", // or "beta"
  "arch": "x86_64",
  "friendly_name": "SUSE Linux Enterprise Server 11 x86_64",
  "enabled_repositories": [1150],
  "product_class": "7261",
  "product_family": "sles",
  "cpe": "cpe:/o:suse:sled-addon:12.0",
  "free": false,
  "product_type": "base",
  "recommended": false,
  "description": null,
  "eula_url": "https://nu.novell.com/SUSE:/Products:/SLE-12/images/repo/SLE-12-Server-POOL-x86_64-Media.license/",
  "extensions": [
    { }, { }, ...
      ]
    }
  ],
  "repositories": [     
    {
      "id": 1357,
      "name": "SLE10-SDK-SP4-Online",
      "distro_target": "sles-10-x86_64",
      "description": "SLE10-SDK-SP4-Online for sles-10-x86_64",
      "url": "https://nu.novell.com/repo/$RCE/SLE10-SDK-SP4-Online/sles-10-x86_64",
      "autorefresh": true,
      "installer_updates":false
    }
  ]
}, { } ...
]
```


##### <a>System subscriptions</a>

Listing all the subscriptions known by system.


```
GET /connect/systems/subscriptions
```

###### Curl
```
curl -u '<username>:<password>' https://scc.suse.com/connect/systems/subscriptions
```

###### Response
```
Status: 200 OK
```
```json
[
  {
    "id": 112,
    "regcode": "35098ff7",
    "name": "Subscription 2",
    "type": null,
    "status": "NOTACTIVATED",
    "starts_at": "2014-05-14T09:13:26.589Z",
    "expires_at": null,
    "system_limit": 15,
    "systems_count": 1,
    "virtual_count": null,
    "product_classes": ["7260"],
    "families": ["sles", "sled"],
    "systems": [{ "id": 117, "login": "login2", "password": "password2" }],
    "product_ids": [239, 238, 240]
  }
]


```

##### <a>System Activations</a>

Activation is created when system activates a product. Therefore, each activated product would have activation. System can have
many activations.

Activation entity inlcudes following information from subscription used:

  - `regcode` (*String*)
  - `type` (*String*)
  - `starts_at` (*String*)
  - `expires_at` (*String*)

Additionally holds info about service, hence product.

```
GET /connect/systems/activations
```

###### Curl
```
curl -u '<username>:<password>' https://scc.suse.com/connect/systems/activations
```

###### Response
```
Status: 200 OK
```
```json
[
  {
    "id": 42,
    "regcode": null,
    "type": null,
    "status": null,
    "starts_at": null,
    "expires_at": null,
    "system_id": 4252,
    "service": {
      "id": 1722,
      "name": "Web_and_Scripting_Module_12_x86_64",
      "url": "Web_and_Scripting_Module_12_x86_64",
      "product": {
        "id": 1153,
        "name": "Web and Scripting Module",
        "identifier": "sle-module-web-scripting",
        "former_identifier": "sle-module-web-scripting",
        "version": "12",
        "release_type": null,
        "release_stage": "released", // or "beta"
        "arch": "x86_64",
        "friendly_name": "Web and Scripting Module 12 x86_64",
        "product_class": null,
        "product_family": "sles",
        "cpe": "cpe:/o:suse:sle-module-web-scripting:12.0",
        "free": true,
        "description": "The SUSE Linux Enterprise Web and Scripting Module delivers a comprehensive suite of scripting languages, frameworks, and related tools helping developers and systems administrators accelerate the creation of stable, modern web applications, including: PHP, Ruby on Rails, Python version 3. Access to the Web and Scripting Module is included in your SUSE Linux Enterprise Server subscription. The module has a different lifecycle than SUSE Linux Enterprise Server itself; please check the Release Notes for further details.",
        "eula_url": "SLE-12-module-web-scripting-POOL-x86_64-Media1.license",
        "enabled_repositories": [1494],
        "product_type": "module",
        "recommended": false,
        "repositories": [
          {
            "id": 1494,
            "name": "SLE-MODULE-WEB-SCRIPTING12-Pool",
            "distro_target": "sle-12-x86_64",
            "description": "SLE-MODULE-WEB-SCRIPTING12-Pool for sle-12-x86_64",
            "url": "SLE-12-module-web-scripting-POOL-x86_64-Media1",
            "enabled": true,
            "autorefresh": false,
            "installer_updates":false
          }
        ]
      }
    }
  },
  {
    "id": 124232,
    "regcode": "Babboom",
    "type": "evaluation",
    "status": "ACTIVE",
    "starts_at": "2012-07-21T00:00:00.000Z",
    "expires_at": "2015-12-31T00:00:00.000Z",
    "system_id": 34242,
    "service": {
      "id": 1106,
      "name": "SUSE_Linux_Enterprise_Server_12_x86_64",
      "url": "SUSE_Linux_Enterprise_Server_12_x86_64",
      "product": {
        "id": 42,
        "identifier": "SLES",
        "former_identifier": "SLES",
        "version": "11",
        "release_type": "GA",
        "release_stage": "released", // or "beta"
        "arch": "x86_64",
        "friendly_name": "SUSE Linux Enterprise Server 11 x86_64",
        "product_class": "7261",
        "product_family": "sles",
        "repos": [
          {
            "id": 1150,
            "name": "SLES11-Pool",
            "distro_target": "sle-11-x86_64",
            "description": "dummy description [WIP]",
            "url": "SLE-SERVER/11-POOL"
          }
        ]
      }
    }
  }
]

```

***

### Public
All endpoints on this level do not require authentication. They are
publicly available. Of course, that means that only publicly available resources
will be listed.

#### Installer-Updates repositories

Returns an array of Installer-Updates repositories for the given product.

```
GET /connect/repositories/installer
```
###### Parameters (Payloads)

  - required parameters:
    - `identifier` ( *String* ): Product name, e.g. `SLES`.
    - `version` ( *String* ): Product version e.g. `12`, `11-3`
    - `arch` ( *String* ): System architecture, e.g. `x86_64`.
  - optional parameter:
    - `release_type` ( *String* ): Release type, e.q `GA`

###### Curl
```
curl "https://scc.suse.com/connect/repositories/installer?identifier=SLES&version=12.2&arch=x86_64"
```

###### Response
```
Status: 200 OK
```

```json
[
  {
    "id":2101,
    "name":"SLES12-SP2-Installer-Updates",
    "distro_target":"sle-12-x86_64",
    "description":"SLES12-SP2-Installer-Updates for sle-12-x86_64",
    "url":"https://updates.suse.com/SUSE/Updates/SLE-SERVER-INSTALLER/12-SP2/x86_64/update/",
    "enabled":false,
    "autorefresh":true,
    "installer_updates":true
  }
]
```

#### Packages search

Returns an array of products which repositories contain specified package.

_Currently does not support pagination._

```
GET /api/products/search_packages
```
###### Parameters (Payloads)

  - required parameters:
    - `package_name` ( *String* ): Package name, e.g. `vim`.

###### Curl
```
curl "https://scc.suse.com/api/products/search_packages?package_name=vim"
```

###### Response
```
Status: 200 OK
```

```json
[
  {
    "id":1357,
    "friendly_name":"SUSE Linux Enterprise Server 12 SP2 x86_64",
    "arch":"x86_64",
    "packages":
      [
        {"name":"vim","version":"7.4.326","release":"2.62","arch":"x86_64","repo":"SLES12-SP2-Pool"},
        {"name":"vim","version":"7.4.326","release":"7.1","arch":"x86_64","repo":"SLES12-SP2-Updates"}
      ]
  }
]
```
