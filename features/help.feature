Feature: Help output

  SUSEConnect should provide valid help messages

  Background:
    Given I run `SUSEConnect --help`

  Scenario: help should contain host parameter
    Then the output should contain:
      """
      --url [URL]
      """

  Scenario: help should contain token parameter
    Then the output should contain:
      """
      -r, --regcode [REGCODE]
      """

  # Common Options

  Scenario: help should contain help option
    Then the output should contain:
      """
      --help
      """

  Scenario: help should contain dry mode option
    Then the output should contain:
      """
      -d, --dry-run
      """

  Scenario: help should contain version option
    Then the output should contain:
      """
      --version
      """

  Scenario: help should contain verbose option
    Then the output should contain:
      """
      --debug
      """
