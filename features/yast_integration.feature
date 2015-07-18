@yast
Feature: YaST integration testing

  In order to deliver the best possible quality of the SUSEConnect package we
  have to also test that the YaST class which uses the connect gem still works.

  ### YaST checks ###
  Scenario: System registration
    Given the file named "/etc/zypp/credentials.d/SCCcredentials" should not exist
    When I call YaST registration "register" method

    Then a file named "/etc/zypp/credentials.d/SCCcredentials" should exist
    And the file "/etc/zypp/credentials.d/SCCcredentials" should contain "SCC_"


  Scenario: Base product registration
    Given a file named "/etc/zypp/credentials.d/SUSE_Linux_Enterprise_Server_12_x86_64" should not exist
    And a file named "/etc/zypp/services.d/SUSE_Linux_Enterprise_Server_12_x86_64.service" should not exist

    When I call YaST registration "register_product" method

    Then a file named "/etc/zypp/credentials.d/SUSE_Linux_Enterprise_Server_12_x86_64" should exist
    And the file "/etc/zypp/credentials.d/SUSE_Linux_Enterprise_Server_12_x86_64" should contain "SCC_"

    And a file named "/etc/zypp/services.d/SUSE_Linux_Enterprise_Server_12_x86_64.service" should exist
    And a file named "/etc/zypp/repos.d/SUSE_Linux_Enterprise_Server_12_x86_64:SLES12-Pool.repo" should exist


  Scenario: Reading the remote extensions
    When I call YaST registration "get_addon_list" method

    Then the returned list should contain the "sle-sdk" extension
    And the returned list should contain the "sle-ha" extension


  Scenario: Registering the SDK extension
    Given a file named "/etc/zypp/credentials.d/SUSE_Linux_Enterprise_Software_Development_Kit_12_x86_64" should not exist
    And a file named "/etc/zypp/services.d/SUSE_Linux_Enterprise_Software_Development_Kit_12_x86_64.service" should not exist

    When I call YaST registration "register_product" method with "sdk" product

    Then a file named "/etc/zypp/credentials.d/SUSE_Linux_Enterprise_Software_Development_Kit_12_x86_64" should exist
    And the file "/etc/zypp/credentials.d/SUSE_Linux_Enterprise_Software_Development_Kit_12_x86_64" should contain "SCC_"

    And a file named "/etc/zypp/services.d/SUSE_Linux_Enterprise_Software_Development_Kit_12_x86_64.service" should exist
    And a file named "/etc/zypp/repos.d/SUSE_Linux_Enterprise_Software_Development_Kit_12_x86_64:SLE-SDK12-Pool.repo" should exist


  Scenario: Reading the migration products
    When I call YaST registration "migration_products" method

    Then the result should contain the SP1 migration target

