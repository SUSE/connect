@slow_process
Feature: Test localized server responses

  Scenario: Register base system
    Given I have a system with activated base product

  Scenario: API response language check
    Given I set the environment variables to:
      | variable | value |
      | LANG     | de    |

    When I call SUSEConnect with '--regcode INVALID' arguments
    Then the exit status should be 67

    And the output should contain "Keine Subscription mit diesem Registrierungscode gefunden."


  Scenario: Remove all registration leftovers
    Then I deregister the system
