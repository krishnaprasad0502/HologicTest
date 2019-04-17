/*------------------------------------------------------------
Author:         Denise Bacher
Company:        Salesforce.com
Description:    Test class to validate CaseBillShipTo page and CaseBillShipTo_ControllerX
                Tests Excecuted:
                
                setBillShipTo_hasCustomerName - set the bill/ship to for a case that has a Customer Name lookup
                
                setBillShipTo_noCustomerName - set the bill/ship to for a case that has no Customer Name lookup - should be displayed a warning message
                
History:
<Date>          <Authors Name>         <Brief Description of Change>
11/08/2016      Denise Bacher          Initial Creation (US-0001169)
22/06/2017      Amarendra Nagireddy    Modified test methods to cover methods implemented as the part of US-0003039
------------------------------------------------------------*/
@isTest
private class CaseBillShipTo_ControllerX_Test {
    
    public static Id accountCustomerRecordTypeId = GlobalUtility.getRecordTypeId('Account', 'Customer');
    public static Configuration_Settings__c orgDefaults;
    public static List<Account> customerAccounts = new List<Account>();
    public static List<Site_Location__c> siteLocations = new List<Site_Location__c>();
    public static List<Customer_Relationship__x> customerRelationships = new List<Customer_Relationship__x>();
    private static Account siteAccount;
    
    
    static{
        orgDefaults = TestUtility.setupConfigurationSettings();
        TestUtility.insertCustSetting('CaseTrigger');
        TestUtility.insertCustSetting('sitelocTrigger'); 
        // set up customer accounts
        for(Integer i = 0; i < 200; i++){
            customerAccounts.add(TestUtility.newAccount('CustAccount-'+i, 'custParty'+i, null, null, accountCustomerRecordTypeId));
        }
        insert customerAccounts;
        
        siteAccount = TestUtility.newAccount('Site Account', 'testSite', 'ABC Street', customerAccounts[0].id, GlobalUtility.getRecordTypeId('Account', 'Site'));
        siteAccount.BillingCountryCode = 'US';
        siteAccount.BillingStateCode = 'NY';            
        insert siteAccount;
        
        // set up site locations and customer relationships
        for(Account a : customerAccounts){
           Site_Location__c sl1 = TestUtility.newSiteLocation('123 A Street Suite 1', '123 A Street', 'Suite 1', 'Suite 2', null,
                'Some City', 'MA', '11111', 'US',
                a.Oracle_Party_Id__c, siteAccount.id, true);
            sl1.Bill_To__c = true;
            siteLocations.add(sl1);
                
            Site_Location__c sl2 = TestUtility.newSiteLocation('456 B Street Suite 1', '456 B Street', 'Suite 1', 'Suite 2', null,
                'Some City', 'MA', '11111', 'US',
                a.Oracle_Party_Id__c, siteAccount.id, true);
            sl2.Ship_To__c = true;
            siteLocations.add(sl2);
            
           customerRelationships.add(new Customer_Relationship__x(
                PartyId__c = a.Oracle_Party_Id__c
                , Related_Oracle_Party_ID__c = customerAccounts[0].Oracle_Party_Id__c
                , Bill_To__c = true
                , Ship_To__c = true
                , Status__c = 'Active'
            ));
        }
        
        insert siteLocations;
        
       
    }
    
    static testMethod void setBillShipTo_hasCustomerName(){
        Account siteAccount = [Select Id From Account Where ParentId =: customerAccounts[0].Id Limit 1];
        Case currentCase = TestUtility.newCase(siteAccount.Id, null, null, null, GlobalUtility.getRecordTypeId('Case', 'B_SH_Install'), 'Applications', 'New', 'Low', 'Sales Order');
        //22/06/2017(Amarendra Nagireddy)-Set case Bill_to_Customer__c,Bill_to_Customer__c field values,based on these values set Bill to site and Ship to Site values
        currentCase.Bill_to_Customer__c=customerAccounts[0].Id;
        currentCase.Ship_to_Customer__c=customerAccounts[0].Id;
        insert currentCase;
        
        currentCase = [Select Id, AccountId, Customer_Name__c, Customer_Name__r.Oracle_Party_Id__c, Bill_to_Customer__c, Bill_to_Site_Location__c, Ship_to_Customer__c, Ship_to_Site_Location__c
            From Case
            Where Id =: currentCase.Id];
        
        PageReference pageRef = Page.CaseBillShipTo;
        Test.setCurrentPage(pageRef);
        //22/06/2017(Amarendra Nagireddy)-Pass required Parameters from Visualforce page
        ApexPages.currentPage().getParameters().put('searchkey','123 A');
        ApexPages.currentPage().getParameters().put('STSsearchkey','456 B');
        ApexPages.currentPage().getParameters().put('selectedBTS',siteLocations[0].id);
        ApexPages.currentPage().getParameters().put('selectedSTS',siteLocations[1].id);
        Test.startTest();
            CaseBillShipTo_ControllerX.mockCustomerRelationships = customerRelationships;
            ApexPages.StandardController stdCtrl = new ApexPages.StandardController(currentCase);
            CaseBillShipTo_ControllerX ctrl = new CaseBillShipTo_ControllerX(stdCtrl);
            //22/06/2017(Amarendra Nagireddy)-Call search and pagination methods implemented as the part of US-0003039 
            ctrl.setNext();
            ctrl.setPrevious();
            ctrl.runSearch();
            ctrl.SelectedBTS();
            ctrl.STSsetNext();
            ctrl.STSsetPrevious();
            ctrl.STSrunSearch();
            ctrl.SelectedSTS();
            System.assertEquals(201, ctrl.billToAcctOptions.size()); // 200 accounts + 1 for the "none" option
            System.assertEquals(201, ctrl.shipToAcctOptions.size()); // 200 accounts + 1 for the "none" option
            System.assertEquals(2, ctrl.billToSiteOptions.size()); // 1 for the "none" option
            System.assertEquals(2, ctrl.shipToSiteOptions.size()); // 1 for the "none" option
            
            ctrl.currCase.Bill_to_Customer__c = ctrl.billToAcctOptions[1].getValue();
            ctrl.billToAcctSelected();
            System.assertEquals(2, ctrl.billToSiteOptions.size()); // 1 site locations + 1 for the "none" option
            ctrl.currCase.Bill_to_Site_Location__c = ctrl.billToSiteOptions[1].getValue();
            
            ctrl.currCase.ship_to_Customer__c = ctrl.shipToAcctOptions[1].getValue();
            ctrl.shipToAcctSelected();
            System.assertEquals(2, ctrl.shipToSiteOptions.size()); // 1 site locations + 1 for the "none" option
            ctrl.currCase.Ship_to_Site_Location__c = ctrl.shipToSiteOptions[1].getValue();
            
            stdCtrl.save();
        Test.stopTest();
        
        currentCase = [Select Id, AccountId, Customer_Name__c, Customer_Name__r.Oracle_Party_Id__c, Bill_to_Customer__c, Bill_to_Site_Location__c, Ship_to_Customer__c, Ship_to_Site_Location__c
            From Case
            Where Id =: currentCase.Id];
        System.assertNotEquals(null, currentCase.Bill_to_Customer__c);
        System.assertNotEquals(null, currentCase.Bill_to_Site_Location__c);
        System.assertNotEquals(null, currentCase.Ship_to_Customer__c);
        System.assertNotEquals(null, currentCase.Ship_to_Site_Location__c);
    }
    
    
    
    static testMethod void setBillShipTo_noCustomerName(){
        Case currentCase = TestUtility.newCase(customerAccounts[0].Id, null, null, null, GlobalUtility.getRecordTypeId('Case', 'B_SH_Install'), 'Applications', 'New', 'Low', 'Sales Order');
        insert currentCase;
        
        currentCase = [Select Id, AccountId, Customer_Name__c, Customer_Name__r.Oracle_Party_Id__c, Bill_to_Customer__c, Bill_to_Site_Location__c, Ship_to_Customer__c, Ship_to_Site_Location__c
            From Case
            Where Id =: currentCase.Id];
        
        PageReference pageRef = Page.CaseBillShipTo;
        Test.setCurrentPage(pageRef);
        
        Test.startTest();
            ApexPages.StandardController stdCtrl = new ApexPages.StandardController(currentCase);
            CaseBillShipTo_ControllerX ctrl = new CaseBillShipTo_ControllerX(stdCtrl);
           //22/06/2017(Amarendra Nagireddy)-Set pagination value to cover pagination methods
            ctrl.pagination=10;
            ctrl.setNext();
            ctrl.setPrevious();
            ctrl.STSpagination=10;
            ctrl.STSsetNext();
            ctrl.STSsetPrevious();
            System.assert(ApexPages.hasMessages(), 'No messages');
            System.assertEquals(1, ApexPages.getMessages().size());
            System.assertEquals('The Case is missing a Customer Name, or a Customer Name with an Oracle Party Id.', ApexPages.getMessages()[0].getSummary());
            System.assertEquals(1, ctrl.billToAcctOptions.size()); // 1 for the "none" option
            System.assertEquals(1, ctrl.shipToAcctOptions.size()); // 1 for the "none" option
            System.assertEquals(1, ctrl.billToSiteOptions.size()); // 1 for the "none" option
            System.assertEquals(1, ctrl.shipToSiteOptions.size()); // 1 for the "none" option
        Test.stopTest();
    }
    
    
}