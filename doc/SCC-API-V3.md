**This is the documentation for version 3 of the API. Please check the docs of the [latest version](SCC-API-(Implemented).md)!**

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

```Accept: application/vnd.scc.suse.com.v3+json```

The current API version is 3.
Hint: to get knowledge, with what version SCC just respond - take a look at respond header `scc-api-version`
e.g. following clearly indicates that SCC responded with version 3 of API

```
scc-api-version: v3
```


## Localized response:

To receive translated messages, set the HTTP Accept-Language header to the user's preferred language(s),
comma-separated list if multiple.

```Accept-Language: DE```

## Request compressed data:

If you want to minimize bandwith usage - it is possible to request compressed representation of data.
E.g. for `https://scc.suse.com/connect/organizations/products` endpoint you can get only 5% of data
5 769 626 bytes uncomressed and 269 268 compressed.
For using that technic - just add `-H "Accept-Encoding: gzip, deflate"` to you request headers, so the
Curl example would be:

```
curl -H "Accept-Encoding: gzip, deflate" -u"<login>:<password>" https://scc.suse.com/connect/organizations/products | zcat
```
    

```Accept-Language: DE```

## ToC: 

  - [Organizations](#organizations)
    - [list products](#list-of-products-available-for-organization)
    - [list repositories](#list-of-repositories-available-for-organization)
    - [list subscriptions](#list-of-subscriptions-available-for-organization)
    - [list systems](#list-of-systems-known-by-organization)
    - [show system](#show-system-of-organization)
    - [destroy system](#destroy-system-of-organization)
    - [create system](#create-system-for-organization)
  - [Subscriptions](#subscriptions)
    - [announce system](#announce-system)
  - [Systems](#systems)
    - [product](#product)
    - [activate product](#activate-product)
    - [upgrade product](#upgrade-product)
    - [update system](#update-system)
    - [deregister system](#deregister-system)
    - [services](#system-services)
    - [subscriptions](#system-subscriptions)
    - [activations](#system-activations)
  - [Public](#public)

***
***

### <a id="organizations">Organizations</a>
For all endpoints on this level of the organization credentials are used (basic auth)
where webcompanyid is an username and credentials is the password.
All calls will return the list of resources as they are available through the
scope of the specified organization.

  - [list products](#list-of-products-available-for-organization)
  - [list repositories](#list-of-repositories-available-for-organization)
  - [list subscriptions](#list-of-subscriptions-available-for-organization)
  - [list systems](#list-of-systems-known-by-organization)
  - [show system](#show-system-of-organization)
  - [destroy system](#destroy-system-of-organization)
  - [create system](#create-system-for-organization)
 
##### <a id="list-of-products-available-for-organization">List of Products available for organization</a>
List all available products. This includes a list of all repositories
for each product.
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
    "id": 42,
    "name": "SUSE Linux Enterprise Server","name": "SUSE Linux Enterprise Server",
    "identifier": "SLES",
    "former_identifier": "SUSE_SLES",
    "version": "11",
    "release_type": "GA",
    "arch": "x86_64",
    "friendly_name": "SUSE Linux Enterprise Server 11 x86_64",
    "enabled_repositories": [1150],
    "product_class": "7261",
    "product_family": "sles",
    "cpe": "cpe:/o:suse:sled-addon:12.0",
    "free": false,
    "description": null,
    "eula_url": "https://nu.novell.com/SUSE:/Products:/SLE-12/images/repo/SLE-12-Server-POOL-x86_64-Media.license/",
    "extensions": [
      {
        "id": 1145,
        "name": "SUSE Linux Enterprise Server",
        "identifier": "sle-sdk",
        "former_identifier": "sle-sdk",
        "version": "12",
        "release_type": null,
        "arch": "ppc64le",
        "friendly_name": "SUSE Linux Enterprise Software Development Kit 12 ppc64le",
        "enabled_repositories": [1364, 1229],
        "product_class": null,
        "product_family": "sles",
        "cpe": "cpe:/o:suse:sle-sdk:12.0",
        "free": true,
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
            "autorefresh": true
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
        "autorefresh": true
      }
    ]
}
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
    "autorefresh": true
  }
]
```

***

##### <a >List of Systems known by organization</a>
By given credentials determine the organization of interest and output all systems for that organization. 

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

##### <a >Create System for Organization</a>
By given credentials determine the organization of interest and consume subscription and create system by given parameters. 

```
POST /connect/organizations/systems
```

###### Curl
```
curl -u '<webcompanyid>:<credentials>' -X 'POST' https://scc.suse.com/connect/organizations/systems
```

###### Parameters
  - required
    - system
      - login `login which should be assigned to the system`
      - password `password which should be assigned to the system`
      - registration_proxy_uuid `uuid of the system forwarded registration`
    - product
     - identifier `zypper name (Internal Name) of product`
     - version `zypper version of product`
     - release_type `release type e.g. GA`
     - arch `arch of the product required`

###### Response
The response will contain system object.

```
Status: 202 Accepted
```

***

##### <a >Destroy System of Organization</a>
By given credentials determine the organization of interest and destroy requested system by id.

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

[^^](#home)
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
    - `hwinfo` ( *String* ): Hardware information used to evaluate a
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
    "sockets": 2,
    "graphics": "nvidia",
    "UUID": "6A5072A0-311B-430E-8EDE-A8770788B92D" 
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
- [upgrade product](#upgrade-product)
- [update system](#update-system)
- [deregister system](#deregister-system)
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
curl https://scc.suse.com/connect/systems/products -u<username>:<password> -d identifier=SLES -d version=11-SP2 -d arch=x86_64
```

###### Response:
```json
{
  "id": 42,
  "name": "SUSE Linux Enterprise Server",
  "identifier": "SUSE_SLES",
  "version": "11",
  "release_type": "GA",
  "arch": "x86_64",
  "friendly_name": "SUSE Linux Enterprise Server 11 x86_64",
  "enabled_repositories": [1150],
  "product_class": "7261",
  "product_family": "sles",
  "cpe": "cpe:/o:suse:sled-addon:12.0",
  "free": false,
  "product_type: '',
  "description": null,
  "eula_url": "https://nu.novell.com/SUSE:/Products:/SLE-12/images/repo/SLE-12-Server-POOL-x86_64-Media.license/",
  "extensions": [
    {
      "id": 1145,
      "name": "SUSE Linux Enterprise Server",
      "identifier": "sle-sdk",
      "version": "12",
      "release_type": null,
      "arch": "ppc64le",
      "friendly_name": "SUSE Linux Enterprise Software Development Kit 12 ppc64le",
      "enabled_repositories": [1364, 1229],
      "product_class": null,
      "cpe": "cpe:/o:suse:sle-sdk:12.0",
      "free": true,
      "product_type: 'extension',
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
          "autorefresh": true
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
      "autorefresh": true
    }
  ]
}
```

product_type can be '' (for base products), 'module', or 'extension'

##### Errors:
422: "No product specified"
422: 'The requested product is not activated on this system.'


##### <a id="sys_prod_create">Activate product</a>
Activate a product and receive the service, consuming a regcode.

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
    "extensions": [ ]
  }  
}
```

##### Errors:

422: "No product specified"
422: "No token specified"
422: "No valid subscription found"
422: "No repositories found for product"


##### <a id="sys_prod_update">Upgrade product</a>
Upgrade a system, for example from SLES11 to SLES12, receiving the service for the new product.  In an upgrade, the existing subscription should entitle the system to use either version of the product, so no registration code is necessary and the server checks that the system is already associated to a subscription covering the requested upgrade, or that the upgrade is to a free product.
```
PUT /connect/systems/products
```
###### Parameters (Payloads)

  - required:
    - `identifier` ( *String* ): Product name, e.g. `SLES`.
    - `version` ( *String* ): Product version e.g. `12`.
    - `arch` ( *String* ): System architecture, e.g. `x86_64`.

###### Curl
```
curl https://scc.suse.com/connect/systems/products -X 'PUT' -u<username>:<password> -d '{"identifier": "SLES", "version": "12", "arch": "x86_64" }' -H 'Content-Type:application/json'
```

###### Response

See response of 'activate' call. 

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
      "repositories": [
        {
          "id": 908,
          "name": "Base product 1 12 SP1-Base",
          "distro_target": "i586",
          "description": "Base product 1 12 SP1-Base for i586",
          "url": "https://nu.novell.com/suse/qopjp",
          "enabled": false,
          "autorefresh": true
        },
        {
          "id": 909,
          "name": "Base product 1 12 SP1-Pool",
          "distro_target": "i586",
          "description": "Base product 1 12 SP1-Pool for i586",
          "url": "https://nu.novell.com/suse/qopjp",
          "enabled": false,
          "autorefresh": true
        },
        {
          "id": 911,
          "name": "Base product 1 12 SP1-SDK",
          "distro_target": "i586",
          "description": "Base product 1 12 SP1-SDK for i586",
          "url": "https://nu.novell.com/suse/qopjp",
          "enabled": false,
          "autorefresh": true
        },
        {
          "id": 910,
          "name": "Base product 1 12 SP1-Updates",
          "distro_target": "i586",
          "description": "Base product 1 12 SP1-Updates for i586",
          "url": "https://nu.novell.com/suse/qopjp",
          "enabled": false,
          "autorefresh": true
        }
      ]
    }
  }
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
        "arch": "x86_64",
        "friendly_name": "Web and Scripting Module 12 x86_64",
        "product_class": null,
        "product_family": "sles",
        "cpe": "cpe:/o:suse:sle-module-web-scripting:12.0",
        "free": true,
        "description": "The SUSE Linux Enterprise Web and Scripting Module delivers a comprehensive suite of scripting languages, frameworks, and related tools helping developers and systems administrators accelerate the creation of stable, modern web applications, including: PHP, Ruby on Rails, Python version 3. Access to the Web and Scripting Module is included in your SUSE Linux Enterprise Server subscription. The module has a different lifecycle than SUSE Linux Enterprise Server itself; please check the Release Notes for further details.",
        "eula_url": "SLE-12-module-web-scripting-POOL-x86_64-Media1.license",
        "enabled_repositories": [1494],
        "repositories": [
          {
            "id": 1494,
            "name": "SLE-MODULE-WEB-SCRIPTING12-Pool",
            "distro_target": "sle-12-x86_64",
            "description": "SLE-MODULE-WEB-SCRIPTING12-Pool for sle-12-x86_64",
            "url": "SLE-12-module-web-scripting-POOL-x86_64-Media1",
            "enabled": true,
            "autorefresh": false
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
            "url": SLE-SERVER/11-POOL"
          }
        ]
      }
    }
  }
]

```

***

### <a id="public">Public</a>
For all endpoints on this level there is no authentication needed. They are
publicly available. Of course, that means that only publicly available resources
will be listed. 

Currently the SCC API has no publicly available endpoints. 
