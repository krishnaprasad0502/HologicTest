/*------------------------------------------------------------
Author:         Denise Bacher
Company:        Salesforce.com
Description:    Test class to validate AccountTrigger
                Tests Excecuted:
                
                insertAccountsStreetAddress - verify that on insert of Account, the BillingStreet are parsed out into the custom 1-4 fields
                
                updateAccountsStreetAddress - verify that on update of Account, the custom 1-4 fields are updated to match what's in the BillingStreet
History:
<Date>          <Authors Name>      <Brief Description of Change>
04/08/2016      Denise Bacher       Initial Creation
08/11/2016      Denise Bacher       Remove ShippingStreet_LineX__c fields (US1450)
03/12/2018      Mani Sundaresan     International Territory Management (US6875)
------------------------------------------------------------*/
@isTest
private class AccountTrigger_Test {
    public static Id accountCustomerRecordTypeId = GlobalUtility.getRecordTypeId('Account', 'Customer');
    public static Id accountSiteRecordTypeId = GlobalUtility.getRecordTypeId('Account', 'Site');
    public static String streetLine = 'Line 1\nLine 2\nLine 3\nLine 4\nLine 5\nLine 6';
    
    static{
        //TestUtility.setupConfigurationSettings();
        /*Configuration_Settings__c orgDefaults = new Configuration_Settings__c();
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
       
        
        insert orgDefaults;*/
    }
    
    static testMethod void insertAccountsStreetAddress() {
        Test.startTest();
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
            List<Account> accountInserts = new List<Account>();
            for(Integer i = 0; i < 100; i++){
                accountInserts.add(TestUtility.newAccountWithAddresses('Account-C-' + i, null, accountCustomerRecordTypeId, 
                    streetLine, 'BillingCity', 'Massachusetts', 'United States', '55555', 
                    streetLine, 'ShippingCity', 'Massachusetts', 'United States', '55555'));
                    
                accountInserts.add(TestUtility.newAccountWithAddresses('Account-S-' + i, null, accountCustomerRecordTypeId, 
                    streetLine, 'BillingCity', 'Massachusetts', 'United States', '55555', 
                    streetLine, 'ShippingCity', 'Massachusetts', 'United States', '55555')); 
            }
            insert accountInserts;
        Test.stopTest();
        
        for(Account a : [Select BillingStreet_Line1__c, BillingStreet_Line2__c, BillingStreet_Line3__c, BillingStreet_Line4__c
                        From Account])
        {
            System.assertEquals('Line 1', a.BillingStreet_Line1__c);
            System.assertEquals('Line 2', a.BillingStreet_Line2__c);
            System.assertEquals('Line 3', a.BillingStreet_Line3__c);
            System.assertEquals('Line 4', a.BillingStreet_Line4__c);
        }
    }
    
    static testMethod void updateAccountsStreetAddress() {
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
        List<Account> accountUpdates = new List<Account>();
        for(Integer i = 0; i < 100; i++){
            accountUpdates.add(TestUtility.newAccountWithAddresses('Account-C-' + i, null, accountCustomerRecordTypeId, 
                streetLine, 'BillingCity', 'Massachusetts', 'United States', '55555', 
                streetLine, 'ShippingCity', 'Massachusetts', 'United States', '55555'));
                
            accountUpdates.add(TestUtility.newAccountWithAddresses('Account-S-' + i, null, accountCustomerRecordTypeId, 
                streetLine, 'BillingCity', 'Massachusetts', 'United States', '55555', 
                streetLine, 'ShippingCity', 'Massachusetts', 'United States', '55555')); 
        }
        insert accountUpdates;
        
        // verify the street addresses split correctly
        for(Account a : [Select BillingStreet_Line1__c, BillingStreet_Line2__c, BillingStreet_Line3__c, BillingStreet_Line4__c
                        From Account])
        {
            System.assertEquals('Line 1', a.BillingStreet_Line1__c);
            System.assertEquals('Line 2', a.BillingStreet_Line2__c);
            System.assertEquals('Line 3', a.BillingStreet_Line3__c);
            System.assertEquals('Line 4', a.BillingStreet_Line4__c);
        }
        
        Test.startTest();
            for(Account a : accountUpdates){
                a.BillingStreet = '';
                a.ShippingStreet = '';
            }
            update accountUpdates;
        Test.stopTest();
        
        // verify the custom street addresses are blank to match the BillingStreet and ShippingStreet
        for(Account a : [Select BillingStreet_Line1__c, BillingStreet_Line2__c, BillingStreet_Line3__c, BillingStreet_Line4__c
                        From Account])
        {
            System.assertEquals(null, a.BillingStreet_Line1__c);
            System.assertEquals(null, a.BillingStreet_Line2__c);
            System.assertEquals(null, a.BillingStreet_Line3__c);
            System.assertEquals(null, a.BillingStreet_Line4__c);
        }
    }
    
    static testMethod void test_ampsFlows(){
        
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
        List<AMPS_Marketing_Activity_Flow__c> parentFlowList =  new List<AMPS_Marketing_Activity_Flow__c>();
        parentFlowList.add(new AMPS_Marketing_Activity_Flow__c(Initiating_Task_Type__c='New AMPS Marketing',name ='Flow 1',AMPS_Track__c='GREEN',Number_of_days_to_be_added__c=13));
            
        insert parentFlowList;                                                              

        Id profID = [select id from profile where name='Medical Aesthetics Sales Admin'].id;


        User user1 = new User(alias = 'test123', email='test123@hologic.com',
        emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US',
        localesidkey='en_US', profileid = profID , country='United States',IsActive =true,
        timezonesidkey='America/Los_Angeles', username='tester@hologic.com');
        
        insert user1;
        System.runAs(user1){
        ID prospectRecTypeId =  [SELECT Id FROM RecordType WHERE DeveloperName ='Prospect' Limit 1].id;
        ID siteRecTypeId = [SELECT Id FROM RecordType WHERE DeveloperName ='Site' Limit 1].id;
        
        Test.startTest();

        Account objSoldToAcc = TestUtility.newAccount('Test Account - 00001', '', '', null, prospectRecTypeId );
        objSoldToAcc.ShippingStateCode = 'AK';
        objSoldToAcc.ShippingCountryCode = 'US'; 
        objSoldToAcc.ShippingPostalCode = '10010'; 
        objSoldToAcc.ShippingCity = 'citay'; 
        objSoldToAcc.CurrencyIsoCode = 'USD';
        objSoldToAcc.CDQ_Status__c = 'New';
        objSoldToAcc.ShippingStreet = 'SHIPTest1 \n SHIPTest2 \n SHIPTest3 \n SHIPTest4';
        insert objSoldToAcc;
        
        Territory2Model terrModel = new Territory2Model();
        terrModel.DeveloperName = 'TestTerrModel123';
        terrModel.Name = 'TestTerrModel123';
            
        insert terrModel;
            
        Territory2 terr = new Territory2();
        terr.DeveloperName = 'TestTerr123';
        terr.name = 'TestTerr123';
        for (Territory2Model model : [select id from Territory2Model where DeveloperName = 'TestTerrModel123' and Name = 'TestTerrModel123']){
            terr.Territory2ModelId = model.id;
        }
        for (Territory2Type type : [select id from Territory2Type limit 1]){
            terr.Territory2TypeId = type.id; 
        }
            
        insert terr;
            
        ObjectTerritory2Association terrAccount = new ObjectTerritory2Association();
        terrAccount.Territory2Id = terr.id;
        terrAccount.ObjectId = objSoldToAcc.id;
        terrAccount.AssociationCause = 'Territory2Manual';
            
        insert terrAccount;
            
        UserTerritory2Association userInTerr = new UserTerritory2Association();
        userInTerr.Territory2Id = terr.id;
        userInTerr.UserId = user1.id;
        userInTerr.RoleInTerritory2 = 'AMPS Representative';
            
        insert userInTerr;
            
       objSoldToAcc.AMPS_Track__c = 'New AMPS Marketing';
       update objSoldToAcc;
        
       Test.stopTest();    

       }   
    }
    
    @isTest(SeeAllData=true)
    static void test_IntlTerritoryAssignment(){
        Test.startTest();
        //Insert accounts
        Account custAcc = TestUtility.newAccountWithAddresses('Account-Customer', null, accountCustomerRecordTypeId, 
                    streetLine, 'BANGOR', '', 'United Kingdom', 'LL57 2PW', 
                    streetLine, 'BANGOR', '', 'United Kingdom', 'LL57 2PW');
                    
        insert custAcc;
        
        Account siteAcc = TestUtility.newAccountWithAddresses('Account-Site', null, accountSiteRecordTypeId, 
                    streetLine, 'BANGOR', '', 'United Kingdom', 'LL57 2PW', 
                    streetLine, 'BANGOR', '', 'United Kingdom', 'LL57 2PW');
        siteAcc.ParentId = custAcc.Id;
                    
        insert siteAcc;
        
        Test.stopTest();
        
    }
}