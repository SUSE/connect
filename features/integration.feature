@slow_process
Feature: SUSEConnect full stack integration testing
  In order to deliver the best possible quality of SUSEConnect package we have to do a full stack integration testing
  This means we have to register a test machine against production server and examine all relevant data

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

  Scenario: System de-registration
    When I cleanly deregister the system removing local credentials
    Then a file named "/etc/zypp/credentials.d/SCCcredentials" should not exist

    And a file named "/etc/zypp/credentials.d/SUSE_Linux_Enterprise_Server_12_x86_64" should not exist
    And a file named "/etc/zypp/credentials.d/SUSE_Linux_Enterprise_Software_Development_Kit_12_x86_64" should not exist
    And a file named "/etc/zypp/credentials.d/Web_and_Scripting_Module_12_x86_64" should not exist

    And I run `zypper lr`
    And the output should not contain "SUSE_Linux_Enterprise_Server_12_x86_64"
    And the output should not contain "SUSE_Linux_Enterprise_Software_Development_Kit_12_x86_64"
    And the output should not contain "Web_and_Scripting_Module_12_x86_64"

  Scenario: Error cleanly if system record was deleted on SCC only
    When I call SUSEConnect with '--regcode VALID' arguments
    Then I deregister the system only
    And I call SUSEConnect with '--status true' arguments
    Then the exit status should be 67
    And the output should contain:
    """
    Not authorised. If using existing SCC credentials
    """
    Then I remove local credentials

  Scenario: client provides meaningful message in case of invalid reg-code
    When I call SUSEConnect with '--regcode invalid' arguments
    Then the exit status should be 67
    And the output should contain:
    """
    Provided registration code is not recognized by registration server.
    """

  Scenario: Remove all registration leftovers
    When System cleanup
