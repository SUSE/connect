@slow_process
Feature: Test localized server responses
  Scenario: API response language check
    Given I set the environment variables to:
      | variable | value |
      | LANG     | de    |

    When I call SUSEConnect with '--regcode INVALID' arguments
    Then the output should contain "Unbekannter Registrierungscode"
