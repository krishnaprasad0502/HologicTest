/*------------------------------------------------------------
Author:         Mani Sundaresan
Description:    Test class to validate AccountContactRelationTriggerActions
Tests Excecuted:

History:
<Date>         <Author Name>      <Brief Description of Change>     <Copa.do US#>
07/05/2018      Mani Sundaresan      Initial Creation(US-4409)
20/11/2018      Niraj Wani		   Issue with View All Cases Y/N	US-0006167
------------------------------------------------------------------------------------*/
@isTest
public with sharing class AccountContactRelation_Test {
    
    public static Id accountCustomerRecordTypeId = GlobalUtility.getRecordTypeId('Account', 'Customer');
    public static Id accountSiteRecordTypeId = GlobalUtility.getRecordTypeId('Account', 'Site');
    public static String streetLine = 'Line 1\nLine 2\nLine 3\nLine 4\nLine 5\nLine 6';
    
    static{
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
        //insert orgDefaults;
    }
    
    static testMethod void testInsertAccountShareRecords(){
        UserRole portalRole = [SELECT Id FROM UserRole WHERE PortalType = 'None' Limit 1];
        Profile profile1 = [SELECT Id FROM Profile WHERE name = 'System Administrator'];
        User Admin = new User(
            UserRoleId = portalRole.Id,
            ProfileId = profile1.Id,
            Username = System.now().millisecond() +'HealthAdmin@test.test',
            Alias = 'batman',
            Email='bruce.wayne@wayneenterprises.com',
            EmailEncodingKey='UTF-8',
            Firstname='FirstName',
            Lastname='LastName',
            LanguageLocaleKey='en_US',
            LocaleSidKey='en_US',
            TimeZoneSidKey='America/Chicago'
        );
        Database.insert(Admin);
           
        list<Account> Accounts = new list<Account>();
        list<Contact> Contacts = new list<Contact>();
        system.runAs(Admin){
            TestUtility.setupConfigurationSettings();   
            Trigger_Switch__c ts = new Trigger_Switch__c();
            ts.Name = 'AccountContactRelationTrigger';
            ts.Active__c = true;
            insert ts;
            
            //Create test Account record
            Account acc1 = TestUtility.newAccount('Test Account1',null);
            acc1.recordTypeId = accountSiteRecordTypeId;
            Account acc2 = TestUtility.newAccount('Test Account2',null);
            acc2.recordTypeId = accountSiteRecordTypeId;
            Account parentAcc = TestUtility.newAccount('Parent Account',null);
            parentAcc.recordTypeId =accountCustomerRecordTypeId;
            insert(parentAcc);
            acc2.ParentId = parentAcc.id;
            Accounts.add(acc1);
            Accounts.add(acc2);
            database.insert(Accounts);
           
            Contacts = TestUtility.getContacts(2);
            Contacts[0].AccountId = acc1.Id;
            Contacts[1].AccountId = acc2.Id;
            database.insert(Contacts);
    	}
        
        Profile profile2 = [SELECT Id FROM Profile WHERE name =: Label.Community_Profile_Name];
        User Customer1 = new User(
            ProfileId = profile2.Id,
            Username = System.now().millisecond() +'HealthAdmin@test.test',
            Alias = 'batman',
            Email='bruce.wayne@wayneenterprises.com',
            EmailEncodingKey='UTF-8',
            Firstname='FirstName',
            Lastname='LastName',
            LanguageLocaleKey='en_US',
            LocaleSidKey='en_US',
            TimeZoneSidKey='America/Chicago',
            ContactId = Contacts[0].Id    
        );
        Database.insert(Customer1);
        
        User Customer2 = new User(
            ProfileId = profile2.Id,
            Username = System.now().millisecond() +'HealthAdmin@test2.test',
            Alias = 'batman2',
            Email='bruce.wayne@wayneenterprises2.com',
            EmailEncodingKey='UTF-8',
            Firstname='ACTriggerTest',
            Lastname='Hologic',
            LanguageLocaleKey='en_US',
            LocaleSidKey='en_US',
            TimeZoneSidKey='America/Chicago',
            ContactId = Contacts[1].Id    
        );
        Database.insert(Customer2);
        
        system.debug('Contact 1 : '+Contacts[0].Id);
        system.debug('User 1 : '+Customer1.Id + 'Contact 1: '+Customer1.ContactId);
        system.debug('Contact 2 : '+Contacts[1].Id);
        system.debug('User 2 : '+Customer2.Id + 'Contact 2: '+Customer2.ContactId);
        
        system.runAs(Admin){
            AccountContactRelation ACR = new AccountContactRelation();
            ACR.AccountId = Accounts[0].Id;
            ACR.ContactId = Contacts[1].Id;
            ACR.Community_View_All_Cases__c = 'Yes';
            insert ACR;
            
            delete ACR;
            
            AccountContactRelation ACR2 = new AccountContactRelation();
            ACR2.AccountId = Accounts[1].Id;
            ACR2.ContactId = Contacts[0].Id;
            ACR2.Community_View_All_Cases__c = 'Yes';
            insert ACR2;
          
            ACR2.Community_View_All_Cases__c = 'No';
            update ACR2;
            
            //ACR.Community_View_All_Cases__c = 'Yes';
            //update ACR;
            
           
           
        }
    }
}