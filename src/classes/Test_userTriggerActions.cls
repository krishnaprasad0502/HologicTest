/*-----------------------------------------------------------------------------
Author:     Mani Sundaresan
Description:  Test Class for User object trigger framework
Class:  userTriggerActions   

History:
<Date>      <Authors Name>    <Brief Description of Change>
02/16/2017  Mani Sundaresan    Initial Creation
22/10/2018  Nikhil Mutyam      Addes test method "testCreateSharingforL2".
-----------------------------------------------------------------------------*/
@isTest
private class Test_userTriggerActions{

    private static Configuration_Settings__c orgDefaults;
    private static Account custAccount;
    private static Account siteAccount;
    private static Contact defaultContact;
    private static List<Product2> products;
    private static List<Asset> assets;
    private static List<Case> cases = new List<Case>();
    private static Pricebook2 pricebook;
    private static List<User> userList;
    
    
    static{
        orgDefaults = TestUtility.setupConfigurationSettings();
        
        Trigger_Switch__c ts = new Trigger_Switch__c();
        ts.Name = 'UserTrigger';
        ts.Active__c = true;
        insert ts;
        
        TestUtility.insertCustSetting('CaseTrigger');
        
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
        for(Integer i = 0; i < 100; i++){
           
            Asset sys1 = TestUtility.newAsset(siteAccount.Name + ' Asset 01', siteAccount.Id, custAccount.Id, products[0].Id);
            sys1.ContactId = defaultContact.Id;
            Asset sys2 = TestUtility.newAsset(siteAccount.Name + ' Asset 02', siteAccount.Id, custAccount.Id, products[1].Id);
            sys2.ContactId = defaultContact.Id;
            assets.add(sys1);
            assets.add(sys2);
        }
        insert assets;
        
        Case nonBillableCase = TestUtility.newCase(siteAccount.Id, null, assets[0].Id, null, GlobalUtility.getRecordTypeId('Case', 'B_SH_Service'), 'Service', 'New', 'Low', 'Phone');
        nonBillableCase.Bill_to_Customer__c = custAccount.Id;
        nonBillableCase.Customer_Name__c = custAccount.Id;
        nonBillableCase.Subject = 'Test Subject';
        cases.add(nonBillableCase);
        
        insert cases;
    }
    
     static testMethod void Test_delegateUser(){
     
        List<WorkOrder> workOrderList = new List<WorkOrder>();
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        userList = new List<User>();
        
        User demoUser1 = TestUtility.newUser(p.Id,'demoUser');
        User demoUser2 = TestUtility.newUser(p.Id,'demoUse2');
        User demoUser3 = TestUtility.newUser(p.Id,'demoUse3');
        
        userList.add(demoUser1);
        userList.add(demoUser2);
        userList.add(demoUser3);
        
        insert userList;
        
        userList.clear();
        
        demoUser1.ManagerId= demoUser2.Id;
        userList.add(demoUser1);
        demoUser2.ManagerId= demoUser3.Id;
        userList.add(demoUser2);
        
        update userList;
        
        System.runAs(demoUser1){
            for(Case c : cases){
                //workOrderList.add(TestUtility.newWorkOrder(siteAccount.Id, c.Id, null, GlobalUtility.getRecordTypeId('WorkOrder', 'B_SH_Billable_PM'), 'New'));
                WorkOrder wo = TestUtility.newWorkOrder(siteAccount.Id, c.Id, null, GlobalUtility.getRecordTypeId('WorkOrder', 'B_SH_FE_Install_Upgrade_Move'), 'New');
                wo.Submitted_for_Approval__c = False;
                wo.Pricebook2Id = pricebook.Id;
                workOrderList.add(wo);
            }
            
            System.debug('WOList:'+workOrderList.size());
            System.debug('WOList1:'+workOrderList);
            
            Test.startTest();
                insert workOrderList;
            Test.stopTest();
            
            System.debug('woDelegate:'+workOrderList[0].District_Service_Manager__c);
            
            for(WorkOrderLineItem woli : [Select Id, RecordTypeId, RecordType.Name, Quantity From WorkOrderLineItem Where WorkOrderId IN: workOrderList]){
                System.debug('HW1');
                System.assertEquals(Integer.valueOf('1'), woli.Quantity);
                System.assertEquals('B&SH Add a Part', woli.RecordType.Name);
            }
        }
        
        User demoUser4 = TestUtility.newUser(p.Id,'demoUse4');
        insert demoUser4;
        
        demoUser2.DelegatedApproverId = demoUser4.Id;
        update demoUser2;
        demoUser3.DelegatedApproverId = demoUser4.Id;
        update demouser3;
        
    }
    
    /*Test method that helps test the logic of mapping L2 Account and L3 User*/
    public static testmethod void testCreateSharingforL2(){
        //TestUtility.setupConfigurationSettings();
        
        //Create test Account record L2
        Account acc1 = TestUtility.newAccount('Test Account',null);
        database.insert(acc1);
        
        //Create test Account record L3
        Account acc2 = TestUtility.newAccount('Test Account',null);
        acc2.ParentId = acc1.Id;
        database.insert(acc2);
        
        Contact cnt = new Contact();
        cnt.FirstName = 'Contact';
        cnt.LastName = 'Test';
        cnt.AccountId = acc2.Id;
        insert cnt;
        
        Profile profile2 = [SELECT Id FROM Profile WHERE name =: Label.Community_Profile_Name];
        User portalAccountOwner2 = new User(
        ProfileId = profile2.Id,
        Username = System.now().millisecond() +'HealthAdmin@test.test',
        Alias = 'batman',
        Email='testmhg@gm.com',
        EmailEncodingKey='UTF-8',
        Firstname='FirstName',
        Lastname='LastName',
        LanguageLocaleKey='en_US',
        LocaleSidKey='en_US',
        TimeZoneSidKey='America/Chicago',
        ContactId = cnt.Id    
        );
        Database.insert(portalAccountOwner2);
    }
}