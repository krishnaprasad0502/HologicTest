/*------------------------------------------------------------
Author:         Kasmoor Reddy
Company:        Apps Associates
Description:    Test class to validate ActivityTriggerActions
                Tests Excecuted:
                createProcedureValidation-- verify whether the procedure created from activities.
                
History:
<Date>          <Authors Name>      <Brief Description of Change>
10/26/2017       Kasmoor Reddy      Initial Creation (US3490)
04/09/2019   Alex Powning      Added Swarm Waypoint Actions Func
------------------------------------------------------------*/
@isTest
public with sharing class ActivityTriggerActions_Test {
  private static Configuration_Settings__c orgDefaults;
  static testMethod void createProcedureValidation(){
        orgDefaults = TestUtility.setupConfigurationSettings();
        TestUtility.insertCustSetting('OpportunityTrigger');
        TestUtility.insertCustSetting('CaseTrigger');
        TestUtility.insertCustSetting('EventTrigger');
        //Creating Test Data
        // insert an account
        Account custAccount = TestUtility.newAccount('Customer Account', 'testCust', 'ABC Street', null, GlobalUtility.getRecordTypeId('Account', 'Customer'));
        insert custAccount;
        System.assertEquals('Customer Account', custAccount.Name);
        
        Account siteAccount = TestUtility.newAccount('Site Account', 'testSite', 'ABC Street', custAccount.Id, GlobalUtility.getRecordTypeId('Account', 'Site'));
        siteAccount.BillingCountryCode = 'US';
        siteAccount.BillingStateCode = 'NY';
        siteAccount.Internal__c = true;
        insert siteAccount;
        System.assertEquals('Site Account', siteAccount.Name);
        
        Product_Source_Division__c psd = TestUtility.newProductSourceDivision('1234','MAMMOGRAPHY');
        Insert psd;

        Product_Source_Division__c psd1 = TestUtility.newProductSourceDivision('12345','MOLECULAR');
        Insert psd1;
        
        List<Product2> products = new List<Product2>();
        products.add(TestUtility.newProduct('Product 01'));
        products[0].Product_Source_Division__c = psd.Id;
        products.add(TestUtility.newProduct('Product 02'));
        products[1].Product_Source_Division__c = psd1.Id;
        insert products;
        System.assertEquals(2, products.size());
        
        
        //insert contact
        Contact defaultContact = TestUtility.newContact('Default', 'Contact', custAccount.Id);
        insert defaultContact;
        System.assertEquals('Default', defaultContact.FirstName);
        //insert opportunity
        Opportunity oppfrst = TestUtility.newOpportunity('Test Opportunity', siteAccount.Id, System.Today(), 'Target', 'Omitted');
        insert oppfrst;
        System.assertEquals('Test Opportunity',oppfrst.Name);
        
        //insert asset1
        Asset asset = TestUtility.newAsset('TestAsset', siteAccount.id, custAccount.id,products[0].id);
        asset.ContactId= defaultContact.id;
        insert asset;
        System.assertEquals('TestAsset',asset.Name);
        
        //insert case
         Case cse = TestUtility.newCase(custAccount.id, defaultContact.id,asset.id,products[0].id, GlobalUtility.getRecordTypeId('Case', 'Diagnostic_Service'), 'Complaint', 'New', 'Low', 'Sales Order');
        //case.Complaint__c = 'Yes';
         insert cse;
         System.assertEquals('New',cse.Status);
         
        //insert workorder
        WorkOrder wrkdr = TestUtility.newWorkOrder(siteAccount.id,cse.id,asset.id,GlobalUtility.getRecordTypeId('WorkOrder', 'B_SH_Applications'), 'New');
        insert wrkdr;
        System.assertEquals('New',wrkdr.Status);
        
        //insert Event
        List<Event> lstevnts = new List<Event>();
        Event evn1 = new Event(Subject = 'Test1', Whatid = siteAccount.id,Whoid = defaultContact.id,Create_Procedure_From_Event__c = true,DurationInMinutes = 10,ActivityDateTime = system.today());
        lstevnts.add(evn1);
        Event evn2 = new Event(Subject = 'Test2', Whatid = cse.id,Whoid = defaultContact.id,Create_Procedure_From_Event__c = true,DurationInMinutes = 10,ActivityDateTime = system.today());
        lstevnts.add(evn2);
        Event evn3 = new Event(Subject = 'Test3', Whatid = wrkdr.id,Whoid = defaultContact.id,Create_Procedure_From_Event__c = true,DurationInMinutes = 10,ActivityDateTime = system.today());
        lstevnts.add(evn3);
        Event evn4 = new Event(Subject = 'Test4', Whatid = oppfrst.id,Whoid = defaultContact.id,Create_Procedure_From_Event__c = true,DurationInMinutes = 10,ActivityDateTime = system.today());
        lstevnts.add(evn4);
        insert lstevnts;
        System.assertEquals(4, lstevnts.size());
        
        //insert Task
        List<Task> lsttsks = new List<Task>();
        Task tsk1 = new Task(Subject = 'Test1', Whatid = siteAccount.id,Whoid = defaultContact.id,Create_Procedure_from_Task__c = true,Status = 'Completed',ActivityDate = system.today());
        lsttsks.add(tsk1);
        Task tsk2 = new Task(Subject = 'Test2', Whatid = cse.id,Whoid = defaultContact.id,Create_Procedure_from_Task__c = true,Status = 'Completed',ActivityDate = system.today());
        lsttsks.add(tsk2);
        Task tsk3 = new Task(Subject = 'Test3', Whatid = wrkdr.id,Whoid = defaultContact.id,Create_Procedure_from_Task__c = true,Status = 'Completed',ActivityDate = system.today());
        lsttsks.add(tsk3);
        Task tsk4 = new Task(Subject = 'Test4', Whatid = oppfrst.id,Create_Procedure_from_Task__c = true,Status = 'Completed',ActivityDate = system.today());
        lsttsks.add(tsk4);
        insert lsttsks;
        System.assertEquals(4, lsttsks.size()); 
        
  }
    
    static testMethod void swarmWaypointActivityActionsValidation(){
        TestUtility.insertCustSetting('EventTrigger');
        Configuration_Settings__c orgDefaults = new Configuration_Settings__c();
        orgDefaults.Account_Creation_Exception__c = true;
        orgDefaults.Account_Hierarchy_Depth__c = 5;
        orgDefaults.Case_List_Column_01__c = 'CaseNumber';
        orgDefaults.Case_List_Records_Per_Page__c = 5;
        orgDefaults.Override_Entitlement_on_Case__c = true;
        orgDefaults.Auto_Close_Case_B_SH_Applications__c = true;
        orgDefaults.Auto_Close_Case_B_SH_Install__c = true;
        orgDefaults.Auto_Close_Case_B_SH_PM__c = true;
        orgDefaults.Auto_Close_Case_Billable_B_SH_Service__c = true;
        orgDefaults.Auto_Close_Case_NonBillable_B_SH_Service__c = true;
        insert orgDefaults;
        Test.startTest();
        
        Boolean isActive = GlobalUtility.isTriggerActive('EventTrigger');
        system.debug('is trigger active?**************************' + isActive);
        
        Swarm_Waypoint__c swarmW = new Swarm_Waypoint__c();
        insert swarmW;
        
        List<Swarm_Waypoint__c> swarms = [select id from Swarm_Waypoint__c limit 1];
        
        Event swarmEvent = new Event(Subject = 'Test1', Whatid = swarms[0].id, DurationInMinutes = 10,ActivityDateTime = system.today());
        insert swarmEvent;
        
        ID prospectRecTypeId =  [SELECT Id FROM RecordType WHERE DeveloperName ='Prospect' Limit 1].id;
		Account acct = TestUtility.newAccount('Test Account - 00001', '', '', null, prospectRecTypeId );
        acct.ShippingStateCode = 'AK';
        acct.ShippingCountryCode = 'US'; 
        acct.ShippingPostalCode = '10010'; 
        acct.ShippingCity = 'citay'; 
        acct.CurrencyIsoCode = 'USD';
        acct.CDQ_Status__c = 'New';
        acct.ShippingStreet = 'SHIPTest1 \n SHIPTest2 \n SHIPTest3 \n SHIPTest4';
        insert acct;
        
        List<account> accts = [select id from account limit 1];
        
        Event swarmEvent2 = new Event(Subject = 'Test2', Whatid = accts[0].id,Create_Procedure_From_Event__c = true,DurationInMinutes = 10,ActivityDateTime = system.today());
        insert swarmEvent2;
        
        Test.stopTest();
    }
}