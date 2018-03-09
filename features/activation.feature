@slow_process
Feature: Test product activation

  @skip-sles-15
  Scenario: System registration
    Given I have a system with activated base product

    Then the output should contain "Activating SLES"
    And the output should contain "Adding zypper service"
    And the output should contain "Installing release package"
    And the output should contain "=> Activation successful!"


  @skip-sles-12
  Scenario: System registration
    Given I have a system with activated base product

    Then the output should contain "Adding zypper service"
    And the output should contain "Installing release package"

    And the output should contain "Activating sle-module-basesystem"
    And the output should contain "Adding zypper service"
    And the output should contain "Installing release package"

    And zypper should contain a service for sle-module-basesystem

    And the output should contain "Activating sle-module-server-applications 15"
    And the output should contain "Adding zypper service"
    And the output should contain "Installing release package"

    And zypper should contain a service for sle-module-server-applications
    And the output should contain "=> Activation successful!"


  Scenario: Files are created as required
    Then a file named "/etc/zypp/credentials.d/SCCcredentials" should exist
    And the file "/etc/zypp/credentials.d/SCCcredentials" should contain "SCC_"

    And zypp credentials for base should exist
    And zypp credentials for base should contain "SCC_"

    And zypper should contain a service for base product
    And zypper should contain the repositories for base product


  Scenario: System de-registration
    When I deregister the system
    Then a file named "/etc/zypp/credentials.d/SCCcredentials" should not exist

    And zypp credentials for base should not exist
    And zypper should not contain a service for base product
    And zypper should not contain the repositories for base product


  Scenario: Error cleanly if system record was deleted on SCC only
    When I call SUSEConnect with '--regcode VALID' arguments
    And I delete the system on SCC

    And I call SUSEConnect with '--status true' arguments
    Then the exit status should be 67
    And the output should contain:
    """
    Invalid system credentials, probably because the registered system was deleted in SUSE Customer Center.
    """


  Scenario: System cleanup
    Then a file named "/etc/zypp/credentials.d/SCCcredentials" should exist
    And zypp credentials for base should exist
    And zypper should contain the repositories for base product

    When I call SUSEConnect with '--cleanup true' arguments
    Then a file named "/etc/zypp/credentials.d/SCCcredentials" should not exist
    And zypp credentials for base should not exist


  Scenario: Remove all registration leftovers
    When System cleanup
