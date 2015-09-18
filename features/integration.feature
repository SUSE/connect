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


  Scenario: System registration requires a regcode
    When I call SUSEConnect with '' arguments
    Then the exit status should be 1
    And the output should contain "Please set the regcode parameter"


  Scenario: Free extension activation does not require regcode and activates the extension
    When I call SUSEConnect with '--product sle-sdk/12/x86_64' arguments
    Then the exit status should be 0

    And a file named "/etc/zypp/credentials.d/SUSE_Linux_Enterprise_Software_Development_Kit_12_x86_64" should exist
    And the file "/etc/zypp/credentials.d/SUSE_Linux_Enterprise_Software_Development_Kit_12_x86_64" should contain "SCC_"

    And zypper should contain a service for sdk product
    And zypper should contain a repositories for sdk product


  Scenario: Paid extension activation requires regcode
    When I call SUSEConnect with '--product sle-live-patching/12/x86_64' arguments
    Then the exit status should be 67
    And the output should contain "Please provide a registration code for this product"


  Scenario: API response language check
    Given I set the environment variables to:
      | variable | value |
      | LANG     | de    |

    When I call SUSEConnect with '--regcode INVALID' arguments
    Then the exit status should be 67

    And the output should contain "Keine Subscription mit diesem Registrierungscode gefunden"

  Scenario: Lists all possible extensions
    When I run `SUSEConnect --list-extensions`
    Then the exit status should be 0
    And the output should contain "Containers Module 12 x86_64"
    And the output should contain "sle-module-containers/12/x86_64"
    And the output should contain "Advanced Systems Management Module 12 x86_64"
    And the output should contain "sle-module-adv-systems-management/12/x86_64"
    And the output should contain "Web and Scripting Module 12 x86_64"
    And the output should contain "sle-module-web-scripting/12/x86_64"
    And the output should contain "SUSE Linux Enterprise Software Development Kit 12 x86_64"
    And the output should contain "sle-sdk/12/x86_64"
    And the output should contain "Legacy Module 12 x86_64"
    And the output should contain "sle-module-legacy/12/x86_64"
    And the output should contain "Public Cloud Module 12 x86_64"
    And the output should contain "sle-module-public-cloud/12/x86_64"
    And the output should contain "Toolchain Module 12 x86_64"
    And the output should contain "sle-module-toolchain/12/x86_64"
    And the output should contain "SUSE Enterprise Storage 1 x86_64"
    And the output should contain "ses/1/x86_64"
    And the output should contain "SUSE Linux Enterprise Workstation Extension 12 x86_64"
    And the output should contain "sle-we/12/x86_64"
    And the output should contain "SUSE Cloud for SLE 12 Compute Nodes 5 x86_64"
    And the output should contain "suse-sle12-cloud-compute/5/x86_64"
    And the output should contain "SUSE Linux Enterprise Live Patching 12 x86_64"
    And the output should contain "sle-live-patching/12/x86_64"
    And the output should contain "SUSE Linux Enterprise High Availability Extension 12 x86_64"
    And the output should contain "sle-ha/12/x86_64"
    And the output should contain "SUSE Linux Enterprise High Availability GEO Extension 12 x86_64"
    And the output should contain "sle-ha-geo/12/x86_64"
    And the output should contain "https://www.suse.com/products/server/features/modules.html"


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
    When I deregister the system
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
    Then I delete the system on SCC

    And I call SUSEConnect with '--status true' arguments
    Then the exit status should be 67
    And the output should contain:
    """
    Invalid system credentials, probably because the registered system was deleted in SUSE Customer Center.
    """


  Scenario: System cleanup
    Then a file named "/etc/zypp/credentials.d/SCCcredentials" should exist
    And a file named "/etc/zypp/credentials.d/SUSE_Linux_Enterprise_Server_12_x86_64" should exist

    And I run `zypper lr`
    And the output should contain "SUSE_Linux_Enterprise_Server_12_x86_64"

    When I call SUSEConnect with '--cleanup true' arguments

    Then a file named "/etc/zypp/credentials.d/SCCcredentials" should not exist
    And a file named "/etc/zypp/credentials.d/SUSE_Linux_Enterprise_Server_12_x86_64" should not exist


  Scenario: Client provides meaningful message in case of invalid reg-code
    When I call SUSEConnect with '--regcode INVALID' arguments
    Then the exit status should be 67
    And the output should contain:
    """
    Invalid registration code.
    """

  Scenario: Client provides meaningful message in case of not yet active regcode
    When I call SUSEConnect with '--regcode NOTYETACTIVATED' arguments
    Then the exit status should be 67
    And the output should contain:
    """
    Not yet activated registration code. Please visit https://scc.suse.com to activate it.
    """

  Scenario: Client provides meaningful message in case of expired regcode
    When I call SUSEConnect with '--regcode EXPIRED' arguments
    Then the exit status should be 67
    And the output should contain:
    """
    Expired registration code.
    """

  Scenario: Remove all registration leftovers
    When System cleanup
