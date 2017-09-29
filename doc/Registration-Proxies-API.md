## Scope

This documents describes the details of the `/connect/organizations/systems` API endpoint,
which is used by **Registration Proxies** (namely **SMT** and **SUSE Manager**) to provide the information about systems they manage to the **Suse Customer Center** interface.
See [[SCC-API-(Implemented)]] for the full API specification.

## Creating or updating systems

As SMT servers *may not* distinguish between freshly-created and updated systems under their management, SCC API endpoint *should* treat those two situations equally (and we use verbs *create* and *update* interchangeably in this section).

To submit a system to the SCC, Registration Proxy *must* use a **POST** HTTP request to the `/connect/organizations/systems` endpoint. The request's payload *must* contain a JSON object that *should* correspond a single system.

System representation object *must* contain all the following keys:

- `"login"` — string
- `"password"` — string

System representation object *should* also contain the following keys:

- `"hostname"` — string, the system's hostname as reported to the Registration Proxy by connect (also *may* be a FQDN or an IP address; API *must* handle those cases in the same way)
- `"hwinfo"` — JSON object, as reported to the Registration Proxy by connect
- `"products"` — array of activated products data for this system
- `"regcodes"` — array of regcodes (strings) this system has been associated with during its activation

#### `"products"`

`"products"` value *must* be an array of JSON objects. Those objects *should* contain the `"id"` key. This key *must* be an integer representing the product's id in the SCC database, as it is reported by SCC API.

This object *should* also contain the following keys:

- `"identifier"` — string, human-readable name of the product
- `"version"` — string, human-readable version of the product
- `"arch"` — string, architecture of the product

And also *may* contain `"release_type"` key, string (*may* be an empty one), which indicates the special build of a product.

Those recommended and optional keys *should* not be used in the API, and are intended for the debugging purposes.

#### `"hwinfo"`

`"hwinfo"` value *must* be a JSON object. That object *may* contain any of the following keys:

- `"uuid"` — string, RFC-formatted UUID of the host (typically obtained from system's `dmidecode` output)
- `"cpus"` — integer, number of CPUs in the system
- `"sockets"` — integer, number of CPU sockets in the system
- `"arch"` — string, architecture of the installed SUSE Linux
- `"hypervisor"` — string, type of hypervisor which is used to run this virtual system (it *must* be set to the `null` <u>JSON value</u> to indicate a physical system)

#### Example request payload

```json
{
  "hostname": "starsky",
  "login": "dave_starsky",
  "password": "Purplemonkeys",
  "hwinfo": {
    "uuid": "ef2f2f2c-864a-40e5-b49b-f79ed3912805",
    "cpus": 2,
    "sockets": 4,
    "arch": "s390x",
    "hypervisor": null
  },
  "products": [
    {
      "id": 668,
      "identifier": "SUSE-Linux-Enterprise-Server",
      "version": "10",
      "arch": "s390x",
      "release_type": "HP_SPECIAL_BUILD"
    }, {
      "id": 1224,
      "identifier": "SUSE-Linux-Enterprise-SDK",
      "version": "10",
      "arch": "s390x"
    }
  ],
  "regcodes": [
    "DEAD4168BEEF",
    "BULLS4903EYE"
  ]
}
```

### Response

When system is created correctly, SCC *should* respond with a **201: Created** header and a body containing a valid JSON object with the created system's data, which *must* be `id`, `login` and `password`.

#### Example successful response

```json
{
  "id": 1337,
  "login": "bill",
  "password": "53cr37"
}
```

## Deleting systems

To delete Registration Proxy-managed systems from SCC, clients can submit a **DELETE** request to the `/connect/organizations/systems/:id` API endpoint. This request *should* not contain a body. The `:id` parameter *must* be its internal SCC `id` (ie. the `id` returned when creating the system was created).

When a system is successfully deleted, SCC *should* respond with a **204: No Content** and no body. If a system is not found, SCC *should* respond with a **404: Not found** header.