Feature: Registration

  In order to register a system we should provide a functionality to pass
  registration token as a parameter and register system on SUSE Customer Center (SCC)

  Scenario: passed url parameter without argument
    And I run `SUSEConnect --token 34fd2b04-4e40-425c-a137-7721e0303382 --url`
    Then output should inform us about you need an argument if running with url parameter
    And the exit status should be 1

  Scenario: passed url parameter with argument
    And I run `SUSEConnect --token 34fd2b04-4e40-425c-a137-7721e0303382 --url https://localhost:3000/`
    Then outputs should not contain info about required url param
    And the exit status should be 0

  Scenario: usual run
    And I run `SUSEConnect --token 34fd2b04-4e40-425c-a137-7721e0303382`
    And the exit status should be 0

  Scenario: passed token parameter without argument
    Given I run `SUSEConnect --token --url http://localhost:3000`
    And the exit status should be 1
