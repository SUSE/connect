Feature: Help output

  SUSEConnect should provide valid help messages

  Scenario: help should contain host parameter
    Given I run `SUSEConnect --help`
    Then the output should contain "--url [URL]"
    And the output should contain "-r, --regcode [REGCODE]"
    And the output should contain "--list-extensions"
    And the output should contain "--help"
    And the output should contain "--version"
    And the output should contain "--debug"
