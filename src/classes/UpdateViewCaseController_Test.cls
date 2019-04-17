/********************************************************************************************************************
    Author       : Sunil Kumar Sharma
    Company      : Hexaware Technologies
    Created Date : 02/11/2019 
    Description  : This test class is used for controller "UpdateViewCaseController" to enable /disable the view all cases value on account relationship object.

    History:
    <Date>         <Author Name>            <Brief Description of Change>    <Copa.do US#>
    02/11/2019     Sunil                    Initial Creation                  US-0006703    
********************************************************************************************************************/
@isTest
public class UpdateViewCaseController_Test {
    @testSetup static void setupTestData() {
        TestUtility.setupConfigurationSettings();
        Account testAccount = TestUtility.newAccount('Account0', 'Account0');
        database.insert(testAccount) ;
        
        Contact cont = new Contact();
        cont.FirstName='Test';
        cont.LastName='Test';
        cont.Accountid= testAccount.id;
        cont.Email = 'test@gmail.com';
        cont.MailingCountryCode = 'US';
        cont.Phone= '(121)999-5544';
        database.insert(cont);  
         
    }
    
    @isTest static void testfetchAccount(){
        List<Contact> contactId = new List<Contact>([SELECT Id FROM Contact WHERE FirstName = 'Test']);
        List <AccountContactRelation> lst = UpdateViewCaseController.fetchAccount(contactId[0].Id) ;
        sObject sObj = Schema.getGlobalDescribe().get('AccountContactRelation').newSObject() ;
        UpdateViewCaseController.getselectOptions(sObj,'Community_View_All_Cases__c') ;
        UpdateViewCaseController.saveAccount(lst) ;
    }
}