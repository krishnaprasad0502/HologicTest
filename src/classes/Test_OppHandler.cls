@isTest 
private class Test_OppHandler 
{
    private static Account parent;
    public static contact con;

    static testMethod void OppTrigger() 
    {

        // setup data
         TestUtility.setupConfigurationSettings();
         
        Trigger_Switch__c ts = new Trigger_Switch__c();
        ts.Name = 'Contracttrigger';
        ts.Active__c = true;
        insert ts;
        
        Trigger_Switch__c tsop= new Trigger_Switch__c();
        tsop.Name = 'OpportunityTrigger';
        tsop.Active__c = true;        
        insert tsop;

         // need to make sure the triggers are turned on
        Trigger_Switch__c cs1 = new Trigger_Switch__c(name = 'CreateContractAgreePrice', Active__c = true);
        insert cs1;
        Trigger_Switch__c cs2 = new Trigger_Switch__c(name = 'SBQQ_QuoteTrigger', Active__c = true);
        insert cs2;
        parent = TestUtility.newAccount('Account0', 'Account0');
        insert parent;
        
        Con = TestUtility.newContact('Firstname ','Lastname ', parent.id);
        con.Phone = '+(999) 999-9999';
         insert con;

        Id pricebookId = Test.getStandardPricebookId();

        // create opportunity
        Opportunity newOpp = new Opportunity();
        newOpp.AccountId = parent.Id;
        newOpp.StageName = 'Target';
        newOpp.CloseDate = System.today();
        newOpp.Name = 'OppTest';
        newOpp.Pricebook2Id = pricebookId;
        
        insert newOpp;

        

        //Create Products
        List<Product2> prodList=new List<Product2>();
        for(Integer i=0; i<=5; i++){
            String prodName='Product ' + string.valueOf(i);
            prodList.add(new Product2(Name = prodName, IsActive = true, Quotable__c = true));
        }

        insert prodList;
        

        //Create Price Book Entries
        List<PricebookEntry> priceentires=new List<PricebookEntry>();

        for(Integer i=0; i<=5; i++){
            priceentires.add(new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = prodList.get(i).id, UnitPrice= 2000.00, IsActive = true));
        }

        //create quote
        SBQQ__Quote__c q=new SBQQ__Quote__c(Tax_Calculated__c =true,ApprovalStatus__c='Approved',SBQQ__Account__c=parent.Id , SBQQ__Opportunity2__c=newOpp.id,SBQQ__PriceBook__c=pricebookId,SBQQ__StartDate__c=system.today(), SBQQ__SubscriptionTerm__c=12);
 
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
        q.ApprovalStatus__c='Approved';
        update q;



        Test.startTest();
        //mark the quote as primary
        newOpp.SBQQ__PrimaryQuote__c=q.id;
        newOpp.StageName = 'Closed Won';
        newOpp.CloseDate = System.today();
        newOpp.Pricing_Agreement_Created__c = true;
        newOpp.LPS_Contact__c = con.id;
        update newOpp;
        System.assertNotEquals([select Id from Contract where SBQQ__Quote__c = : q.id], null);

        Test.stopTest();


    }
    
    static testMethod void OppTrigger_Amendments() 
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
        
         // make sure the triggers are enabled
        Trigger_Switch__c cs1 = new Trigger_Switch__c(name = 'CreateContractAgreePrice', Active__c = true);
        insert cs1;
        Trigger_Switch__c cs2 = new Trigger_Switch__c(name = 'SBQQ_QuoteTrigger', Active__c = true);
        insert cs2;

        //setup data
        parent = TestUtility.newAccount('Account0', 'Account0');
        insert parent;
        
        Con = TestUtility.newContact('Firstname ','Lastname ', parent.id);
        con.Phone = '+(999) 999-9999';
         insert con;

        Id pricebookId = Test.getStandardPricebookId();

        // create opportunity
        Opportunity newOpp = new Opportunity();
        newOpp.AccountId = parent.Id;
        newOpp.StageName = 'Target';
        newOpp.CloseDate = System.today();
        newOpp.Name = 'OppTest';
        newOpp.Pricebook2Id = pricebookId;
        insert newOpp;

        



        //Create Products
        List<Product2> prodList=new List<Product2>();
        for(Integer i=0; i<=5; i++){
            String prodName='Product ' + string.valueOf(i);
            prodList.add(new Product2(Name = prodName, IsActive = true, Quotable__c = true));
        }

        insert prodList;



        //Create Price Book Entries
        List<PricebookEntry> priceentires=new List<PricebookEntry>();

        for(Integer i=0; i<=5; i++){
            priceentires.add(new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = prodList.get(i).id, UnitPrice= 2000.00, IsActive = true));
        }

        //insert priceentires;

        Contract contract=new Contract(StartDate=system.today().addDays(-5), Accountid=parent.id, Contract_End_Date__c=system.today().addDays(10) );
        insert contract;
        
        //Create Pricing Agreement Lines for each Contract
        List<Agreed_Price__c> agree_price_lines=new List<Agreed_Price__c>();
        
        
        for(Integer i=0; i<=5; i++){
            agree_price_lines.add(new Agreed_Price__c(Active__c=true, Contract__c=contract.id, Start_Date__c=system.today().addDays(-5), End_Date__c=system.today().addDays(10), Price__c=2000.00, Product__c=prodList.get(i).id));
        }
        contract.Status='Activated';
        
        insert agree_price_lines;
        update contract;


        SBQQ__Quote__c q=new SBQQ__Quote__c(Tax_Calculated__c =true,SBQQ__Account__c=parent.Id , SBQQ__Opportunity2__c=newOpp.id,SBQQ__PriceBook__c=pricebookId,SBQQ__StartDate__c=system.today(), SBQQ__SubscriptionTerm__c=12);
 
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
        q.ApprovalStatus__c='Approved';
        update q;

        Test.startTest();
        newOpp.SBQQ__AmendedContract__c=contract.id;
        newOpp.SBQQ__PrimaryQuote__c=q.id;
        newOpp.StageName = 'Closed Won';
        newOpp.CloseDate = System.today();
        newOpp.Renewal_Contract_End_Date__c=system.today();
        newOpp.Pricing_Agreement_Created__c = true;
        newOpp.LPS_Contact__c = con.id;
        update newOpp;
        system.assertEquals([select Price__c from Agreed_Price__c where Id=:agree_price_lines[0].Id].Price__c,2000);
        Test.stopTest();


    }
}