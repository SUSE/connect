@slow_process
Feature: SUSEConnect full stack integration testing
  In order to deliver the best possible quality of SUSEConnect package we have to do a full stack integration testing
  This means we have to register a test machine against production server and examine all relevant data

  ### Temporary addition for ease of testing
  @libzypplocked
  Scenario: libzypp locked should exit with 7
    When I call SUSEConnect with '--regcode VALID' arguments
    Then the exit status should be 7

  ### SUSEConnect cmd checks ###
  Scenario: System registration
    When I call SUSEConnect with '--regcode VALID' arguments
    Then the exit status should be 0

    And a file named "/etc/zypp/credentials.d/SCCcredentials" should exist
    And the file "/etc/zypp/credentials.d/SCCcredentials" should contain "SCC_"

    And a file named "/etc/zypp/credentials.d/SUSE_Linux_Enterprise_Server_12_x86_64" should exist
    And the file "/etc/zypp/credentials.d/SUSE_Linux_Enterprise_Server_12_x86_64" should contain "SCC_"

    And zypper should contain a service for base product
    And zypper should contain a repositories for base product

  Scenario: Extension activation with regcode
    When I call SUSEConnect with '--regcode VALID --product sle-sdk/12/x86_64' arguments
    Then the exit status should be 0

    And a file named "/etc/zypp/credentials.d/SUSE_Linux_Enterprise_Software_Development_Kit_12_x86_64" should exist
    And the file "/etc/zypp/credentials.d/SUSE_Linux_Enterprise_Software_Development_Kit_12_x86_64" should contain "SCC_"

    And zypper should contain a service for sdk product
    And zypper should contain a repositories for sdk product

  Scenario: API response language check
    Given I set the environment variables to
      | variable | value |
      | LANG     | de    |
    When I call SUSEConnect with '--regcode INVALID' arguments
    Then the exit status should be 67

    And the output should contain "Keine Subscription mit diesem Registrierungscode gefunden"

  ### SUSE::Connect library checks ###
  Scenario: Free extension activation
    When SUSEConnect library should be able to activate a free extension without regcode
    Then zypper should contain a service for wsm product
    And zypper should contain a repositories for wsm product

  Scenario: Product information (extensions)
    When SUSEConnect library should be able to retrieve the product information

  Scenario: API version check
    When SUSEConnect library should respect API headers

  # De-register the system at the end of the feature
  Scenario: System de-registration
    When SUSEConnect library should be able to de-register the system
    Then a file named "/etc/zypp/credentials.d/SCCcredentials" should not exist

