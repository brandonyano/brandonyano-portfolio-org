/**
 * Mass Lead Converter Controller
 * Uses StandardSetController to manage Lead records for bulk conversion
 */
public with sharing class MassLeadConverterController {
    
    private ApexPages.StandardSetController standardController;
    private final Integer pageSize = 25;  // Page size constant
    
    // Properties for default conversion settings
    public Boolean createOpportunity { get; set; }
    public Boolean sendEmailToOwner { get; set; }
    
    // Wrapper class for Lead rows with selection checkbox
    public class LeadWrapper {
        public Boolean selected { get; set; }
        public Lead leadRecord { get; set; }
        
        public LeadWrapper(Lead lead) {
            this.leadRecord = lead;
            this.selected = false;
        }
    }
    
    public List<LeadWrapper> leadWrappers { get; set; }
    
    // Simplified Constructor
    public MassLeadConverterController(ApexPages.StandardSetController controller) {
        // Set up custom query to exclude converted leads
        String query = 'SELECT Id, FirstName, LastName, Company, Email, Phone, Status, LeadSource, Owner.Name, CreatedDate FROM Lead WHERE IsConverted = false ORDER BY CreatedDate DESC';
        this.standardController = new ApexPages.StandardSetController(Database.getQueryLocator(query));
        this.standardController.setPageSize(pageSize);
        
        // Initialize default values
        this.createOpportunity = true;
        this.sendEmailToOwner = false;
        
        // Initialize wrapper list
        refreshLeadWrappers();
    }
    
    /**
     * Refresh the lead wrapper list from current page records
     */
    public void refreshLeadWrappers() {
        leadWrappers = new List<LeadWrapper>();
        List<Lead> currentPageLeads = (List<Lead>) standardController.getRecords();
        
        for (Lead lead : currentPageLeads) {
            leadWrappers.add(new LeadWrapper(lead));
        }
    }
    
    /**
     * Simple refresh - just refresh current page wrappers
     */
    public void refreshAfterConversion() {
        // Simple approach: just refresh the wrappers for current page
        refreshLeadWrappers();
    }
    
    /**
     * Select/Deselect all leads on current page
     */
    public void selectAll() {
        for (LeadWrapper wrapper : leadWrappers) {
            wrapper.selected = true;
        }
    }
    
    public void deselectAll() {
        for (LeadWrapper wrapper : leadWrappers) {
            wrapper.selected = false;
        }
    }
    
    /**
     * Get count of selected leads
     */
    public Integer getSelectedCount() {
        Integer count = 0;
        for (LeadWrapper wrapper : leadWrappers) {
            if (wrapper.selected) {
                count++;
            }
        }
        return count;
    }
    
    /**
     * Bulk convert selected leads
     */
    public PageReference convertSelectedLeads() {
        // Add immediate feedback to confirm method is called
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Processing conversion request...'));
        
        List<LeadWrapper> selectedWrappers = new List<LeadWrapper>();
        
        // Collect selected leads
        for (LeadWrapper wrapper : leadWrappers) {
            if (wrapper.selected) {
                selectedWrappers.add(wrapper);
            }
        }
        
        if (selectedWrappers.isEmpty()) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 'Please select at least one lead to convert.'));
            return null;
        }
        
        // Get the converted status from Lead object
        String convertedStatus = getLeadConvertedStatus();
        
        // Prepare lead conversion
        List<Database.LeadConvert> leadConverts = new List<Database.LeadConvert>();
        
        for (LeadWrapper wrapper : selectedWrappers) {
            Database.LeadConvert lc = new Database.LeadConvert();
            lc.setLeadId(wrapper.leadRecord.Id);
            lc.setConvertedStatus(convertedStatus);
            
            // Set conversion options
            lc.setDoNotCreateOpportunity(!createOpportunity);
            lc.setSendNotificationEmail(sendEmailToOwner);
            
            // Set owner ID (required for conversion)
            lc.setOwnerId(UserInfo.getUserId());
            
            leadConverts.add(lc);
        }
        
        // Perform bulk conversion
        try {
            List<Database.LeadConvertResult> results = Database.convertLead(leadConverts, false);
            
            Integer successCount = 0;
            Integer errorCount = 0;
            List<String> errors = new List<String>();
            
            for (Integer i = 0; i < results.size(); i++) {
                Database.LeadConvertResult result = results[i];
                if (result.isSuccess()) {
                    successCount++;
                } else {
                    errorCount++;
                    String leadName = selectedWrappers[i].leadRecord.FirstName + ' ' + selectedWrappers[i].leadRecord.LastName;
                    for (Database.Error error : result.getErrors()) {
                        errors.add('Lead ' + leadName + ': ' + error.getMessage());
                    }
                }
            }
            
            // Display results with proper user feedback
            if (successCount > 0) {
                String successMsg = successCount + ' lead(s) converted successfully';
                if (createOpportunity) {
                    successMsg += ' with opportunities created';
                }
                successMsg += '.';
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, successMsg));
            }
            
            if (errorCount > 0) {
                for (String errorMsg : errors) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errorMsg));
                }
            }
            
            // Simple refresh after conversion
            refreshAfterConversion();
            
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 
                'Error converting leads: ' + e.getMessage()));
        }
        
        return null;
    }
    

    
    /**
     * Simplified helper method to get the converted status for leads
     */
    private String getLeadConvertedStatus() {
        // Simple approach: try common values, fallback to 'Qualified'
        List<String> commonStatuses = new List<String>{'Closed - Converted', 'Converted', 'Qualified'};
        
        Schema.DescribeFieldResult fieldResult = Lead.Status.getDescribe();
        List<Schema.PicklistEntry> picklistValues = fieldResult.getPicklistValues();
        
        for (String status : commonStatuses) {
            for (Schema.PicklistEntry entry : picklistValues) {
                if (entry.isActive() && entry.getValue().equals(status)) {
                    return entry.getValue();
                }
            }
        }
        
        return 'Qualified'; // Safe fallback
    }
    
    /**
     * Navigation methods for StandardSetController
     */
    public void first() {
        standardController.first();
        refreshLeadWrappers();
    }
    
    public void previous() {
        standardController.previous();
        refreshLeadWrappers();
    }
    
    public void next() {
        standardController.next();
        refreshLeadWrappers();
    }
    
    public void last() {
        standardController.last();
        refreshLeadWrappers();
    }
    
    // Getters for pagination info
    public Boolean getHasPrevious() {
        return standardController.getHasPrevious();
    }
    
    public Boolean getHasNext() {
        return standardController.getHasNext();
    }
    
    public Integer getPageNumber() {
        return standardController.getPageNumber();
    }
    
    public Integer getTotalPages() {
        Integer totalRecords = standardController.getResultSize();
        Integer pageSize = standardController.getPageSize();
        return (Integer) Math.ceil((Decimal) totalRecords / pageSize);
    }
    
    public Integer getResultSize() {
        return standardController.getResultSize();
    }
}