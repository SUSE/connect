Feature: Version output

  SUSEConnect should print its version if --version parameter is present

  Scenario: version should be properly formed
    Given I run `SUSEConnect --version`
    Then the output should match /^\d{1,2}\.\d{1,2}\.\d{1,2}$/

  Scenario: if version param is passed alone
    Given I run `SUSEConnect --version`
    Then the output should contain exactly current version number

  Scenario: if version param is passed before other params client should exit after version output
    Given I run `SUSEConnect --version --help`
    Then the output should contain only version
