/*----------------------------------------------------------------------------------------------------------------------------------------------
Author:     Mani Sundaresan
Description:  Test class to validate CSRIntake, CustomerServiceReport pages and CSRController class.
Tests Excecuted:
        
         init - verifies that the test data gets created successfully
        
History:
<Date>      <Authors Name>    <Brief Description of Change>
05/04/2017  Mani Sundaresan    Initial Creation(US2248)
12/18/2017  Kasmoor Reddy      made some enhancements to increase code coverage as part of US-0003783.
-------------------------------------------------------------------------------------------------------------------------------------------------*/
@isTest
private class Test_CSRController{

    private static Configuration_Settings__c orgDefaults;
    private static Account custAccount;
    private static Account siteAccount;
    private static Contact defaultContact;
    private static List<Product2> products;
    private static List<Asset> assets;
    private static List<Case> cases = new List<Case>();
    private static List<Task> taskList = new List<Task>();
    private static List<WorkOrder> woList = new List<WorkOrder>();
    private static List<WorkOrderLineItem> woliList = new List<WorkOrderLineItem>();
    private static Pricebook2 pricebook;
    static PageReference pageRef;
    static PageReference pageRef2;
    static CSRController csr;
     static User otherUser;
    
    
    static{
        orgDefaults = TestUtility.setupConfigurationSettings();
        
        TestUtility.insertCustSetting('CaseTrigger');
        
        insert new CSRWOTypes__c(Name='B&SH FE Service',RecordType_Name__c='B&SH FE Service', RecordType_Id__c= GlobalUtility.getRecordTypeId('WorkOrder', 'B_SH_FE_Service'));
        insert new CSRWOTypes__c(Name='B&SH Billable PM',RecordType_Name__c='B&SH Billable PM', RecordType_Id__c=GlobalUtility.getRecordTypeId('WorkOrder', 'B_SH_Billable_PM'));
        
        insert new CSRTypes__c(Name='B&SH Service',RecordType_Name__c='B&SH Service',RecordType_Id__c=GlobalUtility.getRecordTypeId('Case', 'B_SH_Service'));
        
        insert new CSRPriority__c(Name='Sev 1',Case_Priority__c='Sev 1');
        
         //insert an User
        otherUser = TestUtility.newUser(UserInfo.getProfileId(), 'other');
        insert otherUser;
        
        // insert pricebooks
        pricebook = TestUtility.newPricebook('Test Pricebook');
        insert new List<Pricebook2> {pricebook}; 
        
        // insert an account
        custAccount = TestUtility.newAccount('Customer Account', 'testCust', 'ABC Street', null, GlobalUtility.getRecordTypeId('Account', 'Customer'));
        custAccount.BillingCountryCode = 'US';
        custAccount.BillingStateCode = 'NY';        
        insert new List<Account>{custAccount};
        
        siteAccount = TestUtility.newAccount('Site Account', 'testSite', 'ABC Street', custAccount.Id, GlobalUtility.getRecordTypeId('Account', 'Site'));
        siteAccount.BillingCountryCode = 'US';
        siteAccount.BillingStateCode = 'NY';            
        insert siteAccount;
        
        // update org defaults
        orgDefaults.Default_B_SH_Parts_Pricebook2Id__c = pricebook.Id;
        
        defaultContact = TestUtility.newContact('Default', 'Contact', custAccount.Id);
        
        insert new List<Contact>{defaultContact};
        
        Product2 prod = TestUtility.newProduct('Product 03');
        insert prod;
        
        products = new List<Product2>();
        products.add(TestUtility.newProduct('Product 01'));
        products.add(TestUtility.newProduct('Product 02'));
        products[0].PM_Product__c = prod.Id;
        products[1].PM_Product__c = prod.Id;
        insert products;
        
        
        update products[0];
        update products[1];
        
        List<PriceBookEntry> pbeList = new List<PriceBookEntry>();
        for(Product2 pd : products){
            PriceBookEntry pbe = new PriceBookEntry();
            pbe.Product2Id = pd.Id;
            pbe.Pricebook2Id = pricebook.Id;
            pbe.unitprice=1.0;
            pbe.isActive = true;
            pbeList.add(pbe);
        }
        insert pbeList;
        
        assets = new List<Asset>();
        //for(Integer i = 0; i < 10; i++){
        
        Asset sys1 = TestUtility.newAsset(siteAccount.Name + ' Asset 01', siteAccount.Id, custAccount.Id, products[0].Id);
        sys1.ContactId = defaultContact.Id;
        Asset sys2 = TestUtility.newAsset(siteAccount.Name + ' Asset 02', siteAccount.Id, custAccount.Id, products[1].Id);
        sys2.ContactId = defaultContact.Id;
        assets.add(sys1);
        assets.add(sys2);
        //}
        insert assets;
        
        Asset_Attribute__c assetAttribute = new Asset_Attribute__c(Name='Software Version',Asset__c=assets[0].Id,Category__c = 'SOFTWARE');
        insert assetAttribute;
        
        System.runAs(otherUser){
        
        //for(Asset a : assets){
            Case nonBillableCase = TestUtility.newCase(siteAccount.Id, null, assets[0].Id, null, GlobalUtility.getRecordTypeId('Case', 'B_SH_Service'), 'Service', 'New', 'Low', 'Phone');
            nonBillableCase.Priority = 'Sev 1';
            nonBillableCase.Bill_to_Customer__c = custAccount.Id;
            nonBillableCase.Customer_Name__c = custAccount.Id;
            nonBillableCase.Subject = 'Test Subject';
            cases.add(nonBillableCase);
            
            Case nonBillableCase2 = TestUtility.newCase(siteAccount.Id, null, assets[0].Id, null, GlobalUtility.getRecordTypeId('Case', 'B_SH_Service'), 'Service', 'New', 'Low', 'Phone');
            nonBillableCase2.Bill_to_Customer__c = custAccount.Id;
            nonBillableCase2.Customer_Name__c = custAccount.Id;
            nonBillableCase2.Subject = 'Test Subject';
            nonBillableCase2.De_Installed_Asset__c = assets[1].Id;
            nonBillableCase2.Priority = 'Sev 1';
            cases.add(nonBillableCase2);
            
            Case nonBillableCase3 = TestUtility.newCase(siteAccount.Id, null, assets[0].Id, null, GlobalUtility.getRecordTypeId('Case', 'B_SH_Service'), 'Service', 'New', 'Low', 'Phone');
            nonBillableCase3.Bill_to_Customer__c = custAccount.Id;
            nonBillableCase3.Customer_Name__c = custAccount.Id;
            nonBillableCase3.Subject = 'Test Subject';
            //nonBillableCase3.De_Installed_Asset__c = assets[1].Id;
            nonBillableCase3.Priority = 'Sev 1';
            cases.add(nonBillableCase3);
        //}
        insert cases;
        
        
        Task t1 = TestUtility.newTask('Test',cases[0].Id);
        t1.Note_Type__c = 'FE Resolution';
        taskList.add(t1);
        
        
        Task t2 = TestUtility.newTask('Test',cases[1].Id);
        t2.Note_Type__c = 'Resolution';
        taskList.add(t2);
        
        insert taskList;
        
        WorkOrder wo1 = TestUtility.newWorkOrder(custAccount.Id,cases[0].Id,assets[0].id,GlobalUtility.getRecordTypeId('WorkOrder', 'B_SH_FE_Service'),'New');
        woList.add(wo1);
        
        WorkOrder wo2 = TestUtility.newWorkOrder(siteAccount.Id,cases[1].Id,assets[1].id,GlobalUtility.getRecordTypeId('WorkOrder', 'B_SH_FE_Service'),'New');
        woList.add(wo2);
        
        insert woList;
        
        WorkOrderLineItem wlitm1 = TestUtility.newWorkOrderLineItem(woList[0].Id, assets[0].id, GlobalUtility.getRecordTypeId('WorkOrderLineItem', 'B_SH_Add_a_Part'), 'New');
        woliList.add(wlitm1);
        
        WorkOrderLineItem wlitm2 = TestUtility.newWorkOrderLineItem(woList[1].Id, assets[1].id, GlobalUtility.getRecordTypeId('WorkOrderLineItem', 'B_SH_Add_a_Part'), 'New');
        woliList.add(wlitm2);
        
        insert woliList;
        
        }
        
        
        
        }
        
        static testMethod void test_fromCustomerAccount(){
        
            pageRef = Page.CSRIntakeForm;
            Test.setCurrentPage(pageRef);
         
            ApexPages.StandardController con = new ApexPages.StandardController(custAccount);
            ApexPages.currentPage().getParameters().put('Id',custAccount.id);
            ApexPages.currentPage().getParameters().put('RecordType','Customer');
            csr = new CSRController();
        }
        
        static testMethod void test_fromSiteAccount(){
            pageRef = Page.CSRIntakeForm;
            Test.setCurrentPage(pageRef);
         
            ApexPages.StandardController con = new ApexPages.StandardController(siteAccount);
            ApexPages.currentPage().getParameters().put('Id',siteAccount.id);
            ApexPages.currentPage().getParameters().put('RecordType','Site');
            csr = new CSRController();
        }
        
        static testMethod void test_fromAsset(){
            pageRef = Page.CSRIntakeForm;
            Test.setCurrentPage(pageRef);
         
            ApexPages.StandardController con = new ApexPages.StandardController(assets[0]);
            ApexPages.currentPage().getParameters().put('Id',assets[0].id);
            ApexPages.currentPage().getParameters().put('AssetId',assets[0].id);
            ApexPages.currentPage().getParameters().put('Selected','true');
            //ApexPages.currentPage().getParameters().put('Master','true');
            ApexPages.currentPage().getParameters().put('caseMasterChkBox','true');
            
            csr = new CSRController(); 
            csr.setSelected(); 
            csr.setCaseSelected();
            
            
        }
        
        static testMethod void test_fromCase(){
            pageRef = Page.CSRIntakeForm;
            Test.setCurrentPage(pageRef);
         
            ApexPages.StandardController con = new ApexPages.StandardController(cases[0]);
            ApexPages.currentPage().getParameters().put('Id',cases[0].id);
            ApexPages.currentPage().getParameters().put('CaseId',cases[0].id);
            ApexPages.currentPage().getParameters().put('master','Master');
            CSRController.case_Wrapper caseWrap = new CSRController.case_Wrapper(cases[0],true,null,null);
            caseWrap.selected = true;
            csr = new CSRController(); 
            csr.caseMasterChkBox = true;   
            csr.setCaseSelected();
            csr.selectedCaseTypes.add(new SelectOption('High', 'High'));
            csr.servStartDate = system.today();
            csr.servEndDate = system.today()+1;
            csr.selectedRTs.add(new SelectOption(GlobalUtility.getRecordTypeId('Case', 'B_SH_Service'), GlobalUtility.getRecordTypeId('Case', 'B_SH_Service')));
            csr.filterCaseRecs();
            csr.generateReport();
            csr.Cancel();
            
            
            ApexPages.currentPage().getParameters().put('selectedCaseTypes','Other');
            ApexPages.currentPage().getParameters().put('selectedRTs','B&SH Service');
            CSRController.case_Wrapper caseWrap1 = new CSRController.case_Wrapper(cases[1],true,null,null);
            caseWrap1.selected = true;
            
            csr = new CSRController();    
            csr.setCaseSelected();
            csr.caseMasterChkBox = true;
            csr.filterCaseRecs();
            csr.generateReport();
            csr.Cancel();
            
            
        }
}