@slow_process
Feature: SUSEConnect full stack integration testing
  In order to deliver the best possible quality of SUSEConnect package we have to do a full stack integration testing
  This means we have to register a test machine against production server and examine all relevant data

  Scenario: Successful system registration
    When I call SUSEConnect with '--regcode VALID' arguments
    Then the exit status should be 0

    And SUSEConnect should create the 'SCCcredentials' file
    And 'SCCcredentials' file should contain 'SCC' prefixed system guid
    And SUSEConnect should create the 'service credentials' file

    And 'Service credentials' file should contain 'SCC' prefixed system guid

    Then SUSEConnect should add a new zypper service for base product
    And SUSEConnect should add a new repositories for base product

  Scenario: API response language check
    When I call SUSEConnect with '--regcode INVALID --language de' arguments
    Then the exit status should be 67

    And the output should contain "Keine Subscription mit diesem Registrierungscode gefunden"

  Scenario: Extension activation with regcode
    When I call SUSEConnect with '--regcode VALID --product sle-sdk/12/x86_64' arguments
    Then the exit status should be 0

    And SUSEConnect should create the 'SUSE_Linux_Enterprise_Software_Development_Kit_12_x86_64' file
    And 'SUSE_Linux_Enterprise_Software_Development_Kit_12_x86_64' file should contain 'SCC' prefixed system guid

  # SUSE::Connect library checks
  Scenario: API version check
    When SUSEConnect library should respect API headers
