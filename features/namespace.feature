@slow_process
Feature: `namespace` CLI argument and option persistence

  Scenario: It stores namespace from a CLI argument in the config file
    When I call SUSEConnect with '--regcode VALID --namespace foobar' arguments
    Then a file named "/etc/SUSEConnect" should exist
    And the file "/etc/SUSEConnect" should contain "namespace: foobar"

  Scenario: It keeps namespace from a configfile when no parameter specified
    When there's a file "/etc/SUSEConnect" with a line "namespace: foobar"
    When I call SUSEConnect with '--regcode VALID --write-config true' arguments
    Then a file named "/etc/SUSEConnect" should exist
    And the file "/etc/SUSEConnect" should contain "namespace: foobar"

  Scenario: It overrides and saves namespace from CLI arguments
    When there's a file "/etc/SUSEConnect" with a line "namespace: foobar"
    When I call SUSEConnect with '--regcode VALID --namespace barbaz' arguments
    Then a file named "/etc/SUSEConnect" should exist
    And the file "/etc/SUSEConnect" should contain "namespace: barbaz"
