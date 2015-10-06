Feature: SUSEConnect should provide expected exit statuses

  Scenario: call for help should exit with 0
    When I run `SUSEConnect --help`
    Then the exit status should be 0

  Scenario: version call should exit with 0
    When I run `SUSEConnect --version`
    Then the exit status should be 0

  Scenario: binary call without token should exit with 1
    When I run `SUSEConnect`
    Then the exit status should be 1

  @libzypplocked
  Scenario: libzypp locked should exit with 7
    When I call SUSEConnect with '--regcode VALID' arguments
    Then the exit status should be 7
