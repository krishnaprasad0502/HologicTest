/*--------------------------------------------------------------------------------------------------
Author:      Mani Sundaresan
Description:  Test class to validate contractExpiration scheduler and batch job
Tests Excecuted:
        
        testScheduler - verifies the scheduler works
        
        testBatch - verfies that the Status on Contract, Agreed Price and Customer Eligible Contract records have been updated

History:
<Date>      <Authors Name>    <Brief Description of Change>
09/23/2016  Mani Sundaresan   Initial Creation
02/01/2017  Ronald Mendoza    US-0001739 Added Test Method for Price Increases
02/09/2017  Ronald Mendoza    US-0001678 - Updating testBatch method to test Auto Renewals
02/14/2017  Ronald Mendoza    US-0002196 - Updating testBatch method to test Manual Renewals
02/26/2018	Kasmoor Reddy 	  US-0003995 - Updating testBatch method to insert AgreedFixedPricing to enhance the code coverage
---------------------------------------------------------------------------------------------------------*/
@isTest
private class Test_ContractExpiration{

    
    static{
        TestUtility.setupConfigurationSettings();
    }

    static testMethod void testScheduler(){
    
       Test.startTest();
       contractExpiration scheduledJob = new contractExpiration();     
       String sch = '0 0 0 * * ?';
       String jobId = System.schedule('Test Schedule', sch, scheduledJob);
      
       CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id =: jobId];
       System.assertEquals(sch, ct.CronExpression);
        System.assertEquals(0, ct.TimesTriggered);
        Test.stopTest();
    
    }
    
    static testMethod void testBatch(){
    
        List<Contract> contractList = new List<Contract>();
        List<Customer_Eligible_Contract__c> cec = new List<Customer_Eligible_Contract__c>();
        List<Agreed_Price__c> ap = new List<Agreed_Price__c>();
        
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        
        /*User u = new User(Alias = 'standt', Email='standarduser@testorg.com',EmailEncodingKey='UTF-8', FirstName='Salesforce', LastName='Administrator', LanguageLocaleKey='en_US',
                 LocaleSidKey='en_US', ProfileId = p.Id,TimeZoneSidKey='America/Los_Angeles', UserName='standarduser@testorg.com');
        insert u;*/
        
        User u = [SELECT Id from User where LastName='Administrator' AND FirstName='Salesforce' LIMIT 1];
        
        System.runAs(u){

        
            Account testAccount =  TestUtility.newAccount('Test Site Account2', 'testSite2', 'ABC Street2', null, GlobalUtility.getRecordTypeId('Account', 'Customer'));
            insert testAccount;
            
            Contract c1 = new Contract(AccountId = testAccount.Id, Contract_End_Date__c = Date.Today().addDays(-1), Automatic_Renewal__c = False);
            c1.Contract_Source__c='TestSource';
            c1.Agreed_Price_Groups_Exist__c=true;
            c1.number_of_times_Auto_Renewed__c=2;
            insert c1;
            c1.status = 'Activated';
            update c1;
            
            //Inserting Agreed Pricing for the Contract C1

            Agreed_Price__c ap1= new Agreed_Price__c();
            ap1.Contract__c=c1.id;
            ap1.Price__c=23;
            insert ap1;
            ap1.Price__c=24;
            update ap1;
            

            //Creating Contract For Automatic Renewal
            Contract c2 = new Contract(AccountId = testAccount.Id, Contract_End_Date__c = Date.Today().addDays(-1), Automatic_Renewal__c = True);
                        c2.Contract_Source__c='TestSource';

            insert c2;
            c2.status = 'Activated';
            update c2;
            //Inserting Agreed Pricing for the Contract C2
            Agreed_Price__c ap2= new Agreed_Price__c();
            ap2.Contract__c=c2.id;
            ap2.Price__c=23;
            insert ap2;
            ap2.Price__c=24;
            update ap2;
            

            //Creating Contract For Manual Renewal
            Contract c3 = new Contract(AccountId = testAccount.Id, Contract_End_Date__c = Date.Today().addDays(-1), Automatic_Renewal__c = False);
                        c3.Contract_Source__c='TestSource';

            insert c3;
            c3.status = 'Activated';
            update c3;
            
            //Inserting Agreed Pricing for the Contract C3

            Agreed_Price__c ap3= new Agreed_Price__c();
            ap3.Contract__c=c3.id;
            ap3.Price__c=23;
            insert ap3;
            ap3.Price__c=24;
            update ap3;
            
            
            Test.startTest();
            Database.executeBatch(new ContractExpiration(), 200);

          //  Database.executeBatch(new contractExpiration());
            Test.stopTest();
            
            //Testing if Active Contract with End Date is Today or before Today and Auto Renewal is False is set to expired
            Contract con1 = [SELECT Id, Status from Contract where Id=:c1.Id];
            System.assertEquals('Expired', con1.Status);
            Agreed_Price__c apr1 = [SELECT Id, Price__c,End_Date__c from Agreed_Price__c where Id = :ap1.Id];
            System.assertEquals(24, apr1.Price__c);

            //Testing Automatic Renewals to check if Contract End Date was Pushed 12 months and also still active
            Contract con2 = [SELECT Id, Status, Contract_End_Date__c from Contract where Id=:c2.Id];
            System.assertEquals('Activated', con2.Status);
            System.assertEquals(c2.Contract_End_Date__c.addYears(1), con2.Contract_End_Date__c);

            //Testing Manual Renewals to check if Contract End Date was Pushed 12 months and also still active
            Contract con3 = [SELECT Id, Status, Contract_End_Date__c from Contract where Id=:c3.Id];
            System.assertEquals('Expired', con3.Status);
            System.assertNotEquals(c3.Contract_End_Date__c.addYears(1), con3.Contract_End_Date__c);      
        }
    }
        
    //US-0001739 - contractPriceIncrease Test Method
    /*static testMethod void testPriceIncreaseBatch(){
    
        List<Contract> contractList = new List<Contract>();
        List<Agreed_Price__c> ap = new List<Agreed_Price__c>();
        
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User u = [SELECT Id from User where LastName='Administrator' AND FirstName='Salesforce' LIMIT 1];
        
        System.runAs(u){
            //Create Test Data for Account
            Account testAccount =  TestUtility.newAccount('Test Site Account2', 'testSite2', 'ABC Street2', null, GlobalUtility.getRecordTypeId('Account', 'Customer'));
            insert testAccount;
            //Create Test Contract with anniversary date being equal to today in order to execute price increase
            Contract c1 = new Contract(AccountId = testAccount.Id, StartDate = Date.Today().addDays(-366), Price_Protection__c = False, Price_Increase_Percent__c = .03, Contract_End_Date__c = Date.Today().addDays(300), Status = 'Draft');           
            insert c1;
            c1.status = 'Activated';
            update c1;
            //System.debug(c1); 
            //Add Agreed prices to Contract in order to test uplifts
            Agreed_Price__c ap1 = new Agreed_Price__c(Contract__c = c1.Id, Start_Date__c=Date.Today().addDays(-30), End_Date__c = Date.Today().addDays(100), Price__c = 100);
            insert ap1;
            Agreed_Price__c ap2 = new Agreed_Price__c(Contract__c = c1.Id, Start_Date__c=Date.Today().addDays(-40), End_Date__c = Date.Today().addDays(105), Price__c = 200);
            insert ap2;
            Agreed_Price__c ap3 = new Agreed_Price__c(Contract__c = c1.Id, Start_Date__c=Date.Today().addDays(-60), End_Date__c = Date.Today().addDays(110), Price__c = 300);
            insert ap3;
            //Execute Test Method for contract expiration
            Test.startTest();
            Database.executeBatch(new contractExpiration());
            Test.stopTest();          
            //Query Agreed Prices and check if Price Increases occured
            Agreed_Price__c apr1 = [SELECT Id, Price__c,End_Date__c from Agreed_Price__c where Id = :ap1.Id];
            Agreed_Price__c apr2 = [SELECT Id, Price__c,End_Date__c from Agreed_Price__c where Id = :ap2.Id];
            Agreed_Price__c apr3 = [SELECT Id, Price__c,End_Date__c from Agreed_Price__c where Id = :ap3.Id];
            Temporarily Removing Price Increase Assertions since requirements are changing
            System.assertEquals(103, apr1.Price__c);
            System.assertEquals(206, apr2.Price__c);
            System.assertEquals(309, apr3.Price__c);
            
        }
    }*/
}