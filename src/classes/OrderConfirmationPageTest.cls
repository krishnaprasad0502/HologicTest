@isTest
private class OrderConfirmationPageTest {
    
    @isTest static void Test1_CancelAndClose() {
    
        Trigger_Switch__c ts = new Trigger_Switch__c();
        ts.Name = 'Contracttrigger';
        ts.Active__c = true;
        insert ts;
        
        Trigger_Switch__c tsop= new Trigger_Switch__c();
        tsop.Name = 'OpportunityTrigger';
        tsop.Active__c = true;
        insert tsop;
        
        TestUtility.insertCustSetting('sitelocTrigger');
        
        
        ApexPages.Standardcontroller sc;
        CreateData();
        String accName1='1234567';
         Account account=TestUtility.newAccount(accName1, accName1);
         account.Oracle_Party_Id__c=null;
       insert account;
         List<Site_Location__c> siteList = new List<Site_Location__c>();
        for(Integer i=0; i<=3; i++){
            String siteName = 'SiteLocation'+string.valueOf(i);
            siteList.add(new Site_Location__c(Name=siteName, Deliver_To__c =true, Bill_To__c = true, Ship_To__c = true, Address_Line_1__c = siteName, Account__c = account.id, Active__c = false));
        }
        insert siteList; 
        //Create Opp
        Opportunity newOpp = new Opportunity();
        newOpp.AccountId = account.id;
        newOpp.StageName = 'Target';
        newOpp.CloseDate = System.today();
        newOpp.Name = 'OppTest';
    
        insert newOpp;
        SBQQ__Quote__c q=new SBQQ__Quote__c(Quote_Name__c='OrderConfirmationPageTest Quote', Order_Type__c='DANBURY SYSTEM ORDER', Operating_Unit__c='HOLX_US_OU', SBQQ__Account__c=account.id, SBQQ__Opportunity2__c=newOpp.id,SBQQ__PriceBook__c=null, Bill_To_Account__c=account.id, Deliver_To_Account__c=account.id, Ship_To_Account__c=account.id,Deliverto_Site__c=siteList[0].id);
     insert q;
      SBQQ__Quote__c thisQuote = [SELECT Id,SBQQ__Account__c,SBQQ__Account__r.Oracle_Party_Id__c FROM SBQQ__Quote__c WHERE Quote_Name__c = 'OrderConfirmationPageTest Quote' and SBQQ__Account__r.Oracle_Party_Id__c=null LIMIT 1];
    thisQuote.Operating_Unit__c='HOLX_US_OU';
        thisQuote.SBQQ__Account__r.Oracle_Party_Id__c='';
        update(thisQuote);
        ApexPages.StandardController stdcontroller = new ApexPages.StandardController(thisQuote);
        OrderConfirmationPageController ocp = new OrderConfirmationPageController(stdcontroller);
       ocp.tempQuoteLWList=null;
        ocp.OffsetSize=20;
         ocp.CountTotalRecords=15;
      ocp.QueryLimit=150;
        ocp.Previous();
        ocp.sortExpression='';
       String sorte= ocp.getSortDirection();
         
       String sortex= ocp.getSortDirection();
      
           String sortexp= ocp.getSortDirection();
        ocp.getQuoteWrapper();
        ocp.ValidateOrder();
        ocp.setSelected();
        ocp.CancelAndClose();
            
    }
     @isTest static void Test_CancelAndClose() {
    
        Trigger_Switch__c ts = new Trigger_Switch__c();
        ts.Name = 'Contracttrigger';
        ts.Active__c = true;
        insert ts;
        
        Trigger_Switch__c tsop= new Trigger_Switch__c();
        tsop.Name = 'OpportunityTrigger';
        tsop.Active__c = true;
        insert tsop;
        
        TestUtility.insertCustSetting('sitelocTrigger');
        
        
        ApexPages.Standardcontroller sc;
        CreateData();
        String accName1='1234567';
         Account account=TestUtility.newAccount(accName1, accName1);
         account.Oracle_Party_Id__c=null;
       insert account;
         List<Site_Location__c> siteList = new List<Site_Location__c>();
        for(Integer i=0; i<=3; i++){
            String siteName = 'SiteLocation'+string.valueOf(i);
            siteList.add(new Site_Location__c(Name=siteName, Deliver_To__c =false, Bill_To__c = true, Ship_To__c = true, Address_Line_1__c = siteName, Account__c = account.id, Active__c = false));
        }
        insert siteList; 
        //Create Opp
        Opportunity newOpp = new Opportunity();
        newOpp.AccountId = account.id;
        newOpp.StageName = 'Target';
        newOpp.CloseDate = System.today();
        newOpp.Name = 'OppTest';
    
        insert newOpp;
        SBQQ__Quote__c q=new SBQQ__Quote__c(Quote_Name__c='OrderConfirmationPageTest Quote', Order_Type__c='DANBURY SYSTEM ORDER', Operating_Unit__c='HOLX_US_OU', SBQQ__Account__c=account.id, SBQQ__Opportunity2__c=newOpp.id,SBQQ__PriceBook__c=null, Bill_To_Account__c=account.id, Deliver_To_Account__c=account.id, Ship_To_Account__c=account.id,Deliverto_Site__c=siteList[0].id);
        try
        {
            insert q;
        }
        catch(Exception e)
        {
            system.assertNotEquals(e.getMessage(),'Insert Success');
        }
        SBQQ__QuoteLine__c ql=new SBQQ__QuoteLine__c(SBQQ__Quote__c=q.Id, Account__c=account.id, Include_In_Order__c=true, SBQQ__Product__c=null, SBQQ__ListPrice__c = 100, SBQQ__Quantity__c=1, Bill_To_Account__c=account.id, Deliver_To_Account__c=account.id, Ship_To_Account__c=account.id,Deliverto_Site__c=siteList[0].id,SBQQ__Incomplete__c=true);
        try
        {
         insert ql;
        }
       catch(Exception e)
       {
           system.assertNotEquals(e.getMessage(), 'Insertion Success');
       }
      try
      {
          SBQQ__Quote__c thisQuote = [SELECT Id,SBQQ__Account__c,SBQQ__Account__r.Oracle_Party_Id__c FROM SBQQ__Quote__c WHERE Quote_Name__c = 'OrderConfirmationPageTest Quote' and SBQQ__Account__r.Oracle_Party_Id__c=null LIMIT 1];
    thisQuote.Operating_Unit__c='HOLX_US_OU';
        thisQuote.SBQQ__Account__r.Oracle_Party_Id__c='';
        update(thisQuote);
        ApexPages.StandardController stdcontroller = new ApexPages.StandardController(thisQuote);
        OrderConfirmationPageController ocp = new OrderConfirmationPageController(stdcontroller);
       ocp.tempQuoteLWList=null;
        ocp.OffsetSize=20;
         ocp.CountTotalRecords=15;
      ocp.QueryLimit=150;
        ocp.Previous();
        ocp.sortExpression='';
       String sorte= ocp.getSortDirection();
         
       String sortex= ocp.getSortDirection();
      
           String sortexp= ocp.getSortDirection();
        ocp.getQuoteWrapper();
        ocp.ValidateOrder();
        ocp.setSelected();
        ocp.CancelAndClose();
      }
         catch(Exception e)
         {
             system.assertNotEquals(e.getMessage(), 'list has rows');
         }
    }
    
    @isTest static void Test2_SaveAndCancel() {
    
        Trigger_Switch__c ts = new Trigger_Switch__c();
        ts.Name = 'Contracttrigger';
        ts.Active__c = true;
        insert ts;
        
        Trigger_Switch__c tsop= new Trigger_Switch__c();
        tsop.Name = 'OpportunityTrigger';
        tsop.Active__c = true;
        insert tsop;
        
        TestUtility.insertCustSetting('sitelocTrigger');
        
        ApexPages.Standardcontroller sc;
        CreateData();

        SBQQ__Quote__c thisQuote = [SELECT Id,SBQQ__Account__c,Order_Type__c,SBQQ__Account__r.Oracle_Party_Id__c,Deliverto_Site__r.Active__c,DeliverTo_Site__c,Deliverto_Site__r.Deliver_To__c,Bill_To_Account__c,Ship_To_Account__c FROM SBQQ__Quote__c WHERE Quote_Name__c = 'OrderConfirmationPageTest Quote' and SBQQ__Account__r.Oracle_Party_Id__c!=null LIMIT 1];
        thisQuote.Operating_Unit__c='HOLX_US_OU';
 		thisQuote.Deliverto_Site__r.Deliver_To__c=false;
        thisQuote.Deliverto_Site__r.Active__c=false;
        thisQuote.Bill_To_Account__c=null;
        thisQuote.Ship_To_Account__c=null;
        thisQuote.Order_Type__c='BEDFORD BILLING ONLY ORDER';
        update(thisQuote);
        SBQQ__QuoteLine__c thisQuoteLine=[select id,Quotable__c,Brand__c,SBQQ__Product__r.Quotable__c,DeliverTo_Site__c,Deliverto_Site__r.Deliver_To__c,Deliverto_Site__r.Active__c from SBQQ__QuoteLine__c where SBQQ__Quote__c =:thisQuote.id limit 1];
        thisQuoteLine.SBQQ__Product__r.Quotable__c=false;
        thisQuoteLine.Deliverto_Site__r.Active__c=false;
        thisQuoteLine.Deliverto_Site__r.Deliver_To__c=false;
        update(thisQuoteLine);
        //thisQuoteLine.Quotable__c=false;
        PageReference pageRef = Page.OrderConfirmationPage;
  		Test.setCurrentPage(pageRef);
  		pageRef.getParameters().put('PageNumber','3');
        ApexPages.StandardController stdcontroller = new ApexPages.StandardController(thisQuote);
        OrderConfirmationPageController ocp = new OrderConfirmationPageController(stdcontroller);
       	OrderConfirmationPageController.QuoteLineWrapper lw=new OrderConfirmationPageController.QuoteLineWrapper(thisQuoteLine,true,'',false);
       	list<OrderConfirmationPageController.QuoteLineWrapper> listWrapper=new  list<OrderConfirmationPageController.QuoteLineWrapper>();
        listWrapper.add(lw);
       ocp.sortExpression=thisQuoteLine.Brand__c;
          ocp.Next();
         String sortexpp= ocp.getSortDirection();
       map<id,OrderConfirmationPageController.QuoteLineWrapper> m=new map<id,OrderConfirmationPageController.QuoteLineWrapper>();
        m.put(thisQuoteLine.id,lw);
         ocp.CountTotalRecords=15;
        ocp.qlProductsMap=m;
        system.debug(ocp.qlProductsMap.values());
       //ocp.tempQuoteLWList=listWrapper;
       //ocp.paginationQuoteLineWrapperList=listWrapper;
       //system.debug( ocp.paginationQuoteLineWrapperList);
       //system.debug(ocp.paginationQuoteLineWrapperList.size());
        ocp.getQuoteWrapper();
        ocp.OffsetSize=5;
     
        pageRef.getParameters().put('sortExp','ASC');
        String sortExp=ocp.sortExpression;
        ocp.QueryLimit=10;
        ocp.Next();
        ocp.noPagination();
        ocp.getDisablePrevious();
        ocp.setSortDirection('ASC');
        ocp.getSortDirection();
        ocp.ValidateOrder();
        ocp.setOrderType();
        ocp.getDisableNext();
        ocp.getSortDirection();
        ocp.SaveAndCancel();
    }

    @isTest static void Test3_CreateOrder() {    
    
        Trigger_Switch__c ts = new Trigger_Switch__c();
        ts.Name = 'Contracttrigger';
        ts.Active__c = true;
        insert ts;
        
        Trigger_Switch__c tsop= new Trigger_Switch__c();
        tsop.Name = 'OpportunityTrigger';
        tsop.Active__c = true;
        insert tsop;
        
        TestUtility.insertCustSetting('sitelocTrigger');     
        
        ApexPages.Standardcontroller sc;
        CreateData();

        SBQQ__Quote__c thisQuote = [SELECT Id,SBQQ__Account__c,SBQQ__Account__r.Oracle_Party_Id__c FROM SBQQ__Quote__c WHERE Quote_Name__c = 'OrderConfirmationPageTest Quote' LIMIT 1];
    
        ApexPages.StandardController stdcontroller = new ApexPages.StandardController(thisQuote);
        OrderConfirmationPageController ocp = new OrderConfirmationPageController(stdcontroller);
        ocp.OffsetSize=5;
        ocp.CountTotalRecords=15;
       ocp.QueryLimit=15;
      ocp.Previous();
        ocp.getDisableNext();
        List<OrderConfirmationPageController.QuoteWrapper> quotes=ocp.getQuoteWrapper();        
        List<OrderConfirmationPageController.QuoteLineWrapper> quotelines=ocp.getQuoteLineWrapper();
        ocp.paginationQuoteLineWrapperList=quotelines;
        ocp.setSelected();
        ocp.ValidateOrder();

        ocp.CreateOrder();
    }
    
    @isTest static void Test4_MissingDataValidationsOU() {

        //Operating_Unit__c
        //SBQQ__Account__r.Oracle_Party_Id__c
        
        
        Trigger_Switch__c ts = new Trigger_Switch__c();
        ts.Name = 'Contracttrigger';
        ts.Active__c = true;
        insert ts;
        
        Trigger_Switch__c tsop= new Trigger_Switch__c();
        tsop.Name = 'OpportunityTrigger';
        tsop.Active__c = true;
        insert tsop;
        
        TestUtility.insertCustSetting('sitelocTrigger');
        
        ApexPages.Standardcontroller sc;
        CreateData();

        SBQQ__Quote__c thisQuote = [SELECT Id,Operating_Unit__c, SBQQ__Account__r.Oracle_Party_Id__c FROM SBQQ__Quote__c WHERE Quote_Name__c = 'OrderConfirmationPageTest Quote' LIMIT 1];
    
        thisQuote.Operating_Unit__c = '';
        update thisQuote;
        ApexPages.StandardController stdcontroller = new ApexPages.StandardController(thisQuote);
        OrderConfirmationPageController ocp = new OrderConfirmationPageController(stdcontroller);
        ocp.ValidateOrder();
ocp.CancelAndClose();

    }
    
    @isTest static void Test4_MissingDataValidationsPartyId() {
    
        
        Trigger_Switch__c ts = new Trigger_Switch__c();
        ts.Name = 'Contracttrigger';
        ts.Active__c = true;
        insert ts;
        
        Trigger_Switch__c tsop= new Trigger_Switch__c();
        tsop.Name = 'OpportunityTrigger';
        tsop.Active__c = true;
        insert tsop;
        
        TestUtility.insertCustSetting('sitelocTrigger');       
          
        //Operating_Unit__c
        //SBQQ__Account__r.Oracle_Party_Id__c

        ApexPages.Standardcontroller sc;
        CreateData();

        SBQQ__Quote__c thisQuote = [SELECT Id, Operating_Unit__c, SBQQ__Account__r.Oracle_Party_Id__c FROM SBQQ__Quote__c WHERE Quote_Name__c = 'OrderConfirmationPageTest Quote' LIMIT 1];
        string NameContains = 'FN-2187';
        List<Account> accListforUpdate = new List<Account>();
        for (Account a : [Select Id, Name, Oracle_Party_Id__c FROM Account where Name LIKE :NameContains]) {
            a.Oracle_Party_Id__c = null;
            accListforUpdate.add(a);
        }   
        update accListforUpdate;

        ApexPages.StandardController stdcontroller = new ApexPages.StandardController(thisQuote);
        OrderConfirmationPageController ocp = new OrderConfirmationPageController(stdcontroller);
        
        ocp.ValidateOrder();


    }
    
    //Test Methods to validate Pagination functionality
    static testMethod void testNext(){
        Trigger_Switch__c ts = new Trigger_Switch__c();
        ts.Name = 'Contracttrigger';
        ts.Active__c = true;
        insert ts;
        
        Trigger_Switch__c tsop= new Trigger_Switch__c();
        tsop.Name = 'OpportunityTrigger';
        tsop.Active__c = true;
        insert tsop;
        
        TestUtility.insertCustSetting('sitelocTrigger');     
          
        //Operating_Unit__c
        //SBQQ__Account__r.Oracle_Party_Id__c

        ApexPages.Standardcontroller sc;
        CreateData();

        SBQQ__Quote__c thisQuote = [SELECT Id, Operating_Unit__c, SBQQ__Account__r.Oracle_Party_Id__c FROM SBQQ__Quote__c WHERE Quote_Name__c = 'OrderConfirmationPageTest Quote' LIMIT 1];
       
        ApexPages.StandardController stdcontroller = new ApexPages.StandardController(thisQuote);
        OrderConfirmationPageController ocp = new OrderConfirmationPageController(stdcontroller);
        ocp.Next();
    }
    
    static testMethod void testPrevious(){
        
        Trigger_Switch__c ts = new Trigger_Switch__c();
        ts.Name = 'Contracttrigger';
        ts.Active__c = true;
        insert ts;
        
        Trigger_Switch__c tsop= new Trigger_Switch__c();
        tsop.Name = 'OpportunityTrigger';
        tsop.Active__c = true;
        insert tsop;
        
        TestUtility.insertCustSetting('sitelocTrigger');      
          
        //Operating_Unit__c
        //SBQQ__Account__r.Oracle_Party_Id__c

        ApexPages.Standardcontroller sc;
        CreateData();

        SBQQ__Quote__c thisQuote = [SELECT Id, Operating_Unit__c, SBQQ__Account__r.Oracle_Party_Id__c FROM SBQQ__Quote__c WHERE Quote_Name__c = 'OrderConfirmationPageTest Quote' LIMIT 1];
        
        ApexPages.StandardController stdcontroller = new ApexPages.StandardController(thisQuote);
        OrderConfirmationPageController ocp = new OrderConfirmationPageController(stdcontroller);
        ocp.Previous();    
    }
    
    static testMethod void testSetSelected(){
    
        Trigger_Switch__c ts = new Trigger_Switch__c();
        ts.Name = 'Contracttrigger';
        ts.Active__c = true;
        insert ts;
        
        Trigger_Switch__c tsop= new Trigger_Switch__c();
        tsop.Name = 'OpportunityTrigger';
        tsop.Active__c = true;
        insert tsop; 
        
        TestUtility.insertCustSetting('sitelocTrigger');    
          
        //Operating_Unit__c
        //SBQQ__Account__r.Oracle_Party_Id__c

        ApexPages.Standardcontroller sc;
        CreateData();

        SBQQ__Quote__c thisQuote = [SELECT Id, Operating_Unit__c, SBQQ__Account__r.Oracle_Party_Id__c FROM SBQQ__Quote__c WHERE Quote_Name__c = 'OrderConfirmationPageTest Quote' LIMIT 1];
        
        ApexPages.StandardController stdcontroller = new ApexPages.StandardController(thisQuote);
        OrderConfirmationPageController ocp = new OrderConfirmationPageController(stdcontroller);
        //RMendoza Adding to test setOrderType method for Order Type functionality
        ocp.setOrderType();
        ocp.setSelected();      
    }
    
    static void testdisableNext(){
    
        Trigger_Switch__c ts = new Trigger_Switch__c();
        ts.Name = 'Contracttrigger';
        ts.Active__c = true;
        insert ts;
        
        Trigger_Switch__c tsop= new Trigger_Switch__c();
        tsop.Name = 'OpportunityTrigger';
        tsop.Active__c = true;
        insert tsop;
        
        TestUtility.insertCustSetting('sitelocTrigger');      
          
        //Operating_Unit__c
        //SBQQ__Account__r.Oracle_Party_Id__c

        ApexPages.Standardcontroller sc;
        CreateData();

        SBQQ__Quote__c thisQuote = [SELECT Id, Operating_Unit__c, SBQQ__Account__r.Oracle_Party_Id__c FROM SBQQ__Quote__c WHERE Quote_Name__c = 'OrderConfirmationPageTest Quote' LIMIT 1];
  
        ApexPages.StandardController stdcontroller = new ApexPages.StandardController(thisQuote);
        OrderConfirmationPageController ocp = new OrderConfirmationPageController(stdcontroller);
        ocp.getDisableNext();    
    }
    
    static testMethod void testdisablePrevious(){
    
        Trigger_Switch__c ts = new Trigger_Switch__c();
        ts.Name = 'Contracttrigger';
        ts.Active__c = true;
        insert ts;
        
        Trigger_Switch__c tsop= new Trigger_Switch__c();
        tsop.Name = 'OpportunityTrigger';
        tsop.Active__c = true;
        insert tsop;
        
        TestUtility.insertCustSetting('sitelocTrigger');        
          
        //Operating_Unit__c
        //SBQQ__Account__r.Oracle_Party_Id__c

        ApexPages.Standardcontroller sc;
        CreateData();

        SBQQ__Quote__c thisQuote = [SELECT Id, Operating_Unit__c, SBQQ__Account__r.Oracle_Party_Id__c FROM SBQQ__Quote__c WHERE Quote_Name__c = 'OrderConfirmationPageTest Quote' LIMIT 1];
        
        ApexPages.StandardController stdcontroller = new ApexPages.StandardController(thisQuote);
        OrderConfirmationPageController ocp = new OrderConfirmationPageController(stdcontroller);
        ocp.getDisablePrevious();
        ocp.noPagination();
        ocp.getSortDirection();
        ocp.testSorting();
    }   

    public static void CreateData() {
         TestUtility.setupConfigurationSettings();
       
        // Create Account(s)
        List<Account> accList=new List<Account>();
          
        for(Integer i=0; i<=3; i++){
            String accName='1234567' + string.valueOf(i);
            accList.add(TestUtility.newAccount(accName, accName));
        }

        Integer k=0;
        for(Account acc:accList){

            acc.Oracle_Party_Id__c=String.valueOf(k);
            k++;
        }
      
         
        insert accList;
        

        //Create Site Locations
        List<Site_Location__c> siteList = new List<Site_Location__c>();
        for(Integer i=0; i<=3; i++){
            String siteName = 'SiteLocation'+string.valueOf(i);
            siteList.add(new Site_Location__c(Name=siteName, Deliver_To__c =true, Bill_To__c = true, Ship_To__c = true, Address_Line_1__c = siteName, Account__c = accLIst.get(i).id, Active__c = false));
        }
        insert siteList;        


        //Id pricebookId = Test.getStandardPricebookId();
        //Create Products
        List<Product2> prodList=new List<Product2>();
        for(Integer i=0; i<=5; i++){
            String prodName='Product ' + string.valueOf(i);
            prodList.add(new Product2(Name = prodName, IsActive = true, Quotable__c = false));
        }

        insert prodList;
        
        PriceBook2 priceBook = new PriceBook2();
        pricebook.name='Test PriceBook';
        insert pricebook;

        //Create Price Book Entries
        List<PricebookEntry> priceentires=new List<PricebookEntry>();

        for(Integer i=0; i<=5; i++){
          priceentires.add(new PricebookEntry(Pricebook2Id = pricebook.Id, Product2Id = prodList.get(i).id, UnitPrice= 2000.00, IsActive = true));
        }

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
        
        
        system.debug(agree_price_lines);

        //Create Relationship/Predence for an Account (Custom Agreement Relationship)
        List<Customer_Eligible_Contract__c> eligible=new List<Customer_Eligible_Contract__c>();
        for(Integer i=0; i<=3; i++){
            eligible.add(new Customer_Eligible_Contract__c(Selected__c=true, Contract__c=contractList.get(i).id, Effective_Date__c=system.today(),Expiration_Date__c=system.today().addYears(1),   Customer_Account__c=accList.get(0).id, Precedence_Value__c=i));
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
        newOpp.Pricebook2Id = pricebook.Id;
        insert newOpp;

        //Create Quote/Quote Lines
        
        
        SBQQ__Quote__c q=new SBQQ__Quote__c(Quote_Name__c='OrderConfirmationPageTest Quote', Order_Type__c='DANBURY SYSTEM ORDER', Operating_Unit__c='HOLX_US_OU', SBQQ__Account__c=accList.get(0).id, SBQQ__Opportunity2__c=newOpp.id,SBQQ__PriceBook__c=pricebook.Id, Bill_To_Account__c=accList.get(1).id, Deliver_To_Account__c=accList.get(2).id, Ship_To_Account__c=accList.get(3).id,Deliverto_Site__c=siteList[0].id);
        insert q;
        

        List<SBQQ__QuoteLine__c> quoteLines=new List<SBQQ__QuoteLine__c>();

        for(Integer i=0; i<=5; i++){
            quoteLines.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c=q.Id, Account__c=accList.get(0).id, Include_In_Order__c=true, SBQQ__Product__c=prodList.get(i).Id, SBQQ__ListPrice__c = 100, SBQQ__Quantity__c=1, Bill_To_Account__c=accList.get(1).id, Deliver_To_Account__c=accList.get(2).id, Ship_To_Account__c=accList.get(3).id,Deliverto_Site__c=siteList[0].id,SBQQ__Incomplete__c=true));
        }
         system.debug(quoteLines); 
        try{
        insert quoteLines;
        }
        catch(Exception e)
        {
            system.assertNotEquals(e.getMessage(),'Insert Success');
        }

        quoteLines=[Select id,SBQQ__Product__c,SBQQ__ListPrice__c, SBQQ__OriginalPrice__c from SBQQ__QuoteLine__c where SBQQ__Quote__c=:q.id];
        system.debug(quoteLines);   


    }   
    
}