@isTest
private class test_Hologic_QCP {
    
    @isTest static void test_method_standard_contracted_list_price() {
         TestUtility.setupConfigurationSettings();
         TestUtility.insertCustSetting('OpportunityTrigger');
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
            prodList.add(new Product2(Name = prodName, IsActive = true,ProductCode='23456'));
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
                agree_price_lines.add(new Agreed_Price__c(Tier__c=1, Active__c=true, Contract__c=con.id, Start_Date__c=system.today().addDays(-5), End_Date__c=system.today().addYears(10), Price__c=2000.00, Product__c=prodList.get(i).id));
            }
            con.Status='Activated';
        }   

        
        update contractList;
        system.debug(contractList);

        Asset theAsset= TestUtility.newAsset('TestAsset', accList[0].Id, accList[0].Id, prodList[0].Id);
        theAsset.RecordTypeId = GlobalUtility.getRecordTypeId('Asset','System');
        insert theAsset;
        insert agree_price_lines;
        
        
        system.debug(agree_price_lines);

        //Create Relationship/Predence for an Account (Custom Agreement Relationship)
        List<Customer_Eligible_Contract__c> eligible=new List<Customer_Eligible_Contract__c>();
        for(Integer i=0; i<=3; i++){
            eligible.add(new Customer_Eligible_Contract__c(Selected__c=true, Contract__c=contractList.get(i).id, Effective_Date__c=system.today().addDays(-5),Expiration_Date__c=system.today().addYears(1),   Customer_Account__c=accList.get(0).id, Precedence_Value__c=i,Tier__c=1 ));
        }

        insert eligible;
        List<Customer_Eligible_Contract__c> cecs=new List<Customer_Eligible_Contract__c>([Select id, Active_Contract__c, Effective_Date__c, Expiration_Date__c, Contract__c, Agreement_Active__c,Tier__c from Customer_Eligible_Contract__c]);
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
        SBQQ__Quote__c q=new SBQQ__Quote__c(SBQQ__Account__c=accList.get(0).id, Tax_Calculated__c =true, SBQQ__Opportunity2__c=newOpp.id,SBQQ__PriceBook__c=pricebookId,SBQQ__StartDate__c=system.today(), SBQQ__EndDate__c=system.today().addMonths(12),SBQQ__SubscriptionTerm__c=12);
        q.Contract_Price_Map__c=prodList[0].ProductCode+';'+100.00+','+prodList[0].ProductCode+';'+100.00;
            q.Contract_Price_Map_Discounts__c=prodList[0].ProductCode+';'+100.00+','+prodList[0].id+';'+100.00;
        q.Contract_AgreedPrice_Map__c=prodList[0].ProductCode+';'+agree_price_lines[0].Id+','+prodList[0].ProductCode+';'+agree_price_lines[0].id;
            insert q;
        
        q.SBQQ__Primary__c = false;
        update q;

        List<SBQQ__QuoteLine__c> quoteLines=new List<SBQQ__QuoteLine__c>();
        Set<SBQQ__QuoteLine__c> quoteLineset=new Set<SBQQ__QuoteLine__c>();

        for(Integer i=0; i<=5; i++){
            quoteLineset.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c=q.Id, SBQQ__Product__c=prodList.get(i).Id ,  SBQQ__ListPrice__c = 100, SBQQ__Quantity__c=1));
        }
        //quoteLines[0].Covered_Asset__c=theAsset.Id;
        //insert quoteLines;
        quoteLines.addAll(quoteLineset);
        insert quoteLines;
        quoteLines[0].POS_Quote_Line__c = quoteLines[2].Id;
        quoteLines[1].SBQQ__RequiredBy__c = quoteLines[0].Id;
        
        update quoteLines;
        
        q.SBQQ__Primary__c = true;
        update q;
        quoteLines=[Select id,POS_Quote_Line__c,SBQQ__ProductOption__c,Covered_Asset__c,PAProductKey__c,SBQQ__Product__c,SBQQ__ListPrice__c, SBQQ__OriginalPrice__c, SBQQ__ProductCode__c,SBQQ__RequiredBy__c from SBQQ__QuoteLine__c where SBQQ__Quote__c=:q.id];
        system.debug(quoteLines);

        q=[Select Contract_AgreedPrice_Map__c,Contract_Price_Map__c, Contract_Price_Map_Discounts__c, Quote_Type__c from SBQQ__Quote__c where id=:q.id];
        
        //Price out Quote
         HologicQuoteCalculator target1 = new HologicQuoteCalculator();
        target1.onInit(quoteLines);
        target1.onBeforeCalculate(q, quoteLines);
        target1.onBeforePriceRules(q, quoteLines);
        system.debug(quoteLines);
        target1.onAfterPriceRules(q, quoteLines);
        target1.onAfterCalculate(q, quoteLines);
    

    }
    
    @isTest static void test_method_non_contracted_invalid_precedence() {
         TestUtility.setupConfigurationSettings();
         TestUtility.insertCustSetting('OpportunityTrigger');
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
            prodList.add(new Product2(Name = prodName, IsActive = true));
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
                agree_price_lines.add(new Agreed_Price__c(Tier__c=1, Active__c=true, Contract__c=con.id, Start_Date__c=system.today().addDays(-5), End_Date__c=system.today().addDays(10), Price__c=2000.00, Product__c=prodList.get(i).id));
            }
            con.Status='Activated';
        }   

        
        update contractList;
        insert agree_price_lines;
        
        
        system.debug(agree_price_lines);

        //Create Relationship/Predence for an Account (Custom Agreement Relationship)
        List<Customer_Eligible_Contract__c> eligible=new List<Customer_Eligible_Contract__c>();
        for(Integer i=0; i<=3; i++){
            eligible.add(new Customer_Eligible_Contract__c(Selected__c=true, Contract__c=contractList.get(i).id, Effective_Date__c=system.today(),Expiration_Date__c=system.today().addYears(1),  Customer_Account__c=accList.get(0).id, Precedence_Value__c=1,Tier__c=1 ));
        }

        insert eligible;
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
        SBQQ__Quote__c q=new SBQQ__Quote__c(Tax_Calculated__c =true, Customer_Eligible_Contract__c=eligible.get(0).id, Marketing_Program__c='None', Quote_Type__c='Non-Contracted Pricing', SBQQ__Account__c=accList.get(0).id, SBQQ__Opportunity2__c=newOpp.id,SBQQ__PriceBook__c=pricebookId,SBQQ__StartDate__c=system.today(), SBQQ__EndDate__c=system.today().addMonths(12),SBQQ__SubscriptionTerm__c=12);
        insert q;
        
        q.SBQQ__Primary__c = false;
        update q;

        SBQQ__Quote__c quotetest=[Select id, Customer_Eligible_Contract__c from SBQQ__Quote__c where id=:q.id];
        system.debug(q);

        List<SBQQ__QuoteLine__c> quoteLines=new List<SBQQ__QuoteLine__c>();
        Set<SBQQ__QuoteLine__c> quoteLineset=new Set<SBQQ__QuoteLine__c>();

        for(Integer i=0; i<=5; i++){
            quoteLineset.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c=q.Id, SBQQ__Product__c=prodList.get(i).Id ,  SBQQ__ListPrice__c = 100, SBQQ__Quantity__c=1));
        }

        //insert quoteLines;
        quoteLines.addAll(quoteLineset);

        insert quoteLines;

        quoteLines=[Select id,SBQQ__ProductOption__c,POS_Quote_Line__c,Covered_Asset__c,SBQQ__Product__c,SBQQ__ListPrice__c, PAProductKey__c,SBQQ__OriginalPrice__c, SBQQ__ProductCode__c,SBQQ__RequiredBy__c from SBQQ__QuoteLine__c where SBQQ__Quote__c=:q.id];
        system.debug(quoteLines);

        //Price out Quote
         HologicQuoteCalculator target1 = new HologicQuoteCalculator();
        target1.onInit(quoteLines);
        target1.onBeforeCalculate(q, quoteLines);
        target1.onBeforePriceRules(q, quoteLines);
        system.debug(quoteLines);
        target1.onAfterPriceRules(q, quoteLines);
        target1.onAfterCalculate(q, quoteLines);
    

    }
    
    @isTest static void test_method_standard_contracted_list_price_no_tiers() {
         TestUtility.setupConfigurationSettings();
         TestUtility.insertCustSetting('OpportunityTrigger');
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
            prodList.add(new Product2(Name = prodName, IsActive = true));
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
                agree_price_lines.add(new Agreed_Price__c(Tier__c=null, Active__c=true, Contract__c=con.id, Start_Date__c=system.today().addDays(-5), End_Date__c=system.today().addDays(10), Price__c=2000.00, Product__c=prodList.get(i).id));
            }
            con.Status='Activated';
        }   

        
        update contractList;
        insert agree_price_lines;
        
        
        system.debug(agree_price_lines);

        //Create Relationship/Predence for an Account (Custom Agreement Relationship)
        List<Customer_Eligible_Contract__c> eligible=new List<Customer_Eligible_Contract__c>();
        for(Integer i=0; i<=3; i++){
            eligible.add(new Customer_Eligible_Contract__c(Selected__c=true, Contract__c=contractList.get(i).id, Effective_Date__c=system.today(),Expiration_Date__c=system.today().addYears(1),   Customer_Account__c=accList.get(0).id, Precedence_Value__c=i,Tier__c=null ));
        }

        insert eligible;
        List<Customer_Eligible_Contract__c> cecs=new List<Customer_Eligible_Contract__c>([Select id, Contract__c, Agreement_Active__c,Tier__c from Customer_Eligible_Contract__c]);
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
        SBQQ__Quote__c q=new SBQQ__Quote__c(Tax_Calculated__c =true, Customer_Eligible_Contract__c=eligible.get(0).id, SBQQ__Account__c=accList.get(0).id, SBQQ__Opportunity2__c=newOpp.id,SBQQ__PriceBook__c=pricebookId,SBQQ__StartDate__c=system.today(), SBQQ__EndDate__c=system.today().addMonths(12),SBQQ__SubscriptionTerm__c=12);
        insert q;

        List<SBQQ__QuoteLine__c> quoteLines=new List<SBQQ__QuoteLine__c>();
        Map<Id,SBQQ__QuoteLine__c> quoteLineMap=new Map<Id,SBQQ__QuoteLine__c>();

        for(Integer i=0; i<=5; i++){
            quoteLines.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c=q.Id, SBQQ__Product__c=prodList.get(i).Id ,  SBQQ__ListPrice__c = 100, SBQQ__Quantity__c=1));
        }

        //insert quoteLines;
        quotelineMap.putAll(quoteLines);

        if(quotelineMap.size()>0){
            insert quotelineMap.values();
        }

        quoteLines=[Select id,SBQQ__ProductOption__c,POS_Quote_Line__c,Covered_Asset__c,SBQQ__Product__c,SBQQ__ListPrice__c, PAProductKey__c, SBQQ__OriginalPrice__c, SBQQ__ProductCode__c,SBQQ__RequiredBy__c from SBQQ__QuoteLine__c where SBQQ__Quote__c=:q.id];
        system.debug(quoteLines);

        //Price out Quote
         HologicQuoteCalculator target1 = new HologicQuoteCalculator();
        target1.onInit(quoteLines);
        target1.onBeforeCalculate(q, quoteLines);
        target1.onBeforePriceRules(q, quoteLines);
        system.debug(quoteLines);
        target1.onAfterPriceRules(q, quoteLines);
        target1.onAfterCalculate(q, quoteLines);
    

    }

    @isTest static void test_method_non_contracted_contract_only() {
         TestUtility.setupConfigurationSettings();
         TestUtility.insertCustSetting('OpportunityTrigger');
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
            prodList.add(new Product2(Name = prodName, IsActive = true));
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
                agree_price_lines.add(new Agreed_Price__c(Tier__c=1, Active__c=true, Contract__c=con.id, Start_Date__c=system.today().addDays(-5), End_Date__c=system.today().addDays(10), Price__c=2000.00, Product__c=prodList.get(i).id));
            }
            con.Status='Activated';
        }   

        
        update contractList;
        insert agree_price_lines;
        
        
        system.debug(agree_price_lines);

        //NO CECS
        //List<Customer_Eligible_Contract__c> eligible=new List<Customer_Eligible_Contract__c>();
        //for(Integer i=0; i<=3; i++){
        //  eligible.add(new Customer_Eligible_Contract__c(Selected__c=true, Contract__c=contractList.get(i).id, Effective_Date__c=system.today(),Expiration_Date__c=system.today().addYears(1),   Customer_Account__c=accList.get(0).id, Precedence_Value__c=1,Tier__c=1 ));
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
        SBQQ__Quote__c q=new SBQQ__Quote__c(Price_Agreement__c=contractList.get(0).id, Tax_Calculated__c =true,  Marketing_Program__c='None', Quote_Type__c='Non-Contracted Pricing', SBQQ__Account__c=accList.get(0).id, SBQQ__Opportunity2__c=newOpp.id,SBQQ__PriceBook__c=pricebookId,SBQQ__StartDate__c=system.today(), SBQQ__EndDate__c=system.today().addMonths(12),SBQQ__SubscriptionTerm__c=12);
        insert q;

        SBQQ__Quote__c quotetest=[Select id, Customer_Eligible_Contract__c from SBQQ__Quote__c where id=:q.id];
        system.debug(q);

        List<SBQQ__QuoteLine__c> quoteLines=new List<SBQQ__QuoteLine__c>();
        Map<Id,SBQQ__QuoteLine__c> quoteLineMap=new Map<Id,SBQQ__QuoteLine__c>();

        for(Integer i=0; i<=5; i++){
            quoteLines.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c=q.Id, SBQQ__Product__c=prodList.get(i).Id ,  SBQQ__ListPrice__c = 100, SBQQ__Quantity__c=1));
        }

        //insert quoteLines;
        quotelineMap.putAll(quoteLines);

        if(quotelineMap.size()>0){
            insert quotelineMap.values();
        }

        quoteLines=[Select id,SBQQ__Product__c,SBQQ__ProductOption__c,POS_Quote_Line__c,Covered_Asset__c,SBQQ__ListPrice__c, PAProductKey__c, SBQQ__OriginalPrice__c, SBQQ__ProductCode__c,SBQQ__RequiredBy__c from SBQQ__QuoteLine__c where SBQQ__Quote__c=:q.id];
        system.debug(quoteLines);

        //Price out Quote
         HologicQuoteCalculator target1 = new HologicQuoteCalculator();
        target1.onInit(quoteLines);
        target1.onBeforeCalculate(q, quoteLines);
        target1.onBeforePriceRules(q, quoteLines);
        system.debug(quoteLines);
        target1.onAfterPriceRules(q, quoteLines);
        target1.onAfterCalculate(q, quoteLines);
    

    }

    @isTest static void test_method_use_list_price() {
         TestUtility.setupConfigurationSettings();
         TestUtility.insertCustSetting('OpportunityTrigger');
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
            prodList.add(new Product2(Name = prodName, IsActive = true));
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
                agree_price_lines.add(new Agreed_Price__c(Tier__c=1, Active__c=true, Contract__c=con.id, Start_Date__c=system.today().addDays(-5), End_Date__c=system.today().addDays(10), Price__c=2000.00, Product__c=prodList.get(i).id));
            }
            con.Status='Activated';
        }   

        
        update contractList;
        insert agree_price_lines;
        
        
        system.debug(agree_price_lines);

        //NO CECS
        //List<Customer_Eligible_Contract__c> eligible=new List<Customer_Eligible_Contract__c>();
        //for(Integer i=0; i<=3; i++){
        //  eligible.add(new Customer_Eligible_Contract__c(Selected__c=true, Contract__c=contractList.get(i).id, Effective_Date__c=system.today(),Expiration_Date__c=system.today().addYears(1),   Customer_Account__c=accList.get(0).id, Precedence_Value__c=1,Tier__c=1 ));
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
        SBQQ__Quote__c q=new SBQQ__Quote__c(Price_Agreement__c=contractList.get(0).id, Use_List_price__c=true, Tax_Calculated__c =true,  Marketing_Program__c='None', Quote_Type__c='Non-Contracted Pricing', SBQQ__Account__c=accList.get(0).id, SBQQ__Opportunity2__c=newOpp.id,SBQQ__PriceBook__c=pricebookId,SBQQ__StartDate__c=system.today(), SBQQ__EndDate__c=system.today().addMonths(12),SBQQ__SubscriptionTerm__c=12);
        insert q;

        SBQQ__Quote__c quotetest=[Select id, Customer_Eligible_Contract__c from SBQQ__Quote__c where id=:q.id];
        system.debug(q);

        List<SBQQ__QuoteLine__c> quoteLines=new List<SBQQ__QuoteLine__c>();
        Map<Id,SBQQ__QuoteLine__c> quoteLineMap=new Map<Id,SBQQ__QuoteLine__c>();

        for(Integer i=0; i<=5; i++){
            quoteLines.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c=q.Id, SBQQ__Product__c=prodList.get(i).Id ,  SBQQ__ListPrice__c = 100, SBQQ__Quantity__c=1));
        }

        //insert quoteLines;
        quotelineMap.putAll(quoteLines);

        if(quotelineMap.size()>0){
            insert quotelineMap.values();
        }

        quoteLines=[Select id,SBQQ__Product__c,SBQQ__ProductOption__c,POS_Quote_Line__c,Covered_Asset__c,SBQQ__ListPrice__c, PAProductKey__c, SBQQ__OriginalPrice__c, SBQQ__ProductCode__c,SBQQ__RequiredBy__c from SBQQ__QuoteLine__c where SBQQ__Quote__c=:q.id];
        system.debug(quoteLines);

        //Price out Quote
         HologicQuoteCalculator target1 = new HologicQuoteCalculator();
        target1.onInit(quoteLines);
        target1.onBeforeCalculate(q, quoteLines);
        target1.onBeforePriceRules(q, quoteLines);
        system.debug(quoteLines);
        target1.onAfterPriceRules(q, quoteLines);
        target1.onAfterCalculate(q, quoteLines);
    

    }
}