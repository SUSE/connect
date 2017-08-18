<a id="home"></a>
This page lists API calls that are currently in planning. 
The available API is documented [here](https://github.com/SUSE/connect/wiki/SCC-API-(Implemented))

  - [Organizations](#organizations)
    - [show organization](#org_show)
    - [manage systems](#manage-systems)
    - [list services](#org_service_list)
    - [forward registration](#forward-registration)
  - [Subscriptions](#subscriptions)
    - [show subscription](#sub_show)
    - [list systems](#sub_sys_list)
    - [remove system](#sub_sys_destroy)
    - [list products](#sub_prod_list)
    - [list services](#sub_service_list)
    - [list repositories](#sub_repo_list)
  - [Systems](#systems)
    - [show system](#sys_show)
    - [list products](#sys_prod_list)
    - [list repositories](#sys_repo_list)
  - [Public](#public)
    - [list products](#prod_list)
    - [list services](#service_list)
    - [list repositories](#repo_list)

***
***

### <a id="organizations">Organizations</a>
[^^](#home)
***

##### <a id="org_show">Show Organization</a>
Shows the organization's details. This includes attributes and ID. Additionally,
a list of all subscriptions, systems, products, and repositories for this
organization.
```
GET /connect/organizations
```
[^](#organizations)
***

##### Manage systems

The `/connect/organizations/systems` API endpoint also supports announcing,
updating and deleting systems behind Registration Proxies.

Please see the [[Registration Proxies API]] wiki page for detailed specs of that API.

[^](#organizations)
***

##### <a id="org_service_list">List Services</a>
List all services for the organization.
```
GET /connect/organizations/services
```
###### Parameters
  - optional:
    - `product_id` ( *Integer* ): Product ID.

[^](#organizations)
***

##### <a id="org_fwd_registration">Forward Registration</a>
Use case - SMT forwards registered via it registrations.

```
POST /connect/organizations/subscriptions
```

###### Parameters
  - required:
    - `product_id`  ( *Integer*): Product ID.
    - `system_guid` ( *String* ): GUID of system supposed to be registered
    - `proxy_guid`  ( *String* ): GUID of system acting as registration proxy (SMT/SUSE Manager)
  - optional:
    - `hwinfo` ( *Object* ): System hardware information

###### Response: 
The response will contain system just registered. This call will consume one subscriptions.

```
Status: 201 OK
```
```json
{
  "id": 15,
  "hostname": "host.localdomain.local",
  "login": "loginlogin",
  "hwinfo": {"cpu_type": "x86_64", "platform_type": "x86_64"}
}

```

[^](#organizations)
***
***


### <a id="subscriptions">Subscriptions</a>
[^^](#home)
***

##### <a id="sub_show">Show Subscription</a>
Show subscription details. This includes a list of all systems, products, and
repositories.
```
GET /connect/subscriptions
```
[^](#subscriptions)
***

##### <a id="sub_sys_list">List Systems</a>
List all systems for the subscription. This includes a list of all products and
repositories for each system.
```
GET /connect/subscriptions/systems
```
[^](#subscriptions)
***

##### <a id="sub_sys_destroy">Remove System</a>
Remove a system from the associated subscription.
```
DELETE /connect/subscriptions/systems
```
###### Parameters
  - required:
    - `system_id` ( *Integer* ): System ID.

[^](#subscriptions)
***

##### <a id="sub_prod_list">List Products</a>
List all Products for the subscription. This includes a list of all repositories
for each product.
```
GET /connect/subscriptions/products
```
###### Parameters
  - optional:
    - `type` ( *String* ): Type of product. Valid values: `add-on`, `base`.

[^](#subscriptions)
***

##### <a id="sub_service_list">List Services</a>
List all services for the subscription.
```
GET /connect/subscriptions/services
```
###### Parameters
  - optional:
    - `product_id` ( *Integer* ): Product ID.

[^](#subscriptions)
***


##### <a id="sub_repo_list">List Repositories</a>
List all repositories for the subscription.
```
GET /connect/subscriptions/repos
```
###### Parameters
  - optional:
    - `product_id` ( *Integer* ): Product ID.

[^](#subscriptions)
***
***


### <a id="systems">Systems</a>
[^^](#home)
***

##### <a id="sys_show">Show System</a>
Show system details. This includes a list of all products and repositories.
```
GET /connect/systems
```

###### Response
```
Status: 200 OK
```
```json
[
  {
    "identifier": "a1b2c3d4e5f6g7h8",
    "name": "virtual-system.domain.net",
    "parent": "physical-host.domain.net",
    "hardware": {
      "sockets": 2,
      "graphics": "nvidia"
    },
    "products": [
      {
        "product_id": 42,
        "name": "SUSE_SLES",
        "type": "base",
        "editions": [
          {
            "version": "12.1",
            "arch": "i686",
            "repos": [
              {
                "name": "SLE12-SP1-Pool",
                "archs": [
                  "x86_64"
                ],
                "url": "https://download.suse.com/repo/SLE12-SP1-Pool/sles-12-x86_64",
                "target distribution": "sles-12-x86_64",
                "tags": [
                  "enabled",
                  "autorefresh"
                ]
              }
            ]
          }
        ]
      }
    ]
  }
]
```
[^](#systems)
***

##### <a id="sys_prod_list">List Products</a>
List all products for the system. This includes a list of all repositories
for each product.
```
GET /connect/systems/products
```
###### Parameters
  - optional:
    - `product_id` ( *String* ): Zypper CPE product identifier
    - `type` ( *String* ): Type of product. Valid values: `extension`, `base`. [Not implemented]

###### Response
```
Status: 200 OK
```
```json
[

    {
        "id": 293,
        "name": "Extension",
        "created_at": "2014-03-07T12:55:54.829Z",
        "updated_at": "2014-03-07T12:55:54.829Z",
        "productdataid": 77238,
        "nnw_product_data": "ab12cdff6532",
        "edition_id": 37,
        "architecture_id": 12,
        "zypper_name": "Zypper Product Name 1",
        "release_type": null
    }

]
```
[^](#systems)
***


##### <a id="sys_service_list">List Services</a>
List all services for the system.
```
GET /connect/systems/services
```
###### Parameters
  - optional:
    - `product_id` ( *Integer* ): Product ID.

###### Response
```
Status: 200 OK
```
```json
[
  {
    "repositories": [
                      {
                      "name": "SLE12-SP1-Pool",
                      "archs": [
                        "x86_64"
                       ],
                      "url": "https://download.suse.com/repo/SLE12-SP1-Pool/sles-12-x86_64",
                      "target distribution": "sles-12-x86_64",
                      "tags": [
                        "enabled",
                        "autorefresh"
                      ]
                     },
                    ...
                    ]
  }
]
```
[^](#systems)
***


##### <a id="sys_repo_list">List Repositories</a>
List all repositories for the system.
```
GET /connect/systems/repos
```
###### Parameters
  - optional:
    - `product_id` ( *Integer* ): Product ID.

###### Response
```
Status: 200 OK
```
```json
[
  {
    "name": "SLE12-SP1-Pool",
    "archs": [
      "x86_64"
     ],
    "url": "https://download.suse.com/repo/SLE12-SP1-Pool/sles-12-x86_64",
    "target distribution": "sles-12-x86_64",
    "tags": [
      "enabled",
      "autorefresh"
    ]
  }
]
```
[^](#systems)
***
***


### <a id="public">Public</a>
For all endpoints on this level there is no authentication needed. They are
publicly available. Of course, that means that only publicly available resources
will be listed.

The typical use case for these calls is the
[SLE installer](Requirement-Connect#installer).

  - [list products](#prod_list)
  - [list services](#service_list)
  - [list repositories](#repo_list)

[^^](#home)
***


##### <a id="prod_list">List Products</a>
Implemented and [moved](https://github.com/SUSE/connect/wiki/SCC-API-(Implemented)#wiki-prod_list)

[^](#public)
***

##### <a id="service_list">List Services</a>
List all publicly available services.
```
GET /connect/services
```
###### Parameters
  - optional:
    - `product_id` ( *Integer* ): Product ID.

[^](#public)
***
