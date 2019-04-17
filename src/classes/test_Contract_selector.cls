@isTest
private class test_Contract_selector {
    
    @isTest static void test_no_CECs() {
        TestUtility.setupConfigurationSettings();
        Trigger_Switch__c ts = new Trigger_Switch__c();
        ts.Name = 'OpportunityTrigger';
        ts.Active__c = true;
        insert ts;
       // Create Account(s)
        List<Account> accList=new List<Account>();
        for(Integer i=0; i<=3; i++){
            String accName='Test Account ' + string.valueOf(i);
            accList.add(TestUtility.newAccount(accName, accName));
        }

        insert accList;
        //Create Opportunity


        Id pricebookId = Test.getStandardPricebookId();
        //Create Products
        List<Product2> prodList=new List<Product2>();
        for(Integer i=0; i<=5; i++){
            String prodName='Product ' + string.valueOf(i);
            prodList.add(new Product2(Name = prodName, IsActive = true,Quotable__c=true));
        }

        insert prodList;
        system.debug('prodList----'+prodList);
        

        //Create Price Book Entries
        //List<PricebookEntry> priceentires=new List<PricebookEntry>();

        //for(Integer i=0; i<=5; i++){
        //  priceentires.add(new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = prodList.get(i).id, UnitPrice= 2000.00, IsActive = true));
        //}

        //insert priceentires;
        
        //Create Contract(s) for each Account
        List<Contract> contractList=new List<Contract>();
        for(Integer i=0; i<=3; i++){
            String conName='Test Contract ' + string.valueOf(i);
            contractList.add(new Contract(StartDate=system.today().addDays(-5), Accountid=accList.get(i).id, Contract_End_Date__c=system.today().addYears(10) ));
        }
        insert contractList;


        //Create Pricing Agreement Lines for each Contract
        List<Agreed_Price__c> agree_price_lines=new List<Agreed_Price__c>();
        
        for(Contract con:contractList){
            for(Integer i=0; i<=5; i++){
                agree_price_lines.add(new Agreed_Price__c(/*Tier__c=1, */Active__c=true, Contract__c=con.id, Start_Date__c=system.today().addDays(-5), End_Date__c=system.today().addDays(10), Price__c=2000.00, Product__c=prodList.get(i).id));
            }
            con.Status='Activated';
        }   

        
        update contractList;
        insert agree_price_lines;
        
        
        system.debug(agree_price_lines);

        //NO CECS
        //List<Customer_Eligible_Contract__c> eligible=new List<Customer_Eligible_Contract__c>();
        //for(Integer i=0; i<=3; i++){
        //  eligible.add(new Customer_Eligible_Contract__c(Selected__c=true, Contract__c=contractList.get(i).id, Effective_Date__c=system.today(),Expiration_Date__c=system.today().addYears(1),  Customer_Account__c=accList.get(0).id, Precedence_Value__c=1,Tier__c=1 ));
        //}

        //insert eligible;
        //List<Customer_Eligible_Contract__c> cecs=new List<Customer_Eligible_Contract__c>([Select id, Contract__c, Agreement_Active__c,Tier__c from Customer_Eligible_Contract__c]);
        //system.debug(cecs);
        

        //Create Opp
        Opportunity newOpp = new Opportunity();
        newOpp.AccountId = accList.get(0).id;
        newOpp.StageName = 'Target';
        newOpp.CloseDate = System.today();
        newOpp.Name = 'OppTest';
        newOpp.Pricebook2Id = pricebookId;
        insert newOpp;

        //Create Quote/Quote Lines
        SBQQ__Quote__c q=new SBQQ__Quote__c(Price_Agreement__c=contractList.get(0).id, Tax_Calculated__c =true,  Marketing_Program__c='None', Quote_Type__c='Non-Contracted Pricing', SBQQ__Account__c=accList.get(0).id, SBQQ__Opportunity2__c=newOpp.id,SBQQ__PriceBook__c=pricebookId,SBQQ__StartDate__c=system.today(), SBQQ__EndDate__c=system.today().addMonths(12),SBQQ__SubscriptionTerm__c=12,Contract_Update_Check__c = true);
        insert q;
        
        List<SBQQ__QuoteLine__c> quoteLines=new List<SBQQ__QuoteLine__c>();
        Map<Id,SBQQ__QuoteLine__c> quoteLineMap=new Map<Id,SBQQ__QuoteLine__c>();
        
        for(Integer i=0; i<=5; i++){
            quoteLines.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c=q.Id, SBQQ__Product__c=prodList.get(i).Id ,  SBQQ__ListPrice__c = 100, SBQQ__Quantity__c=1));
        }
        quotelineMap.putAll(quoteLines);

        if(quotelineMap.size()>0){
            insert quotelineMap.values();
        }
        //quoteLines.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c=q.Id, SBQQ__Product__c=prodList.get(0).Id ,  SBQQ__ListPrice__c = 100, SBQQ__Quantity__c=1));
        //quoteLines[0].Covered_Asset__c=theAsset.Id;
        system.debug('quoteLines----'+quoteLines);
        //insert quoteLines;
        system.debug('quoteLines----'+quoteLines);

        PageReference pageRef = Page.Contract_Selector;
        Test.setCurrentPage(pageRef);
        ApexPages.standardController sta_controller = new ApexPages.standardController(q);
        Ext_Contract_Selector_Quote controller = new Ext_Contract_Selector_Quote(sta_controller);
        controller.RunThat();
        system.assertEquals(controller.CountTotalRecords,0);
        //controller.selectedContract=contractList.get(0).id;
        controller.saveContract();
        controller.returnToPrevious();

    }
    
    @isTest static void test_invalid_CECs() {
        TestUtility.setupConfigurationSettings();
        Trigger_Switch__c ts = new Trigger_Switch__c();
        ts.Name = 'OpportunityTrigger';
        ts.Active__c = true;
        insert ts;
       // Create Account(s)
        List<Account> accList=new List<Account>();
        for(Integer i=0; i<=3; i++){
            String accName='Test Account ' + string.valueOf(i);
            accList.add(TestUtility.newAccount(accName, accName));
        }

        insert accList;
        //Create Opportunity


        Id pricebookId = Test.getStandardPricebookId();
        //Create Products
        List<Product2> prodList=new List<Product2>();
        for(Integer i=0; i<=5; i++){
            String prodName='Product ' + string.valueOf(i);
            prodList.add(new Product2(Name = prodName, IsActive = true,Quotable__c=true));
        }

        insert prodList;
        

        //Create Price Book Entries
        //List<PricebookEntry> priceentires=new List<PricebookEntry>();

        //for(Integer i=0; i<=5; i++){
        //  priceentires.add(new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = prodList.get(i).id, UnitPrice= 2000.00, IsActive = true));
        //}

        //insert priceentires;
        
        //Create Contract(s) for each Account
        List<Contract> contractList=new List<Contract>();
        for(Integer i=0; i<=3; i++){
            String conName='Test Contract ' + string.valueOf(i);
            contractList.add(new Contract(StartDate=system.today().addDays(-5), Accountid=accList.get(i).id, Contract_End_Date__c=system.today().addYears(10) ));
        }
        insert contractList;


        //Create Pricing Agreement Lines for each Contract
        List<Agreed_Price__c> agree_price_lines=new List<Agreed_Price__c>();
        
        for(Contract con:contractList){
            for(Integer i=0; i<=5; i++){
                agree_price_lines.add(new Agreed_Price__c(/*Tier__c=1,*/ Active__c=true, Contract__c=con.id, Start_Date__c=system.today().addDays(-5), End_Date__c=system.today().addDays(10), Price__c=2000.00, Product__c=prodList.get(i).id));
            }
            con.Status='Activated';
        }   

        
        update contractList;
        insert agree_price_lines;
        
        
        system.debug(agree_price_lines);

        
        List<Customer_Eligible_Contract__c> eligible=new List<Customer_Eligible_Contract__c>();
        for(Integer i=0; i<=3; i++){
            eligible.add(new Customer_Eligible_Contract__c(Selected__c=true, Contract__c=contractList.get(i).id, Effective_Date__c=system.today(),Expiration_Date__c=system.today().addYears(1),  Customer_Account__c=accList.get(0).id, Precedence_Value__c=1/*,Tier__c=1*/ ));
        }

        insert eligible;
        List<Customer_Eligible_Contract__c> cecs=new List<Customer_Eligible_Contract__c>([Select id, Contract__c, Agreement_Active__c/*,Tier__c*/ from Customer_Eligible_Contract__c]);
        system.debug(cecs);
        

        //Create Opp
        Opportunity newOpp = new Opportunity();
        newOpp.AccountId = accList.get(0).id;
        newOpp.StageName = 'Target';
        newOpp.CloseDate = System.today();
        newOpp.Name = 'OppTest';
        newOpp.Pricebook2Id = pricebookId;
        insert newOpp;

        //Create Quote/Quote Lines
        SBQQ__Quote__c q=new SBQQ__Quote__c(Price_Agreement__c=contractList.get(0).id, Tax_Calculated__c =true,  Marketing_Program__c='None', Quote_Type__c='Non-Contracted Pricing', SBQQ__Account__c=accList.get(0).id, SBQQ__Opportunity2__c=newOpp.id,SBQQ__PriceBook__c=pricebookId,SBQQ__StartDate__c=system.today(), SBQQ__EndDate__c=system.today().addMonths(12),SBQQ__SubscriptionTerm__c=12,Contract_Update_Check__c = false);
        insert q;      

        List<SBQQ__QuoteLine__c> quoteLines=new List<SBQQ__QuoteLine__c>();
        Map<Id,SBQQ__QuoteLine__c> quoteLineMap=new Map<Id,SBQQ__QuoteLine__c>();
        
        for(Integer i=0; i<=5; i++){
            quoteLines.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c=q.Id, SBQQ__Product__c=prodList.get(i).Id ,  SBQQ__ListPrice__c = 100, SBQQ__Quantity__c=1));
        }
        quotelineMap.putAll(quoteLines);
        
        if(quotelineMap.size()>0){
            insert quotelineMap.values();
        }
        //quoteLines[0].Covered_Asset__c=theAsset.Id;
        system.debug('quoteLines----'+quoteLines);
        //insert quoteLines;
        system.debug('quoteLines----'+quoteLines);

        PageReference pageRef = Page.Contract_Selector;
        Test.setCurrentPage(pageRef);
        ApexPages.standardController sta_controller = new ApexPages.standardController(q);
        Ext_Contract_Selector_Quote controller = new Ext_Contract_Selector_Quote(sta_controller);
        controller.RunThat();
        controller.selectedContract=contractList.get(0).id;
        controller.getDisablePrevious();
        controller.getDisableNext();
        controller.Next();
        controller.Previous();
        controller.saveContract();
        controller.returnToPrevious();

    }

    @isTest static void test_invalid_Quote_Tax() {
        TestUtility.setupConfigurationSettings();
        Trigger_Switch__c ts = new Trigger_Switch__c();
        ts.Name = 'OpportunityTrigger';
        ts.Active__c = true;
        insert ts;
        // Create Account(s)
        List<Account> accList=new List<Account>();
        for(Integer i=0; i<=3; i++){
            String accName='Test Account ' + string.valueOf(i);
            accList.add(TestUtility.newAccount(accName, accName));
        }

        insert accList;
        //Create Opportunity


        Id pricebookId = Test.getStandardPricebookId();
        //Create Products
        List<Product2> prodList=new List<Product2>();
        for(Integer i=0; i<=5; i++){
            String prodName='Product ' + string.valueOf(i);
            prodList.add(new Product2(Name = prodName, IsActive = true,Quotable__c=true));
        }

        insert prodList;
        

        //Create Price Book Entries
        //List<PricebookEntry> priceentires=new List<PricebookEntry>();

        //for(Integer i=0; i<=5; i++){
        //  priceentires.add(new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = prodList.get(i).id, UnitPrice= 2000.00, IsActive = true));
        //}

        //insert priceentires;
        
        //Create Contract(s) for each Account
        List<Contract> contractList=new List<Contract>();
        for(Integer i=0; i<=3; i++){
            String conName='Test Contract ' + string.valueOf(i);
            contractList.add(new Contract(StartDate=system.today().addDays(-5), Accountid=accList.get(i).id, Contract_End_Date__c=system.today().addYears(10) ));
        }
        insert contractList;


        //Create Pricing Agreement Lines for each Contract
        List<Agreed_Price__c> agree_price_lines=new List<Agreed_Price__c>();
        
        for(Contract con:contractList){
            for(Integer i=0; i<=5; i++){
                agree_price_lines.add(new Agreed_Price__c( Active__c=true, Contract__c=con.id, Start_Date__c=system.today().addDays(-5), End_Date__c=system.today().addDays(10), Price__c=2000.00, Product__c=prodList.get(i).id));
                //agree_price_lines.add(new Agreed_Price__c(Tier__c=1, Active__c=true, Contract__c=con.id, Start_Date__c=system.today().addDays(-5), End_Date__c=system.today().addDays(10), Price__c=2000.00, Product__c=prodList.get(i).id));
            }
            con.Status='Activated';
        }   

        
        update contractList;
        insert agree_price_lines;
        
        
        system.debug(agree_price_lines);

        
        List<Customer_Eligible_Contract__c> eligible=new List<Customer_Eligible_Contract__c>();
        for(Integer i=0; i<=3; i++){
            eligible.add(new Customer_Eligible_Contract__c(Selected__c=true, Contract__c=contractList.get(i).id, Effective_Date__c=system.today(),Expiration_Date__c=system.today().addYears(1),  Customer_Account__c=accList.get(0).id, Precedence_Value__c=1/*,Tier__c=1 */));
        }

        insert eligible;
        List<Customer_Eligible_Contract__c> cecs=new List<Customer_Eligible_Contract__c>([Select id, Contract__c, Agreement_Active__c /*,Tier__c*/ from Customer_Eligible_Contract__c]);
        system.debug(cecs);
        

        //Create Opp
        Opportunity newOpp = new Opportunity();
        newOpp.AccountId = accList.get(0).id;
        newOpp.StageName = 'Target';
        newOpp.CloseDate = System.today();
        newOpp.Name = 'OppTest';
        newOpp.Pricebook2Id = pricebookId;
        insert newOpp;

        //Create Quote/Quote Lines
        SBQQ__Quote__c q=new SBQQ__Quote__c(Price_Agreement__c=contractList.get(0).id,  Tax_Calculated__c =true, Marketing_Program__c='None', Quote_Type__c='Non-Contracted Pricing', SBQQ__Account__c=accList.get(0).id, SBQQ__Opportunity2__c=newOpp.id,SBQQ__PriceBook__c=pricebookId,SBQQ__StartDate__c=system.today(), SBQQ__EndDate__c=system.today().addMonths(12),SBQQ__SubscriptionTerm__c=12,Contract_Update_Check__c = true);
        insert q;
        
        List<SBQQ__QuoteLine__c> quoteLines=new List<SBQQ__QuoteLine__c>();
        Map<Id,SBQQ__QuoteLine__c> quoteLineMap=new Map<Id,SBQQ__QuoteLine__c>();
        
        for(Integer i=0; i<=5; i++){
            quoteLines.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c=q.Id, SBQQ__Product__c=prodList.get(i).Id ,  SBQQ__ListPrice__c = 100, SBQQ__Quantity__c=1));
        }
        quotelineMap.putAll(quoteLines);
        
        if(quotelineMap.size()>0){
            insert quotelineMap.values();
        }
        //quoteLines[0].Covered_Asset__c=theAsset.Id;
        system.debug('quoteLines----'+quoteLines);
        //insert quoteLines;
        system.debug('quoteLines----'+quoteLines);
        

        PageReference pageRef = Page.Contract_Selector;
        Test.setCurrentPage(pageRef);
        ApexPages.standardController sta_controller = new ApexPages.standardController(q);
        Ext_Contract_Selector_Quote controller = new Ext_Contract_Selector_Quote(sta_controller);
        controller.RunThat();
        controller.myQuote.Tax_Calculated__c =false;
        controller.selectedContract=contractList.get(0).id;
        controller.saveContract();
        controller.returnToPrevious();

    }
    
}