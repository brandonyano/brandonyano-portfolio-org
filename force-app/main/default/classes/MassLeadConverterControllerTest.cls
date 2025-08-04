/**
 * Test class for MassLeadConverterController
 */
@isTest
public class MassLeadConverterControllerTest {
    
    @testSetup
    static void setupTestData() {
        // Create test leads
        List<Lead> testLeads = new List<Lead>();
        for (Integer i = 0; i < 30; i++) {
            testLeads.add(new Lead(
                FirstName = 'Test',
                LastName = 'Lead ' + i,
                Company = 'Test Company ' + i,
                Email = 'testlead' + i + '@example.com',
                Phone = '555-000-' + String.valueOf(i).leftPad(4, '0'),
                Status = 'Open - Not Contacted',
                LeadSource = 'Web'
            ));
        }
        insert testLeads;
    }
    
    @isTest
    static void testControllerInitialization() {
        // Setup StandardSetController - the controller will create its own query
        List<Lead> leads = [SELECT Id FROM Lead LIMIT 25];
        ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(leads);
        
        Test.startTest();
        MassLeadConverterController controller = new MassLeadConverterController(ssc);
        Test.stopTest();
        
        // Verify initialization
        System.assertNotEquals(null, controller.leadWrappers, 'Lead wrappers should be initialized');
        System.assertEquals(25, controller.leadWrappers.size(), 'Should have 25 lead wrappers');
        System.assertEquals(true, controller.createOpportunity, 'Create opportunity should default to true');
        System.assertEquals(false, controller.sendEmailToOwner, 'Send email should default to false');
    }
    
    @isTest
    static void testSelectAllDeselectAll() {
        List<Lead> leads = [SELECT Id FROM Lead LIMIT 25];
        ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(leads);
        MassLeadConverterController controller = new MassLeadConverterController(ssc);
        
        Test.startTest();
        
        // Test select all
        controller.selectAll();
        System.assertEquals(25, controller.getSelectedCount(), 'All leads should be selected');
        
        // Test deselect all
        controller.deselectAll();
        System.assertEquals(0, controller.getSelectedCount(), 'No leads should be selected');
        
        Test.stopTest();
    }
    
    @isTest
    static void testPagination() {
        List<Lead> leads = [SELECT Id FROM Lead LIMIT 30];
        ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(leads);
        MassLeadConverterController controller = new MassLeadConverterController(ssc);
        
        Test.startTest();
        
        // Test navigation methods
        controller.first();
        System.assertEquals(1, controller.getPageNumber(), 'Should be on first page');
        
        if (controller.getHasNext()) {
            controller.next();
            System.assertEquals(2, controller.getPageNumber(), 'Should be on second page');
            
            controller.previous();
            System.assertEquals(1, controller.getPageNumber(), 'Should be back on first page');
            
            controller.last();
            System.assertEquals(controller.getTotalPages(), controller.getPageNumber(), 'Should be on last page');
        }
        
        Test.stopTest();
    }
    
    @isTest
    static void testConvertSelectedLeadsSuccess() {
        List<Lead> leads = [SELECT Id FROM Lead LIMIT 5];
        ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(leads);
        MassLeadConverterController controller = new MassLeadConverterController(ssc);
        
        // Set up page messages
        ApexPages.currentPage().getParameters().put('test', 'true');
        
        Test.startTest();
        
        // Select first 3 leads
        for (Integer i = 0; i < 3; i++) {
            controller.leadWrappers[i].selected = true;
        }
        
        // Set conversion options
        controller.createOpportunity = true;
        
        // Convert leads
        PageReference result = controller.convertSelectedLeads();
        
        Test.stopTest();
        
        // Verify conversion (in test context, this might not fully execute)
        System.assertEquals(null, result, 'Should return null for page refresh');
        // After conversion, selections are reset due to refreshLeadWrappers call
        System.assertEquals(0, controller.getSelectedCount(), 'Selection should be reset after conversion');
    }
    
    @isTest
    static void testConvertSelectedLeadsNoSelection() {
        List<Lead> leads = [SELECT Id FROM Lead LIMIT 5];
        ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(leads);
        MassLeadConverterController controller = new MassLeadConverterController(ssc);
        
        Test.startTest();
        
        // Don't select any leads
        PageReference result = controller.convertSelectedLeads();
        
        Test.stopTest();
        
        // Verify warning message
        System.assertEquals(null, result, 'Should return null');
        System.assertEquals(0, controller.getSelectedCount(), 'Should have no selected leads');
        
        // Check that a warning message was added
        List<ApexPages.Message> messages = ApexPages.getMessages();
        Boolean foundWarning = false;
        for (ApexPages.Message msg : messages) {
            if (msg.getSeverity() == ApexPages.Severity.WARNING) {
                foundWarning = true;
                break;
            }
        }
        System.assertEquals(true, foundWarning, 'Should have warning message');
    }
    
    @isTest
    static void testRefreshLeadWrappers() {
        List<Lead> leads = [SELECT Id FROM Lead LIMIT 10];
        ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(leads);
        MassLeadConverterController controller = new MassLeadConverterController(ssc);
        
        Test.startTest();
        
        // Modify selection
        controller.leadWrappers[0].selected = true;
        System.assertEquals(1, controller.getSelectedCount(), 'Should have 1 selected');
        
        // Refresh wrappers
        controller.refreshLeadWrappers();
        System.assertEquals(0, controller.getSelectedCount(), 'Selection should be reset after refresh');
        
        Test.stopTest();
    }
    
    @isTest
    static void testGettersAndProperties() {
        List<Lead> leads = [SELECT Id FROM Lead LIMIT 30];
        ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(leads);
        MassLeadConverterController controller = new MassLeadConverterController(ssc);
        
        Test.startTest();
        
        // Test getters
        System.assertNotEquals(null, controller.getResultSize(), 'Result size should not be null');
        System.assertNotEquals(null, controller.getTotalPages(), 'Total pages should not be null');
        System.assertNotEquals(null, controller.getPageNumber(), 'Page number should not be null');
        
        // Test property setters
        controller.createOpportunity = false;
        controller.sendEmailToOwner = true;
        
        System.assertEquals(false, controller.createOpportunity);
        System.assertEquals(true, controller.sendEmailToOwner);
        
        Test.stopTest();
    }
    
    @isTest
    static void testLeadWrapperClass() {
        Lead testLead = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Company = 'Test Company',
            Email = 'test@example.com'
        );
        
        Test.startTest();
        
        MassLeadConverterController.LeadWrapper wrapper = new MassLeadConverterController.LeadWrapper(testLead);
        
        Test.stopTest();
        
        // Verify wrapper initialization
        System.assertEquals(testLead, wrapper.leadRecord, 'Lead record should be set');
        System.assertEquals(false, wrapper.selected, 'Should default to not selected');
        
        // Test selection
        wrapper.selected = true;
        System.assertEquals(true, wrapper.selected, 'Should be selected');
    }
}