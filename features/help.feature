Feature: Help output

  SUSEConnect should provide valid help messages

  Background:
    Given I run `SUSEConnect --help`

  Scenario: help should contain host parameter
    Then the output should contain:
      """
      --url [URL]                  Connection base url (e.g. https://scc.suse.com).
      """

  Scenario: help should contain token parameter
    Then the output should contain:
      """
      -t, --token [TOKEN]              Registration token.
      """

  # Common Options

  Scenario: help should contain help option
    Then the output should contain:
      """
      --help                       Show this message.
      """

  Scenario: help should contain dry mode option
    Then the output should contain:
      """
      -d, --dry-mode                   Dry mode. Does not make any changes to the system.
      """

  Scenario: help should contain version option
    Then the output should contain:
      """
      --version                    Print version
      """

  Scenario: help should contain verbose option
    Then the output should contain:
      """
      -v, --verbose                    Run verbosely.
      """
