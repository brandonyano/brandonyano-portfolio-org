/**
 * @description Controller for the Two-Step Opportunity Creation Wizard
 * @author AI Assistant
 * @version 1.0
 */
public with sharing class OpportunityWizardController {
    
    // Step management
    public Integer currentStep { get; set; }
    public Boolean isStep1 { get { return currentStep == 1; } }
    public Boolean isStep2 { get { return currentStep == 2; } }
    public Boolean isStep3 { get { return currentStep == 3; } }
    
    // Opportunity data
    public Opportunity newOpportunity { get; set; }
    public Account selectedAccount { get; set; }
    public Contact selectedContact { get; set; }
    
    // Product selection
    public List<PricebookEntry> availableProducts { get; set; }
    public List<OpportunityLineItemWrapper> selectedProducts { get; set; }
    public Map<Id, PricebookEntry> productMap { get; set; }
    
    // Search and filtering
    public String accountSearchTerm { get; set; }
    public String contactSearchTerm { get; set; }
    public String productSearchTerm { get; set; }
    public List<Account> searchAccounts { get; set; }
    public List<Contact> searchContacts { get; set; }
    public String selectedAccountId { get; set; }
    public String selectedContactId { get; set; }
    
    // Messages
    public String message { get; set; }
    public String messageType { get; set; }
    
    /**
     * @description Constructor - initializes the wizard
     */
    public OpportunityWizardController() {
        initializeWizard();
    }
    
    /**
     * @description Initialize wizard state and data
     */
    private void initializeWizard() {
        currentStep = 1;
        newOpportunity = new Opportunity();
        newOpportunity.CloseDate = Date.today().addDays(30);
        newOpportunity.StageName = 'Prospecting';
        
        selectedProducts = new List<OpportunityLineItemWrapper>();
        productMap = new Map<Id, PricebookEntry>();
        
        loadAvailableProducts();
    }
    
    /**
     * @description Load available products from the standard price book
     */
    private void loadAvailableProducts() {
        try {
            availableProducts = [
                SELECT Id, Name, Product2Id, Product2.Name, Product2.Description, 
                       UnitPrice, Product2.ProductCode
                FROM PricebookEntry 
                WHERE Pricebook2.IsStandard = true 
                AND IsActive = true 
                AND Product2.IsActive = true
                ORDER BY Product2.Name
                LIMIT 100
            ];
            
            for (PricebookEntry pbe : availableProducts) {
                productMap.put(pbe.Id, pbe);
            }
        } catch (Exception e) {
            addMessage('Error loading products: ' + e.getMessage(), 'error');
        }
    }
    
    /**
     * @description Search for accounts based on search term
     */
    public void searchAccounts() {
        if (String.isBlank(accountSearchTerm)) {
            searchAccounts = new List<Account>();
            return;
        }
        
        try {
            String searchPattern = '%' + accountSearchTerm + '%';
            searchAccounts = [
                SELECT Id, Name, BillingCity, BillingState, Phone, Type
                FROM Account 
                WHERE Name LIKE :searchPattern
                ORDER BY Name
                LIMIT 10
            ];
        } catch (Exception e) {
            addMessage('Error searching accounts: ' + e.getMessage(), 'error');
        }
    }
    
    /**
     * @description Search for contacts based on search term
     */
    public void searchContacts() {
        if (String.isBlank(contactSearchTerm)) {
            searchContacts = new List<Contact>();
            return;
        }
        
        try {
            String searchPattern = '%' + contactSearchTerm + '%';
            searchContacts = [
                SELECT Id, Name, Email, Phone, Title, Account.Name
                FROM Contact 
                WHERE Name LIKE :searchPattern
                ORDER BY Name
                LIMIT 10
            ];
        } catch (Exception e) {
            addMessage('Error searching contacts: ' + e.getMessage(), 'error');
        }
    }
    
    /**
     * @description Select an account for the opportunity
     */
    public void selectAccount() {
        String accountId = ApexPages.currentPage().getParameters().get('accountId');
        if (String.isNotBlank(accountId)) {
            try {
                selectedAccount = [SELECT Id, Name, BillingCity, BillingState, Phone, Type 
                                  FROM Account WHERE Id = :accountId];
                newOpportunity.AccountId = selectedAccount.Id;
                addMessage('Account selected: ' + selectedAccount.Name, 'success');
            } catch (Exception e) {
                addMessage('Error selecting account: ' + e.getMessage(), 'error');
            }
        }
    }
    
    /**
     * @description Select an account for the opportunity (overloaded for direct ID)
     */
    public void selectAccountById() {
        String accountId = ApexPages.currentPage().getParameters().get('selectedAccountId');
        if (String.isNotBlank(accountId)) {
            try {
                selectedAccount = [SELECT Id, Name, BillingCity, BillingState, Phone, Type 
                                  FROM Account WHERE Id = :accountId];
                newOpportunity.AccountId = selectedAccount.Id;
                addMessage('Account selected: ' + selectedAccount.Name, 'success');
            } catch (Exception e) {
                addMessage('Error selecting account: ' + e.getMessage(), 'error');
            }
        }
    }
    
    /**
     * @description Select a contact for the opportunity
     */
    public void selectContact() {
        String contactId = ApexPages.currentPage().getParameters().get('contactId');
        if (String.isNotBlank(contactId)) {
            try {
                selectedContact = [SELECT Id, Name, Email, Phone, Title, Account.Name 
                                  FROM Contact WHERE Id = :contactId];
                addMessage('Contact selected: ' + selectedContact.Name, 'success');
            } catch (Exception e) {
                addMessage('Error selecting contact: ' + e.getMessage(), 'error');
            }
        }
    }
    
    /**
     * @description Select a contact for the opportunity (overloaded for direct ID)
     */
    public void selectContactById() {
        String contactId = ApexPages.currentPage().getParameters().get('selectedContactId');
        if (String.isNotBlank(contactId)) {
            try {
                selectedContact = [SELECT Id, Name, Email, Phone, Title, Account.Name 
                                  FROM Contact WHERE Id = :contactId];
                addMessage('Contact selected: ' + selectedContact.Name, 'success');
            } catch (Exception e) {
                addMessage('Error selecting contact: ' + e.getMessage(), 'error');
            }
        }
    }
    
    /**
     * @description Add a product to the opportunity
     */
    public void addProduct() {
        String productId = ApexPages.currentPage().getParameters().get('productId');
        if (String.isNotBlank(productId) && productMap.containsKey(productId)) {
            PricebookEntry pbe = productMap.get(productId);
            
            // Check if product is already added
            for (OpportunityLineItemWrapper wrapper : selectedProducts) {
                if (wrapper.pricebookEntryId == productId) {
                    addMessage('Product already added to opportunity', 'warning');
                    return;
                }
            }
            
            OpportunityLineItemWrapper wrapper = new OpportunityLineItemWrapper();
            wrapper.pricebookEntryId = productId;
            wrapper.productName = pbe.Product2.Name;
            wrapper.unitPrice = pbe.UnitPrice;
            wrapper.quantity = 1;
            wrapper.totalPrice = pbe.UnitPrice;
            
            selectedProducts.add(wrapper);
            addMessage('Product added: ' + pbe.Product2.Name, 'success');
        }
    }
    
    /**
     * @description Remove a product from the opportunity
     */
    public void removeProduct() {
        String productId = ApexPages.currentPage().getParameters().get('productId');
        if (String.isNotBlank(productId)) {
            for (Integer i = 0; i < selectedProducts.size(); i++) {
                if (selectedProducts[i].pricebookEntryId == productId) {
                    selectedProducts.remove(i);
                    addMessage('Product removed', 'success');
                    break;
                }
            }
        }
    }
    
    /**
     * @description Update product quantities and recalculate totals
     */
    public void updateProductQuantities() {
        for (OpportunityLineItemWrapper wrapper : selectedProducts) {
            wrapper.totalPrice = wrapper.unitPrice * wrapper.quantity;
        }
    }
    
    /**
     * @description Validate step 1 data
     */
    private Boolean validateStep1() {
        if (String.isBlank(newOpportunity.Name)) {
            addMessage('Opportunity Name is required', 'error');
            return false;
        }
        if (newOpportunity.CloseDate == null) {
            addMessage('Close Date is required', 'error');
            return false;
        }
        if (newOpportunity.CloseDate < Date.today()) {
            addMessage('Close Date cannot be in the past', 'error');
            return false;
        }
        if (newOpportunity.AccountId == null) {
            addMessage('Please select an Account', 'error');
            return false;
        }
        return true;
    }
    
    /**
     * @description Validate step 2 data
     */
    private Boolean validateStep2() {
        if (selectedProducts.isEmpty()) {
            addMessage('Please add at least one product', 'error');
            return false;
        }
        
        for (OpportunityLineItemWrapper wrapper : selectedProducts) {
            if (wrapper.quantity <= 0) {
                addMessage('Product quantity must be greater than 0', 'error');
                return false;
            }
        }
        return true;
    }
    
    /**
     * @description Navigate to next step
     */
    public PageReference nextStep() {
        if (currentStep == 1) {
            if (!validateStep1()) {
                return null;
            }
            currentStep = 2;
        } else if (currentStep == 2) {
            if (!validateStep2()) {
                return null;
            }
            currentStep = 3;
        }
        return null;
    }
    
    /**
     * @description Navigate to previous step
     */
    public PageReference previousStep() {
        if (currentStep > 1) {
            currentStep--;
        }
        return null;
    }
    
    /**
     * @description Save the opportunity and line items
     */
    public PageReference saveOpportunity() {
        try {
            // Set default values
            if (String.isBlank(newOpportunity.Type)) {
                newOpportunity.Type = 'New Customer';
            }
            
            // Insert opportunity
            insert newOpportunity;
            
            // Create opportunity line items
            List<OpportunityLineItem> lineItems = new List<OpportunityLineItem>();
            for (OpportunityLineItemWrapper wrapper : selectedProducts) {
                OpportunityLineItem oli = new OpportunityLineItem();
                oli.OpportunityId = newOpportunity.Id;
                oli.PricebookEntryId = wrapper.pricebookEntryId;
                oli.Quantity = wrapper.quantity;
                oli.TotalPrice = wrapper.totalPrice;
                lineItems.add(oli);
            }
            
            if (!lineItems.isEmpty()) {
                insert lineItems;
            }
            
            addMessage('Opportunity created successfully!', 'success');
            
            // Redirect to the new opportunity
            PageReference oppPage = new PageReference('/' + newOpportunity.Id);
            oppPage.setRedirect(true);
            return oppPage;
            
        } catch (Exception e) {
            addMessage('Error creating opportunity: ' + e.getMessage(), 'error');
            return null;
        }
    }
    
    /**
     * @description Add a message to display to the user
     */
    private void addMessage(String msg, String type) {
        message = msg;
        messageType = type;
    }
    
    /**
     * @description Get total opportunity amount
     */
    public Decimal getTotalAmount() {
        Decimal total = 0;
        for (OpportunityLineItemWrapper wrapper : selectedProducts) {
            total += wrapper.totalPrice;
        }
        return total;
    }
    
    /**
     * @description Get filtered products based on search term
     */
    public List<PricebookEntry> getFilteredProducts() {
        if (String.isBlank(productSearchTerm)) {
            return availableProducts;
        }
        
        List<PricebookEntry> filtered = new List<PricebookEntry>();
        String searchPattern = productSearchTerm.toLowerCase();
        
        for (PricebookEntry pbe : availableProducts) {
            if (pbe.Product2.Name.toLowerCase().contains(searchPattern) ||
                (pbe.Product2.Description != null && pbe.Product2.Description.toLowerCase().contains(searchPattern))) {
                filtered.add(pbe);
            }
        }
        
        return filtered;
    }
    
    /**
     * @description Wrapper class for opportunity line items
     */
    public class OpportunityLineItemWrapper {
        public String pricebookEntryId { get; set; }
        public String productName { get; set; }
        public Decimal unitPrice { get; set; }
        public Integer quantity { get; set; }
        public Decimal totalPrice { get; set; }
        
        public OpportunityLineItemWrapper() {
            quantity = 1;
            unitPrice = 0;
            totalPrice = 0;
        }
    }
} 