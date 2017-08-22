See [migration.rb](../../master/lib/suse/connect/migration.rb) for more details.

## Implemented methods

- [system products](#system-products)
- [rollback](#rollback)
- [add service](#add-service)
- [remove service](#remove-service)
- [enable repository](#enable-repository)
- [disable repository](#disable-repository)
- [list repositories](#repositories)
- [find products](#find_products)
- [install release package](#install_release_package)

### <a name="system-products">System products</a>
#### system_products(client_params = {})
        # Returns installed and activated products on the system
        # @param [Hash] client_params parameters to instantiate {Client}
        # @return [Array <OpenStruct>] the list of system products

### <a name="rollback">Restores a state of the system before migration/uprade</a>
#### rollback(client_params = {})

### <a name="add-service">Add service</a>
#### add_service(service_url, service_name)
        # Forwards the service which should be added with zypper
        # @param [String] service_url the url from the service to add
        # @param [String] service_name the name of the service to add


### <a name="remove-service">Remove service</a>
#### remove_service(service_name)
        # Forwards the service names which should be removed with zypper
        # @param [String] service_name the name of the service to remove


### <a name="enable-repository">Enable Repository</a>
#### enable_repository(repository_name)
        # Forwards the repository which should be enabled with zypper
        # @param [String] repository name to enable

### <a name="disable-repository">Disable Repository</a>
#### disable_repository(repository_name)
        # Forwards the repository which should be disabled with zypper
        # @param [String] repository name to disable


### <a name="repositories">List zypper repositories</a>
#### repositories
        # Returns the list of available repositories
        # @return [Array <OpenStruct>] the list of zypper repositories

### <a name="find_products">Find products</a>
#### find_products(identifier)
        # Finds the solvable products available on the system
        # @param [String] identifier e.g. SLES
        # @return [Array <OpenStruct>] the list of solvable products available on the system


### <a name="install_release_package">Install release package</a>
#### def install_release_package(identifier)
        # Installs the product release package
        # @param [String] identifier e.g. SLES
        

