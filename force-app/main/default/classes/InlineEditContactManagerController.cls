/**
 * @description Controller for Inline Edit Contact Manager Visualforce page
 * @author AI Assistant
 * @version 1.0
 */
public with sharing class InlineEditContactManagerController {
    
    // Constants
    private static final Integer RECORDS_PER_PAGE = 10;
    
    // Public properties for the page
    public String searchTerm { get; set; }
    public String selectedContactId { get; set; }
    public Integer currentPage { get; set; }
    public Integer totalPages { get; set; }
    public Boolean isFirstPage { get; set; }
    public Boolean isLastPage { get; set; }
    
    // Private properties
    private Integer totalRecords;
    private Map<Id, Contact> originalContacts;
    
    // Wrapper class for contact with editing state
    public class ContactWrapper {
        public Contact record { get; set; }
        public Boolean isEditing { get; set; }
        
        public ContactWrapper(Contact c) {
            this.record = c;
            this.isEditing = false;
        }
    }
    
    // Public properties
    public List<ContactWrapper> contacts { get; set; }
    
    /**
     * @description Constructor - initializes the controller
     */
    public InlineEditContactManagerController() {
        initializeController();
    }
    
    /**
     * @description Initialize controller properties and load initial data
     */
    private void initializeController() {
        searchTerm = '';
        currentPage = 1;
        originalContacts = new Map<Id, Contact>();
        
        loadContacts();
    }
    

    
    /**
     * @description Load contacts based on current search criteria and pagination
     */
    private void loadContacts() {
        try {
            // Build the SOQL query
            String query = buildContactQuery();
            
            // Get total count for pagination
            String countQuery = 'SELECT COUNT() FROM Contact WHERE ' + getWhereClause();
            totalRecords = Database.countQuery(countQuery);
            
            // Calculate pagination
            totalPages = Math.ceil((Decimal)totalRecords / RECORDS_PER_PAGE).intValue();
            if (totalPages == 0) totalPages = 1;
            
            isFirstPage = (currentPage == 1);
            isLastPage = (currentPage >= totalPages);
            
            // Add pagination to query
            query += ' LIMIT ' + RECORDS_PER_PAGE + ' OFFSET ' + ((currentPage - 1) * RECORDS_PER_PAGE);
            
            // Execute query
            List<Contact> contactList = Database.query(query);
            
            // Create wrappers and store originals
            contacts = new List<ContactWrapper>();
            originalContacts.clear();
            
            for (Contact c : contactList) {
                contacts.add(new ContactWrapper(c));
                originalContacts.put(c.Id, c.clone(true, true, true, true));
            }
            
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(
                ApexPages.Severity.ERROR, 
                'Error loading contacts: ' + e.getMessage()
            ));
        }
    }
    
    /**
     * @description Build the SOQL query for contacts
     * @return String - the complete SOQL query
     */
    private String buildContactQuery() {
        return 'SELECT Id, FirstName, LastName, Email, Phone, Title, Department, ' +
               'AccountId, Account.Name ' +
               'FROM Contact ' +
               'WHERE ' + getWhereClause() + ' ' +
               'ORDER BY LastName, FirstName';
    }
    
    /**
     * @description Build the WHERE clause for filtering
     * @return String - the WHERE clause
     */
    private String getWhereClause() {
        List<String> conditions = new List<String>();
        
        // Search term condition
        if (String.isNotBlank(searchTerm)) {
            String searchPattern = '%' + searchTerm + '%';
            conditions.add('(FirstName LIKE \'' + searchPattern + '\' OR LastName LIKE \'' + searchPattern + '\' OR Email LIKE \'' + searchPattern + '\')');
        }
        
        // If no conditions, return a default condition
        if (conditions.isEmpty()) {
            return 'Id != null';
        }
        
        return String.join(conditions, ' AND ');
    }
    
    /**
     * @description Search contacts based on current criteria
     * @return PageReference - null to stay on same page
     */
    public PageReference searchContacts() {
        currentPage = 1; // Reset to first page when searching
        loadContacts();
        return null;
    }
    
    /**
     * @description Toggle edit mode for a specific contact
     * @return PageReference - null to stay on same page
     */
    public PageReference toggleEditMode() {
        if (String.isBlank(selectedContactId)) {
            return null;
        }
        
        for (ContactWrapper wrapper : contacts) {
            if (wrapper.record.Id == selectedContactId) {
                if (wrapper.isEditing) {
                    // Save the contact
                    return saveContact(wrapper);
                } else {
                    // Enter edit mode
                    wrapper.isEditing = true;
                }
                break;
            }
        }
        
        return null;
    }
    
    /**
     * @description Save a contact record
     * @param wrapper - the contact wrapper to save
     * @return PageReference - null to stay on same page
     */
    private PageReference saveContact(ContactWrapper wrapper) {
        try {
            // Validate required fields
            if (String.isBlank(wrapper.record.LastName)) {
                ApexPages.addMessage(new ApexPages.Message(
                    ApexPages.Severity.ERROR, 
                    'Last Name is required'
                ));
                return null;
            }
            
            // Validate email format if provided
            if (String.isNotBlank(wrapper.record.Email) && 
                !Pattern.matches('[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,4}', wrapper.record.Email)) {
                ApexPages.addMessage(new ApexPages.Message(
                    ApexPages.Severity.ERROR, 
                    'Please enter a valid email address'
                ));
                return null;
            }
            
            // Update the contact
            update wrapper.record;
            
            // Exit edit mode
            wrapper.isEditing = false;
            
            // Update original contact
            originalContacts.put(wrapper.record.Id, wrapper.record.clone(true, true, true, true));
            
            ApexPages.addMessage(new ApexPages.Message(
                ApexPages.Severity.CONFIRM, 
                'Contact updated successfully'
            ));
            
        } catch (DmlException e) {
            ApexPages.addMessage(new ApexPages.Message(
                ApexPages.Severity.ERROR, 
                'Error updating contact: ' + e.getDmlMessage(0)
            ));
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(
                ApexPages.Severity.ERROR, 
                'Error updating contact: ' + e.getMessage()
            ));
        }
        
        return null;
    }
    
    /**
     * @description Cancel edit mode for a contact
     * @return PageReference - null to stay on same page
     */
    public PageReference cancelEdit() {
        if (String.isBlank(selectedContactId)) {
            return null;
        }
        
        for (ContactWrapper wrapper : contacts) {
            if (wrapper.record.Id == selectedContactId) {
                // Restore original values
                Contact original = originalContacts.get(wrapper.record.Id);
                if (original != null) {
                    wrapper.record.FirstName = original.FirstName;
                    wrapper.record.LastName = original.LastName;
                    wrapper.record.Email = original.Email;
                    wrapper.record.Phone = original.Phone;
                    wrapper.record.Title = original.Title;
                    wrapper.record.Department = original.Department;
                    wrapper.record.AccountId = original.AccountId;
                }
                
                // Exit edit mode
                wrapper.isEditing = false;
                break;
            }
        }
        
        return null;
    }
    
    /**
     * @description Navigate to previous page
     * @return PageReference - null to stay on same page
     */
    public PageReference previous() {
        if (currentPage > 1) {
            currentPage--;
            loadContacts();
        }
        return null;
    }
    
    /**
     * @description Navigate to next page
     * @return PageReference - null to stay on same page
     */
    public PageReference next() {
        if (currentPage < totalPages) {
            currentPage++;
            loadContacts();
        }
        return null;
    }
    
    /**
     * @description Get the total number of records
     * @return Integer - total number of records
     */
    public Integer getTotalRecords() {
        return totalRecords;
    }
} 