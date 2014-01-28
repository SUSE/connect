Feature: exit statuses

  SUSEConnect should provide expected exit statuses

  Scenario: call for help shou
    When I run `SUSEConnect -h`
    Then the exit status should be 0
