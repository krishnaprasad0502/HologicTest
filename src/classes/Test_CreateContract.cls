@isTest
private class Test_CreateContract 
{
    private static Account acc;
    static testMethod void TestPageTypeAmendment()
    {
         TestUtility.setupConfigurationSettings();
         TestUtility.insertCustSetting('OpportunityTrigger');
       acc = TestUtility.newAccount('Account0', 'Account0');
        insert acc;
        Contract contract = new Contract();
        contract.AccountId = acc.Id;
        contract.Status = 'Draft';
        contract.StartDate = System.today();
        contract.Contract_End_Date__c = System.today().addMonths(12);
        insert contract;
        PageReference pageRef = Page.ContractNewAmendOpp;
        Test.setCurrentPage(pageRef);
      
        // Add parameters to page URL
        ApexPages.currentPage().getParameters().put('type', 'Amendment');

        ApexPages.standardController sta_controller = new ApexPages.standardController(contract);
        Ext_ContractNewAnR controller = new Ext_ContractNewAnR(sta_controller);
        controller.returnContract();
        controller.RunThat();
        ApexPages.Message[] msgs=ApexPages.getMessages();
        Boolean found=false;
        for (ApexPages.Message msg : msgs)
        {
           if (msg.getSummary()=='Inactive Contracts can not be Amended. ')
           {
              found=true;
           }
        }
        System.debug(found);
    }   
    static testMethod void TestPageTypeRenewal()
    {
         TestUtility.setupConfigurationSettings();
       TestUtility.insertCustSetting('OpportunityTrigger');
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

        ID stdPBId = Test.getStandardPricebookId();

        //Pricebook2 pb = new Pricebook2(Name='TestPB', IsActive=TRUE);
        //insert pb;
        //Product2 p2 = new Product2(Description='TestProd',Family='Family',Name='MyProduct',ProductCode='123',IsActive=TRUE);
        //insert p2;
        //PricebookEntry stdpbe = new PricebookEntry(Product2Id = p2.id, IsActive = TRUE,UnitPrice=100.0,Pricebook2Id=stdPBId,UseStandardPrice=true);
        //insert stdpbe;
        ////PricebookEntry pbe = new PricebookEntry(Product2Id = p2.id, IsActive = TRUE,UnitPrice=100.0,Pricebook2Id=stdPBId,UseStandardPrice=FALSE);
        ////insert pbe;
        Opportunity opp = new Opportunity(Name='TestOpp', StageName='Qualify', CloseDate=System.today(), AccountId = acc.Id);
        insert opp;

        Pricebook2 pb = new Pricebook2(Name='TestPB', IsActive=TRUE);
        insert pb;
        //Create Products
        List<Product2> prodList=new List<Product2>();
        for(Integer i=0; i<=5; i++){
            String prodName='Product ' + string.valueOf(i);
            prodList.add(new Product2(Name = prodName, IsActive = true, Quotable__c = true));
        }

        Test.startTest(); //Adding to reset governor limits

        insert prodList;

        SBQQ__Quote__c q=new SBQQ__Quote__c(Tax_Calculated__c =true, SBQQ__Account__c=acc.Id , SBQQ__Opportunity2__c=opp.id,SBQQ__PriceBook__c=stdPBId);
        insert q;
        List<SBQQ__QuoteLine__c> quoteLines=new List<SBQQ__QuoteLine__c>();
        Map<Id,SBQQ__QuoteLine__c> quoteLineMap=new Map<Id,SBQQ__QuoteLine__c>();

        for(Integer i=0; i<=5; i++){
            quoteLines.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c=q.Id, SBQQ__Product__c=prodList.get(i).Id ,  SBQQ__ListPrice__c = 100, SBQQ__Quantity__c=1));
        }

        for(Integer i=0; i<=5; i++){
            quoteLines.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c=q.Id, SBQQ__Product__c=prodList.get(i).Id ,  SBQQ__ListPrice__c = 100, SBQQ__Quantity__c=1, Include_In_Order__c=false));
        }
        quotelineMap.putAll(quoteLines);

        if(quotelineMap.size()>0){
            insert quotelineMap.values();
        }
        //insert quoteLines;

        Test.stopTest(); //Adding to reset governor limits
        
        //List<SBQQ__QuoteLine__c> quoteLines=new List<SBQQ__QuoteLine__c>();

        //for(Integer i=0; i<=5; i++){
        //    quoteLines.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c=q.Id, SBQQ__Product__c=prodList.get(i).Id ,  SBQQ__ListPrice__c = 100, SBQQ__Quantity__c=1, Include_In_Order__c=false));
        //}
        //Agreed_Price__c AP = new Agreed_Price__c(Discount__c= 10, Price__c = 10.00, Contract__c = contract.Id, Start_Date__c = contract.StartDate, Product__c=p2.Id, Active__c = true);
        //insert AP;
        contract.Automatic_Renewal__c = true;
        update contract;
        PageReference pageRef = Page.ContractNewAmendOpp;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('type', 'Renewal');
        //Add parameters to page URL
        ApexPages.standardController sta_controller = new ApexPages.standardController(contract);
        Ext_ContractNewAnR controller = new Ext_ContractNewAnR(sta_controller);
        controller.returnContract();
        controller.RunThat();
        controller.gotoQuote();
        List<SBQQ__QuoteLine__c> qLines = [SELECT Id FROM SBQQ__QuoteLine__c];
        System.assertEquals((qLines.size()>0), true, 'Quote Lines was not created. ' );
    }
    static testMethod void TestPageType()
    {
        TestUtility.setupConfigurationSettings();
        TestUtility.insertCustSetting('OpportunityTrigger');
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

        ID stdPBId = Test.getStandardPricebookId();

        //Pricebook2 pb = new Pricebook2(Name='TestPB', IsActive=TRUE);
        //insert pb;
        //Product2 p2 = new Product2(Description='TestProd',Family='Family',Name='MyProduct',ProductCode='123',IsActive=TRUE);
        //insert p2;
        //PricebookEntry stdpbe = new PricebookEntry(Product2Id = p2.id, IsActive = TRUE,UnitPrice=100.0,Pricebook2Id=stdPBId,UseStandardPrice=true);
        //insert stdpbe;
        ////PricebookEntry pbe = new PricebookEntry(Product2Id = p2.id, IsActive = TRUE,UnitPrice=100.0,Pricebook2Id=id,UseStandardPrice=FALSE);
        ////insert pbe;
        Opportunity opp = new Opportunity(Name='TestOpp', StageName='Qualify', CloseDate=System.today(), AccountId = acc.Id);
        insert opp;

        Pricebook2 pb = new Pricebook2(Name='TestPB', IsActive=TRUE);
        insert pb;
        //Create Products
        List<Product2> prodList=new List<Product2>();
        for(Integer i=0; i<=5; i++){
            String prodName='Product ' + string.valueOf(i);
            prodList.add(new Product2(Name = prodName, IsActive = true, Quotable__c = true));
        }

        Test.startTest(); //Adding to reset governor limits

        insert prodList;

        SBQQ__Quote__c q=new SBQQ__Quote__c(Tax_Calculated__c =true, SBQQ__Account__c=acc.Id , SBQQ__Opportunity2__c=opp.id,SBQQ__PriceBook__c=stdPBId);
        insert q;
        List<SBQQ__QuoteLine__c> quoteLines=new List<SBQQ__QuoteLine__c>();
        Map<Id,SBQQ__QuoteLine__c> quoteLineMap=new Map<Id,SBQQ__QuoteLine__c>();

        for(Integer i=0; i<=5; i++){
            quoteLines.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c=q.Id, SBQQ__Product__c=prodList.get(i).Id ,  SBQQ__ListPrice__c = 100, SBQQ__Quantity__c=1));
        }

        for(Integer i=0; i<=5; i++){
            quoteLines.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c=q.Id, SBQQ__Product__c=prodList.get(i).Id ,  SBQQ__ListPrice__c = 100, SBQQ__Quantity__c=1, Include_In_Order__c=false));
        }
        quotelineMap.putAll(quoteLines);

        if(quotelineMap.size()>0){
            insert quotelineMap.values();
        }
        //insert quoteLines;
        List<Agreed_Price__c> APLines=new List<Agreed_Price__c>();

        for(Integer i=0; i<=5; i++){
            APLines.add(new Agreed_Price__c(Discount__c= 10, Price__c = 10.00, Contract__c = contract.Id, Start_Date__c = contract.StartDate, Product__c=prodList.get(i).Id, Active__c = true));
        }
        insert APLines;

        Test.stopTest(); //Adding to reset governor limits

        PageReference pageRef = Page.ContractNewAmendOpp;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('type', 'Amendment');
        //Add parameters to page URL
        ApexPages.standardController sta_controller = new ApexPages.standardController(contract);
        Ext_ContractNewAnR controller = new Ext_ContractNewAnR(sta_controller);
        controller.returnContract();
        controller.RunThat();
        controller.gotoQuote();
        List<SBQQ__QuoteLine__c> qLines = [SELECT Id FROM SBQQ__QuoteLine__c];
        System.assertEquals((qLines.size()>0), true, 'Quote Lines was not created. ' );
    }   
    static testMethod void TestPagereturnToPrevious()
    {
         TestUtility.setupConfigurationSettings();
         TestUtility.insertCustSetting('OpportunityTrigger');
       acc = TestUtility.newAccount('Account0', 'Account0');
        insert acc;
        Contract contract = new Contract();
        contract.AccountId = acc.Id;
        contract.Status = 'Draft';
        contract.StartDate = System.today();
        contract.Contract_End_Date__c = System.today() + 5;
        insert contract;

        PageReference pageRef = Page.ContractNewAmendOpp;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('type', 'Amendment');
        //Add parameters to page URL
        ApexPages.standardController sta_controller = new ApexPages.standardController(contract);
        Ext_ContractNewAnR controller = new Ext_ContractNewAnR(sta_controller);
        controller.returnContract();
        //controller.gotoOpp();
        controller.returnToPrevious();
    }   
}