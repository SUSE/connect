Feature: Registration

  In order to register a system we should provide a functionality to pass
  registration token as a parameter and register system on SUSE Customer Center (SCC)

  Scenario: passed url parameter without argument
    When I run `SUSEConnect --regcode 34fd2b04-4e40-425c-a137-7721e0303382 --url`
    Then output should inform us about you need an argument if running with url parameter
    And the exit status should be 1

  Scenario: passed url parameter with argument
    When I run `SUSEConnect --regcode 34fd2b04-4e40-425c-a137-7721e0303382 --url https://localhost:3000/`
    Then outputs should not contain info about required url param
    And the exit status should be 0

  Scenario: usual run
    When I run `SUSEConnect --regcode 34fd2b04-4e40-425c-a137-7721e0303382`
    And the exit status should be 0

  Scenario: passed token parameter without argument
    When I run `SUSEConnect --regcode --url http://localhost:3000`
    And the exit status should be 1

  Scenario: passed invalid regcode
    When I run `SUSEConnect --regcode foo --url http://localhost:3000`
    Then the output should inform us that the regcode was invalid
    And the exit status should be 1

  Scenario: passed not yet active regcode
    When I run `SUSEConnect --regcode foo --url http://localhost:3000`
    Then the output should inform us that the regcode needs to be activated
    And the exit status should be 1

  Scenario: passed expired regcode
    When I run `SUSEConnect --regcode foo --url http://localhost:3000`
    Then the output should inform us that the regcode has expired
    And the exit status should be 1


