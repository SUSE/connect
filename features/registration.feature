Feature: Registration

  In order to register a system we should provide a functionality to pass
  registration token as a parameter and register system on SUSE Customer Center (SCC)

  Scenario: passed host parameter without argument
    And I run `SUSEConnect --token 34fd2b04-4e40-425c-a137-7721e0303382 -h`
    Then output should inform us about you need an argument if running with host parameter
    And the exit status should be 1

  Scenario: passed host parameter with argument
    And I run `SUSEConnect --token 34fd2b04-4e40-425c-a137-7721e0303382 -h 127.0.0.1`
    Then outputs should not contain info about required host param
    And the exit status should be 0

  Scenario: passed port parameter without argument
    And I run `SUSEConnect --token 34fd2b04-4e40-425c-a137-7721e0303382 -p`
    Then output should inform us about you need an argument if running with port parameter
    And the exit status should be 1

  Scenario: passed port parameter with argument
    And I run `SUSEConnect --token 34fd2b04-4e40-425c-a137-7721e0303382 -p 2872`
    Then outputs should not contain info about required port param
    And the exit status should be 0

  Scenario: passed token parameter without argument
    Given I run `SUSEConnect --token -p 2872`
    And the exit status should be 1
