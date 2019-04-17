@isTest
private class SBQQ_QuoteTriggerHandler_Test {
  
  @isTest static void test_method_one() {
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
      prodList.add(new Product2(Name = prodName, IsActive = true, Quotable__c = true));
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
        agree_price_lines.add(new Agreed_Price__c(Active__c=true, Contract__c=con.id, Start_Date__c=system.today().addDays(-5), End_Date__c=system.today().addDays(10), Price__c=2000.00, Product__c=prodList.get(i).id));
      }
      con.Status='Activated';
    }  

    
    update contractList;
    insert agree_price_lines;
    
    


    //Create Relationship/Predence for an Account (Custom Agreement Relationship)
    List<Customer_Eligible_Contract__c> eligible=new List<Customer_Eligible_Contract__c>();
    for(Integer i=0; i<=3; i++){
      eligible.add(new Customer_Eligible_Contract__c(Selected__c=true, Contract__c=contractList.get(i).id, Effective_Date__c=system.today(),Expiration_Date__c=system.today().addYears(1),  Customer_Account__c=accList.get(0).id, Precedence_Value__c=i ));
    }

    insert eligible;
    List<Customer_Eligible_Contract__c> cecs=new List<Customer_Eligible_Contract__c>([Select id, Agreement_Active__c from Customer_Eligible_Contract__c]);
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
    SBQQ__Quote__c q=new SBQQ__Quote__c(SBQQ__Account__c=accList.get(0).id, SBQQ__Opportunity2__c=newOpp.id,SBQQ__PriceBook__c=pricebookId);
     insert q;
     q.SBQQ__Opportunity2__c=null;
      update q;

     List<SBQQ__QuoteLine__c> quoteLines=new List<SBQQ__QuoteLine__c>();
      Map<Id,SBQQ__QuoteLine__c> quoteLineMap=new Map<Id,SBQQ__QuoteLine__c>();

     for(Integer i=0; i<=5; i++){
       quoteLines.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c=q.Id, SBQQ__Product__c=prodList.get(i).Id ,  SBQQ__ListPrice__c = 100, SBQQ__Quantity__c=1));
     }

     quotelineMap.putAll(quoteLines);
        
        if(quotelineMap.size()>0){
            insert quotelineMap.values();
        }


  }
  
  @isTest static void test_method_two() {
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
      prodList.add(new Product2(Name = prodName, IsActive = true, Quotable__c = true));
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
        agree_price_lines.add(new Agreed_Price__c(Active__c=true, Contract__c=con.id, Start_Date__c=system.today().addDays(-5), End_Date__c=system.today().addDays(10), Price__c=2000.00, Product__c=prodList.get(i).id));
      }
      con.Status='Activated';
    }  

    
    update contractList;
    insert agree_price_lines;
    
    


    //Create Relationship/Predence for an Account (Custom Agreement Relationship)
    List<Customer_Eligible_Contract__c> eligible=new List<Customer_Eligible_Contract__c>();
    for(Integer i=0; i<=3; i++){
      eligible.add(new Customer_Eligible_Contract__c(Selected__c=true, Contract__c=contractList.get(i).id, Effective_Date__c=system.today(),Expiration_Date__c=system.today().addYears(1),   Customer_Account__c=accList.get(0).id, Precedence_Value__c=1 ));
    }

    insert eligible;
    List<Customer_Eligible_Contract__c> cecs=new List<Customer_Eligible_Contract__c>([Select id, Agreement_Active__c from Customer_Eligible_Contract__c]);
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
    SBQQ__Quote__c q=new SBQQ__Quote__c(SBQQ__Account__c=accList.get(0).id, SBQQ__Opportunity2__c=newOpp.id,SBQQ__PriceBook__c=pricebookId);
     insert q;
     q.SBQQ__Opportunity2__c=null;
      update q;

     List<SBQQ__QuoteLine__c> quoteLines=new List<SBQQ__QuoteLine__c>();
      Map<Id,SBQQ__QuoteLine__c> quoteLineMap=new Map<Id,SBQQ__QuoteLine__c>();

     for(Integer i=0; i<=5; i++){
       quoteLines.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c=q.Id, SBQQ__Product__c=prodList.get(i).Id ,  SBQQ__ListPrice__c = 100, SBQQ__Quantity__c=1));
     }

     quotelineMap.putAll(quoteLines);
        
        if(quotelineMap.size()>0){
            insert quotelineMap.values();
        }
  }
  
}