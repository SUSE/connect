Feature: Dry-run

  We should be able to simulate run, without any interaction with real API and file

  Scenario: user passed dry-run parameter
    Given I run `SUSEConnect --token 34fd2b04-4e40-425c-a137-7721e0303382 --dry-run`
    Then i should see steps which will happen without dry-run param
