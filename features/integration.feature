Feature: SUSEConnect full stack integration testing
  In order to deliver the best possible quality of SUSEConnect package we have to do a full stack integration testing
  This means we have to register a test machine against production server and examine all relevant data

  @slow_process
  Scenario: Successful system registration
    When I register a system with valid regcode
    Then I wait a while
    And SUSEConnect should create the 'SCCcredentials' file
    And SCCcredentials file should contain 'SCC' prefixed system guid
    And SUSEConnect should create the 'service credentials' file
    And Service credentials file should contain 'SCC' prefixed system guid

    Then SUSEConnect should add a new zypper service for base product
    And SUSEConnect should add a new repositories for base product
