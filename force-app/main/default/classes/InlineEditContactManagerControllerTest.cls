/**
 * @description Test class for InlineEditContactManagerController
 * @author AI Assistant
 * @version 1.0
 */
@isTest
private class InlineEditContactManagerControllerTest {
    
    // Test data setup
    @TestSetup
    static void setupTestData() {
        // Create test accounts
        List<Account> testAccounts = new List<Account>{
            new Account(Name = 'Test Account 1', BillingCity = 'Test City 1'),
            new Account(Name = 'Test Account 2', BillingCity = 'Test City 2')
        };
        insert testAccounts;
        
        // Create test contacts
        List<Contact> testContacts = new List<Contact>{
            new Contact(
                FirstName = 'John',
                LastName = 'Doe',
                Email = 'john.doe@test.com',
                Phone = '555-0101',
                Title = 'Manager',
                Department = 'Sales',
                AccountId = testAccounts[0].Id
            ),
            new Contact(
                FirstName = 'Jane',
                LastName = 'Smith',
                Email = 'jane.smith@test.com',
                Phone = '555-0102',
                Title = 'Director',
                Department = 'Marketing',
                AccountId = testAccounts[0].Id
            ),
            new Contact(
                FirstName = 'Bob',
                LastName = 'Johnson',
                Email = 'bob.johnson@test.com',
                Phone = '555-0103',
                Title = 'VP',
                Department = 'Engineering',
                AccountId = testAccounts[1].Id
            ),
            new Contact(
                FirstName = 'Alice',
                LastName = 'Brown',
                Email = 'alice.brown@test.com',
                Phone = '555-0104',
                Title = 'Analyst',
                Department = 'Finance',
                AccountId = testAccounts[1].Id
            )
        };
        insert testContacts;
    }
    
    /**
     * @description Test controller initialization
     */
    @isTest
    static void testControllerInitialization() {
        // Given
        Test.startTest();
        
        // When
        InlineEditContactManagerController controller = new InlineEditContactManagerController();
        
        // Then
        System.assertNotEquals(null, controller, 'Controller should not be null');
        System.assertEquals('', controller.searchTerm, 'Search term should be empty initially');
        System.assertEquals(1, controller.currentPage, 'Current page should be 1 initially');
        System.assertNotEquals(null, controller.contacts, 'Contacts list should not be null');
        System.assertNotEquals(null, controller.getTotalRecords(), 'Total records should not be null');
        
        Test.stopTest();
    }
    
    /**
     * @description Test loading contacts without search term
     */
    @isTest
    static void testLoadContactsWithoutSearch() {
        // Given
        InlineEditContactManagerController controller = new InlineEditContactManagerController();
        
        // When & Then
        System.assertNotEquals(0, controller.getTotalRecords(), 'Should have test contacts');
        System.assertNotEquals(null, controller.contacts, 'Contacts should be loaded');
        System.assertEquals(1, controller.currentPage, 'Should start on first page');
        System.assertEquals(true, controller.isFirstPage, 'Should be on first page');
        System.assertNotEquals(null, controller.totalPages, 'Total pages should be calculated');
    }
    
    /**
     * @description Test search functionality with valid search term
     */
    @isTest
    static void testSearchContactsWithValidTerm() {
        // Given
        InlineEditContactManagerController controller = new InlineEditContactManagerController();
        controller.searchTerm = 'John';
        
        // When
        Test.startTest();
        PageReference result = controller.searchContacts();
        Test.stopTest();
        
        // Then
        System.assertEquals(null, result, 'Should stay on same page');
        System.assertEquals(1, controller.currentPage, 'Should reset to first page');
        System.assertNotEquals(0, controller.contacts.size(), 'Should find matching contacts');
    }
    
    /**
     * @description Test search functionality with empty search term
     */
    @isTest
    static void testSearchContactsWithEmptyTerm() {
        // Given
        InlineEditContactManagerController controller = new InlineEditContactManagerController();
        controller.searchTerm = '';
        
        // When
        Test.startTest();
        PageReference result = controller.searchContacts();
        Test.stopTest();
        
        // Then
        System.assertEquals(null, result, 'Should stay on same page');
        System.assertEquals(1, controller.currentPage, 'Should reset to first page');
        System.assertNotEquals(0, controller.contacts.size(), 'Should load all contacts');
    }
    
    /**
     * @description Test search functionality with no results
     */
    @isTest
    static void testSearchContactsWithNoResults() {
        // Given
        InlineEditContactManagerController controller = new InlineEditContactManagerController();
        controller.searchTerm = 'NonExistentContact';
        
        // When
        Test.startTest();
        PageReference result = controller.searchContacts();
        Test.stopTest();
        
        // Then
        System.assertEquals(null, result, 'Should stay on same page');
        System.assertEquals(0, controller.contacts.size(), 'Should have no results');
        System.assertEquals(1, controller.totalPages, 'Should have at least one page');
    }
    
    /**
     * @description Test pagination - next page
     */
    @isTest
    static void testNextPage() {
        // Given
        InlineEditContactManagerController controller = new InlineEditContactManagerController();
        controller.currentPage = 1;
        
        // When
        Test.startTest();
        PageReference result = controller.next();
        Test.stopTest();
        
        // Then
        System.assertEquals(null, result, 'Should stay on same page');
        // Note: With only 4 test contacts and 10 records per page, we should stay on page 1
        System.assertEquals(1, controller.currentPage, 'Should remain on first page if no more pages');
    }
    
    /**
     * @description Test pagination - previous page
     */
    @isTest
    static void testPreviousPage() {
        // Given
        InlineEditContactManagerController controller = new InlineEditContactManagerController();
        controller.currentPage = 1;
        
        // When
        Test.startTest();
        PageReference result = controller.previous();
        Test.stopTest();
        
        // Then
        System.assertEquals(null, result, 'Should stay on same page');
        System.assertEquals(1, controller.currentPage, 'Should remain on first page');
    }
    
    /**
     * @description Test toggle edit mode - enter edit mode
     */
    @isTest
    static void testToggleEditModeEnter() {
        // Given
        InlineEditContactManagerController controller = new InlineEditContactManagerController();
        controller.selectedContactId = controller.contacts[0].record.Id;
        
        // When
        Test.startTest();
        PageReference result = controller.toggleEditMode();
        Test.stopTest();
        
        // Then
        System.assertEquals(null, result, 'Should stay on same page');
        System.assertEquals(true, controller.contacts[0].isEditing, 'Contact should be in edit mode');
    }
    
    /**
     * @description Test toggle edit mode - save contact successfully
     */
    @isTest
    static void testToggleEditModeSaveSuccess() {
        // Given
        InlineEditContactManagerController controller = new InlineEditContactManagerController();
        controller.selectedContactId = controller.contacts[0].record.Id;
        controller.toggleEditMode(); // Enter edit mode
        
        // Update contact data
        controller.contacts[0].record.FirstName = 'Updated';
        controller.contacts[0].record.LastName = 'Name';
        controller.contacts[0].record.Email = 'updated@test.com';
        
        // When
        Test.startTest();
        PageReference result = controller.toggleEditMode(); // Save
        Test.stopTest();
        
        // Then
        System.assertEquals(null, result, 'Should stay on same page');
        System.assertEquals(false, controller.contacts[0].isEditing, 'Contact should exit edit mode');
        
        // Verify the contact was updated in database
        Contact updatedContact = [SELECT FirstName, LastName, Email FROM Contact WHERE Id = :controller.contacts[0].record.Id];
        System.assertEquals('Updated', updatedContact.FirstName, 'First name should be updated');
        System.assertEquals('Name', updatedContact.LastName, 'Last name should be updated');
        System.assertEquals('updated@test.com', updatedContact.Email, 'Email should be updated');
    }
    
    /**
     * @description Test toggle edit mode with invalid contact ID
     */
    @isTest
    static void testToggleEditModeInvalidId() {
        // Given
        InlineEditContactManagerController controller = new InlineEditContactManagerController();
        controller.selectedContactId = '001000000000000'; // Invalid ID
        
        // When
        Test.startTest();
        PageReference result = controller.toggleEditMode();
        Test.stopTest();
        
        // Then
        System.assertEquals(null, result, 'Should stay on same page');
        // Should not throw exception, just return null
    }
    
    /**
     * @description Test cancel edit mode
     */
    @isTest
    static void testCancelEdit() {
        // Given
        InlineEditContactManagerController controller = new InlineEditContactManagerController();
        controller.selectedContactId = controller.contacts[0].record.Id;
        controller.toggleEditMode(); // Enter edit mode
        
        // Modify contact data
        String originalFirstName = controller.contacts[0].record.FirstName;
        controller.contacts[0].record.FirstName = 'Modified';
        
        // When
        Test.startTest();
        PageReference result = controller.cancelEdit();
        Test.stopTest();
        
        // Then
        System.assertEquals(null, result, 'Should stay on same page');
        System.assertEquals(false, controller.contacts[0].isEditing, 'Contact should exit edit mode');
        System.assertEquals(originalFirstName, controller.contacts[0].record.FirstName, 'Data should be restored');
    }
    
    /**
     * @description Test save contact with missing required field
     */
    @isTest
    static void testSaveContactMissingLastName() {
        // Given
        InlineEditContactManagerController controller = new InlineEditContactManagerController();
        controller.selectedContactId = controller.contacts[0].record.Id;
        controller.toggleEditMode(); // Enter edit mode
        
        // Clear required field
        controller.contacts[0].record.LastName = '';
        
        // When
        Test.startTest();
        PageReference result = controller.toggleEditMode(); // Try to save
        Test.stopTest();
        
        // Then
        System.assertEquals(null, result, 'Should stay on same page');
        System.assertEquals(true, controller.contacts[0].isEditing, 'Should remain in edit mode due to validation error');
    }
    
    /**
     * @description Test save contact with invalid email format
     */
    @isTest
    static void testSaveContactInvalidEmail() {
        // Given
        InlineEditContactManagerController controller = new InlineEditContactManagerController();
        controller.selectedContactId = controller.contacts[0].record.Id;
        controller.toggleEditMode(); // Enter edit mode
        
        // Set invalid email
        controller.contacts[0].record.Email = 'invalid-email';
        
        // When
        Test.startTest();
        PageReference result = controller.toggleEditMode(); // Try to save
        Test.stopTest();
        
        // Then
        System.assertEquals(null, result, 'Should stay on same page');
        System.assertEquals(true, controller.contacts[0].isEditing, 'Should remain in edit mode due to validation error');
    }
    
    /**
     * @description Test save contact with valid email format
     */
    @isTest
    static void testSaveContactValidEmail() {
        // Given
        InlineEditContactManagerController controller = new InlineEditContactManagerController();
        controller.selectedContactId = controller.contacts[0].record.Id;
        controller.toggleEditMode(); // Enter edit mode
        
        // Set valid email
        controller.contacts[0].record.Email = 'valid.email@test.com';
        
        // When
        Test.startTest();
        PageReference result = controller.toggleEditMode(); // Save
        Test.stopTest();
        
        // Then
        System.assertEquals(null, result, 'Should stay on same page');
        System.assertEquals(false, controller.contacts[0].isEditing, 'Should exit edit mode');
    }
    
    /**
     * @description Test save contact with empty email (should be allowed)
     */
    @isTest
    static void testSaveContactEmptyEmail() {
        // Given
        InlineEditContactManagerController controller = new InlineEditContactManagerController();
        controller.selectedContactId = controller.contacts[0].record.Id;
        controller.toggleEditMode(); // Enter edit mode
        
        // Set empty email
        controller.contacts[0].record.Email = '';
        
        // When
        Test.startTest();
        PageReference result = controller.toggleEditMode(); // Save
        Test.stopTest();
        
        // Then
        System.assertEquals(null, result, 'Should stay on same page');
        System.assertEquals(false, controller.contacts[0].isEditing, 'Should exit edit mode');
    }
    
    /**
     * @description Test search by first name
     */
    @isTest
    static void testSearchByFirstName() {
        // Given
        InlineEditContactManagerController controller = new InlineEditContactManagerController();
        controller.searchTerm = 'John';
        
        // When
        Test.startTest();
        controller.searchContacts();
        Test.stopTest();
        
        // Then
        System.assertNotEquals(0, controller.contacts.size(), 'Should find contacts with first name John');
        Boolean foundJohn = false;
        for (InlineEditContactManagerController.ContactWrapper wrapper : controller.contacts) {
            if (wrapper.record.FirstName == 'John') {
                foundJohn = true;
                break;
            }
        }
        System.assertEquals(true, foundJohn, 'Should find contact with first name John');
    }
    
    /**
     * @description Test search by last name
     */
    @isTest
    static void testSearchByLastName() {
        // Given
        InlineEditContactManagerController controller = new InlineEditContactManagerController();
        controller.searchTerm = 'Doe';
        
        // When
        Test.startTest();
        controller.searchContacts();
        Test.stopTest();
        
        // Then
        System.assertEquals(1, controller.contacts.size(), 'Should find one contact with last name Doe');
        System.assertEquals('Doe', controller.contacts[0].record.LastName, 'Should find the correct contact');
    }
    
    /**
     * @description Test search by email
     */
    @isTest
    static void testSearchByEmail() {
        // Given
        InlineEditContactManagerController controller = new InlineEditContactManagerController();
        controller.searchTerm = 'jane.smith@test.com';
        
        // When
        Test.startTest();
        controller.searchContacts();
        Test.stopTest();
        
        // Then
        System.assertEquals(1, controller.contacts.size(), 'Should find one contact with matching email');
        System.assertEquals('jane.smith@test.com', controller.contacts[0].record.Email, 'Should find the correct contact');
    }
    
    /**
     * @description Test search with partial match
     */
    @isTest
    static void testSearchPartialMatch() {
        // Given
        InlineEditContactManagerController controller = new InlineEditContactManagerController();
        controller.searchTerm = 'test.com';
        
        // When
        Test.startTest();
        controller.searchContacts();
        Test.stopTest();
        
        // Then
        System.assertNotEquals(0, controller.contacts.size(), 'Should find contacts with email containing test.com');
    }
    
    /**
     * @description Test pagination properties
     */
    @isTest
    static void testPaginationProperties() {
        // Given
        InlineEditContactManagerController controller = new InlineEditContactManagerController();
        
        // When & Then
        System.assertNotEquals(null, controller.isFirstPage, 'isFirstPage should not be null');
        System.assertNotEquals(null, controller.isLastPage, 'isLastPage should not be null');
        System.assertNotEquals(null, controller.totalPages, 'totalPages should not be null');
        System.assertNotEquals(null, controller.getTotalRecords(), 'getTotalRecords should not be null');
    }
    
    /**
     * @description Test contact wrapper functionality
     */
    @isTest
    static void testContactWrapper() {
        // Given
        Contact testContact = new Contact(FirstName = 'Test', LastName = 'Contact');
        
        // When
        InlineEditContactManagerController.ContactWrapper wrapper = 
            new InlineEditContactManagerController.ContactWrapper(testContact);
        
        // Then
        System.assertEquals(testContact, wrapper.record, 'Record should be set correctly');
        System.assertEquals(false, wrapper.isEditing, 'isEditing should be false initially');
    }
    
    /**
     * @description Test error handling in loadContacts method
     */
    @isTest
    static void testLoadContactsErrorHandling() {
        // Given
        InlineEditContactManagerController controller = new InlineEditContactManagerController();
        
        // This test verifies that the controller handles errors gracefully
        // The actual error handling is tested through the various validation scenarios above
        
        // When & Then
        System.assertNotEquals(null, controller.contacts, 'Contacts should be initialized even if empty');
    }
} 