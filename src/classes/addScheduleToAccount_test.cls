@isTest
private class addScheduleToAccount_test {
    private static testMethod void testaddScheduleToAccount1() {
          TestUtility.setupConfigurationSettings();
       
        Account acc = TestUtility.newAccount('Account0', 'Account0');
        insert acc;
        
        Contract cntrct = new Contract(Name='TestContract', StartDate=System.Today(), Contract_End_Date__c = System.today() + 5, ContractTerm=11, AccountId=acc.Id, Status='Draft');
        insert cntrct ;
        
        cntrct.Status = 'Activated';
        update cntrct; 
    
        ApexPages.StandardController sc;
        addScheduleToAccount asta;
                
        Test.startTest();
            sc = new ApexPages.StandardController(acc);
            asta = new addScheduleToAccount( sc );
            
            List<addScheduleToAccount.schedule> schedules=asta.getCurrentPage();
            //asta.nextPage();
            //asta.prevPage();
            asta.scheduleList[0].selected = TRUE;
            asta.selectSchedules();
            schedules = asta.getSelectedSchedules();            
            
            List<addScheduleToAccount.CECWrapper> prioritizers=asta.getPrioritizerPage();
            
            asta.saveAll();
                       
        Test.stopTest();
    }
    private static testMethod void testaddScheduleToAccount2() {
            TestUtility.setupConfigurationSettings();
     
        Account acc = TestUtility.newAccount('Account0', 'Account0');
        insert acc;
        
        Contract cntrct = new Contract(Name='TestContract', StartDate=System.Today(), Contract_End_Date__c = System.today() + 5, ContractTerm=11, AccountId=acc.Id, Status='Draft');
        insert cntrct ;
        
        cntrct.Status = 'Activated';
        update cntrct; 
    
        ApexPages.StandardController sc;
        addScheduleToAccount asta;
                
        Test.startTest();
            sc = new ApexPages.StandardController(acc);
            asta = new addScheduleToAccount( sc );
            
            List<addScheduleToAccount.schedule> schedules=asta.getCurrentPage();
            //asta.nextPage();
            //asta.prevPage();
            asta.scheduleList[0].selected = TRUE;
            asta.selectSchedules();
            schedules = asta.getSelectedSchedules();            
            
            List<addScheduleToAccount.CECWrapper> prioritizers=asta.getPrioritizerPage();
            
            asta.cancel();
                       
        Test.stopTest();
    } 
    private static testMethod void testaddScheduleToAccount3() {
           TestUtility.setupConfigurationSettings();
      
        Account acc = TestUtility.newAccount('Account0', 'Account0');
        insert acc;
        
        Contract cntrct = new Contract(Name='TestContract', StartDate=System.Today(),  Contract_End_Date__c = System.today() + 5, ContractTerm=11, AccountId=acc.Id, Status='Draft');
        insert cntrct ;
        
        cntrct.Status = 'Activated';
        update cntrct; 
    
        ApexPages.StandardController sc;
        addScheduleToAccount asta;
                
        Test.startTest();
            sc = new ApexPages.StandardController(acc);
            asta = new addScheduleToAccount( sc );
            
            List<addScheduleToAccount.schedule> schedules=asta.getCurrentPage();
            //asta.nextPage();
            //asta.prevPage();
            asta.scheduleList[0].selected = FALSE;
            asta.selectSchedules();
            schedules = asta.getSelectedSchedules();            
            
            List<addScheduleToAccount.CECWrapper> prioritizers=asta.getPrioritizerPage();
            
            asta.cancel();
                       
        Test.stopTest();
    }     
    private static testMethod void testaddScheduleToAccount4() {
           TestUtility.setupConfigurationSettings();
      
        Account acc = TestUtility.newAccount('Account0', 'Account0');
        insert acc;
        
        Contract cntrct = new Contract(Name='TestContract', StartDate=System.Today(), Contract_End_Date__c = System.today() + 5,  ContractTerm=11, AccountId=acc.Id, Status='Draft');
        insert cntrct ;
        
        cntrct.Status = 'Activated';
        update cntrct; 
    
        ApexPages.StandardController sc;
        addScheduleToAccount asta;
                
        Test.startTest();
            sc = new ApexPages.StandardController(acc);
            asta = new addScheduleToAccount( sc );
            
            List<addScheduleToAccount.schedule> schedules=asta.getCurrentPage();
            //asta.nextPage();
            //asta.prevPage();
            asta.scheduleList[0].selected = FALSE;
            asta.selectSchedules();
            schedules = asta.getSelectedSchedules();            
            
            List<addScheduleToAccount.CECWrapper> prioritizers=asta.getPrioritizerPage();
            
            asta.saveAll();
                       
        Test.stopTest();
    }   
    private static testMethod void testaddScheduleToAccount5() {
         TestUtility.setupConfigurationSettings();
        
        Account acc = TestUtility.newAccount('Account0', 'Account0');
        insert acc;
        
        Contract cntrct = new Contract(Name='TestContract', StartDate=System.Today(), Contract_End_Date__c = System.today() + 5, ContractTerm=11, AccountId=acc.Id, Status='Draft');
        insert cntrct ;
        Contract cntrct2 = new Contract(Name='TestContract', StartDate=System.Today(), Contract_End_Date__c = System.today() + 5, ContractTerm=11, AccountId=acc.Id, Status='Draft');
        insert cntrct2 ;        
        cntrct.Status = 'Activated';
        update cntrct; 
        cntrct2.Status = 'Activated';
        update cntrct2;     
        ApexPages.StandardController sc;
        addScheduleToAccount asta;
                
        Test.startTest();
            sc = new ApexPages.StandardController(acc);
            asta = new addScheduleToAccount( sc );
            
            List<addScheduleToAccount.schedule> schedules=asta.getCurrentPage();
            //asta.nextPage();
            //asta.prevPage();
            asta.scheduleList[0].selected = TRUE;
            asta.scheduleList[1].selected = TRUE;    
            asta.selectSchedules();
            schedules = asta.getSelectedSchedules();            
            
            List<addScheduleToAccount.CECWrapper> prioritizers=asta.getPrioritizerPage();
            //can't save with duplicate orders
            asta.SelectedCECWrapper[0].theCEC.Precedence_Value__c=2;
            asta.SelectedCECWrapper[1].theCEC.Precedence_Value__c=2;        
            asta.saveAll();
            //also can't save with 0 orders
            asta.SelectedCECWrapper[0].theCEC.Precedence_Value__c=0;
            asta.SelectedCECWrapper[1].theCEC.Precedence_Value__c=0;        
            asta.saveAll();                       
        Test.stopTest();
    }   
    private static testMethod void testaddScheduleToAccount6() {
           TestUtility.setupConfigurationSettings();
      
        Account acc = TestUtility.newAccount('Account0', 'Account0');
        insert acc;
        
        Contract cntrct = new Contract(Name='TestContract', StartDate=System.Today(), Contract_End_Date__c = System.today() + 5, ContractTerm=11, AccountId=acc.Id, Status='Draft');
        insert cntrct ;
        Contract cntrct2 = new Contract(Name='TestContract', StartDate=System.Today(), Contract_End_Date__c = System.today() + 5, ContractTerm=11, AccountId=acc.Id, Status='Draft');
        insert cntrct2 ;        
        cntrct.Status = 'Activated';
        update cntrct; 
        cntrct2.Status = 'Activated';
        update cntrct2;     
        ApexPages.StandardController sc;
        addScheduleToAccount asta;
                
            sc = new ApexPages.StandardController(acc);
            asta = new addScheduleToAccount( sc );
            
            List<addScheduleToAccount.schedule> schedules=asta.getCurrentPage();
            //asta.nextPage();
            //asta.prevPage();
            asta.scheduleList[0].selected = TRUE;
            asta.scheduleList[1].selected = TRUE;    
            asta.selectSchedules();
            schedules = asta.getSelectedSchedules();            
            
            List<addScheduleToAccount.CECWrapper> prioritizers=asta.getPrioritizerPage();
            //can't save with duplicate orders
            asta.SelectedCECWrapper[0].theCEC.Precedence_Value__c=1;
            asta.SelectedCECWrapper[1].theCEC.Precedence_Value__c=2;        
            asta.saveAll();
        ApexPages.StandardController sc2;
        addScheduleToAccount asta2;
        Test.startTest();
            sc2 = new ApexPages.StandardController(acc);
            asta2 = new addScheduleToAccount( sc2 );
            
            List<addScheduleToAccount.schedule> schedules2=asta2.getCurrentPage();
            //asta.nextPage();
            //asta.prevPage();
            asta2.scheduleList[0].selected = TRUE;
            asta2.scheduleList[1].selected = TRUE;    
            asta2.selectSchedules();
            schedules2 = asta2.getSelectedSchedules();            
            
            List<addScheduleToAccount.CECWrapper> prioritizers2=asta.getPrioritizerPage();
            //can't save with duplicate orders
            asta2.SelectedCECWrapper[0].theCEC.Precedence_Value__c=1;
            asta2.SelectedCECWrapper[1].theCEC.Precedence_Value__c=2;        
            asta2.saveAll();
        Test.stopTest();

    }    
    private static testMethod void testaddScheduleToAccount7() {
         TestUtility.setupConfigurationSettings();
        
        Account acc = TestUtility.newAccount('Account0', 'Account0');
        insert acc;
        
        Contract cntrct = new Contract(Name='TestContract', StartDate=System.Today(), Contract_End_Date__c = System.today() + 5, ContractTerm=1, AccountId=acc.Id, Status='Draft');
        insert cntrct ;
        Contract cntrct2 = new Contract(Name='TestContract', StartDate=System.Today(), Contract_End_Date__c = System.today() + 5, ContractTerm=1, AccountId=acc.Id, Status='Draft');
        insert cntrct2 ;        
        cntrct.Status = 'Activated';
        update cntrct; 
        cntrct2.Status = 'Activated';
        update cntrct2;     
        ApexPages.StandardController sc;
        addScheduleToAccount asta;
                
        Test.startTest();
            sc = new ApexPages.StandardController(acc);
            asta = new addScheduleToAccount( sc );
            
            List<addScheduleToAccount.schedule> schedules=asta.getCurrentPage();
            //asta.nextPage();
            //asta.prevPage();
            asta.scheduleList[0].selected = TRUE;
            asta.scheduleList[1].selected = TRUE;    
            asta.selectSchedules();
            schedules = asta.getSelectedSchedules();            
            
            List<addScheduleToAccount.CECWrapper> prioritizers=asta.getPrioritizerPage();
            //can't save with duplicate orders
            asta.SelectedCECWrapper[0].theCEC.Precedence_Value__c=2;
            asta.SelectedCECWrapper[1].theCEC.Precedence_Value__c=2;        
            asta.saveAll();
            //also can't save with 0 orders
            asta.SelectedCECWrapper[0].theCEC.Precedence_Value__c=0;
            asta.SelectedCECWrapper[1].theCEC.Precedence_Value__c=0; 
            //also can't save with 0 Tiers
            asta.SelectedCECWrapper[0].theCEC.Tier__c=0;
            asta.SelectedCECWrapper[1].theCEC.Tier__c=0; 
        	//also can't save with bad dates based on contract effective and expiration dates
            asta.SelectedCECWrapper[0].theCEC.Effective_Date__c = System.Today().AddDays(-100);
            asta.SelectedCECWrapper[1].theCEC.Effective_Date__c = System.Today().AddDays(100);
            asta.SelectedCECWrapper[0].theCEC.Expiration_Date__c = System.Today().AddDays(100);
            asta.SelectedCECWrapper[1].theCEC.Expiration_Date__c = System.Today().AddDays(-100);        
            asta.saveAll();  
             //also can't save with bad dates based on contract effective and expiration dates
            asta.SelectedCECWrapper[0].theCEC.Effective_Date__c = System.Today().AddDays(100);
            asta.SelectedCECWrapper[1].theCEC.Effective_Date__c = System.Today().AddDays(-100);
            asta.SelectedCECWrapper[0].theCEC.Expiration_Date__c = System.Today().AddDays(-100);
            asta.SelectedCECWrapper[1].theCEC.Expiration_Date__c = System.Today().AddDays(100);        
            asta.saveAll();         
        Test.stopTest();
    }   
}