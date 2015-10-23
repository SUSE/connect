@slow_process
Feature: Rollback registration state to system products

  Scenario: Register base system
    Given I have a system with activated base product


  Scenario: Migration targets
    When Prepare SUSEConnect client with a valid regcode
    Then I should receive 'SLES12-SP1' as a migration target


  Scenario: Rollback can be called on activated system without an issue
    When I call the migration rollback method

    Then a file named "/etc/zypp/credentials.d/SCCcredentials" should exist
    And the file "/etc/zypp/credentials.d/SCCcredentials" should contain "SCC_"

    And a file named "/etc/zypp/credentials.d/SUSE_Linux_Enterprise_Server_12_x86_64" should exist
    And the file "/etc/zypp/credentials.d/SUSE_Linux_Enterprise_Server_12_x86_64" should contain "SCC_"

    And zypper should contain a service for base product
    And zypper should contain the repositories for base product


  Scenario: Rollback can be called from console with the same outcome as called from library
    When I run `SUSEConnect --rollback`

    Then the exit status should be 0
    And the output should contain "> Beginning registration rollback. This can take some time..."
    And a file named "/etc/zypp/credentials.d/SCCcredentials" should exist
    And the file "/etc/zypp/credentials.d/SCCcredentials" should contain "SCC_"

    And a file named "/etc/zypp/credentials.d/SUSE_Linux_Enterprise_Server_12_x86_64" should exist
    And the file "/etc/zypp/credentials.d/SUSE_Linux_Enterprise_Server_12_x86_64" should contain "SCC_"

    And zypper should contain a service for base product
    And zypper should contain the repositories for base product


  Scenario: Remove all registration leftovers
    Then I deregister the system
