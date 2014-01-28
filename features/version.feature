Feature: Version output

  SUSEConnect should print its version if --version parameter is present

  Background:
    Given I run `SUSEConnect --version`

  Scenario: version should be properly formed
    Then the output should match /^\d{1,2}\.\d{1,2}\.\d{1,2}$/
