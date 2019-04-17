@isTest
private class  Test_ContractNewAmendOpp
{   
    private static Account acc;
    private static Account acc2; 
    static testMethod void test_OpportunityTriggerHandler()
    {
            TestUtility.setupConfigurationSettings();

        // Setup data

        //create account
        acc = TestUtility.newAccount('Account0', 'Account0');
        insert acc;

        Trigger_Switch__c ts = new Trigger_Switch__c();
        ts.Name = 'OpportunityTrigger';
        ts.Active__c = true;
        insert ts;

        Trigger_Switch__c productTriggerSwitch = new Trigger_Switch__c();
        productTriggerSwitch.Name = 'ProductTrigger';
        Trigger_Switch__c productReplacementSwitch = new Trigger_Switch__c(name = 'ProductReplacement', Active__c = true);
        insert productReplacementSwitch;
        productTriggerSwitch.Active__c = true;
        insert productTriggerSwitch;

        //create contract and activate
        Contract contract = new Contract();
        contract.AccountId = acc.Id;
        contract.Status = 'Draft';
        contract.StartDate = System.today();
        contract.Contract_End_Date__c = System.today().addMonths(3);
        insert contract;
        contract.Status = 'Activated';
        update contract;

        //Create opprotunity

        ID stdPBId = Test.getStandardPricebookId();
        Opportunity opp = new Opportunity(Name='TestOpp', StageName='Qualify', CloseDate=System.today(), AccountId = acc.Id,SBQQ__RenewedContract__c=contract.id);
        insert opp;

        Pricebook2 pb = new Pricebook2(Name='TestPB', IsActive=TRUE);
        insert pb;
        //Create Products
        List<Product2> prodList=new List<Product2>();
        for(Integer i=0; i<=5; i++){
            String prodName='Product ' + string.valueOf(i);
            prodList.add(new Product2(Name = prodName, IsActive = true, Quotable__c = true));
        }

        insert prodList;

        // Create quote and make it primary

        SBQQ__Quote__c q=new SBQQ__Quote__c(Tax_Calculated__c =true, SBQQ__Account__c=acc.Id , SBQQ__Opportunity2__c=opp.id,SBQQ__PriceBook__c=pb.id);
        q.SBQQ__StartDate__c = System.today();
        q.SBQQ__EndDate__c = System.today().addMonths(2);
        insert q;
        contract.SBQQ__Quote__c = q.Id;
        update contract;
        /*List<SBQQ__QuoteLine__c> quoteLines=new List<SBQQ__QuoteLine__c>();

        for(Integer i=0; i<=5; i++){
            quoteLines.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c=q.Id, SBQQ__Product__c=prodList.get(i).Id ,  SBQQ__ListPrice__c = 100, SBQQ__Quantity__c=1));
        }

        for(Integer i=0; i<=5; i++){
            quoteLines.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c=q.Id, SBQQ__Product__c=prodList.get(i).Id ,  SBQQ__ListPrice__c = 100, SBQQ__Quantity__c=1, Include_In_Order__c=false));
        }

        insert quoteLines;*/

        opp.SBQQ__PrimaryQuote__c = q.Id;
        opp.SBQQ__AmendedContract__c=contract.id;
        update opp;

        Test.startTest();

        List<SBQQ__QuoteLine__c> quoteLines=new List<SBQQ__QuoteLine__c>();
        Map<Id,SBQQ__QuoteLine__c> quoteLineMap=new Map<Id,SBQQ__QuoteLine__c>();

        SBQQ__QuoteLineGroup__c quoteLineGroup = new SBQQ__QuoteLineGroup__c(Name = 'Test Group', SBQQ__Quote__c = q.Id);

        insert quoteLineGroup;

        for(Integer i=0; i<=5; i++){
            quoteLines.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c=q.Id, SBQQ__Product__c=prodList.get(i).Id ,  SBQQ__ListPrice__c = 100, SBQQ__Quantity__c=1, SBQQ__Group__c = quoteLineGroup.Id));
        }
        quotelineMap.putAll(quoteLines);

        if(quotelineMap.size()>0){
            insert quotelineMap.values();
        }
        //insert quoteLines;

        // create agreed prices
        List<Agreed_Price__c> APLines=new List<Agreed_Price__c>();
        Agreed_Price_Group__c agreedPriceGroup = new Agreed_Price_Group__c(Shipment_Period__c = 'Monthly', Contract__c = contract.Id, Group_Name__c = 'Commitments', of_Boxes__c = 100, number_of_Months__c = 12, Tier__c = 1);
        insert agreedPriceGroup;

        for(Integer i=0; i<=5; i++){
            APLines.add(new Agreed_Price__c(Discount__c= 10, Price__c = 10.00, Contract__c = contract.Id, Start_Date__c = contract.StartDate, End_Date__c=contract.Contract_End_Date__c,Product__c=prodList.get(i).Id, Active__c = true, Agreed_Price_Group__c = agreedPriceGroup.Id,Number__c=123));
        }
        insert APLines;

        APLines.get(1).Agreed_Price_Required_By__c = APLines.get(0).Id;
        update APLines;


        List<Opportunity> lst_opp = new List<Opportunity>();
        lst_opp.add(opp);
        List<Contract> lst_con = new List<Contract>();
        lst_con.add(contract);
        
        
        // test creating a contract
        Map<String, String> contractMap = OpportunityTriggerHandler.createContract(lst_opp);
        System.assertNotEquals(contractMap, null);

        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        
        User u = [SELECT Id from User where LastName='Administrator' AND FirstName='Salesforce' LIMIT 1];
        
        System.runAs(u){
            //test creating agreed prices
            OpportunityTriggerHandler.createAgreementPrices(lst_con);
            //System.assert([select count() from Agreed_Price__c where Contract__c = :contract.Id] > 0);
        
            //test amending a price agreeement
            //contractMap = OpportunityTriggerHandler.amendAgreementPrices(lst_opp);
            //System.assertNotEquals(contractMap, null);
        }

        // test find opp
        Map<String, Opportunity> oppMap=CreateAmendRenewalHelper.FindOpp(lst_con);
        system.assertNotEquals(oppMap, null);


        Boolean booTest = CreateAmendRenewalHelper.CreateQL(contract, q.Id, 'Amendment');
        System.assert(booTest);
        
        Test.stopTest();

        //CreateAmendRenewalHelper.CreateBulkQuotes(lst_opp);
    }

    static testMethod void test_OpportunityTriggerHandler_Renewal()
    {
        Test.startTest();

        TestUtility.setupConfigurationSettings();
        acc = TestUtility.newAccount('Account0', 'Account0');

        Trigger_Switch__c ts = new Trigger_Switch__c();
        ts.Name = 'OpportunityTrigger';
        ts.Active__c = true;
        insert ts;

        Trigger_Switch__c productTriggerSwitch = new Trigger_Switch__c();
        productTriggerSwitch.Name = 'ProductTrigger';
        Trigger_Switch__c productReplacementSwitch = new Trigger_Switch__c(name = 'ProductReplacement', Active__c = true);
        insert productReplacementSwitch;
        productTriggerSwitch.Active__c = true;
        insert productTriggerSwitch;

        insert acc;
        Contract contract = new Contract();
        contract.AccountId = acc.Id;
        contract.Status = 'Draft';
        contract.StartDate = System.today();
        contract.Contract_End_Date__c = System.today() + 5;
        insert contract;
        contract.Status = 'Activated';
        update contract;

        ID stdPBId = Test.getStandardPricebookId();

        Opportunity opp = new Opportunity(Name='TestOpp', StageName='Qualify', CloseDate=System.today(), AccountId = acc.Id);
        //opp.RecordType = [select Id from RecordType where Name = 'Surgical Open Opportunity' and SobjectType = 'Opportunity' LIMIT 1];
        
        insert opp;
        

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
        contract.SBQQ__Quote__c = q.Id;
        update contract;
        
        /*List<SBQQ__QuoteLine__c> quoteLines=new List<SBQQ__QuoteLine__c>();

        for(Integer i=0; i<=5; i++){
            quoteLines.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c=q.Id, SBQQ__Product__c=prodList.get(i).Id ,  SBQQ__ListPrice__c = 100, SBQQ__Quantity__c=1));
        }

        for(Integer i=0; i<=5; i++){
            quoteLines.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c=q.Id, SBQQ__Product__c=prodList.get(i).Id ,  SBQQ__ListPrice__c = 100, SBQQ__Quantity__c=1, Include_In_Order__c=false));
        }
        
        insert quoteLines;*/
        
        opp.SBQQ__PrimaryQuote__c = q.Id;
        opp.SBQQ__RenewedContract__c=contract.id;
        update opp;

        List<Agreed_Price__c> APLines=new List<Agreed_Price__c>();
        Agreed_Price_Group__c agreedPriceGroup = new Agreed_Price_Group__c(Shipment_Period__c = 'Monthly', Contract__c = contract.Id, Group_Name__c = 'Commitments', of_Boxes__c = 100, number_of_Months__c = 12, Tier__c = 1);
        insert agreedPriceGroup;

        for(Integer i=0; i<=5; i++){
            APLines.add(new Agreed_Price__c(Discount__c= 10, Price__c = 10.00, Contract__c = contract.Id, Start_Date__c = contract.StartDate, Product__c=prodList.get(i).Id, Active__c = true, Agreed_Price_Group__c = agreedPriceGroup.Id));
        }
        insert APLines;

        APLines.get(1).Agreed_Price_Required_By__c = APLines.get(0).Id;
        update APLines;

        //quoteLines.get(0).Agreed_Price_Line__c=APLines.get(0).id;
        //update quoteLines;

        List<Opportunity> lst_opp = new List<Opportunity>();
        lst_opp.add(opp);
        List<Contract> lst_con = new List<Contract>();
        lst_con.add(contract);
        //OpportunityTriggerHandler controller = new Ext_ContractNewAnR();
        //OpportunityTriggerHandler.createContract(lst_opp);
        //OpportunityTriggerHandler.createAgreementPrices(lst_con);
        //OpportunityTriggerHandler.amendAgreementPrices(lst_opp);
        //String quoteId = CreateAmendRenewalHelper.CreateQuote(opp);
        
        Boolean booTest = CreateAmendRenewalHelper.CreateQL(contract, q.Id, 'Renewal');

        //CreateAmendRenewalHelper.CreateBulkQuotes(lst_opp);
        Test.stopTest();
    }

     static testMethod void test_CreateRenewalQuote()
    {
        Test.startTest();

        TestUtility.setupConfigurationSettings();
        acc = TestUtility.newAccount('Account0', 'Account0');

        Trigger_Switch__c ts = new Trigger_Switch__c();
        ts.Name = 'OpportunityTrigger';
        ts.Active__c = true;
        insert ts;

        Trigger_Switch__c productTriggerSwitch = new Trigger_Switch__c();
        productTriggerSwitch.Name = 'ProductTrigger';
        Trigger_Switch__c productReplacementSwitch = new Trigger_Switch__c(name = 'ProductReplacement', Active__c = true);
        insert productReplacementSwitch;
        productTriggerSwitch.Active__c = true;
        insert productTriggerSwitch;

        insert acc;
       
        List<contract> conList=new List<Contract>();
        Contract contract = new Contract();
        contract.AccountId = acc.Id;
        contract.Status = 'Draft';
        contract.StartDate = System.today();
        contract.Contract_End_Date__c = System.today() + 5;
      
        insert contract;
        contract.Status = 'Activated';
        update contract;
        conList.add(contract);
		 contract.Marketing_Program__c='Brevera';
        update contract;

        //Create existing CEC for amendment
        Customer_Eligible_Contract__c cec1 = new Customer_Eligible_Contract__c(Customer_Account__c = acc.Id, Contract__c = contract.Id,Selected__c=true);
        insert cec1;
        ID stdPBId = Test.getStandardPricebookId();

        Opportunity opp = new Opportunity(Name='TestOpp', StageName='Qualify', CloseDate=System.today(), AccountId = acc.Id);
        opp.RecordType = [select Id from RecordType where Name = 'Surgical Open Opportunity' and SobjectType = 'Opportunity' LIMIT 1];
        
        insert opp;
        

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
        contract.SBQQ__Quote__c = q.Id;
        update contract;
        
        
        opp.SBQQ__PrimaryQuote__c = q.Id;
        opp.SBQQ__RenewedContract__c=contract.id;
        update opp;


		CreateAmendRenewalHelper.FindOpp(conList);
        String quoteId = CreateAmendRenewalHelper.CreateQuote(opp);
        
       

        Test.stopTest();
    }

    static testMethod void test_CreateAgreedPrices_Renewal()
    {
        Test.startTest();

        TestUtility.setupConfigurationSettings();
        acc = TestUtility.newAccount('Account0', 'Account0');

        Trigger_Switch__c ts = new Trigger_Switch__c();
        ts.Name = 'OpportunityTrigger';
        ts.Active__c = true;
        insert ts;

        Trigger_Switch__c productTriggerSwitch = new Trigger_Switch__c();
        productTriggerSwitch.Name = 'ProductTrigger';
        Trigger_Switch__c productReplacementSwitch = new Trigger_Switch__c(name = 'ProductReplacement', Active__c = true);
        insert productReplacementSwitch;
        productTriggerSwitch.Active__c = true;
        insert productTriggerSwitch;

        insert acc;
        Contract contract = new Contract();
        contract.AccountId = acc.Id;
        contract.Status = 'Draft';
        contract.StartDate = System.today();
        contract.Contract_End_Date__c = System.today() + 5;
        insert contract;
        contract.Status = 'Activated';
        update contract;

        ID stdPBId = Test.getStandardPricebookId();

        
        list <Surgical_Opportunity_Record_Type_IDs__c> surgicalRecordTypeList = new list<Surgical_Opportunity_Record_Type_IDs__c>();

        for(recordType rt: [SELECT ID, SObjectType, Name FROM RecordType where SObjectType = 'Opportunity' AND Name = 'Surgical Open Opportunity' LIMIT 1]){
            surgicalRecordTypeList.add(new Surgical_Opportunity_Record_Type_IDs__c(Surgical_Open_Opportunity__c = rt.Id));
        }

        insert surgicalRecordTypeList;

        Surgical_Opportunity_Record_Type_IDs__c recordTypes = Surgical_Opportunity_Record_Type_IDs__c.getOrgDefaults();

        Opportunity opp = new Opportunity(Name='TestOpp', StageName='Qualify', CloseDate=System.today(), AccountId = acc.Id);
        opp.RecordType = [select Id from RecordType where Name = 'Surgical Open Opportunity' and SobjectType = 'Opportunity' LIMIT 1];
        System.debug('Oppty Record Type ' + opp.RecordType);
        insert opp;
        

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
        
        contract.SBQQ__Quote__c = q.Id;
        contract.SBQQ__Opportunity__c = opp.Id;
        update contract;
        
        List<SBQQ__QuoteLine__c> quoteLines=new List<SBQQ__QuoteLine__c>();
        Map<Id,SBQQ__QuoteLine__c> quoteLineMap=new Map<Id,SBQQ__QuoteLine__c>();

       
        //insert quoteLines;

        List<Agreed_Price__c> APLines=new List<Agreed_Price__c>();
        Agreed_Price_Group__c agreedPriceGroup = new Agreed_Price_Group__c(Shipment_Period__c = 'Monthly', Contract__c = contract.Id, Group_Name__c = 'Commitments', of_Boxes__c = 100, number_of_Months__c = 12, Tier__c = 1);
        insert agreedPriceGroup;

        for(Integer i=0; i<=5; i++){
            APLines.add(new Agreed_Price__c(Discount__c= 10, Price__c = 10.00, Contract__c = contract.Id, Start_Date__c = contract.StartDate, Product__c=prodList.get(i).Id, Active__c = true, Agreed_Price_Group__c = agreedPriceGroup.Id));
        }
        insert APLines;

        APLines.get(1).Agreed_Price_Required_By__c = APLines.get(0).Id;
        update APLines;
         for(Integer i=0; i<=5; i++){
            quoteLines.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c=q.Id, SBQQ__Product__c=prodList.get(i).Id ,  SBQQ__ListPrice__c = 100, SBQQ__Quantity__c=1, Create_Agreed_Price__c = true,Agreed_Price_Line__c=APLines[1].id));
        }

        System.debug(quoteLines);
        quotelineMap.putAll(quoteLines);

        if(quotelineMap.size()>0){
            insert quotelineMap.values();
        }
        
        opp.SBQQ__PrimaryQuote__c = q.Id;
        opp.SBQQ__RenewedContract__c=contract.id;
        update opp;
		Map<Id,Id> agreedIds=new Map<Id,Id>();
        agreedIds.put(APLines[1].id,APLines[1].id);

        //List<Opportunity> lst_opp = new List<Opportunity>();
        //lst_opp.add(opp);
        List<Contract> lst_con = new List<Contract>();
        lst_con.add(contract);
 
        // test creating a contract
        //Map<String, String> contractMap = OpportunityTriggerHandler.createContract(lst_opp);

        OpportunityTriggerHandler.createAgreementPrices(lst_con);
        try
        {
             CreateAmendRenewalHelper.UpdateRequiredQL(agreedIds,q.Id);
        }
        catch(Exception e)
        {
            system.debug(e);
        }
       

        Test.stopTest();
    }

    static testMethod void TestPagegoToContractAmend()
    {

        // setup test data
        TestUtility.setupConfigurationSettings();
        acc = TestUtility.newAccount('Account0', 'Account0');
        insert acc;

        acc2 = TestUtility.newAccount('Account1', 'Account1');
        insert acc2;

        Trigger_Switch__c ts = new Trigger_Switch__c();
        ts.Name = 'OpportunityTrigger';
        ts.Active__c = true;
        insert ts;

        Trigger_Switch__c productTriggerSwitch = new Trigger_Switch__c();
        productTriggerSwitch.Name = 'ProductTrigger';
        Trigger_Switch__c productReplacementSwitch = new Trigger_Switch__c(name = 'ProductReplacement', Active__c = true);
        insert productReplacementSwitch;
        productTriggerSwitch.Active__c = true;
        insert productTriggerSwitch;

        //create contract
        Contract contract = new Contract();
        contract.AccountId = acc.Id;
        contract.Status = 'Draft';
        contract.StartDate = System.today();
        contract.Contract_End_Date__c = System.today() + 5;
        insert contract;
        contract.Status = 'Activated';

        update contract;

        //create opportunity and products
        //BSH_Opportunity_Record_Type_IDs__c bshRecordTypes = BSH_Opportunity_Record_Type_IDs__c.getOrgDefaults();
        //ID bshOpptyRecordType = bshRecordTypes.Opportunity_BSH_Sales_Oppty__c;
        Opportunity opp = new Opportunity(Name='TestOpp', StageName='Qualify', CloseDate=System.today(), AccountId = acc.Id);
        opp.RecordType = [select Id from RecordType where Name = 'B&SH Sales Open Opportunity' and SobjectType = 'Opportunity'];
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

        Test.startTest();

        //insert prodList;

        // create quote and quote lines
        SBQQ__Quote__c q=new SBQQ__Quote__c(Tax_Calculated__c =true, SBQQ__Account__c=acc.Id , SBQQ__Opportunity2__c=opp.id,SBQQ__PriceBook__c=pb.id);
        insert q;
        /*List<SBQQ__QuoteLine__c> quoteLines=new List<SBQQ__QuoteLine__c>();

        for(Integer i=0; i<=5; i++){
            quoteLines.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c=q.Id, SBQQ__Product__c=prodList.get(i).Id ,  SBQQ__ListPrice__c = 100, SBQQ__Quantity__c=1));
        }

        for(Integer i=0; i<=5; i++){
            quoteLines.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c=q.Id, SBQQ__Product__c=prodList.get(i).Id ,  SBQQ__ListPrice__c = 100, SBQQ__Quantity__c=1, Include_In_Order__c=false));
        }*/

        List<Agreed_Price__c> APLines=new List<Agreed_Price__c>();
        Agreed_Price_Group__c agreedPriceGroup = new Agreed_Price_Group__c(Shipment_Period__c = 'Monthly', Contract__c = contract.Id, Group_Name__c = 'Commitments', of_Boxes__c = 100, number_of_Months__c = 12, Tier__c = 1);
        insert agreedPriceGroup;

        for(Integer i=0; i<=5; i++){
            APLines.add(new Agreed_Price__c(Discount__c= 10, Price__c = 10.00, Contract__c = contract.Id, Start_Date__c = contract.StartDate, Product__c=prodList.get(i).Id, Active__c = true, Agreed_Price_Group__c = agreedPriceGroup.Id));
        }
        insert APLines;

        APLines.get(1).Agreed_Price_Required_By__c = APLines.get(0).Id;
        update APLines;

        //insert quoteLines;

        //quoteLines.get(1).SBQQ__RequiredBy__c = quoteLines.get(0).Id;
        //update quoteLines;

        //make quote primary
        opp.SBQQ__PrimaryQuote__c = q.id;
        update opp;
        contract.Automatic_Renewal__c = true;
        contract.SBQQ__Quote__c = q.Id;
        contract.SBQQ__Opportunity__c = opp.Id;
        contract.Marketing_Program__c='Brevera';
        update contract;

        //Create existing CEC for amendment
        Customer_Eligible_Contract__c cec1 = new Customer_Eligible_Contract__c(Customer_Account__c = acc.Id, Contract__c = contract.Id,Selected__c=true);
        insert cec1;

        //Create existing CEC for amendment for related accounts
        //Customer_Eligible_Contract__c cec2 = new Customer_Eligible_Contract__c(Customer_Account__c = acc2.Id, Contract__c = contract.Id);
        //insert cec2;

        // setup page and parameters
        PageReference pageRef = Page.ContractNewAmendOpp;
        PageRef.getParameters().put('type','Amendment');
        Test.setCurrentPage(pageRef);
        ApexPages.standardController sta_controller = new ApexPages.standardController(contract);

        // create controller
        Ext_ContractNewAnR controller = new Ext_ContractNewAnR(sta_controller);

        // create renewal
        controller.RunThat();
        system.assert([SELECT Id FROM Opportunity WHERE SBQQ__AmendedContract__c = :contract.Id] != null);
        system.assertNotEquals(controller.returnContract(),null);
        system.assertNotEquals(controller.gotoOpp(),null);
        system.assertNotEquals(controller.gotoQuote(),null);
        system.assertNotEquals(controller.returnToPrevious(),null);

        Test.stopTest();

    }
    static testMethod void TestPagegoToContractRenewal()
    {
        // setup data
        TestUtility.setupConfigurationSettings();
        acc = TestUtility.newAccount('Account0', 'Account0');
        insert acc;

        acc2 = TestUtility.newAccount('Account1', 'Account1');
        insert acc2;

        Trigger_Switch__c ts = new Trigger_Switch__c();
        ts.Name = 'OpportunityTrigger';
        ts.Active__c = true;
        insert ts;

        Trigger_Switch__c productTriggerSwitch = new Trigger_Switch__c();
        productTriggerSwitch.Name = 'ProductTrigger';
        Trigger_Switch__c productReplacementSwitch = new Trigger_Switch__c(name = 'ProductReplacement', Active__c = true);
        insert productReplacementSwitch;
        productTriggerSwitch.Active__c = true;
        insert productTriggerSwitch;

        // create contract
        Contract contract = new Contract();
        contract.AccountId = acc.Id;
        contract.Status = 'Draft';
        contract.StartDate = System.today();
        contract.Contract_End_Date__c = System.today() + 5;
        insert contract;
        contract.Status = 'Activated';
        update contract;

        //create opportunity and products
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

        // create quote
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

        Test.startTest();
        quotelineMap.putAll(quoteLines);

        if(quotelineMap.size()>0){
            insert quotelineMap.values();
        }
        //insert quoteLines;

        //make quote primary
        opp.SBQQ__PrimaryQuote__c = q.id;
        contract.SBQQ__Quote__c = q.Id;
        contract.SBQQ__Opportunity__c = opp.Id;
        opp.SBQQ__RenewedContract__c=contract.id;
        update opp;

        contract.Automatic_Renewal__c = false;
        contract.SBQQ__Quote__c = q.Id;
        contract.SBQQ__Opportunity__c = opp.Id;
        update contract;

        //Create existing CEC for amendment
        Customer_Eligible_Contract__c cec1 = new Customer_Eligible_Contract__c(Customer_Account__c = acc.Id, Contract__c = contract.Id);
        insert cec1;

        //Create existing CEC for amendment for related accounts
        Customer_Eligible_Contract__c cec2 = new Customer_Eligible_Contract__c(Customer_Account__c = acc2.Id, Contract__c = contract.Id);
        insert cec2;

        // setup page and parameters
        PageReference pageRef = Page.ContractNewAmendOpp;
        PageRef.getParameters().put('type','Renewal');
        Test.setCurrentPage(pageRef);
        ApexPages.standardController sta_controller = new ApexPages.standardController(contract);

        // create controller
        Ext_ContractNewAnR controller = new Ext_ContractNewAnR(sta_controller);
        controller.RunThat();
         //system.assert([SELECT SBQQ__RenewalOpportunity__c FROM Contract WHERE id = : contract.Id] != null);
         system.assert([SELECT Id FROM Opportunity WHERE SBQQ__RenewedContract__c = :contract.Id] != null);

         Test.stopTest();
    }
}