@isTest
private class Test_SBQQ_QuoteTriggerHandler {
       
    static testMethod void testSBQQQuoteHandler()
    {
        TestUtility.setupConfigurationSettings();
                
        TestUtility.insertCustSetting('OpportunityTrigger');

        Trigger_Switch__c cs1 = new Trigger_Switch__c(name = 'CreateContractAgreePrice', Active__c = true);
        insert cs1;
        Trigger_Switch__c cs2 = new Trigger_Switch__c(name = 'SBQQ_QuoteTrigger', Active__c = true);
        insert cs2;     
        //Create Products
        List<Product2> prodList=new List<Product2>();
        for(Integer i=0; i<=5; i++){
            String prodName='Product ' + string.valueOf(i);
            prodList.add(new Product2(Name = prodName, IsActive = true));
        }

        insert prodList;
        Account acc = TestUtility.newAccount('Account0', 'Account0');
        insert acc;
        Contract contract = new Contract();
        contract.AccountId = acc.Id;
        contract.Status = 'Draft';
        contract.StartDate = System.today();
        contract.Contract_End_Date__c = System.today() + 5;
        insert contract;
        contract.Status = 'Activated';
        update contract;
         List<Agreed_Price__c> agree_price_lines=new List<Agreed_Price__c>();
          for(Integer i=0; i<=5; i++){
                agree_price_lines.add(new Agreed_Price__c(Active__c=true, Contract__c=contract.id, Start_Date__c=contract.StartDate, End_Date__c=contract.Contract_End_Date__c, Price__c=2000.00, Product__c=prodList.get(i).id));
            }
        insert agree_price_lines;
        
        Customer_Eligible_Contract__c cec = new Customer_Eligible_Contract__c(Selected__c=true, Contract__c=contract.id, Effective_Date__c=contract.StartDate,   Expiration_Date__c = contract.Contract_End_Date__c,Customer_Account__c=acc.id, Precedence_Value__c=1);
        insert cec;
        
        Id pricebookId = Test.getStandardPricebookId();
        Test.startTest();

        Opportunity newOpp = new Opportunity();
        newOpp.AccountId = acc.Id;
        newOpp.StageName = 'Target';
        newOpp.CloseDate = System.today();
        newOpp.Name = 'OppTest';
        //newOpp.Pricebook2Id = pb2.Id;
        insert newOpp;
        
        SBQQ__Quote__c q=new SBQQ__Quote__c(Tax_Calculated__c =true, SBQQ__Account__c=acc.Id , SBQQ__Opportunity2__c=newOpp.id,SBQQ__PriceBook__c=pricebookId);
        q.Customer_Eligible_Contract__c = cec.Id;
        insert q;
        Test.stopTest();
        q.Quote_Name__c='test';
        update q;
    }

    
}