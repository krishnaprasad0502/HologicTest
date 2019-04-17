/*--------------------------------------------------------------------------------------------------
Author:      Mani Sundaresan
Description:  Test class to validate Temp_QuoteJobRecordClearanceJobScheduler scheduler class
Tests Excecuted:

testScheduler - verifies the scheduler works


History:
<Date>      <Authors Name>    <Brief Description of Change>
06/09/2017  Mani Sundaresan   Initial Creation
---------------------------------------------------------------------------------------------------------*/
@isTest(seeAllData = false)
private class QuoteJobRecordClearanceJobScheduler_Test{
    
    static testMethod void testScheduler(){
        List<SBQQ__QuoteLine__c> quoteLines=new List<SBQQ__QuoteLine__c>();
         TestUtility.setupConfigurationSettings();
         TestUtility.insertCustSetting('OpportunityTrigger'); 
                List<Account> accList=new List<Account>();
        for(Integer i=0; i<=3; i++){
            String accName='1234567' + string.valueOf(i);
            accList.add(TestUtility.newAccount(accName, accName));
        }

        //insert accList;
        
        Integer k=0;
        for(Account acc:accList){

            acc.Oracle_Party_Id__c=String.valueOf(k);
            k++;
        }
        System.assertNotEquals(accList,null,'success');
        insert accList;
         PriceBook2 pricebook = new Pricebook2(name='Test Pricebook');
        insert pricebook;
               
        //Create Products
        List<Product2> prodList=new List<Product2>();
        for(Integer i=0; i<=5; i++){
            String prodName='Product ' + string.valueOf(i);
            prodList.add(new Product2(Name = prodName, IsActive = true, Quotable__c = true,Description='test product'));
        }
       
        System.assertNotEquals(prodList,null,'success');
        insert prodList;
         Opportunity newOpp = new Opportunity();
        newOpp.AccountId = accList.get(0).id;
        newOpp.StageName = 'Target';
        newOpp.CloseDate = System.today();
        newOpp.Name = 'OppTest';
        newOpp.Pricebook2Id = pricebook.Id;
        insert newOpp;
        System.assertEquals('OppTest',newOpp.Name);
         SBQQ__Quote__c q=new SBQQ__Quote__c(Quote_Name__c='OrderConfirmationPageTest Quote', Order_Type__c='DANBURY SYSTEM ORDER', Operating_Unit__c='HOLX_US_OU', SBQQ__Account__c=accList.get(0).id, SBQQ__Opportunity2__c=newOpp.id,SBQQ__PriceBook__c=pricebook.Id,Requested_Date__c = system.today());
        insert q;
          /*for(Integer i=0; i<=2; i++){
            quoteLines.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c=q.Id, Account__c=accList.get(0).id, Include_In_Order__c=true, SBQQ__Product__c=prodList.get(i).Id, SBQQ__ListPrice__c = 100, SBQQ__Quantity__c=1,Requested_Date__c = system.today()));
        }*/
        
        quoteLines.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c=q.Id, Account__c=accList.get(0).id, Include_In_Order__c=true, SBQQ__Product__c=prodList.get(0).Id, SBQQ__ListPrice__c = 100, SBQQ__Quantity__c=1,Requested_Date__c = system.today()));
        insert quoteLines;
        SBQQ__RecordJob__c sb=new SBQQ__RecordJob__c(SBQQ__JobStatus__c='Queued',SBQQ__IsRead__c=true,SBQQ__JobDetails__c='Sample Job Details',SBQQ__JobId__c=q.Id,SBQQ__RecordId__c='::'+q.id+'::');
        insert sb;
        Test.startTest();
        Temp_QuoteJobRecordClearanceJobScheduler scheduledJob = new Temp_QuoteJobRecordClearanceJobScheduler();     
        String sch = '0 0 0 * * ?';
        String jobId = System.schedule('Test Schedule', sch, scheduledJob);
        
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id =: jobId];
        System.assertEquals(sch, ct.CronExpression);
        System.assertEquals(0, ct.TimesTriggered);
        Test.stopTest();
        
    }
    
     static testMethod void testScheduler1(){
        List<SBQQ__QuoteLine__c> quoteLines=new List<SBQQ__QuoteLine__c>();
         TestUtility.setupConfigurationSettings();
         TestUtility.insertCustSetting('OpportunityTrigger'); 
                List<Account> accList=new List<Account>();
        for(Integer i=0; i<=3; i++){
            String accName='1234567' + string.valueOf(i);
            accList.add(TestUtility.newAccount(accName, accName));
        }

        //insert accList;
        
        Integer k=0;
        for(Account acc:accList){

            acc.Oracle_Party_Id__c=String.valueOf(k);
            k++;
        }
        System.assertNotEquals(accList,null,'success');
        insert accList;
         PriceBook2 pricebook = new Pricebook2(name='Test Pricebook');
        insert pricebook;
               
        //Create Products
        List<Product2> prodList=new List<Product2>();
        for(Integer i=0; i<=5; i++){
            String prodName='Product ' + string.valueOf(i);
            prodList.add(new Product2(Name = prodName, IsActive = true, Quotable__c = true,Description='test product'));
        }
       
        System.assertNotEquals(prodList,null,'success');
        insert prodList;
         Opportunity newOpp = new Opportunity();
        newOpp.AccountId = accList.get(0).id;
        newOpp.StageName = 'Target';
        newOpp.CloseDate = System.today();
        newOpp.Name = 'OppTest';
        newOpp.Pricebook2Id = pricebook.Id;
        insert newOpp;
        System.assertEquals('OppTest',newOpp.Name);
          SBQQ__Quote__c q=new SBQQ__Quote__c(Quote_Name__c='OrderConfirmationPageTest Quote', Order_Type__c='DANBURY SYSTEM ORDER', Operating_Unit__c='HOLX_US_OU', SBQQ__Account__c=accList.get(0).id, SBQQ__Opportunity2__c=newOpp.id,SBQQ__PriceBook__c=pricebook.Id,Requested_Date__c = system.today());
        insert q;
          /*for(Integer i=0; i<=2; i++){
            quoteLines.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c=q.Id, Account__c=accList.get(0).id, Include_In_Order__c=true, SBQQ__Product__c=prodList.get(i).Id, SBQQ__ListPrice__c = 100, SBQQ__Quantity__c=1,Requested_Date__c = system.today()));
        }*/
      
        //Profile objProfile = [Select Id, Name from Profile where Name =: 'System Administrator' limit 1];

		User objeUser = [Select Id, ProfileId,name from User where name=:'Salesforce Administrator' limit 1];
        system.runAs(objeUser)
        {
           
        
        quoteLines.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c=q.Id, Account__c=accList.get(0).id, Include_In_Order__c=true, SBQQ__Product__c=prodList.get(0).Id, SBQQ__ListPrice__c = 100, SBQQ__Quantity__c=1,Requested_Date__c = system.today()));
        insert quoteLines;
        SBQQ__RecordJob__c sb1=new SBQQ__RecordJob__c(SBQQ__JobStatus__c='Queued',SBQQ__IsRead__c=true,SBQQ__JobDetails__c='Sample Job Details',SBQQ__JobId__c=q.Id,SBQQ__RecordId__c='::'+q.id+'::');
        insert sb1; 
        }
         
        Test.startTest();
        Temp_QuoteJobRecordClearanceJobScheduler scheduledJob = new Temp_QuoteJobRecordClearanceJobScheduler();     
        String sch = '0 0 0 * * ?';
        String jobId = System.schedule('Test Schedule', sch, scheduledJob);
        
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id =: jobId];
        System.assertEquals(sch, ct.CronExpression);
        System.assertEquals(0, ct.TimesTriggered);
        Test.stopTest();
        
    }
}