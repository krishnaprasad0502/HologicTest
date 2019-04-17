/*--------------------------------------------------------------------------------------------------
Author:      Mani Sundaresan
Description:  Test class to validate AddAlignmentsOnAccount scheduler and batch job
Tests Excecuted:

testScheduler - verifies the scheduler works

testBatch - verfies that the Alignments and Territories are added to the newly created Site Accounts

History:
<Date>      <Authors Name>    <Brief Description of Change>
07/22/2016  Mani Sundaresan   Initial Creation
08/12/2016  Mani Sundaresan   Updated to cover Territory creation on Site Accounts
---------------------------------------------------------------------------------------------------------*/
@isTest(seeAllData = true)
private class Test_AddAlignmentsOnAccount{

    
    static testMethod void testScheduler(){
        
        Test.startTest();
        AddAlignmentsOnAccount scheduledJob = new AddAlignmentsOnAccount();     
        String sch = '0 0 0 * * ?';
        String jobId = System.schedule('Test Schedule', sch, scheduledJob);
        
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id =: jobId];
        System.assertEquals(sch, ct.CronExpression);
        System.assertEquals(0, ct.TimesTriggered);
        Test.stopTest();
        
    }
    
    static testMethod void testBatch(){
        
        List<Account> accountList = new List<Account>();
        List<TAV4__Account_Assignment__c> accAssList = new List<TAV4__Account_Assignment__c>();
        List<ObjectTerritory2Association> o2ta = new List<ObjectTerritory2Association>();
        
        ////Alignment Creation/////
        TAV4__Geo_Container__c geo = new TAV4__Geo_Container__c(Name='Test',TAV4__Prefix__c='Test_123',TAV4__Identifier_Length__c=1);
        insert geo;
        
        TAV4__Alignment__c tav = new TAV4__Alignment__c(Name='Test',TAV4__Geo_Container__c=geo.id,TAV4__Is_Valid__c=true,TAV4__Auto_assign_Accounts__c = true);
        insert tav;
        
        //Territory2Model terrModel = [SELECT Id from Territory2Model limit 1];
        
        //List<Territory2Type> terriType   = [SELECT id, DeveloperName from Territory2Type where  DeveloperName = 'AM' LIMIT 1];
        
        Territory2 objTerr = [SELECT Id, Name from Territory2 where Name LIKE '%ABD%' limit 1];
        
        String territoryName = '%'+objTerr.Name+'%';
        
        TAV4__Sales_Area__c sa = [SELECT Id, Name from TAV4__Sales_Area__c where TAV4__Alignment__r.TAV4__Is_Valid__c=true and TAV4__Is_Assignable__c=true limit 1];
        sa.Name = objTerr.Name;
            update sa;
       
        system.debug(sa);
        Id siteAccountRecordType = GlobalUtility.getRecordTypeId('Account','Site');
        
              
        //Account testAccount1 = [SELECT Id from Account where RecordTypeId = :siteAccountRecordType and ParentId != null limit 1];
        Account testAccount1 = TestUtility.newAccountWithAddresses('Test Site Account1',null, GlobalUtility.getRecordTypeId('Account', 'Site') , '55 FRUIT STREET', 'Boston','Massachusetts','United States','02130','','','','','' );
        testAccount1.Account_Status__c = 'Draft';
        Account testAccount2 = TestUtility.newAccountWithAddresses('Test Site Account2',null, GlobalUtility.getRecordTypeId('Account', 'Site') , '55 FRUIT STREET', 'Boston','Massachusetts','United States','02130','','','','','' );
        //Account testAccount3 = TestUtility.newAccount('Test Site Account3', 'testCust1', '55 FRUIT STREET', null, GlobalUtility.getRecordTypeId('Account', 'Customer'));
        testAccount2.Account_Status__c = 'Active';
        Account testAccount4 = TestUtility.newAccountWithAddresses('Test Site Account3',null, GlobalUtility.getRecordTypeId('Account', 'Site') , '55 FRUIT STREET', 'Boston','Massachusetts','United States','02130','','','','','' );
        testAccount4.Account_Status__c = 'Active';
        insert testAccount4;
        Account testAccount5 = TestUtility.newAccountWithAddresses('Test Site Account4',null, GlobalUtility.getRecordTypeId('Account', 'Site') , '55 FRUIT STREET', 'Boston','Massachusetts','United States','02130','','','','','' );
        testAccount5.Account_Status__c = 'Inactive';
        testAccount5.ParentId=testAccount4.id;
        
        accountList.add(testAccount1);
        accountList.add(testAccount2);
        //accountList.add(testAccount3);
        //accountList.add(testAccount4);
        accountList.add(testAccount5);
        
        upsert accountList;
                
        TAV4__Account_Assignment__c accAss2 = new TAV4__Account_Assignment__c(TAV4__Account__c = testAccount5.Id, TAV4__Alignment__c = sa.TAV4__Alignment__c,TAV4__Sales_Area__c=sa.id);
        accAssList.add(accAss2);
        TAV4__Account_Assignment__c accAss1 = new TAV4__Account_Assignment__c(TAV4__Account__c = testAccount2.Id, TAV4__Alignment__c = sa.TAV4__Alignment__c,TAV4__Sales_Area__c=sa.id);
        accAssList.add(accAss1);
        
        insert accAssList;
        
        ObjectTerritory2Association objObjectTerritory2Association = new ObjectTerritory2Association(ObjectId = testAccount1.Id, Territory2Id =objTerr.Id, AssociationCause='Territory2Manual' );
              ObjectTerritory2Association objObjectTerritory2Associations = new ObjectTerritory2Association(ObjectId = testAccount4.Id, Territory2Id =objTerr.Id, AssociationCause='Territory2Manual' );
        o2ta.add(objObjectTerritory2Association);
o2ta.add(objObjectTerritory2Associations);                
        insert o2ta;
        
        Test.startTest();
        accountList[1].ParentId = accountList[0].Id;
        update accountList;
        Database.executeBatch(new AddAlignmentsOnAccount());
        //System.abortJob(batchID);
        Test.stopTest();
        
    }
    
   
    
    
}