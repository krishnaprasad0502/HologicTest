@isTest
private class PopulateContractAgreedPrice_Test{

    static testMethod void testScheduler(){
        Test.startTest();
        PopulateContractAgreedPrice scheduledJob = new PopulateContractAgreedPrice();     
        String sch = '0 0 0 * * ?';
        String jobId = System.schedule('Test Schedule', sch, scheduledJob);
        
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id =: jobId];
        System.assertEquals(sch, ct.CronExpression);
        System.assertEquals(0, ct.TimesTriggered);
        Test.stopTest();
    }
    
    static testMethod void testBatch(){
        
        TestUtility.setupConfigurationSettings();
        TestUtility.insertCustSetting('CustomerEligibleContractTrigger');
        TestUtility.insertCustSetting('AgreedPriceTrigger');
        List<Trigger_Switch__c> tsList = [SELECT Id, Active__c from Trigger_Switch__c where Name IN ('CustomerEligibleContractTrigger','AgreedPriceTrigger')];
        for(Trigger_Switch__c ts : tsList)
            ts.Active__c = false;
            
        update tsList;
        TestUtility.insertCustSetting('ContactTrigger');
        List<Contract> contractList = new List<Contract>();
        List<Customer_Eligible_Contract__c> cecList = new List<Customer_Eligible_Contract__c>();
        List<Agreed_Price__c> apList = new List<Agreed_Price__c>();
        
        Account testAccount =  TestUtility.newAccount('Test Site Account2', 'testSite2', 'ABC Street2', null, GlobalUtility.getRecordTypeId('Account', 'Customer'));
        insert testAccount;
        
        //Contract creation    
        Contract c1 = new Contract(AccountId = testAccount.Id, Contract_End_Date__c = Date.Today().addDays(-1), Automatic_Renewal__c = False);
        c1.Contract_Source__c='TestSource';
        c1.Agreed_Price_Groups_Exist__c=true;
        c1.number_of_times_Auto_Renewed__c=2;
        c1.Division__c = 'BSH';
        contractList.add(c1);
        
        //insert c1;
        //c1.status = 'Activated';
        //update c1;
        
        Contract c2 = new Contract(AccountId = testAccount.Id, Contract_End_Date__c = Date.Today().addDays(-1), Automatic_Renewal__c = False);
        c2.Contract_Source__c='TestSource';
        c2.Agreed_Price_Groups_Exist__c=true;
        c2.number_of_times_Auto_Renewed__c=2;
        c2.Division__c = 'BSH';
        contractList.add(c2);
        
        insert contractList;
        
        contractList[0].Status = 'Activated';
        contractList[1].Status = 'Activated';
        update contractList;
        
        //Agreed Price creation for C1
        for(Integer i=0 ; i<5; i++){
            Agreed_Price__c ap1= new Agreed_Price__c();
            ap1.Contract__c=c1.id;
            ap1.Price__c=23;
            apList.add(ap1);
        }
        insert apList;
        
        //Inserting Customer Eligible Contracts from the Contract C1
        for(Integer i=0;i<5;i++){
            Customer_Eligible_Contract__c cec = new Customer_Eligible_Contract__c();
            cec.Contract__c = c1.Id;
            cec.Precedence_Value__c = 175;
            cec.Customer_Account__c = testAccount.Id;
            cecList.add(cec);
        }
        insert cecList;
        
        apList.clear();
        //Agreed Price creation for C2
        for(Integer i=0 ; i<102; i++){
            Agreed_Price__c ap1= new Agreed_Price__c();
            ap1.Contract__c=c2.id;
            ap1.Price__c=23;
            apList.add(ap1);
        }
        insert apList;
        
        cecList.clear();
        //Inserting Customer Eligible Contracts from the Contract C2
        for(Integer i=0;i<100;i++){
            Customer_Eligible_Contract__c cec = new Customer_Eligible_Contract__c();
            cec.Contract__c = c2.Id;
            cec.Precedence_Value__c = 175;
            cec.Customer_Account__c = testAccount.Id;
            cecList.add(cec);
        }
        insert cecList;
        
        Test.startTest();
        Database.executeBatch(new PopulateContractAgreedPrice());
        Test.stopTest();   
        
    }
    
}