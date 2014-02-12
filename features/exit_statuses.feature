Feature: exit statuses

  SUSEConnect should provide expected exit statuses

  Scenario: call for help should exit with 0
    When I run `SUSEConnect --help`
    Then the exit status should be 0

  Scenario: version call should exit with 0
    When I run `SUSEConnect --version`
    Then the exit status should be 0

  Scenario: binary call without token should exit with 1
    When I run `SUSEConnect`
    Then the exit status should be 1
