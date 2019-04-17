/*--------------------------------------------------------------------------------------------------
Author:      Mani Sundaresan
Description:  Test class to validate FSREmailtoFE apex trigger on Feed Items
Tests Excecuted:


History:
<Date>      <Authors Name>    <Brief Description of Change>
10/27/2016  Mani Sundaresan   Initial Creation
---------------------------------------------------------------------------------------------------------*/
@isTest(seeAllData = True)
private class Test_FSREmailtoFE{
    
    private static Configuration_Settings__c orgDefaults;
    private static Account custAccount;
    private static Account siteAccount;
    private static List<Case> caseList = new List<Case>();
    
    static{
        //orgDefaults = TestUtility.setupConfigurationSettings();  
        
        custAccount = TestUtility.newAccount('Customer Account', 'testCust', 'ABC Street', null, GlobalUtility.getRecordTypeId('Account', 'Customer'));
        custAccount.BillingCountryCode = 'US';
        custAccount.BillingStateCode = 'NY'; 
        
        insert custAccount;
        
        siteAccount = TestUtility.newAccount('Site Account', 'testSite', 'ABC Street', custAccount.Id, GlobalUtility.getRecordTypeId('Account', 'Site'));
        siteAccount.BillingCountryCode = 'US';
        siteAccount.BillingStateCode = 'NY';      
        insert siteAccount;
        
        Case installCase = TestUtility.newCase(siteAccount.Id, null, null, null, GlobalUtility.getRecordTypeId('Case', 'B_SH_Install'), 'New Install', 'New', 'Low', 'Phone');
        caseList.add(installCase);
        insert caseList; 
        
        //WorkOrder wo = TestUtility.newWorkOrder(siteAccount.Id, installCase.Id, null, GlobalUtility.getRecordTypeId('WorkOrder', 'B_SH_FE_Install_Upgrade_Move'), 'Closed');
        //insert wo;
    
    }

    static testMethod void unitTest(){
         
         WorkOrder wo = TestUtility.newWorkOrder(siteAccount.Id, caseList[0].Id, null, GlobalUtility.getRecordTypeId('WorkOrder', 'B_SH_FE_Install_Upgrade_Move'), 'Closed');
         insert wo;
         
         ContentVersion testContentInsert = new ContentVersion();
         testContentInsert.ContentURL='http://www.google.com/';
         testContentInsert.Title ='ServiceReport';
         insert testContentInsert;
         
     
         Test.startTest();
         
         FeedItem feed = new FeedItem (
         ParentId = wo.id,
         RelatedRecordId = testContentInsert.Id,
         Title = 'ServiceReport',
         Body = 'Hello'
         );
         insert feed;
         
         Test.stopTest();   
    
    }


}