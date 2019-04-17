/*----------------------------------------------------------------------------------------------------------------------------------------------
Author:     Mani Sundaresan
Description:  Test class to validate CSRIntake, CustomerServiceReport pages and New_CSRController class.
Tests Excecuted:
        
         init - verifies that the test data gets created successfully
        
History:
<Date>      <Authors Name>    <Brief Description of Change>
05/04/2017  Mani Sundaresan    Initial Creation(US2248)
12/18/2017  Kasmoor Reddy      made some enhancements to increase code coverage as part of US-0003783.

06/20/2018   Ryan Lambert    Remove all code / reference to FSLIS
-------------------------------------------------------------------------------------------------------------------------------------------------*/
@isTest
private class test_CSRControllerMerge{

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
    static CSRControllerMerge csr;
     static User otherUser;
    
    
    static{
        orgDefaults = TestUtility.setupConfigurationSettings();
        
        TestUtility.insertCustSetting('CaseTrigger');

// ADDED BY RL - REQUIRED TO PASS
        TestUtility.insertCustSetting('sitelocTrigger');
// END ADDITION BY RL
        
        insert new CSRWOTypes__c(Name='B&SH FE Service',RecordType_Name__c='B&SH FE Service', RecordType_Id__c= GlobalUtility.getRecordTypeId('WorkOrder', 'B_SH_FE_Service'));
        insert new CSRWOTypes__c(Name='B&SH Billable PM',RecordType_Name__c='B&SH Billable PM', RecordType_Id__c=GlobalUtility.getRecordTypeId('WorkOrder', 'B_SH_Billable_PM'));
         insert new CSRWOTypes__c(Name='PM',RecordType_Name__c='PM', RecordType_Id__c=GlobalUtility.getRecordTypeId('WorkOrder', 'B_SH_PM'));
        
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
        defaultContact.Phone = '+(999) 999-9999';
        
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
         Asset sys3 = TestUtility.newAsset(siteAccount.Name + ' Asset 02', siteAccount.Id, custAccount.Id, products[1].Id);
        sys3.ContactId = defaultContact.Id;
        assets.add(sys1);
        assets.add(sys2);
        assets.add(sys3);
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
            nonBillableCase.PO_Number__c = '1234';
            nonBillableCase.PO_Cap__c = 'ABCD';
            nonBillableCase.status='Closed';
            cases.add(nonBillableCase);
            
            Case nonBillableCase2 = TestUtility.newCase(siteAccount.Id, null, assets[0].Id, null, GlobalUtility.getRecordTypeId('Case', 'B_SH_Service'), 'Service', 'New', 'Low', 'Phone');
            nonBillableCase2.Bill_to_Customer__c = custAccount.Id;
            nonBillableCase2.Customer_Name__c = custAccount.Id;
            nonBillableCase2.Subject = 'Test Subject';
            nonBillableCase2.PO_Number__c = '1234';
            nonBillableCase2.PO_Cap__c = 'ABCD';
            nonBillableCase2.status='Closed';
            nonBillableCase2.De_Installed_Asset__c = assets[1].Id;
            nonBillableCase2.Priority = 'Patient on Table';
            cases.add(nonBillableCase2);
            
            Case nonBillableCase3 = TestUtility.newCase(siteAccount.Id, null,null, null, GlobalUtility.getRecordTypeId('Case', 'B_SH_Service'), 'Service', 'New', 'Low', 'Phone');
            nonBillableCase3.Bill_to_Customer__c = custAccount.Id;
            nonBillableCase3.Customer_Name__c = custAccount.Id;
            nonBillableCase3.Subject = 'Test Subject';
            nonBillableCase3.PO_Number__c = '1234';
            nonBillableCase3.status='Closed';
            nonBillableCase3.PO_Cap__c = 'ABCD';
            //nonBillableCase3.De_Installed_Asset__c = assets[1].Id;
            nonBillableCase3.Priority = 'Sev 1';
            cases.add(nonBillableCase3);
            Case nonBillableCase4 = TestUtility.newCase(siteAccount.Id, null,assets[1].Id, null, GlobalUtility.getRecordTypeId('Case', 'B_SH_Service'), 'Service', 'New', 'Low', 'Phone');
            nonBillableCase4.Bill_to_Customer__c = custAccount.Id;
            nonBillableCase4.Customer_Name__c = custAccount.Id;
            nonBillableCase4.Subject = 'Test Subject';
            nonBillableCase4.status='Closed';
            nonBillableCase4.PO_Number__c = '1234';
            nonBillableCase4.PO_Cap__c = 'ABCD';
            //nonBillableCase3.De_Installed_Asset__c = assets[1].Id;
            nonBillableCase4.Priority = 'Sev 1';
            cases.add(nonBillableCase4);
        //}
        insert cases;
        
         
        Task t1 = TestUtility.newTask('Test',cases[0].Id);
        t1.Note_Type__c = 'FE Resolution';
        taskList.add(t1);
        
        
        Task t2 = TestUtility.newTask('Test',cases[1].Id);
        t2.Note_Type__c = 'Resolution';
        taskList.add(t2);
        
        insert taskList;
        
        WorkOrder wo1 = TestUtility.newWorkOrder(custAccount.Id,null,assets[0].id,GlobalUtility.getRecordTypeId('WorkOrder', 'B_SH_FE_Service'),'Pending');
        wo1.Pricebook2Id=pricebook.id;
            wo1.Completed_Date__c=system.today();
            wo1.FE_Resolution__c='test';
            
            woList.add(wo1);
             WorkOrder wo5 = TestUtility.newWorkOrder(siteAccount.Id,null,assets[0].id,GlobalUtility.getRecordTypeId('WorkOrder', 'B_SH_FE_Service'),'Pending');
        wo5.Completed_Date__c=null;
            wo5.FE_Resolution__c='test';
            woList.add(wo5);
        
        WorkOrder wo2 = TestUtility.newWorkOrder(siteAccount.Id,cases[0].Id,assets[0].id,GlobalUtility.getRecordTypeId('WorkOrder', 'B_SH_FE_Service'),'New');
        wo2.Completed_Date__c=null;
            wo2.FE_Resolution__c='test';
            woList.add(wo2);
            
        WorkOrder wo3 = TestUtility.newWorkOrder(siteAccount.Id,null,assets[1].id,GlobalUtility.getRecordTypeId('WorkOrder', 'B_SH_FE_Service'),'New');
       wo3.Completed_Date__c=system.today();
            wo3.FE_Resolution__c='test';    
        woList.add(wo3);    
        
        insert woList;
        
        WorkOrderLineItem wlitm1 = TestUtility.newWorkOrderLineItem(woList[0].Id, assets[0].id, GlobalUtility.getRecordTypeId('WorkOrderLineItem', 'B_SH_Add_a_Part'), 'New');
        
            woliList.add(wlitm1);
            WorkOrderLineItem wlitm3 = TestUtility.newWorkOrderLineItem(woList[1].Id, assets[0].id, GlobalUtility.getRecordTypeId('WorkOrderLineItem', 'B_SH_Add_a_Part'), 'New');
        
            woliList.add(wlitm3);
        
        WorkOrderLineItem wlitm2 = TestUtility.newWorkOrderLineItem(woList[2].Id, assets[1].id, GlobalUtility.getRecordTypeId('WorkOrderLineItem', 'B_SH_Add_a_Part'), 'New');
        //wlitm2.includePricing=true;
            woliList.add(wlitm2);
        
        insert woliList;
            /*ProductConsumed pc=new ProductConsumed(PricebookEntryId =pbeList[0].id,QuantityConsumed=10,WorkOrderId=wo1.id);
            insert pc;*/
                  
        Schema.Location loc = new Schema.Location();
        loc.Name = 'Test Location';
        loc.IsInventoryLocation = true;
        insert loc;
        
        ProductItem prit = new ProductItem();
        prit.Product2Id = prod.Id;
        prit.QuantityOnHand = 15;
        prit.LocationId = loc.Id;
        insert prit;
            List<ProductConsumed> pconList = new List<ProductConsumed>();
            ProductConsumed pcon=new ProductConsumed();
        pcon.ProductItemId = prit.Id;
        pcon.WorkOrderId = wo1.Id;
        pcon.Return_Asset__c = assets[0].Id;
        pcon.QuantityConsumed = 12;
            pconList.add(pcon);
              ProductConsumed pcon1=new ProductConsumed();
        pcon1.ProductItemId = prit.Id;
        pcon1.WorkOrderId = wo2.Id;
        pcon1.Return_Asset__c = assets[0].Id;
        pcon1.QuantityConsumed = 2;
            pconList.add(pcon1);
        insert pconList;
       
        
        }
      
        }
       
        static testMethod void test_fromCustomerAccount(){
        
            pageRef = Page.CSRIntakeFormLegasy;
            Test.setCurrentPage(pageRef);
         
            ApexPages.StandardController con = new ApexPages.StandardController(custAccount);
            ApexPages.currentPage().getParameters().put('Id',custAccount.id);
            ApexPages.currentPage().getParameters().put('RecordType','Customer');
            csr = new CSRControllerMerge();
        }
        
        static testMethod void test_fromSiteAccount(){
            pageRef = Page.CSRIntakeFormLegasy;
            Test.setCurrentPage(pageRef);
         
            ApexPages.StandardController con = new ApexPages.StandardController(siteAccount);
            ApexPages.currentPage().getParameters().put('Id',siteAccount.id);
            ApexPages.currentPage().getParameters().put('RecordType','Site');
            csr = new CSRControllerMerge();
        }
        
        static testMethod void test_fromAsset(){
            pageRef = Page.CSRIntakeFormLegasy;
            Test.setCurrentPage(pageRef);
         
            ApexPages.StandardController con = new ApexPages.StandardController(assets[0]);
            ApexPages.currentPage().getParameters().put('Id',assets[0].id);
            ApexPages.currentPage().getParameters().put('AssetId',assets[0].id);
            ApexPages.currentPage().getParameters().put('Selected','true');
            //ApexPages.currentPage().getParameters().put('Master','true');
            ApexPages.currentPage().getParameters().put('caseMasterChkBox','true');
            
            csr = new CSRControllerMerge(); 
            csr.SelectedCaseIds.add(cases[1].id);
            csr.setSelected();
            csr.caseMasterChkBox=true;
            
            csr.setSelected();
              //wo_Wrapper woWrap = new wo_Wrapper(woList[0],woliList,null);  
              //csr.woWrapper.add(woWrap); 
           //csr.woWrapper.add(woList[0],woliList,null);
            csr.setCaseSelected();
            csr.includePricing=true;
            csr.PDFAttached();
            csr.setSelected();
            csr.Pagination=0;
            csr.getprev();
            csr.Pagination=5;
            csr.Previous();
            //csr.fromCase=true;
            csr.FirstTimeGetAllCases=0;
            csr.setSelected();
            csr.setCaseSelected();
              csr.selectedCaseTypes.add(new SelectOption('Patient on Table', 'Patient on Table'));
           csr.wrselectedRTs.add(new SelectOption('01261000000XzIe', 'Billable_Event'));
            csr.selectedRTs.add(new SelectOption('01261000000MEII', 'B&SH Service'));
            csr.servStartDate=system.Today();
            csr.servEndDate=system.today()+10;
             csr.setCaseSelected();
           }

        static testMethod void test_fromAsset1(){
            pageRef = Page.CSRIntakeFormLegasy;
            Test.setCurrentPage(pageRef);
         
            
            ApexPages.StandardController con = new ApexPages.StandardController(assets[1]);
            ApexPages.currentPage().getParameters().put('Id',assets[1].id);
            ApexPages.currentPage().getParameters().put('AssetId',assets[1].id);
            ApexPages.currentPage().getParameters().put('Selected','true');
            //ApexPages.currentPage().getParameters().put('Master','true');
            ApexPages.currentPage().getParameters().put('caseMasterChkBox','true');
            
            csr = new CSRControllerMerge(); 
            csr.setSelected(); 
            csr.setCaseSelected();
            
            
            
        }
     static testMethod void test_fromAsset2(){
            pageRef = Page.CSRIntakeFormLegasy;
            Test.setCurrentPage(pageRef);
         
            
            ApexPages.StandardController con = new ApexPages.StandardController(assets[2]);
            ApexPages.currentPage().getParameters().put('Id',assets[2].id);
            ApexPages.currentPage().getParameters().put('AssetId',assets[2].id);
            ApexPages.currentPage().getParameters().put('Selected','true');
            //ApexPages.currentPage().getParameters().put('Master','true');
            ApexPages.currentPage().getParameters().put('caseMasterChkBox','true');
            
            CSRControllerMerge.case_Wrapper caseWrap1 = new CSRControllerMerge.case_Wrapper(cases[1],true,null,null,null,null,system.today(),system.today());
          
         csr = new CSRControllerMerge();
         csr.servStartDate = system.today();
            csr.servEndDate = system.today()+1;
            csr.setSelected(); 
            csr.setCaseSelected();
         
            
            
            
        }
        static testMethod void test_fromCase(){
            pageRef = Page.CSRIntakeFormLegasy;
            Test.setCurrentPage(pageRef);
         
            ApexPages.StandardController con = new ApexPages.StandardController(cases[0]);
            ApexPages.currentPage().getParameters().put('Id',cases[0].id);
            ApexPages.currentPage().getParameters().put('CaseId',cases[0].id);
            ApexPages.currentPage().getParameters().put('master','');
            CSRControllerMerge.case_Wrapper caseWrap = new CSRControllerMerge.case_Wrapper(cases[0],true,null,null,null,'B_SH_FE_Service',system.today(),system.today()+3);
            caseWrap.selected = true;
            csr = new CSRControllerMerge(); 
           csr.includePricing=true;
            csr.caseMasterChkBox = true;   
            csr.setCaseSelected();
            csr.selectedCaseTypes.add(new SelectOption('High', 'High'));
             csr.selectedCaseTypes.add(new SelectOption('Low', 'Low'));
            csr.servStartDate = system.today();
            csr.servEndDate = system.today()+1;
            csr.selectedRTs.add(new SelectOption(GlobalUtility.getRecordTypeId('Case', 'B_SH_Service'), GlobalUtility.getRecordTypeId('Case', 'B_SH_Service')));
            csr.wrselectedRTs.add(new SelectOption('01261000000XzIe', 'Billable_Event'));
            csr.wrselectedRTs.add(new SelectOption('01261000000MEIw', 'B_SH_PM'));
            csr.selectedRTs.add(new SelectOption(GlobalUtility.getRecordTypeId('Case', 'B_SH_Install'), GlobalUtility.getRecordTypeId('Case', 'B_SH_Install')));
            csr.filterCaseRecs();
            csr.generateReport();
            csr.Cancel();
            
            
            ApexPages.currentPage().getParameters().put('selectedCaseTypes','Other');
            ApexPages.currentPage().getParameters().put('selectedRTs','B&SH Service');
            CSRControllerMerge.case_Wrapper caseWrap1 = new CSRControllerMerge.case_Wrapper(cases[1],true,null,null,null,'B_SH_FE_Service',system.today(),null);
            caseWrap1.selected = true;
             
            csr = new CSRControllerMerge(); 
            csr.newCaseWrapper.add(caseWrap1);
            csr.SelectedCaseIds.add(cases[1].id);
            csr.fromMaster=true;
            csr.setCaseSelected();
            csr.setCaseSelected();
            csr.getnxtWorkOrder();
            csr.getprevWorkOrder();
            csr.NextWorkOrder();
            csr.previousWorkOrder();
            csr.PaginationWorkOrder=0;
             csr.getprevWorkOrder();
            csr.PaginationWorkOrder=5;
            csr.previousWorkOrder();
            csr.caseMasterChkBox = true;
            csr.setSelected();
            csr.filterCaseRecs();
            csr.getnxt();
            csr.getprev();
            csr.Next();
             csr.Previous();
             csr.setSelected();
            csr.Pagination=0;
            csr.getprev();
            csr.Pagination=5;
            csr.Previous();
            //csr.fromCase=true;
            csr.fromMaster=true;
            csr.setCaseSelected();
            csr.generateReport();
            csr.Cancel();
              CSRControllerMerge.case_Wrapper caseWrap2 = new CSRControllerMerge.case_Wrapper(cases[2],true,null,null,null,'B_SH_FE_Service',null,null);
            caseWrap2.selected = true;
            
            csr = new CSRControllerMerge();
            csr.newCaseWrapper.add(caseWrap2);
            csr.setCaseSelected();
            csr.caseMasterChkBox = true;
            csr.filterCaseRecs();
            csr.generateReport();
            csr.Cancel();
            
            
        }
    
        static testMethod void test_fromCase1(){
            pageRef = Page.CSRIntakeFormLegasy;
            Test.setCurrentPage(pageRef);
         
            ApexPages.StandardController con = new ApexPages.StandardController(cases[2]);
            ApexPages.currentPage().getParameters().put('Id',cases[2].id);
            ApexPages.currentPage().getParameters().put('CaseId',cases[2].id);
            ApexPages.currentPage().getParameters().put('master','Master');
            CSRControllerMerge.case_Wrapper caseWrap = new CSRControllerMerge.case_Wrapper(cases[2],true,null,taskList,null,'B_SH_FE_Service',system.today(),system.today()+3);
            caseWrap.selected = true;
            csr = new CSRControllerMerge(); 
           csr.includePricing=true;
            csr.caseMasterChkBox = true;   
            csr.setSelected();
            csr.setCaseSelected();
            csr.selectedCaseTypes.add(new SelectOption('High', 'High'));
          
            csr.servStartDate = system.today();
            csr.servEndDate = system.today()+1;
            csr.selectedRTs.add(new SelectOption(GlobalUtility.getRecordTypeId('Case', 'B_SH_Install'), GlobalUtility.getRecordTypeId('Case', 'B_SH_Install')));
            csr.filterCaseRecs();
            csr.Next();
            csr.Previous();
            csr.Pagination=0;
            csr.getprev();
            csr.generateReport();
            csr.Cancel();
            
            
            ApexPages.currentPage().getParameters().put('selectedCaseTypes','Other');
            ApexPages.currentPage().getParameters().put('selectedRTs','B&SH Service');
            //New_CSRController.case_Wrapper caseWrap1 = new New_CSRController.case_Wrapper(cases[1],true,null,null,null,null,null);
            //caseWrap1.selected = true;
            
            csr = new CSRControllerMerge();    
            //csr.setCaseSelected();
            csr.caseMasterChkBox = true;
            csr.filterCaseRecs();
            csr.generateReport();
            csr.Cancel();
            
            
        }
    static testMethod void test_fromCase2(){
            pageRef = Page.CSRIntakeFormLegasy;
            Test.setCurrentPage(pageRef);
         
            ApexPages.StandardController con = new ApexPages.StandardController(cases[1]);
            ApexPages.currentPage().getParameters().put('Id',cases[1].id);
            ApexPages.currentPage().getParameters().put('CaseId',cases[1].id);
            ApexPages.currentPage().getParameters().put('master','Master');
            CSRControllerMerge.case_Wrapper caseWrap = new CSRControllerMerge.case_Wrapper(cases[1],true,null,taskList,null,'B_SH_FE_Service',system.today(),system.today()+3);
            caseWrap.selected = true;
            csr = new CSRControllerMerge(); 
           csr.includePricing=true;
            csr.caseMasterChkBox = true;   
          
          csr.newCaseWrapper.add(caseWrap);
            csr.SelectedCaseIds.add(cases[1].id);
        csr.setSelected();
            csr.fromMaster=true;
            csr.setCaseSelected();
        csr.caseMasterChkBox=false;
         ApexPages.currentPage().getParameters().put('CaseId',null);
            csr.fromMaster=true;
            csr.setCaseSelected();
            csr.selectedCaseTypes.add(new SelectOption('High', 'High'));
           
            csr.servStartDate = system.today();
            csr.servEndDate = system.today()+1;
            csr.selectedRTs.add(new SelectOption(GlobalUtility.getRecordTypeId('Case', 'B_SH_Install'), GlobalUtility.getRecordTypeId('Case', 'B_SH_Install')));
            csr.filterCaseRecs();
            csr.generateReport();
            csr.Cancel();
            
            
            ApexPages.currentPage().getParameters().put('selectedCaseTypes','Other');
            ApexPages.currentPage().getParameters().put('selectedRTs','B&SH Service');
            CSRControllerMerge.case_Wrapper caseWrap1 = new CSRControllerMerge.case_Wrapper(cases[1],true,null,null,null,null,system.today(),system.today());
            caseWrap1.selected = true;
            
            csr = new CSRControllerMerge();    
            //csr.setCaseSelected();
            csr.caseMasterChkBox = true;
            csr.filterCaseRecs();
            csr.generateReport();
            csr.PDFAttached();
            csr.Cancel();
            
            
        }
          

}