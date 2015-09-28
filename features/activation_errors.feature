@slow_process
Feature: Testing error messages of product activation

  Scenario: System registration requires a regcode
    When I call SUSEConnect with '' arguments
    Then the exit status should be 1
    And the output should contain "Please set the regcode parameter"

  Scenario: Client provides meaningful message in case of not yet active regcode
    When I call SUSEConnect with '--regcode NOTYETACTIVATED' arguments
    Then the exit status should be 67
    And the output should contain:
    """
    Not yet activated registration code. Please visit https://scc.suse.com to activate it.
    """

  Scenario: Client provides meaningful message in case of invalid reg-code
    When I call SUSEConnect with '--regcode INVALID' arguments
    Then the exit status should be 67
    And the output should contain:
    """
    Invalid registration code.
    """

  Scenario: Client provides meaningful message in case of expired regcode
    When I call SUSEConnect with '--regcode EXPIRED' arguments
    Then the exit status should be 67
    And the output should contain:
    """
    Expired registration code.
    """
