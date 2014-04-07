Feature: SUSEConnect full stack integration testing
  In order to deliver the best possible quality of SUSEConnect package we have to do a full stack integration testing
  This means we have to register a test machine against production server and examine all relevant data

  Scenario: Successful system registration
    When I register a system with regcode 'E9DB3A42DF2288'
    Then SUSEConnect should create the 'SCCcredentials' file
    And Credentials file should contain 'SCC_' prefixed system guid
