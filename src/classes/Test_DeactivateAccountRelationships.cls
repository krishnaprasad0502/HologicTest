/*--------------------------------------------------------------------------------------------------
Author:      Mani Sundaresan
Description:  Test class to validate DeactivateAccountRelationships scheduler and batch job
Tests Excecuted:
        
        testScheduler - verifies the scheduler works
        
        testBatch - verfies that the Status on Account relationship records have been updated

History:
<Date>      <Authors Name>    <Brief Description of Change>
07/28/2016  Mani Sundaresan   Initial Creation
---------------------------------------------------------------------------------------------------------*/
@isTest
private class Test_DeactivateAccountRelationships{
    
    static{
        TestUtility.setupConfigurationSettings();
    }

    static testMethod void testScheduler(){
    
       Test.startTest();
       DeactivateAccountRelationships scheduledJob = new DeactivateAccountRelationships();     
       String sch = '0 0 0 * * ?';
       String jobId = System.schedule('Test Schedule', sch, scheduledJob);
      
       CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id =: jobId];
       System.assertEquals(sch, ct.CronExpression);
        System.assertEquals(0, ct.TimesTriggered);
        Test.stopTest();
    
    }
    
    static testMethod void testBatch(){
    
        List<Account> accountList = new List<Account>();
        List<Account_Relationships__c> accRel = new List<Account_Relationships__c>();
        
       
        Account testAccount1 = TestUtility.newAccount('Test Site Account1', 'testSite1', 'ABC Street1', null, GlobalUtility.getRecordTypeId('Account', 'Site'));
        Account testAccount2 =  TestUtility.newAccount('Test Site Account2', 'testSite2', 'ABC Street2', null, GlobalUtility.getRecordTypeId('Account', 'Customer'));
        
        accountList.add(testAccount1);
        accountList.add(testAccount2);
        
        insert accountList;
        
        Account_Relationships__c accRel1 = new Account_Relationships__c(Account__c = accountList[0].Id, Related_Entity__c = accountList[1].Id, Status__c = 'Active', Start_Date__c = Date.Today().addDays(-2), End_Date__c = Date.Today().addDays(-1));
        accRel.add(accRel1);
        
        Account_Relationships__c accRel2 = new Account_Relationships__c(Account__c = accountList[0].Id, Related_Entity__c = accountList[1].Id, Status__c = 'Inactive', Start_Date__c = Date.Today(), End_Date__c = Date.Today().addDays(2));
        accRel.add(accRel2);
        
        insert accRel;
        
        Test.startTest();
        Database.executeBatch(new DeactivateAccountRelationships());
        Test.stopTest();
        
        List<Account_Relationships__c> accRelList = [SELECT Id, Status__c, End_Date__c, Start_Date__c from Account_Relationships__c where Id IN :accRel];
        
        for(Account_Relationships__c ar : accRelList){
            if(ar.End_Date__c == Date.Today().addDays(-1))
                System.assertEquals('Inactive', ar.Status__c);
            else if(ar.Start_Date__c == Date.Today())
                System.assertEquals('Active', ar.Status__c);
         }
         
      }
}