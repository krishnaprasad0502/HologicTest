@isTest
private class Test_CreatePA_Opp 
{
    private static Account acc; 
    static testMethod void TestPagegoToContract()
    {
        TestUtility.setupConfigurationSettings();
        
        Trigger_Switch__c ts = new Trigger_Switch__c();
        ts.Name = 'Contracttrigger';
        ts.Active__c = true;
        insert ts;
        
        Trigger_Switch__c tsop= new Trigger_Switch__c();
        tsop.Name = 'OpportunityTrigger';
        tsop.Active__c = true;
        insert tsop;        
        
        acc = TestUtility.newAccount('Account0', 'Account0');
        insert acc;
        Contract contract = new Contract();
        contract.AccountId = acc.Id;
        contract.Status = 'Draft';
        contract.StartDate = System.today();
        contract.Contract_End_Date__c = System.today() + 5;
        insert contract;       
       
        contract.Status = 'Activated';        
        update contract;
       
        Opportunity opp = new Opportunity(Name='TestOpp', StageName='Qualify', CloseDate=System.today(), AccountId = acc.Id);
        insert opp;
        ID stdPBId = Test.getStandardPricebookId();

        Pricebook2 pb = new Pricebook2(Name='TestPB', IsActive=TRUE);
        insert pb;
        SBQQ__Quote__c q=new SBQQ__Quote__c(Tax_Calculated__c =true, SBQQ__Account__c=acc.Id , SBQQ__Opportunity2__c=opp.id,SBQQ__PriceBook__c=pb.id,SBQQ__StartDate__c=system.today(), SBQQ__SubscriptionTerm__c=24);
        insert q;
        opp.SBQQ__PrimaryQuote__c = q.id;
        update opp;

        PageReference pageRef = Page.CreatePA_Opp;
        Test.setCurrentPage(pageRef);
        ApexPages.standardController sta_controller = new ApexPages.standardController(opp);
        Opp_Extension_PA controller = new Opp_Extension_PA(sta_controller);
        controller.RunThatOpp();
        controller.goToContract();
    }   
    static testMethod void TestPagereturnToOpp()
    {
        TestUtility.setupConfigurationSettings();
        
        Trigger_Switch__c ts = new Trigger_Switch__c();
        ts.Name = 'Contracttrigger';
        ts.Active__c = true;
        insert ts;
        
        Trigger_Switch__c tsop= new Trigger_Switch__c();
        tsop.Name = 'OpportunityTrigger';
        tsop.Active__c = true;
        insert tsop;
        
        acc = TestUtility.newAccount('Account0', 'Account0');
        insert acc;
        Contract contract = new Contract();
        contract.AccountId = acc.Id;
        contract.Status = 'Draft';
        contract.StartDate = System.today();
        contract.Contract_End_Date__c = System.today() + 5;
        insert contract;
        
        contract.Status = 'Activated';        
        update contract;          
        
        Opportunity opp = new Opportunity(Name='TestOpp', StageName='Qualify', CloseDate=System.today(), AccountId = acc.Id);
        insert opp;
        ID stdPBId = Test.getStandardPricebookId();

        Pricebook2 pb = new Pricebook2(Name='TestPB', IsActive=TRUE);
        insert pb;
        SBQQ__Quote__c q=new SBQQ__Quote__c(Tax_Calculated__c =true, SBQQ__Account__c=acc.Id , SBQQ__Opportunity2__c=opp.id,SBQQ__PriceBook__c=pb.id,SBQQ__StartDate__c=system.today(), SBQQ__SubscriptionTerm__c=24);
        insert q;
        opp.SBQQ__PrimaryQuote__c = q.id;
        update opp;

        PageReference pageRef = Page.CreatePA_Opp;
        Test.setCurrentPage(pageRef);
        ApexPages.standardController sta_controller = new ApexPages.standardController(opp);
        Opp_Extension_PA controller = new Opp_Extension_PA(sta_controller);
        controller.RunThatOpp();
        controller.returnToOpp();
    }   
    /*
    static testMethod void TestPageRunThatOppCloseWon()
    {
        TestUtility.setupConfigurationSettings();
        acc = TestUtility.newAccount('Account0', 'Account0');
        insert acc;
        Contract contract = new Contract();
        contract.AccountId = acc.Id;
        contract.Status = 'Draft';
        contract.StartDate = System.today();
        contract.Contract_End_Date__c = System.today() + 5;
        insert contract;
        contract.Status = 'Activated';
        update contract;

        Opportunity opp = new Opportunity(Name='TestOpp', StageName='Qualify', CloseDate=System.today(), AccountId = acc.Id);
        insert opp;
        opp.StageName='Closed Won';
        opp.Pricing_Agreement_Created__c = true;
        update opp;

        PageReference pageRef = Page.CreatePA_Opp;
        Test.setCurrentPage(pageRef);
        ApexPages.standardController sta_controller = new ApexPages.standardController(opp);
        Opp_Extension_PA controller = new Opp_Extension_PA(sta_controller);
        controller.RunThatOpp();
        ApexPages.Message[] msgs=ApexPages.getMessages();
        Boolean found=false;
        for (ApexPages.Message msg : msgs)
        {
           if (msg.getSummary()=='Pricing Agreement has Already Been Created for this Opportunity')
           {
              found=true;
           }
        }
        System.debug(found);
        System.assert(found);
    }   
    */
    static testMethod void TestPageRunThatOppQPnull()
    {
        TestUtility.setupConfigurationSettings();
        
        Trigger_Switch__c ts = new Trigger_Switch__c();
        ts.Name = 'Contracttrigger';
        ts.Active__c = true;
        insert ts;
        
        Trigger_Switch__c tsop= new Trigger_Switch__c();
        tsop.Name = 'OpportunityTrigger';
        tsop.Active__c = true;
        insert tsop;
        
        acc = TestUtility.newAccount('Account0', 'Account0');
        insert acc;
        Contract contract = new Contract();
        contract.AccountId = acc.Id;
        contract.Status = 'Draft';
        contract.StartDate = System.today();
        contract.Contract_End_Date__c = System.today() + 5;
        insert contract;       
       
        contract.Status = 'Activated';        
        update contract;
       
        Opportunity opp = new Opportunity(Name='TestOpp', StageName='Qualify', CloseDate=System.today(), AccountId = acc.Id);
        insert opp;

        PageReference pageRef = Page.CreatePA_Opp;
        Test.setCurrentPage(pageRef);
        ApexPages.standardController sta_controller = new ApexPages.standardController(opp);
        Opp_Extension_PA controller = new Opp_Extension_PA(sta_controller);
        controller.RunThatOpp();
        ApexPages.Message[] msgs=ApexPages.getMessages();
        Boolean found=false;
        for (ApexPages.Message msg : msgs)
        {
           if (msg.getSummary()=='No Primary Quote on this Opportunity, Please create before continuing')
           {
              found=true;
           }
        }
        System.debug(found);
        System.assert(found);
    }
    static testMethod void TestPageRunThatOppTypeNew()
    {
        TestUtility.setupConfigurationSettings();
        
        Trigger_Switch__c ts = new Trigger_Switch__c();
        ts.Name = 'Contracttrigger';
        ts.Active__c = true;
        insert ts;
        
        Trigger_Switch__c tsop= new Trigger_Switch__c();
        tsop.Name = 'OpportunityTrigger';
        tsop.Active__c = true;
        insert tsop;
        
        acc = TestUtility.newAccount('Account0', 'Account0');
        insert acc;
        Contract contract = new Contract();
        contract.AccountId = acc.Id;
        contract.Status = 'Draft';
        contract.StartDate = System.today();
        contract.Contract_End_Date__c = System.today() + 5;
        contract.ContractTerm = 10;
        insert contract;
       
        contract.Status = 'Activated';        
        update contract;
       
        Opportunity opp = new Opportunity(Name='TestOpp', StageName='Qualify', CloseDate=System.today(), AccountId = acc.Id);
        insert opp;
        ID stdPBId = Test.getStandardPricebookId();

        Pricebook2 pb = new Pricebook2(Name='TestPB', IsActive=TRUE);
        insert pb;
        SBQQ__Quote__c q=new SBQQ__Quote__c(Tax_Calculated__c =true, SBQQ__Account__c=acc.Id , SBQQ__Opportunity2__c=opp.id,SBQQ__PriceBook__c=pb.id,SBQQ__StartDate__c=system.today(), SBQQ__SubscriptionTerm__c=24, SBQQ__EndDate__c = system.today()+5);
        insert q;
        //opp.StageName='Closed Won';
        opp.Pricing_Agreement_Created__c = true;
        //opp.SBQQ__RenewedContract__c = contract.Id;
        opp.SBQQ__AmendedContract__c = contract.Id;
        opp.SBQQ__PrimaryQuote__c = q.id;
        update opp;

        PageReference pageRef = Page.CreatePA_Opp;
        Test.setCurrentPage(pageRef);
        // Add parameters to page URL
        ApexPages.currentPage().getParameters().put('type', 'New');
        ApexPages.standardController sta_controller = new ApexPages.standardController(opp);
        Opp_Extension_PA controller = new Opp_Extension_PA(sta_controller);
        controller.RunThatOpp();
        ApexPages.Message[] msgs=ApexPages.getMessages();
        Boolean found=false;
        for (ApexPages.Message msg : msgs)
        {
           if (msg.getSummary()=='This Opportunity was generated from an Amendment or a Renewal, you may not create a new Pricing Agreement')
           {
              found=true;
           }
        }
        System.debug(found);
        System.assert(found);
    }
    static testMethod void TestPageRunThatOppAmend()
    {
        TestUtility.setupConfigurationSettings();
        
        Trigger_Switch__c ts = new Trigger_Switch__c();
        ts.Name = 'Contracttrigger';
        ts.Active__c = true;
        insert ts;
        
        Trigger_Switch__c tsop= new Trigger_Switch__c();
        tsop.Name = 'OpportunityTrigger';
        tsop.Active__c = true;
        insert tsop;
        
        acc = TestUtility.newAccount('Account0', 'Account0');
        insert acc;
        Contract contract = new Contract();
        contract.AccountId = acc.Id;
        contract.Status = 'Draft';
        contract.StartDate = System.today();
        contract.Contract_End_Date__c = System.today() + 5;
        contract.ContractTerm=24;
        insert contract;
       
        contract.Status = 'Activated';        
        update contract;
       
        Opportunity opp = new Opportunity(Name='TestOpp', StageName='Qualify', CloseDate=System.today(), AccountId = acc.Id);
        insert opp;
        ID stdPBId = Test.getStandardPricebookId();

        Pricebook2 pb = new Pricebook2(Name='TestPB', IsActive=TRUE);
        insert pb;
        SBQQ__Quote__c q=new SBQQ__Quote__c(Tax_Calculated__c =true, SBQQ__Account__c=acc.Id , SBQQ__Opportunity2__c=opp.id,SBQQ__PriceBook__c=pb.id,SBQQ__StartDate__c=system.today(), SBQQ__SubscriptionTerm__c=24,SBQQ__EndDate__c=system.today().addMonths(24));
        insert q;
        //opp.StageName='Closed Won';
        q.SBQQ__EndDate__c=system.today().addMonths(32);
        update q;
        
        opp.Pricing_Agreement_Created__c = true;
        opp.SBQQ__PrimaryQuote__c = q.id;
        update opp;

        PageReference pageRef = Page.CreatePA_Opp;
        Test.setCurrentPage(pageRef);
        // Add parameters to page URL
        ApexPages.currentPage().getParameters().put('type', 'Amendment');
        ApexPages.standardController sta_controller = new ApexPages.standardController(opp);
        Opp_Extension_PA controller = new Opp_Extension_PA(sta_controller);
        controller.RunThatOpp();
        ApexPages.Message[] msgs=ApexPages.getMessages();
        Boolean found=false;
        for (ApexPages.Message msg : msgs)
        {
           if (msg.getSummary()=='You may not Amend this Opportunity/Pricing Agreement.  This Opportunity was not generated from an Amended Contract')
           {
              found=true;
           }
        }
        System.debug(found);
        System.assert(found);
    }
    static testMethod void TestPageRunThatOppRenew()
    {
        TestUtility.setupConfigurationSettings();
        
        Trigger_Switch__c ts = new Trigger_Switch__c();
        ts.Name = 'Contracttrigger';
        ts.Active__c = true;
        insert ts;
        
        Trigger_Switch__c tsop= new Trigger_Switch__c();
        tsop.Name = 'OpportunityTrigger';
        tsop.Active__c = true;
        insert tsop;
        
        acc = TestUtility.newAccount('Account0', 'Account0');
        insert acc;
        Contract contract = new Contract();
        contract.AccountId = acc.Id;
        contract.Status = 'Draft';
        contract.StartDate = System.today();
        contract.Contract_End_Date__c = System.today() + 5;
        insert contract;
      
        contract.Status = 'Activated';        
        update contract;
       
        Opportunity opp = new Opportunity(Name='TestOpp', StageName='Qualify', CloseDate=System.today(), AccountId = acc.Id);
        insert opp;
        ID stdPBId = Test.getStandardPricebookId();

        Pricebook2 pb = new Pricebook2(Name='TestPB', IsActive=TRUE);
        insert pb;
        SBQQ__Quote__c q=new SBQQ__Quote__c(Tax_Calculated__c =true, ApprovalStatus__c='Approved',SBQQ__Account__c=acc.Id , SBQQ__Opportunity2__c=opp.id,SBQQ__PriceBook__c=pb.id,SBQQ__StartDate__c=system.today(), SBQQ__SubscriptionTerm__c=24,SBQQ__EndDate__c=system.today().addMonths(24));
        insert q;
        //opp.StageName='Closed Won';
        q.SBQQ__EndDate__c=system.today().addMonths(32);
        update q;
        
        opp.Pricing_Agreement_Created__c = true;
        opp.SBQQ__PrimaryQuote__c = q.id;
        update opp;

        PageReference pageRef = Page.CreatePA_Opp;
        Test.setCurrentPage(pageRef);
        // Add parameters to page URL
        ApexPages.currentPage().getParameters().put('type', 'Renewal');
        ApexPages.standardController sta_controller = new ApexPages.standardController(opp);
        Opp_Extension_PA controller = new Opp_Extension_PA(sta_controller);
        controller.RunThatOpp();
        ApexPages.Message[] msgs=ApexPages.getMessages();
        Boolean found=false;
        for (ApexPages.Message msg : msgs)
        {
           if (msg.getSummary()=='You may not Renew this Opportunity/Pricing Agreement.  This Opportunity was not generated from a Renewal Contract')
           {
              found=true;
           }
        }
        System.debug(found);
        System.assert(found);
    }
    static testMethod void TestPageRunThatOppElse()
    {
        TestUtility.setupConfigurationSettings();
        
        Trigger_Switch__c ts = new Trigger_Switch__c();
        ts.Name = 'Contracttrigger';
        ts.Active__c = true;
        insert ts;
        
        Trigger_Switch__c tsop= new Trigger_Switch__c();
        tsop.Name = 'OpportunityTrigger';
        tsop.Active__c = true;
        insert tsop;
        
        acc = TestUtility.newAccount('Account0', 'Account0');
        insert acc;
        Contract contract = new Contract();
        contract.AccountId = acc.Id;
        contract.Status = 'Draft';
        contract.StartDate = System.today();
        contract.Contract_End_Date__c = System.today() + 5;
        insert contract;
        
        contract.Status = 'Activated';        
        update contract;
       
        Opportunity opp = new Opportunity(Name='TestOpp', StageName='Qualify', CloseDate=System.today(), AccountId = acc.Id);
        insert opp;
        ID stdPBId = Test.getStandardPricebookId();

        Pricebook2 pb = new Pricebook2(Name='TestPB', IsActive=TRUE);
        insert pb;
        SBQQ__Quote__c q=new SBQQ__Quote__c(Tax_Calculated__c =true, ApprovalStatus__c='Approved',SBQQ__Account__c=acc.Id , SBQQ__Opportunity2__c=opp.id,SBQQ__PriceBook__c=pb.id,SBQQ__StartDate__c=system.today(), SBQQ__SubscriptionTerm__c=24);
        insert q;
        opp.SBQQ__PrimaryQuote__c = q.id;
        update opp;

        PageReference pageRef = Page.CreatePA_Opp;
        Test.setCurrentPage(pageRef);
        ApexPages.standardController sta_controller = new ApexPages.standardController(opp);
        Opp_Extension_PA controller = new Opp_Extension_PA(sta_controller);
        controller.RunThatOpp();
    }
    //Created method to test Diagnostic Amendments
     static testMethod void TestPageRunThatOppAmendDiag()
    {
        TestUtility.setupConfigurationSettings();
        
        Trigger_Switch__c ts = new Trigger_Switch__c();
        ts.Name = 'Contracttrigger';
        ts.Active__c = true;
        insert ts;
        
        Trigger_Switch__c tsop= new Trigger_Switch__c();
        tsop.Name = 'OpportunityTrigger';
        tsop.Active__c = true;
        insert tsop;
        
        acc = TestUtility.newAccount('Account0', 'Account0');
        insert acc;
        Contract contract = new Contract();
        contract.AccountId = acc.Id;
        contract.Status = 'Draft';
        contract.StartDate = System.today();
        contract.Contract_End_Date__c = System.today() + 5;
        contract.ContractTerm=24;
        insert contract;
       
        contract.Status = 'Activated';        
        update contract;
       
        Opportunity opp = new Opportunity(Name='TestOpp', StageName='Qualify', CloseDate=System.today(), AccountId = acc.Id, SBQQ__AmendedContract__c = contract.Id);
        insert opp;
        ID stdPBId = Test.getStandardPricebookId();

        Pricebook2 pb = new Pricebook2(Name='TestPB', IsActive=TRUE);
        insert pb;
        SBQQ__Quote__c q=new SBQQ__Quote__c(Tax_Calculated__c =true, SBQQ__Account__c=acc.Id , SBQQ__Opportunity2__c=opp.id,SBQQ__PriceBook__c=pb.id,SBQQ__StartDate__c=system.today(), SBQQ__SubscriptionTerm__c=24,SBQQ__EndDate__c=system.today().addMonths(24));
        insert q;
        //opp.StageName='Closed Won';
        q.SBQQ__EndDate__c=system.today().addMonths(32);
        update q;
        
        opp.Pricing_Agreement_Created__c = true;
        opp.SBQQ__PrimaryQuote__c = q.id;
        update opp;

        PageReference pageRef = Page.CreatePA_Opp;
        Test.setCurrentPage(pageRef);
        // Add parameters to page URL
        ApexPages.currentPage().getParameters().put('type', 'DiagnosticAmendment');
        ApexPages.standardController sta_controller = new ApexPages.standardController(opp);
        Opp_Extension_PA controller = new Opp_Extension_PA(sta_controller);
        controller.RunThatOpp();
        controller.gotoQuote();
        ApexPages.Message[] msgs=ApexPages.getMessages();
        Boolean found=false;
        for (ApexPages.Message msg : msgs)
        {
           if (msg.getSummary()=='You may not Amend this Opportunity/Pricing Agreement.  This Opportunity was not generated from an Amended Contract')
           {
              found=true;
           }
        }
    }
}