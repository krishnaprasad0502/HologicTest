@isTest
public class PopulateLocation_Test {
    static{
        TestUtility.setupConfigurationSettings();
    }
static testMethod void Test_populatelocation(){
   // insert an account
        Account custAccount = TestUtility.newAccount('Customer Account', 'testCust', 'ABC Street', null, GlobalUtility.getRecordTypeId('Account', 'Customer'));
        custAccount.BillingCountryCode = 'US';
        custAccount.BillingStateCode = 'NY';        
        insert new List<Account>{custAccount};
         
        Account siteAccount = TestUtility.newAccount('Site Account', 'testSite', 'ABC Street',custAccount.Id, GlobalUtility.getRecordTypeId('Account', 'Site'));
        siteAccount.BillingCountryCode = 'US';
        siteAccount.BillingStateCode = 'NY';
        siteAccount.Internal__c = true;
        insert siteAccount;
        
        Contact Con = TestUtility.newContact('Firstname ','Lastname ', custAccount.id);
        insert con;
          
        External_Website_Contacts__c EBC = new External_Website_Contacts__c(Account_Reference__c=custAccount.id,Account_Display_Name__c = custAccount.Name,City__c = 'Austin',Contact_Reference__c = con.id,Country__c = 'US',State__c = 'TX',Street_Address__c = '12201 Renfert Way',Street_Address_2__c = 'Ste 205',Zip_Code__c = '78758');
        insert EBC;
    
       // EBC.Office_Location__Latitude__s  = 34.21558;
        //EBC.Office_Location__Longitude__s  = 96.024456;
        //update EBC;
   test.startTest(); 
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
   		PopulateLocation.contactAddress(ebc.Id);
     test.stopTest();

}
    
    static testMethod void Test_populatelocationnull(){
   // insert an account
        Account custAccount = TestUtility.newAccount('Customer Account', 'testCust', 'ABC Street', null, GlobalUtility.getRecordTypeId('Account', 'Customer'));
        custAccount.BillingCountryCode = 'US';
        custAccount.BillingStateCode = 'NY';        
        insert new List<Account>{custAccount};
         
        Account siteAccount = TestUtility.newAccount('Site Account', 'testSite', 'ABC Street',custAccount.Id, GlobalUtility.getRecordTypeId('Account', 'Site'));
        siteAccount.BillingCountryCode = 'US';
        siteAccount.BillingStateCode = 'NY';
        siteAccount.Internal__c = true;
        insert siteAccount;
        
        Contact Con = TestUtility.newContact('Firstname ','Lastname ', custAccount.id);
        insert con;
          
        External_Website_Contacts__c EBC = new External_Website_Contacts__c(Account_Reference__c=custAccount.id,Account_Display_Name__c = custAccount.Name,City__c = 'Austin',Contact_Reference__c = con.id,Country__c = 'US',State__c = 'TX',Street_Address__c = '12201 Renfert Way',Street_Address_2__c = 'Ste 205',Zip_Code__c = '78758');
        insert EBC;
  
       
      
   test.startTest(); 
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
   		PopulateLocation.contactAddress(ebc.Id);
     
         EBC.Office_Location__Latitude__s  = 34.21558;
        EBC.Office_Location__Longitude__s  = 96.024456;
        update EBC;
        test.stopTest();

}
  
}