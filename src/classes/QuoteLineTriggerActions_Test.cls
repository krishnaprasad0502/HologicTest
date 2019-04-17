/*-------------------------------------------------------------------------------------------------------------------------------------------
Author:         Mani Sundaresan
Description:    Test class to validate QuoteLineTriggerActions
                Tests Excecuted:
                
                TestcheckFieldsAndDisableTrigger - verify that on update of certain QL fields, the pricing calculation job is not executed
                
History:
<Date>          <Authors Name>      <Brief Description of Change>
05/11/2017      Mani Sundaresan       Initial Creation(HD-4290)
--------------------------------------------------------------------------------------------------------------------------------------------*/
@isTest
private class QuoteLineTriggerActions_Test{

    private static Configuration_Settings__c orgDefaults;

    static testMethod void TestcheckFieldsAndDisableTrigger(){
    
        orgDefaults = TestUtility.setupConfigurationSettings();
        
        //Fetching the Id of Integration API profile
        Profile p = [SELECT Id FROM Profile WHERE Name='Integration API User'];
        
        //Creating a test user with Integration API profile
        User u = TestUtility.newUser(p.Id,'TestUser');
    
        TestUtility.insertCustSetting('OpportunityTrigger');
        TestUtility.insertCustSetting('QuoteLineTrigger');
        
        //Creating Test Data
        Account acc = TestUtility.newAccount('Test Account','12345');
        insert acc;
        
        Opportunity opp = TestUtility.newOpportunity('Test Opportunity', acc.Id, System.Today(), 'Target', 'Omitted');
        insert opp;
        
        Product2 testProd = TestUtility.newProduct('Test Product');
        insert testProd;
        
        SBQQ__Quote__c testQuote = TestUtility.newQuote(acc.Id, opp.Id);
        insert testQuote;
        
        testQuote.SBQQ__Primary__c = false;
        update testQuote;
        
        List<SBQQ__QuoteLine__c> testQuoteLine = new List<SBQQ__QuoteLine__c>();
        set<SBQQ__QuoteLine__c> quoteLineset=new set<SBQQ__QuoteLine__c>();
        for(Integer i=0; i<10; i++)
             quoteLineset.add(TestUtility.newQuoteLine(testQuote.Id, testProd.Id, 10.0, 1.0));
        
        testQuoteLine.addall(quoteLineset);
        insert testQuoteLine;
        
        //Perform the update as an Integration User
        Test.startTest();
        System.runAs(u){
            
            for(SBQQ__QuoteLine__c ql : testQuoteLine)
                ql.Include_In_Order__c = true;
            
            update testQuoteLine;
            testQuote.SBQQ__Primary__c = true;
            update testQuote;
            
            for(SBQQ__QuoteLine__c ql : [SELECT Id, Include_In_Order__c from SBQQ__QuoteLine__c where Id in :testQuoteLine])
                System.assertEquals(True,ql.Include_In_Order__c);
        }
        Test.stopTest();    
    }
    
    
}