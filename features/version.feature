Feature: Version output

  SUSEConnect should print its version if --version parameter is present

  Scenario: if version param is passed alone
    Given I successfully run `SUSEConnect --version`
    Then the output should match /^\d{1,2}\.\d{1,2}\.\d{1,2}$/
    And the output should contain exactly current version number
