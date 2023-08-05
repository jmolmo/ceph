Feature: CephFS Management

    Goal: To test out the CephFS management features

    Background: Login
        Given I am logged in

    Scenario: Create a CephFS Volume
        Given I am on the "cephfs" page
        And I click on "Create" button
        And enter "name" "test_cephfs"
        And I click on "Create Volume" button
        Then I should see a row with "test_cephfs"

    Scenario: Edit CephFS Volume
        Given I am on the "cephfs" page
        And I select a row "test_cephfs"
        And I click on "Edit" button
        And enter "name" "test_cephfs_edit" in the modal
        And I click on "Edit Volume" button
        Then I should see a row with "test_cephfs_edit"

    Scenario: Remove CephFS Volume
        Given I am on the "cephfs" page
        And I select a row "test_cephfs_edit"
        And I click on "Remove" button from the table actions
        Then I should see the modal
        And I check the tick box in modal
        And I click on "Remove Volume" button
        Then I should not see a row with "test_cephfs_edit"
