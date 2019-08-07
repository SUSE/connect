@slow_process
Feature: Test extension/module activation

  Scenario: Register base system
    Given I have a system with activated base product

  Scenario: Lists all possible extensions
    When I run `SUSEConnect --list-extensions`
    Then the exit status should be 0
    And the output should contain "Containers Module"
    And the output should contain "Web and Scripting"
    And the output should contain "Legacy Module"
    And the output should contain "Public Cloud Module"
    And the output should contain "SUSE Linux Enterprise High Availability Extension"
    And the output should contain "https://www.suse.com/documentation/sles-15/singlehtml/art_modules/art_modules.html"

  # Skip in SLES15 for now, since there's no paid extensions that can be activated
  # directly on the root product. Once SUSEConnect automatically activates recommended
  # modules, then we can enable this test with a proper extension.
  @skip-sles-15
  Scenario: Paid extension activation requires regcode
    When I activate a paid extension
    Then the exit status should be 67
    And the output should contain "Please provide a Registration Code for this product"

  Scenario: Free extension activation does not require regcode and activates the extension
    When I activate a free extension
    Then the exit status should be 0
    And a credentials file is created for the extension
    And zypper should contain a service for the extension
    And zypper should contain the repositories for the extension

  Scenario: Remove all registration leftovers
    When System has free extension
    And I run `SUSEConnect -d`
    Then the exit status should be 0
    And the output should contain "Deregistering system from SUSE Customer Center"
    And the output should contain "Deactivating"
    And the output should contain "-> Removing service from system ..."
    And the output should contain "-> Removing release package ..."
    And the output should contain "Cleaning up ..."
    And the output should contain "Successfully deregistered system"
    And It deregisters free extension
