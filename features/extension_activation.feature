@slow_process
Feature: Test extension/module activation

  Scenario: Register base system
    Given I have a system with activated base product

  Scenario: Lists all possible extensions
    When I run `SUSEConnect --list-extensions`
    Then the exit status should be 0
    And the output should contain "Containers Module 12 x86_64"
    And the output should contain "sle-module-containers/12/x86_64"
    And the output should contain "Advanced Systems Management Module 12 x86_64"
    And the output should contain "sle-module-adv-systems-management/12/x86_64"
    And the output should contain "Web and Scripting Module 12 x86_64"
    And the output should contain "sle-module-web-scripting/12/x86_64"
    And the output should contain "SUSE Linux Enterprise Software Development Kit 12 x86_64"
    And the output should contain "sle-sdk/12/x86_64"
    And the output should contain "Legacy Module 12 x86_64"
    And the output should contain "sle-module-legacy/12/x86_64"
    And the output should contain "Public Cloud Module 12 x86_64"
    And the output should contain "sle-module-public-cloud/12/x86_64"
    And the output should contain "Toolchain Module 12 x86_64"
    And the output should contain "sle-module-toolchain/12/x86_64"
    And the output should contain "SUSE Enterprise Storage 2 x86_64"
    And the output should contain "ses/2/x86_64"
    And the output should contain "SUSE Linux Enterprise Workstation Extension 12 x86_64"
    And the output should contain "sle-we/12/x86_64"
    And the output should contain "SUSE Cloud for SLE 12 Compute Nodes 5 x86_64"
    And the output should contain "suse-sle12-cloud-compute/5/x86_64"
    And the output should contain "SUSE Linux Enterprise Live Patching 12 x86_64"
    And the output should contain "sle-live-patching/12/x86_64"
    And the output should contain "SUSE Linux Enterprise High Availability Extension 12 x86_64"
    And the output should contain "sle-ha/12/x86_64"
    And the output should contain "SUSE Linux Enterprise High Availability GEO Extension 12 x86_64"
    And the output should contain "sle-ha-geo/12/x86_64"
    And the output should contain "https://www.suse.com/products/server/features/modules.html"

  Scenario: Paid extension activation requires regcode
    When I call SUSEConnect with '--product sle-live-patching/12/x86_64' arguments
    Then the exit status should be 67
    And the output should contain "Please provide a Registration Code for this product"

  Scenario: Free extension activation does not require regcode and activates the extension
    When I call SUSEConnect with '--product sle-sdk/12/x86_64' arguments
    Then the exit status should be 0

    And a file named "/etc/zypp/credentials.d/SUSE_Linux_Enterprise_Software_Development_Kit_12_x86_64" should exist
    And the file "/etc/zypp/credentials.d/SUSE_Linux_Enterprise_Software_Development_Kit_12_x86_64" should contain "SCC_"

    And zypper should contain a service for sdk product
    And zypper should contain the repositories for sdk product

  Scenario: Remove all registration leftovers
    Then I deregister the system
    And I run `zypper --non-interactive rm sle-sdk-release sle-sdk-release-POOL`
