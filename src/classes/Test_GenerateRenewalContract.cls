@isTest
private class Test_GenerateRenewalContract {
    
    private static Account acc; 
    static testMethod void TestError1()
    {
        TestUtility.setupConfigurationSettings();
        TestUtility.insertCustSetting('OpportunityTrigger');
        TestUtility.insertCustSetting('ContractTrigger');
		 TestUtility.insertCustSetting('CustomerEligibleContractTrigger');
        // 04/10/2017-Krishna Prasad-Added trigger switch to fix Contract Trigger isuue       
        TestUtility.insertCustSetting('SBQQ_QuoteTrigger'); 
        acc = TestUtility.newAccount('Account0', 'Account0');
        insert acc;
        Contract contract = new Contract();
        contract.AccountId = acc.Id;
        contract.Status = 'Draft';
        contract.StartDate = System.today();
        contract.Contract_End_Date__c = System.today() + 5;
        insert contract;
		 //Inserting CEC for the Contract C1
        Customer_Eligible_Contract__c cec1 = new Customer_Eligible_Contract__c();
        cec1.Customer_Account__c = acc.Id;
        cec1.Precedence_Value__c = 1;
        cec1.Selected__c = true;
        cec1.Contract_Activated__c = true;
        cec1.Contract__c = contract.Id;
        insert cec1;
        contract.Status = 'Activated';
        update contract;

        Opportunity opp = new Opportunity(Name='TestOpp', StageName='Qualify', CloseDate=System.today(), AccountId = acc.Id);
        insert opp;
        ID stdPBId = Test.getStandardPricebookId();

        Pricebook2 pb = new Pricebook2(Name='TestPB', IsActive=TRUE);
        insert pb;
        //Create Products
        List<Product2> prodList=new List<Product2>();
        for(Integer i=0; i<=5; i++){
            String prodName='Product ' + string.valueOf(i);
            prodList.add(new Product2(Name = prodName, IsActive = true));
        }

        insert prodList;

        SBQQ__Quote__c q=new SBQQ__Quote__c(Tax_Calculated__c =true, SBQQ__Account__c=acc.Id , SBQQ__Opportunity2__c=opp.id,SBQQ__PriceBook__c=pb.id);
        insert q;

        try
        {
            opp.Renew_Contract_Option__c = 'Don\'t Renew Contract';
            update opp;
            PageReference pageRef = Page.GenerateRenewalContract;
            PageRef.getParameters().put('type','Amendment');
            Test.setCurrentPage(pageRef);
            ApexPages.standardController sta_controller = new ApexPages.standardController(opp);
            Ext_GenerateRenewalContract controller = new Ext_GenerateRenewalContract(sta_controller);
            controller.RunThat();
        }
        catch (Exception e)
        {
            System.assertEquals('Renew Contract option set to do not renew.  ', e.getMessage(), 'Renew Contract option set to do not renew. Did not appear.'   );
        }
    }


    static testMethod void TestError2()
    {
        TestUtility.setupConfigurationSettings();
        TestUtility.insertCustSetting('OpportunityTrigger');
        TestUtility.insertCustSetting('ContractTrigger');
		 TestUtility.insertCustSetting('CustomerEligibleContractTrigger');
        // 04/10/2017-Krishna Prasad-Added trigger switch to fix Contract Trigger isuue       
        TestUtility.insertCustSetting('SBQQ_QuoteTrigger'); 
        acc = TestUtility.newAccount('Account0', 'Account0');
        insert acc;
        Contract contract = new Contract();
        contract.AccountId = acc.Id;
        contract.Status = 'Draft';
        contract.StartDate = System.today();
        contract.Contract_End_Date__c = System.today() + 5;
        insert contract;
		//Inserting CEC for the Contract C1
        Customer_Eligible_Contract__c cec1 = new Customer_Eligible_Contract__c();
        cec1.Customer_Account__c = acc.Id;
        cec1.Precedence_Value__c = 1;
        cec1.Selected__c = true;
        cec1.Contract_Activated__c = true;
        cec1.Contract__c = contract.Id;
        insert cec1;
        contract.Status = 'Activated';
        update contract;

        Opportunity opp = new Opportunity(Name='TestOpp', StageName='Qualify', CloseDate=System.today(), AccountId = acc.Id);
        insert opp;
        ID stdPBId = Test.getStandardPricebookId();

        Pricebook2 pb = new Pricebook2(Name='TestPB', IsActive=TRUE);
        insert pb;
        //Create Products
        List<Product2> prodList=new List<Product2>();
        for(Integer i=0; i<=5; i++){
            String prodName='Product ' + string.valueOf(i);
            prodList.add(new Product2(Name = prodName, IsActive = true));
        }

        insert prodList;

        SBQQ__Quote__c q=new SBQQ__Quote__c(Tax_Calculated__c =true, SBQQ__Account__c=acc.Id , SBQQ__Opportunity2__c=opp.id,SBQQ__PriceBook__c=pb.id);
        insert q;

        try
        {
            //opp.Renew_Contract_Option__c = 'Don\'t Renew Contract';
            //update opp;
            PageReference pageRef = Page.GenerateRenewalContract;
            PageRef.getParameters().put('type','Amendment');
            Test.setCurrentPage(pageRef);
            ApexPages.standardController sta_controller = new ApexPages.standardController(opp);
            Ext_GenerateRenewalContract controller = new Ext_GenerateRenewalContract(sta_controller);
            controller.RunThat();
        }
        catch (Exception e)
        {
            System.assertEquals('Renewal Quote already exists. ', e.getMessage(), 'Renewal Quote already exists. ');
        }
    }

    static testMethod void TestError3()
    {
        TestUtility.setupConfigurationSettings();
        TestUtility.insertCustSetting('OpportunityTrigger');
        TestUtility.insertCustSetting('ContractTrigger');
		 TestUtility.insertCustSetting('CustomerEligibleContractTrigger');
        // 04/10/2017-Krishna Prasad-Added trigger switch to fix Contract Trigger isuue       
        TestUtility.insertCustSetting('SBQQ_QuoteTrigger'); 
        acc = TestUtility.newAccount('Account0', 'Account0');
        insert acc;
        Contract contract = new Contract();
        contract.AccountId = acc.Id;
        contract.Status = 'Draft';
        contract.StartDate = System.today();
        contract.Contract_End_Date__c = System.today() + 5;
        insert contract;
		//Inserting CEC for the Contract C1
        Customer_Eligible_Contract__c cec1 = new Customer_Eligible_Contract__c();
        cec1.Customer_Account__c = acc.Id;
        cec1.Precedence_Value__c = 1;
        cec1.Selected__c = true;
        cec1.Contract_Activated__c = true;
        cec1.Contract__c = contract.Id;
        insert cec1;
        contract.Status = 'Activated';
        update contract;

        Opportunity opp = new Opportunity(Name='TestOpp', StageName='Qualify', CloseDate=System.today(), AccountId = acc.Id);
        insert opp;
        ID stdPBId = Test.getStandardPricebookId();

        Pricebook2 pb = new Pricebook2(Name='TestPB', IsActive=TRUE);
        insert pb;
        //Create Products
        List<Product2> prodList=new List<Product2>();
        for(Integer i=0; i<=5; i++){
            String prodName='Product ' + string.valueOf(i);
            prodList.add(new Product2(Name = prodName, IsActive = true));
        }

        insert prodList;

        SBQQ__Quote__c q=new SBQQ__Quote__c(Tax_Calculated__c =true, SBQQ__Account__c=acc.Id , SBQQ__Opportunity2__c=opp.id,SBQQ__PriceBook__c=pb.id);
        insert q;

        try
        {
            //opp.Renew_Contract_Option__c = 'No Change to Existing Price';
            opp.SBQQ__PrimaryQuote__c = q.Id;
            update opp;
            PageReference pageRef = Page.GenerateRenewalContract;
            PageRef.getParameters().put('type','Amendment');
            Test.setCurrentPage(pageRef);
            ApexPages.standardController sta_controller = new ApexPages.standardController(opp);
            Ext_GenerateRenewalContract controller = new Ext_GenerateRenewalContract(sta_controller);
            controller.RunThat();
        }
        catch (Exception e)
        {
            System.assertEquals('Renewed Contract option field needs to be populated.  ', e.getMessage(), 'Renewed Contract option field needs to be populated.  ');
        }
    }
    static testMethod void TestError4()
    {
        TestUtility.setupConfigurationSettings();
        TestUtility.insertCustSetting('OpportunityTrigger');
        TestUtility.insertCustSetting('ContractTrigger');
		 TestUtility.insertCustSetting('CustomerEligibleContractTrigger');
        // 04/10/2017-Krishna Prasad-Added trigger switch to fix Contract Trigger isuue       
        TestUtility.insertCustSetting('SBQQ_QuoteTrigger'); 
        acc = TestUtility.newAccount('Account0', 'Account0');
        insert acc;
        Contract contract = new Contract();
        contract.AccountId = acc.Id;
        contract.Status = 'Draft';
        contract.StartDate = System.today();
        contract.Contract_End_Date__c = System.today() + 5;
        insert contract;
		//Inserting CEC for the Contract C1
        Customer_Eligible_Contract__c cec1 = new Customer_Eligible_Contract__c();
        cec1.Customer_Account__c = acc.Id;
        cec1.Precedence_Value__c = 1;
        cec1.Selected__c = true;
        cec1.Contract_Activated__c = true;
        cec1.Contract__c = contract.Id;
        insert cec1;
        contract.Status = 'Activated';
        update contract;

        Opportunity opp = new Opportunity(Name='TestOpp', StageName='Qualify', CloseDate=System.today(), AccountId = acc.Id);
        insert opp;
        ID stdPBId = Test.getStandardPricebookId();

        Pricebook2 pb = new Pricebook2(Name='TestPB', IsActive=TRUE);
        insert pb;
        //Create Products
        List<Product2> prodList=new List<Product2>();
        for(Integer i=0; i<=5; i++){
            String prodName='Product ' + string.valueOf(i);
            prodList.add(new Product2(Name = prodName, IsActive = true));
        }

        insert prodList;

        SBQQ__Quote__c q=new SBQQ__Quote__c(Tax_Calculated__c =true, SBQQ__Account__c=acc.Id , SBQQ__Opportunity2__c=opp.id,SBQQ__PriceBook__c=pb.id);
        insert q;

        try
        {
            opp.Renew_Contract_Option__c = 'No Change to Existing Price';
            opp.SBQQ__PrimaryQuote__c = q.Id;
            opp.Justification__c = 'test';
            update opp;
            PageReference pageRef = Page.GenerateRenewalContract;
            PageRef.getParameters().put('type','Amendment');
            Test.setCurrentPage(pageRef);
            ApexPages.standardController sta_controller = new ApexPages.standardController(opp);
            Ext_GenerateRenewalContract controller = new Ext_GenerateRenewalContract(sta_controller);
            controller.RunThat();
        }
        catch (Exception e)
        {
            System.assertEquals('Can not generate a renewal quote on a non-renewal Opportunity.  ', e.getMessage(), 'Can not generate a renewal quote on a non-renewal Opportunity.  ');
        }
    }
    static testMethod void TestPagegoToContractAmend()
    {
        TestUtility.setupConfigurationSettings();
        TestUtility.insertCustSetting('OpportunityTrigger');
        TestUtility.insertCustSetting('ContractTrigger');
		 TestUtility.insertCustSetting('CustomerEligibleContractTrigger');
        // 04/10/2017-Krishna Prasad-Added trigger switch to fix Contract Trigger isuue       
        TestUtility.insertCustSetting('SBQQ_QuoteTrigger'); 
        acc = TestUtility.newAccount('Account0', 'Account0');
        insert acc;
        Contract contract = new Contract();
        contract.AccountId = acc.Id;
        contract.Status = 'Draft';
        contract.StartDate = System.today();
        contract.Contract_End_Date__c = System.today() + 5;
        insert contract;
		//Inserting CEC for the Contract C1
        Customer_Eligible_Contract__c cec1 = new Customer_Eligible_Contract__c();
        cec1.Customer_Account__c = acc.Id;
        cec1.Precedence_Value__c = 1;
        cec1.Selected__c = true;
        cec1.Contract_Activated__c = true;
        cec1.Contract__c = contract.Id;
        insert cec1;
        contract.Status = 'Activated';
        update contract;

        Opportunity opp = new Opportunity(Name='TestOpp', StageName='Qualify', CloseDate=System.today(), AccountId = acc.Id);
        insert opp;
        ID stdPBId = Test.getStandardPricebookId();

        Pricebook2 pb = new Pricebook2(Name='TestPB', IsActive=TRUE);
        insert pb;
        //Create Products
        List<Product2> prodList=new List<Product2>();
        for(Integer i=0; i<=5; i++){
            String prodName='Product ' + string.valueOf(i);
            prodList.add(new Product2(Name = prodName, IsActive = true, Quotable__c = true));
        }

        insert prodList;

        SBQQ__Quote__c q=new SBQQ__Quote__c(Tax_Calculated__c =true, SBQQ__Account__c=acc.Id , SBQQ__Opportunity2__c=opp.id,SBQQ__PriceBook__c=pb.id);
        insert q;
        List<SBQQ__QuoteLine__c> quoteLines=new List<SBQQ__QuoteLine__c>();
        Map<Id,SBQQ__QuoteLine__c> quoteLineMap=new Map<Id,SBQQ__QuoteLine__c>();

        for(Integer i=0; i<=5; i++){
            quoteLines.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c=q.Id, SBQQ__Product__c=prodList.get(i).Id ,  SBQQ__ListPrice__c = 100, SBQQ__Quantity__c=1));
        }

        for(Integer i=0; i<=5; i++){
            quoteLines.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c=q.Id, SBQQ__Product__c=prodList.get(i).Id ,  SBQQ__ListPrice__c = 100, SBQQ__Quantity__c=1, Include_In_Order__c=false));
        }

        //insert quoteLines;
        quotelineMap.putAll(quoteLines);

        if(quotelineMap.size()>0){
            insert quotelineMap.values();
        }
       Test.startTest();

        opp.Renew_Contract_Option__c = 'No Change to Existing Price';
        opp.Justification__c = 'Test';
        opp.SBQQ__RenewedContract__c = contract.Id;
        update opp;

        PageReference pageRef = Page.GenerateRenewalContract;
        PageRef.getParameters().put('type','Amendment');
        Test.setCurrentPage(pageRef);
        ApexPages.standardController sta_controller = new ApexPages.standardController(opp);
        Ext_GenerateRenewalContract controller = new Ext_GenerateRenewalContract(sta_controller);
        controller.RunThat();
        controller.gotoQuote();
        controller.returnToPrevious();
        Test.stopTest();
    }
    static testMethod void TestPagegoToContractRenewal()
    {
        TestUtility.setupConfigurationSettings();
        TestUtility.insertCustSetting('OpportunityTrigger');
        TestUtility.insertCustSetting('ContractTrigger');
		 TestUtility.insertCustSetting('CustomerEligibleContractTrigger');
        // 04/10/2017-Krishna Prasad-Added trigger switch to fix Contract Trigger isuue       
        TestUtility.insertCustSetting('SBQQ_QuoteTrigger'); 
        acc = TestUtility.newAccount('Account0', 'Account0');
        insert acc;
        
        ID stdPBId = Test.getStandardPricebookId();

      
        

        //Pricebook2 pb = new Pricebook2(Name='TestPB', IsActive=TRUE);
        //insert pb;
        //Create Products
        List<Product2> prodList=new List<Product2>();
        for(Integer i=0; i<=5; i++){
            String prodName='Product ' + string.valueOf(i);
            prodList.add(new Product2(Name = prodName, IsActive = true));
        }

        insert prodList;

        /*
        //Create Price Book Entries
        List<PricebookEntry> priceentires=new List<PricebookEntry>();

        for(Integer i=0; i<=5; i++){
            priceentires.add(new PricebookEntry(Pricebook2Id = stdPBId, Product2Id = prodList.get(i).id, UnitPrice= 2000.00, IsActive = true));
        }

        insert priceentires;
        */
        
        Contract contract = new Contract();
        contract.AccountId = acc.Id;
        contract.Status = 'Draft';
        contract.StartDate = System.today();
        contract.Contract_End_Date__c = System.today() + 5;
        contract.Automatic_Renewal__c = false;
        insert contract;
		//Inserting CEC for the Contract C1
        Customer_Eligible_Contract__c cec1 = new Customer_Eligible_Contract__c();
        cec1.Customer_Account__c = acc.Id;
        cec1.Precedence_Value__c = 1;
        cec1.Selected__c = true;
        cec1.Contract_Activated__c = true;
        cec1.Contract__c = contract.Id;
        insert cec1;

        //Create Pricing Agreement Lines for each Contract
        List<Agreed_Price__c> agree_price_lines=new List<Agreed_Price__c>();
        
        //for(Contract con:contractList){
            for(Integer i=0; i<=5; i++){
                agree_price_lines.add(new Agreed_Price__c(Active__c=true,Contract_Activated__c=true, Contract__c=contract.id, Start_Date__c=system.today().addDays(1), End_Date__c=system.today().addDays(4), Price__c=2000.00, Product__c=prodList.get(i).id));//added Contract_Activated__c=true(ks)
            }
            contract.Automatic_Renewal__c = true;
            contract.Status='Activated';
        //}   

        
        update contract;
        insert agree_price_lines;

        /*
        SBQQ__Quote__c q=new SBQQ__Quote__c(SBQQ__Account__c=acc.Id , SBQQ__Opportunity2__c=opp.id,SBQQ__PriceBook__c=stdPBId);
        insert q;

        List<SBQQ__QuoteLine__c> quoteLines=new List<SBQQ__QuoteLine__c>();

        for(Integer i=0; i<=5; i++){
            quoteLines.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c=q.Id, SBQQ__Product__c=prodList.get(i).Id ,  SBQQ__ListPrice__c = 100, SBQQ__Quantity__c=1));
        }


        insert quoteLines;
        */
       Test.startTest();

        Opportunity opp = new Opportunity(Pricebook2Id = stdPBId, Name='TestOpp', StageName='Qualify', CloseDate=System.today(), AccountId = acc.Id);
        insert opp;

        opp.Renew_Contract_Option__c = 'No Change to Existing Price';
        opp.Justification__c = 'Test';
        opp.SBQQ__RenewedContract__c = contract.Id;
        update opp;

        PageReference pageRef = Page.GenerateRenewalContract;
        PageRef.getParameters().put('type','Renewal');
        Test.setCurrentPage(pageRef);
        ApexPages.standardController sta_controller = new ApexPages.standardController(opp);
        Ext_GenerateRenewalContract controller = new Ext_GenerateRenewalContract(sta_controller);
        controller.RunThat();
        controller.gotoQuote();
        controller.returnToPrevious();
        Test.stopTest();
   }
   static testMethod void TestError6()
    {
        TestUtility.setupConfigurationSettings();
        TestUtility.insertCustSetting('OpportunityTrigger');
        TestUtility.insertCustSetting('ContractTrigger');
		 TestUtility.insertCustSetting('CustomerEligibleContractTrigger');
        // 04/10/2017-Krishna Prasad-Added trigger switch to fix Contract Trigger isuue       
        TestUtility.insertCustSetting('SBQQ_QuoteTrigger'); 
        acc = TestUtility.newAccount('Account0', 'Account0');
        insert acc;
        
        ID stdPBId = Test.getStandardPricebookId();

      
        

        //Pricebook2 pb = new Pricebook2(Name='TestPB', IsActive=TRUE);
        //insert pb;
        //Create Products
        List<Product2> prodList=new List<Product2>();
        for(Integer i=0; i<=5; i++){
            String prodName='Product ' + string.valueOf(i);
            prodList.add(new Product2(Name = prodName, IsActive = true));
        }

        insert prodList;

        /*
        //Create Price Book Entries
        List<PricebookEntry> priceentires=new List<PricebookEntry>();

        for(Integer i=0; i<=5; i++){
            priceentires.add(new PricebookEntry(Pricebook2Id = stdPBId, Product2Id = prodList.get(i).id, UnitPrice= 2000.00, IsActive = true));
        }

        insert priceentires;
        */
        
        Contract contract = new Contract();
        contract.AccountId = acc.Id;
        contract.Status = 'Draft';
        contract.StartDate = System.today();
        contract.Contract_End_Date__c = System.today() + 5;
        contract.Automatic_Renewal__c = false;
        insert contract;
		//Inserting CEC for the Contract C1
        Customer_Eligible_Contract__c cec1 = new Customer_Eligible_Contract__c();
        cec1.Customer_Account__c = acc.Id;
        cec1.Precedence_Value__c = 1;
        cec1.Selected__c = true;
        cec1.Contract_Activated__c = true;
        cec1.Contract__c = contract.Id;
        insert cec1;

        //Create Pricing Agreement Lines for each Contract
        List<Agreed_Price__c> agree_price_lines=new List<Agreed_Price__c>();
        
        //for(Contract con:contractList){
            for(Integer i=0; i<=5; i++){
                agree_price_lines.add(new Agreed_Price__c(Active__c=true,Contract_Activated__c=true, Contract__c=contract.id, Start_Date__c=system.today().addDays(1), End_Date__c=system.today().addDays(4), Price__c=2000.00, Product__c=prodList.get(i).id));//added Contract_Activated__c=true(ks)
            }
            contract.Automatic_Renewal__c = true;
            contract.Status='Activated';
        //}   

        
        update contract;
        insert agree_price_lines;

        /*
        SBQQ__Quote__c q=new SBQQ__Quote__c(SBQQ__Account__c=acc.Id , SBQQ__Opportunity2__c=opp.id,SBQQ__PriceBook__c=stdPBId);
        insert q;

        List<SBQQ__QuoteLine__c> quoteLines=new List<SBQQ__QuoteLine__c>();

        for(Integer i=0; i<=5; i++){
            quoteLines.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c=q.Id, SBQQ__Product__c=prodList.get(i).Id ,  SBQQ__ListPrice__c = 100, SBQQ__Quantity__c=1));
        }


        insert quoteLines;
        */
       Test.startTest();

        Opportunity opp = new Opportunity(Pricebook2Id = stdPBId, Name='TestOpp', StageName='Qualify', CloseDate=System.today(), AccountId = acc.Id);
        insert opp;

        opp.Renew_Contract_Option__c = 'No Change to Existing Price';
        opp.Justification__c = 'Test';
        opp.SBQQ__RenewedContract__c = NULL;
        update opp;

        PageReference pageRef = Page.GenerateRenewalContract;
        PageRef.getParameters().put('type','Renewal');
        Test.setCurrentPage(pageRef);
        ApexPages.standardController sta_controller = new ApexPages.standardController(opp);
        Ext_GenerateRenewalContract controller = new Ext_GenerateRenewalContract(sta_controller);
        controller.RunThat();
        controller.gotoQuote();
        controller.returnToPrevious();
        Test.stopTest();
   }
    static testMethod void tierValidation(){
    
        TestUtility.setupConfigurationSettings();
        TestUtility.insertCustSetting('OpportunityTrigger');
        // 04/10/2017-Krishna Prasad-Added trigger switch to fix Contract Trigger isuue       
        TestUtility.insertCustSetting('SBQQ_QuoteTrigger'); 
        TestUtility.insertCustSetting('ContractTrigger');
		 TestUtility.insertCustSetting('CustomerEligibleContractTrigger');
        acc = TestUtility.newAccount('Account0', 'Account0');
        insert acc;
        
        ID stdPBId = Test.getStandardPricebookId();
        
        //Create Products
        List<Product2> prodList=new List<Product2>();
        for(Integer i=0; i<=5; i++){
            String prodName='Product ' + string.valueOf(i);
            prodList.add(new Product2(Name = prodName, IsActive = true));
        }

        insert prodList;
        
        Contract contract = new Contract();
        contract.AccountId = acc.Id;
        contract.Status = 'Draft';
        contract.StartDate = System.today();
        contract.Contract_End_Date__c = System.today() + 5;
        insert contract;
        
        Contract contract1 = new Contract();
        contract1.AccountId = acc.Id;
        contract1.Status = 'Draft';
        contract1.StartDate = System.today();
        contract1.Contract_End_Date__c = System.today() + 5;
        insert contract1;
        
        Contract contract2 = new Contract();
        contract2.AccountId = acc.Id;
        contract2.Status = 'Draft';
        contract2.StartDate = System.today() - 2;
        contract2.Contract_End_Date__c = System.today() + 5;
        insert contract2;
        
        
        List<Agreed_Price__c> agree_price_lines=new List<Agreed_Price__c>();
        
        for(Integer i=0; i<=2; i++){
            agree_price_lines.add(new Agreed_Price__c(Active__c=true,Contract_Activated__c=true, Contract__c=contract.id, Start_Date__c=system.today().addDays(1), End_Date__c=system.today().addDays(4), Price__c=2000.00, Product__c=prodList.get(i).id, Tier__c=1));//added Contract_Activated__c=true(ks)
        }
        agree_price_lines[1].Tier__c=null;
        
        Agreed_Price__c ap99 = new Agreed_Price__c(Active__c=true,Contract_Activated__c=true, Contract__c=contract1.id, Start_Date__c=system.today().addDays(1), End_Date__c=system.today().addDays(4), Price__c=2000.00, Product__c=prodList.get(0).id, Tier__c=1);//added Contract_Activated__c=true(ks)
        agree_price_lines.add(ap99);
        insert agree_price_lines;
        
        List<Customer_Eligible_Contract__c> cecList = new List<Customer_Eligible_Contract__c>();
        
        for(Integer i=0; i<2;i++)
            cecList.add(new Customer_Eligible_Contract__c(Customer_Account__c = acc.Id,Precedence_Value__c =1,Selected__c=true,Contract_Activated__c=true,Contract__c=contract.Id, Expiration_Date__c = System.today() - 1)); //added Contract_Activated__c=true and Expiration_Date__c = System.today() - 1(ks)
        
        cecList[1].Tier__c = 1;
        Customer_Eligible_Contract__c cec99 = new Customer_Eligible_Contract__c(Customer_Account__c = acc.Id,Precedence_Value__c =1,Selected__c=true,Contract_Activated__c=true,Contract__c=contract1.Id, Tier__c=1, Expiration_Date__c = System.today() - 1); //added Contract_Activated__c=true and Expiration_Date__c = System.today() - 1(ks)
        cecList.add(cec99);
        
        Customer_Eligible_Contract__c cec100 = new Customer_Eligible_Contract__c(Customer_Account__c = acc.Id,Precedence_Value__c =1,Selected__c=true,Contract_Activated__c=true,Contract__c=contract2.Id, Expiration_Date__c = System.today() - 1); //added Contract_Activated__c=true and Expiration_Date__c = System.today() - 1(ks)
        cecList.add(cec100);
        
        Customer_Eligible_Contract__c cec101 = new Customer_Eligible_Contract__c(Customer_Account__c = acc.Id,Precedence_Value__c =1,Selected__c=true,Contract_Activated__c=true,Contract__c=contract2.Id, Expiration_Date__c = System.today() - 1 );//added Contract_Activated__c=true and Expiration_Date__c = System.today() - 1(ks)
        cecList.add(cec101);
        
        insert cecList;
        
        contract.Status = 'Activated';
        contract1.Status = 'Activated';
        contract2.Status = 'Activated';
        try{
            update contract;
            update contract1;
            update contract2;
            contract2.Contract_End_Date__c = System.today() + 1;
            update contract2;
        }
        catch(Exception e){
            
            Boolean expectedExceptionThrown =  e.getMessage().contains('Kindly ensure that Tier is populated on all Customer Eligible Contract and Agreed Price records associated with this Contract.') ? true : false; 
            System.AssertEquals(expectedExceptionThrown, true);
        }
        
               
        //contract2.Status = 'Expired';
        //update contract2;
        
        //contract2.Status = 'Activated';
        //update contract2;
    
        
    }
    
     static testMethod void EndDateUpdate(){
     
        TestUtility.setupConfigurationSettings();
        TestUtility.insertCustSetting('OpportunityTrigger');
        TestUtility.insertCustSetting('ContractTrigger');
		 TestUtility.insertCustSetting('CustomerEligibleContractTrigger');
        acc = TestUtility.newAccount('Account0', 'Account0');
        insert acc;
        
        ID stdPBId = Test.getStandardPricebookId();
        
        //Create Products
        List<Product2> prodList=new List<Product2>();
        for(Integer i=0; i<=5; i++){
            String prodName='Product ' + string.valueOf(i);
            prodList.add(new Product2(Name = prodName, IsActive = true));
        }

        insert prodList;
        
        Contract contract = new Contract();
        contract.AccountId = acc.Id;
        contract.Status = 'Draft';
        contract.StartDate = System.today() - 2;
        contract.Contract_End_Date__c = System.today() + 5;
        insert contract;
        
        List<Agreed_Price__c> agree_price_lines=new List<Agreed_Price__c>();
        
        for(Integer i=0; i<=2; i++){
            agree_price_lines.add(new Agreed_Price__c(Active__c=true,Contract_Activated__c=true, Contract__c=contract.id, Start_Date__c=system.today().addDays(1), End_Date__c=system.today().addDays(4), Price__c=2000.00, Product__c=prodList.get(i).id, Tier__c=1));//added Contract_Activated__c=true(ks)
        }
       
        insert agree_price_lines;
        
        List<Customer_Eligible_Contract__c> cecList = new List<Customer_Eligible_Contract__c>();
        
        for(Integer i=0; i<2;i++)
            cecList.add(new Customer_Eligible_Contract__c(Customer_Account__c = acc.Id,Precedence_Value__c=1,Selected__c=true,Contract_Activated__c=true, Expiration_Date__c=system.today().addDays(4), Contract__c=contract.Id, Tier__c=1));//added Contract_Activated__c=true and expiration date(ks)
        
         insert cecList;
         
         contract.Status = 'Activated';
         update contract;
         
         try{
             contract.Contract_End_Date__c = System.today() + 4;
             update contract;
         }
         catch(Exception e){
            
            Boolean expectedExceptionThrown =  e.getMessage().contains('Kindly populate the Tier value.') ? true : false; 
            System.AssertEquals(expectedExceptionThrown, false);
         }
        
         contract.Status = 'Expired';
         update contract;
         
         contract.Status = 'Activated';
         update contract;
     
     }
     
     static testMethod void TestAmendedContract(){
         TestUtility.setupConfigurationSettings();
        TestUtility.insertCustSetting('OpportunityTrigger');
        TestUtility.insertCustSetting('ContractTrigger');
		 TestUtility.insertCustSetting('CustomerEligibleContractTrigger');
        // 04/10/2017-Krishna Prasad-Added trigger switch to fix Contract Trigger isuue       
        TestUtility.insertCustSetting('SBQQ_QuoteTrigger'); 
        acc = TestUtility.newAccount('Account0', 'Account0');
        insert acc;
        
        ID stdPBId = Test.getStandardPricebookId();
        
        //Create Products
        List<Product2> prodList=new List<Product2>();
        for(Integer i=0; i<=5; i++){
            String prodName='Product ' + string.valueOf(i);
            prodList.add(new Product2(Name = prodName, IsActive = true));
        }

        insert prodList;
        
        Contract contract = new Contract();
        contract.AccountId = acc.Id;
        contract.Status = 'Draft';
        contract.StartDate = System.today();
        contract.Contract_End_Date__c = System.today() + 5;
        //contract.Amended_Contract__c = amendedContract.Id;
        insert contract;  
        
        Contract amendedContract = new Contract();
        amendedContract .AccountId = acc.Id;
        amendedContract .Status = 'Draft';
        amendedContract .StartDate = System.today() - 2;
        amendedContract .Contract_End_Date__c = System.today() + 5;
        insert amendedContract;
        
        
        contract.Amended_Contract__c = amendedContract.Id;
        update contract;
        
        Contract updatedCon = [SELECT Id, Status from Contract where Id = :contract.Amended_Contract__c]; 
        //System.assertNotEquals('Expired', updatedCon.Status);   
     } 
          
    
}