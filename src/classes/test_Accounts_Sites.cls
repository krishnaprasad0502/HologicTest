/*------------------------------------------------------------
Author:     Kasmoor Reddy
Company:    Apps Associates
Description:  Test class to validate Accountsandsites apex class
History:
<Date>        <Authors Name>   <Brief Description of Change>
01/02/2018      Kasmoor Reddy       Initial Creation (US3714)
------------------------------------------------------------*/
@isTest
private class test_Accounts_Sites {
	//variable declarations
   private static User testUser;
    private static Id accountCustomerRecordTypeId = GlobalUtility.getRecordTypeId('Account', 'Customer');
    private static Configuration_Settings__c orgDefaults;
    private static List<Account> customerAccounts = new List<Account>();
    public static List<Site_Location__c> siteLocations = new List<Site_Location__c>();
    public static List<Customer_Relationship__x> customerRelationships = new List<Customer_Relationship__x>();
    private static Account siteAccount;
     static {
     	//insert user
               List<Profile> userProfile = [SELECT Id FROM profile WHERE Name='System Administrator' LIMIT 1];
        testUser = TestUtility.newUser(userProfile[0].Id,'GetTaxIn');
        testUser.Operating_Unit__c = 'HOLX_US_OU';    
        insert testUser;

     }
    @isTest static void test_method_quote() {
 
        System.runAs(testUser) {
        //ApexPages.Standardcontroller sc;
        TestUtility.setupConfigurationSettings();
        CreateData();
        
        TestUtility.insertCustSetting('ContractTrigger');
        Test.startTest();
            
        //insert quote
        SBQQ__Quote__c thisQuote = [SELECT Id,SBQQ__Account__c,ShipTo_Site__c FROM SBQQ__Quote__c LIMIT 1];
        
        Customer_Relationship__x mockedRecord = new Customer_Relationship__x(
        PartyId__c = '12456',
        Related_Oracle_Party_ID__c = '789564',
        Bill_To__c=true,
        Ship_To__c=true,
        Status__c = 'Active'
    );
        
         
        PageReference pageRef = Page.AccountsAndSites;
        pageRef.getParameters().put('id', thisQuote.id);
        Test.setCurrentPage(pageRef);
        //AccountsAndSites.mockCustomerRelationships.add(mockedRecord);
        //Customer_Relationship__x request = AccountsAndSites.findById(mockedRecord.Id);
        AccountsAndSites aas = new AccountsAndSites(new ApexPages.StandardController(thisQuote));
        aas.billtositeId=thisQuote.id;
        aas.reloadNeeded=true;
          
        //AccountsAndSites aas = new AccountsAndSites();
        aas.getPageURL();
        aas.SaveMe();
       
        //aas.BillToSiteChanged();
        aas.ShipDateChanged();
      
        aas.BillToAcctLineChanged();
        aas.BillToAcctChanged();
        //aas.quotelinerelatedshiptosite = thisQuote.id + '-' + thisQuote.ShipTo_Site__c;
        aas.ShipToAcctLineChanged();
        aas.ShipToAcctChanged();
        aas.DeliverToAcctLineChanged();
        //aas.ShipToSiteChanged();
        aas.RequestedDateChanged();
        aas.DeliverToAcctChanged();
        //aas.DeliverToSiteChanged();
        system.assert(aas.showCancel);
        aas.Cancel();
        Test.stopTest();
        }
    }
    
     @isTest static void test_method_quoteline() {
        //ApexPages.Standardcontroller sc;
       System.runAs(testUser) {
            TestUtility.setupConfigurationSettings();
        CreateData();
        Test.startTest();
        //insert quote
        SBQQ__Quote__c thisQuote = [SELECT Id,SBQQ__Account__c,ShipTo_Site__c,BillTo_Site__c,DeliverTo_Site__c FROM SBQQ__Quote__c LIMIT 1];
        //insert quoteline
        SBQQ__QuoteLine__c thisQuoteLine = [SELECT Id,SBQQ__Quote__c,BillTo_Site__c,ShipTo_Site__c,DeliverTo_Site__c FROM SBQQ__QuoteLine__c where SBQQ__Quote__c =: thisQuote.id LIMIT 1];
        
         Customer_Relationship__x mockedRecord = new Customer_Relationship__x(
          PartyId__c = '12456',
        Related_Oracle_Party_ID__c = '789564',
        Bill_To__c=true,
        Ship_To__c=true,
        Status__c = 'Active'
    );
        PageReference pageRef = Page.AccountsAndSites;
        pageRef.getParameters().put('id', thisQuoteLine.id);
        Test.setCurrentPage(pageRef);
        //AccountsAndSites.mockCustomerRelationships.add(mockedRecord);
        //Customer_Relationship__x request = AccountsAndSites.findById(mockedRecord.Id);
        ApexPages.StandardController sc = new ApexPages.standardController(thisQuoteLine);
        AccountsAndSites  aas = new AccountsAndSites(sc);
        aas.getPageURL();
         aas.callfunc='call';
      //  aas.productNameDescription='test product';
        aas.SaveMe();
    
         aas.billtositeId=thisQuote.SBQQ__Account__c;
        //aas.BillToSiteChanged();
        aas.ShipDateChanged();
      aas.shiplineid=thisQuoteLine.id ;
           aas.billlineid=thisQuoteLine.id ;
           aas.deliverlineid=thisQuoteLine.id ;
         aas.quotelinerelatedbilltosite = thisQuoteLine.id + '-' + thisQuoteLine.BillTo_Site__c;
        aas.BillToAcctLineChanged();
           aas.BillToAcctChanged();
        aas.quotelinerelatedshiptosite = thisQuoteLine.id + '-' + thisQuoteLine.ShipTo_Site__c;
        aas.ShipToAcctLineChanged();
           aas.ShipToAcctChanged();
         aas.quotelinerelateddelivertosite = thisQuoteLine.id + '-' + thisQuoteLine.DeliverTo_Site__c;
       aas.DeliverToAcctLineChanged();
       aas.LineNumber=0;
        
        //aas.ShipToSiteChanged();
        aas.RequestedDateChanged();
        aas.DeliverToAcctChanged();
           aas.quotelinerelatedbilltosite = thisQuoteLine.id + '-' + thisQuoteLine.BillTo_Site__c;
          aas.quotelinerelatedshiptosite = thisQuoteLine.id + '-' + thisQuoteLine.ShipTo_Site__c;
 aas.quotelinerelateddelivertosite = thisQuoteLine.id + '-' + thisQuoteLine.DeliverTo_Site__c;
         aas.SaveMe();
        system.assertEquals(aas.showCancel,false);
        aas.Cancel();
        Test.stopTest();
    }
     }   
    

    public static void CreateData() {
     //insert configuration settings
     //TestUtility.setupConfigurationSettings();
                // Create test User
       //insert trigger switch
        Trigger_Switch__c ts = new Trigger_Switch__c();
        ts.Name = 'OpportunityTrigger';
        ts.Active__c = true;
        
        insert ts;
         System.assertEquals('OpportunityTrigger', ts.Name);
        
        Trigger_Switch__c ts1 = new Trigger_Switch__c();
        ts1.Name = 'ContractTrigger';
        ts1.Active__c = true;
        insert ts1;
         System.assertEquals('ContractTrigger', ts1.Name);
        TestUtility.insertCustSetting('sitelocTrigger'); 
  
         // Create Account(s)
        List<Account> accList=new List<Account>();
        for(Integer i=0; i<=3; i++){
            String accName='1234567' + string.valueOf(i);
            accList.add(TestUtility.newAccount(accName, accName));
        }

        //insert accList;
        
        Integer k=0;
        for(Account acc:accList){

            acc.Oracle_Party_Id__c=String.valueOf(k);
            k++;
        }
        System.assertNotEquals(accList,null,'success');
        insert accList;
       //insert siteaccount
       siteAccount = TestUtility.newAccount('Site Account', 'testSite', 'ABC Street', accLIst[0].id, GlobalUtility.getRecordTypeId('Account', 'Site'));
        siteAccount.BillingCountryCode = 'US';
        siteAccount.BillingStateCode = 'NY';            
        insert siteAccount;
         System.assertEquals('Site Account', siteAccount.Name);
        //Create Site Locations
        List<Site_Location__c> siteList = new List<Site_Location__c>();
        for(Integer i=0; i<=3; i++){
            String siteName = 'SiteLocation'+string.valueOf(i);
            siteList.add(new Site_Location__c(Name=siteName, Deliver_To__c = true, Bill_To__c = true, Ship_To__c = true, Address_Line_1__c = siteName, Account__c = siteAccount.id, Active__c = true));
        }
        System.assertNotEquals(siteList,null,'success');
        
        insert siteList;
        
       
        //Create Products
        List<Product2> prodList=new List<Product2>();
        for(Integer i=0; i<=5; i++){
            String prodName='Product ' + string.valueOf(i);
            prodList.add(new Product2(Name = prodName, IsActive = true, Quotable__c = true,Description='test product'));
        }
        prodList[0].CPQ_Bundle__c=true;
        System.assertNotEquals(prodList,null,'success');
        insert prodList;
        

        //Create Price Book Entries
        PriceBook2 pricebook = new Pricebook2(name='Test Pricebook');
        List<PricebookEntry> priceentires=new List<PricebookEntry>();

        for(Integer i=0; i<=5; i++){
          priceentires.add(new PricebookEntry(Pricebook2Id = pricebook.Id, Product2Id = prodList.get(i).id, UnitPrice= 2000.00, IsActive = true));
        }

        //insert priceentires;
        
        //Create Contract(s) for each Account
        List<Contract> contractList=new List<Contract>();
        for(Integer i=0; i<=3; i++){
            String conName='Test Contract ' + string.valueOf(i);
            contractList.add(new Contract(StartDate=system.today().addDays(-5), Accountid=accList.get(i).id, Contract_End_Date__c=system.today().addYears(10),Contract_Source__c = 'test' ));
        }
        System.assertNotEquals(contractList,null,'success');
        insert contractList;


        //Create Pricing Agreement Lines for each Contract
        List<Agreed_Price__c> agree_price_lines=new List<Agreed_Price__c>();
        
        for(Contract con:contractList){
            for(Integer i=0; i<=5; i++){
                agree_price_lines.add(new Agreed_Price__c(Active__c=true, Contract__c=con.id, Start_Date__c=system.today().addDays(-5), End_Date__c=system.today().addDays(10), Price__c=2000.00, Product__c=prodList.get(i).id));
                //insert agree_price_lines;
            }
            con.Status='Activated';
        }
        //insert agree_price_lines;
        IF(contractList.SIZE()>0)
           // update contractList;
        insert agree_price_lines;
      

        System.assertNotEquals(contractList,null,'success');
        //update contractList;
        System.assertNotEquals(agree_price_lines,null,'success');
        //insert agree_price_lines;
        
        
        system.debug(agree_price_lines);

        //Create Relationship/Predence for an Account (Custom Agreement Relationship)
        List<Customer_Eligible_Contract__c> eligible=new List<Customer_Eligible_Contract__c>();
        for(Integer i=0; i<=3; i++){
            eligible.add(new Customer_Eligible_Contract__c(Selected__c=true, Contract__c=contractList.get(i).id, Effective_Date__c=system.today(),Expiration_Date__c=system.today().addYears(1),  Customer_Account__c=accList.get(0).id, Precedence_Value__c=i));
        }
        System.assertNotEquals(eligible,null,'success');
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
        System.assertEquals('OppTest',newOpp.Name);
        //Create Quote/Quote Lines
        system.debug('newOpp---'+newOpp);
        system.debug('newOpp---'+newOpp.CurrencyIsoCode);
        SBQQ__Quote__c q=new SBQQ__Quote__c(Quote_Name__c='OrderConfirmationPageTest Quote', Order_Type__c='DANBURY SYSTEM ORDER', Operating_Unit__c='HOLX_US_OU', SBQQ__Account__c=accList.get(0).id, SBQQ__Opportunity2__c=newOpp.id,SBQQ__PriceBook__c=pricebook.Id, Bill_To_Account__c=accList.get(1).id, Deliver_To_Account__c=accList.get(2).id, Ship_To_Account__c=accList.get(3).id,BillTo_Site__c= siteList[0].id,ShipTo_Site__c= siteList[0].id,DeliverTo_Site__c= siteList[0].id,Requested_Date__c = system.today());
        system.debug('q1---'+q.CurrencyIsoCode);
        insert q;
        system.debug('q2---'+q.CurrencyIsoCode);
        
        q.SBQQ__Primary__c = false;
        update q;

         System.assertEquals('OrderConfirmationPageTest Quote',q.Quote_Name__c);
        List<SBQQ__QuoteLine__c> quoteLines=new List<SBQQ__QuoteLine__c>();
        set<SBQQ__QuoteLine__c> quoteLineset=new set<SBQQ__QuoteLine__c>();
		//SBQQ__QuoteLine__c q1=new SBQQ__QuoteLine__c();
        
        for(Integer i=0; i<=5; i++){
            quoteLineset.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c=q.Id, Account__c=accList.get(0).id, Include_In_Order__c=true, SBQQ__Product__c=prodList.get(i).Id, SBQQ__ListPrice__c = 100, SBQQ__Quantity__c=1, Bill_To_Account__c=accList.get(1).id, Deliver_To_Account__c=accList.get(2).id, Ship_To_Account__c=accList.get(3).id,SBQQ__Number__c=i+1,BillTo_Site__c= siteList[0].id,ShipTo_Site__c= siteList[0].id,DeliverTo_Site__c= siteList[0].id,Requested_Date__c = system.today(),Ship_Date__c=system.today()+3));
        }
         
        quoteLines.addall(quoteLineset);
        
        //quoteLines.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c=q.Id, Account__c=accList.get(0).id, Include_In_Order__c=true, SBQQ__Product__c=prodList.get(0).Id, SBQQ__ListPrice__c = 100, SBQQ__Quantity__c=1, Bill_To_Account__c=null, Deliver_To_Account__c=null, Ship_To_Account__c=null,SBQQ__Number__c=6,BillTo_Site__c=null,ShipTo_Site__c=null,DeliverTo_Site__c=null,Requested_Date__c = system.today()));
        
        //quotelineMap.putAll(quoteLines);
        
        System.assertNotEquals(quoteLines,null,'success');
        insert quoteLines;
        
        
        
        quoteLines=[Select id,SBQQ__Product__c,SBQQ__ListPrice__c, SBQQ__OriginalPrice__c,SBQQ__RequiredBy__c from SBQQ__QuoteLine__c where SBQQ__Quote__c=:q.id];
        quoteLines[1].SBQQ__RequiredBy__c = quoteLines[0].Id;
        quoteLines[2].SBQQ__RequiredBy__c = quoteLines[1].Id;
        quoteLines[1].BillTo_Site__c= siteList[1].id;
        quoteLines[1].ShipTo_Site__c= siteList[1].id;
        quoteLines[1].DeliverTo_Site__c= siteList[1].id;
        quoteLines[1].Bill_To_Account__c=accList[0].id; 
        quoteLines[1].Deliver_To_Account__c=accList[0].id; 
        quoteLines[1].Ship_To_Account__c=accList[0].id;
        
        update quoteLines;
        
        q.SBQQ__Primary__c = true;
        //update q;
       system.debug(quoteLines);   


    }
    
    @isTest static void test_method_quote1() {
 
        System.runAs(testUser) {
        //ApexPages.Standardcontroller sc;
        TestUtility.setupConfigurationSettings();
        CreateData1();
        Test.startTest();
        //insert quote
        SBQQ__Quote__c thisQuote = [SELECT Id,SBQQ__Account__c,ShipTo_Site__c FROM SBQQ__Quote__c LIMIT 1];
        
        Customer_Relationship__x mockedRecord = new Customer_Relationship__x(
        PartyId__c = '12456',
        Related_Oracle_Party_ID__c = '789564',
        Bill_To__c=true,
        Ship_To__c=true,
        Status__c = 'Active'
    );
        
         
        PageReference pageRef = Page.AccountsAndSites;
        pageRef.getParameters().put('id', thisQuote.id);
        Test.setCurrentPage(pageRef);
        //AccountsAndSites.mockCustomerRelationships.add(mockedRecord);
        //Customer_Relationship__x request = AccountsAndSites.findById(mockedRecord.Id);
        AccountsAndSites aas = new AccountsAndSites(new ApexPages.StandardController(thisQuote));
        
        //AccountsAndSites aas = new AccountsAndSites();
        aas.linenum=0;
        aas.getPageURL();
        aas.SaveMe();
         // aas.RequestedLineDateChanged();   
        aas.BillToAcctChanged();
        //aas.BillToSiteChanged();
        aas.ShipDateChanged();
        aas.ShipToAcctChanged();
        aas.BillToAcctLineChanged();
        //aas.quotelinerelatedshiptosite = thisQuote.id + '-' + thisQuote.ShipTo_Site__c;
        aas.ShipToAcctLineChanged();
        aas.DeliverToAcctLineChanged();
        //aas.ShipToSiteChanged();
        aas.RequestedDateChanged();
        aas.DeliverToAcctChanged();
        //aas.DeliverToSiteChanged();
        system.assert(aas.showCancel);
        aas.Cancel();
        Test.stopTest();
        }
    }
    
     @isTest static void test_method_quoteline1() {
        //ApexPages.Standardcontroller sc;
       System.runAs(testUser) {
            TestUtility.setupConfigurationSettings();
        CreateData1();
        Test.startTest();
        //insert quote
        SBQQ__Quote__c thisQuote = [SELECT Id,SBQQ__Account__c,ShipTo_Site__c FROM SBQQ__Quote__c LIMIT 1];
        //insert quoteline
        SBQQ__QuoteLine__c thisQuoteLine = [SELECT Id,SBQQ__Quote__c,BillTo_Site__c,ShipTo_Site__c,DeliverTo_Site__c FROM SBQQ__QuoteLine__c where SBQQ__Quote__c =: thisQuote.id LIMIT 1];
        
         Customer_Relationship__x mockedRecord = new Customer_Relationship__x(
          PartyId__c = '12456',
        Related_Oracle_Party_ID__c = '789564',
        Bill_To__c=true,
        Ship_To__c=true,
        Status__c = 'Active'
    );
        PageReference pageRef = Page.AccountsAndSites;
        pageRef.getParameters().put('id', thisQuoteLine.id);
        Test.setCurrentPage(pageRef);
        //AccountsAndSites.mockCustomerRelationships.add(mockedRecord);
        //Customer_Relationship__x request = AccountsAndSites.findById(mockedRecord.Id);
        ApexPages.StandardController sc = new ApexPages.standardController(thisQuote);
        AccountsAndSites  aas = new AccountsAndSites(sc);
        aas.getPageURL();
        //ass.productNameDescription='test product';
        aas.SaveMe();
        aas.BillToAcctChanged();
        //aas.BillToSiteChanged();
        aas.ShipDateChanged();
        aas.ShipToAcctChanged();
        aas.BillToAcctLineChanged();
        //aas.quotelinerelatedshiptosite = thisQuote.id + '-' + thisQuote.ShipTo_Site__c;
        aas.ShipToAcctLineChanged();
        aas.DeliverToAcctLineChanged();
        //aas.ShipToSiteChanged();
        aas.RequestedDateChanged();
        aas.DeliverToAcctChanged();
        system.assertEquals(aas.showCancel,false);
        aas.Cancel();
        Test.stopTest();
    }
 }   
    

    public static void CreateData1() {
    //insert configuration settings
     //TestUtility.setupConfigurationSettings();
                // Create test User
        //insert trigger switch
        Trigger_Switch__c ts = new Trigger_Switch__c();
        ts.Name = 'OpportunityTrigger';
        ts.Active__c = true;
        insert ts;
        
        Trigger_Switch__c ts1 = new Trigger_Switch__c();
        ts1.Name = 'ContractTrigger';
        ts1.Active__c = true;
        insert ts1;
        
        TestUtility.insertCustSetting('sitelocTrigger'); 
  
         // Create Account(s)
        List<Account> accList=new List<Account>();
        for(Integer i=0; i<=3; i++){
            String accName='1234567' + string.valueOf(i);
            accList.add(TestUtility.newAccount(accName, accName));
        }

        //insert accList;
        
        Integer k=0;
        for(Account acc:accList){

            acc.Oracle_Party_Id__c=String.valueOf(k);
            k++;
        }
        System.assertNotEquals(accList,null,'success');
        insert accList;
        //insert siteaccount
       siteAccount = TestUtility.newAccount('Site Account', 'testSite', 'ABC Street', accLIst[0].id, GlobalUtility.getRecordTypeId('Account', 'Site'));
        siteAccount.BillingCountryCode = 'US';
        siteAccount.BillingStateCode = 'NY';            
        insert siteAccount;

        //Create Site Locations
        List<Site_Location__c> siteList = new List<Site_Location__c>();
        for(Integer i=0; i<=3; i++){
            String siteName = 'SiteLocation'+string.valueOf(i);
            siteList.add(new Site_Location__c(Name=siteName, Deliver_To__c = true, Bill_To__c = true, Ship_To__c = true, Address_Line_1__c = siteName, Account__c = siteAccount.id, Active__c = true));
        }
        System.assertNotEquals(siteList,null,'success');
        insert siteList;
        
       
        //Create Products
        List<Product2> prodList=new List<Product2>();
        for(Integer i=0; i<=5; i++){
            String prodName='Product ' + string.valueOf(i);
            prodList.add(new Product2(Name = prodName, IsActive = true, Quotable__c = true,Description='test product'));
        }
        prodList[0].CPQ_Bundle__c=true;
        System.assertNotEquals(prodList,null,'success');
        insert prodList;
        

        //Create Price Book Entries
        PriceBook2 pricebook = new Pricebook2(name='Test Pricebook');
        List<PricebookEntry> priceentires=new List<PricebookEntry>();

        for(Integer i=0; i<=5; i++){
          priceentires.add(new PricebookEntry(Pricebook2Id = pricebook.Id, Product2Id = prodList.get(i).id, UnitPrice= 2000.00, IsActive = true));
        }

        //insert priceentires;
        
        //Create Contract(s) for each Account
        List<Contract> contractList=new List<Contract>();
        for(Integer i=0; i<=3; i++){
            String conName='Test Contract ' + string.valueOf(i);
            contractList.add(new Contract(StartDate=system.today().addDays(-5), Accountid=accList.get(i).id, Contract_End_Date__c=system.today().addYears(10),Contract_Source__c = 'test' ));
        }
        System.assertNotEquals(contractList,null,'success');
        insert contractList;


        //Create Pricing Agreement Lines for each Contract
        List<Agreed_Price__c> agree_price_lines=new List<Agreed_Price__c>();
        
        for(Contract con:contractList){
            for(Integer i=0; i<=5; i++){
                agree_price_lines.add(new Agreed_Price__c(Active__c=true, Contract__c=con.id, Start_Date__c=system.today().addDays(-5), End_Date__c=system.today().addDays(10), Price__c=2000.00, Product__c=prodList.get(i).id));
                //insert agree_price_lines;
            }
            con.Status='Activated';
        }   
        IF(contractList.SIZE()>0)
           // update contractList;
        insert agree_price_lines;
        System.assertNotEquals(contractList,null,'success');
        //update contractList;
        System.assertNotEquals(agree_price_lines,null,'success');
        //insert agree_price_lines;
        
        
        system.debug(agree_price_lines);

        //Create Relationship/Predence for an Account (Custom Agreement Relationship)
        List<Customer_Eligible_Contract__c> eligible=new List<Customer_Eligible_Contract__c>();
        for(Integer i=0; i<=3; i++){
            eligible.add(new Customer_Eligible_Contract__c(Selected__c=true, Contract__c=contractList.get(i).id, Effective_Date__c=system.today(),Expiration_Date__c=system.today().addYears(1),  Customer_Account__c=accList.get(0).id, Precedence_Value__c=i));
        }
        System.assertNotEquals(eligible,null,'success');
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
        System.assertEquals('OppTest',newOpp.Name);

        //Create Quote/Quote Lines
        SBQQ__Quote__c q=new SBQQ__Quote__c(Quote_Name__c='OrderConfirmationPageTest Quote', Operating_Unit__c=null, SBQQ__Account__c=accList.get(0).id, SBQQ__Opportunity2__c=newOpp.id,SBQQ__PriceBook__c=pricebook.Id,Requested_Date__c = system.today());
        insert q;
        System.assertEquals('OrderConfirmationPageTest Quote',q.Quote_Name__c);
        
        q.Bill_To_Account__c=accList[0].id; 
        q.Deliver_To_Account__c=accList[1].id;
        q.Ship_To_Account__c=accList[2].id;
        q.SBQQ__Primary__c = false;
        
        update q;
        
        //q.SBQQ__Primary__c = false;
        //update q;

         System.assertEquals('OrderConfirmationPageTest Quote',q.Quote_Name__c);
        List<SBQQ__QuoteLine__c> quoteLines=new List<SBQQ__QuoteLine__c>();
        set<SBQQ__QuoteLine__c> quoteLineset=new set<SBQQ__QuoteLine__c>();
		//SBQQ__QuoteLine__c q1=new SBQQ__QuoteLine__c();
        
        for(Integer i=0; i<=5; i++){
            quoteLineset.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c=q.Id, Account__c=accList.get(0).id, Include_In_Order__c=true, SBQQ__Product__c=prodList.get(i).Id, SBQQ__ListPrice__c = 100, SBQQ__Quantity__c=1, Bill_To_Account__c=NULL, Deliver_To_Account__c=NULL, Ship_To_Account__c=NULL,SBQQ__Number__c=i+1,BillTo_Site__c= NULL,ShipTo_Site__c= NULL,DeliverTo_Site__c=NULL,Requested_Date__c = system.today()));
        }
         
        quoteLines.addall(quoteLineset);
        
        //quoteLines.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c=q.Id, Account__c=accList.get(0).id, Include_In_Order__c=true, SBQQ__Product__c=prodList.get(0).Id, SBQQ__ListPrice__c = 100, SBQQ__Quantity__c=1, Bill_To_Account__c=null, Deliver_To_Account__c=null, Ship_To_Account__c=null,SBQQ__Number__c=6,BillTo_Site__c=null,ShipTo_Site__c=null,DeliverTo_Site__c=null,Requested_Date__c = system.today()));
        
        //quotelineMap.putAll(quoteLines);
        
        System.assertNotEquals(quoteLines,null,'success');
        insert quoteLines;
        
        /*List<SBQQ__QuoteLine__c> quoteLines=new List<SBQQ__QuoteLine__c>();

        for(Integer i=0; i<=5; i++){
            quoteLines.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c=q.Id, Account__c=accList.get(0).id, Include_In_Order__c=true, SBQQ__Product__c=prodList.get(i).Id, SBQQ__ListPrice__c = 100, SBQQ__Quantity__c=1, Bill_To_Account__c=accList.get(1).id, Deliver_To_Account__c=accList.get(2).id, Ship_To_Account__c=accList.get(3).id,SBQQ__Number__c=i+1,Requested_Date__c = system.today(),Ship_Date__c=system.today()));
        }
        // quoteLines.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c=q.Id, Account__c=accList.get(0).id, Include_In_Order__c=true, SBQQ__Product__c=prodList.get(0).Id, SBQQ__ListPrice__c = 100, SBQQ__Quantity__c=1, Bill_To_Account__c=null, Deliver_To_Account__c=null, Ship_To_Account__c=null,SBQQ__Number__c=6,BillTo_Site__c=null,ShipTo_Site__c=null,DeliverTo_Site__c=null,Requested_Date__c = system.today(),Ship_Date__c=system.today()+1));
     
        System.assertNotEquals(quoteLines,null,'success');
        insert quoteLines;*/
        quoteLines=[Select id,SBQQ__Product__c,SBQQ__ListPrice__c, SBQQ__OriginalPrice__c,SBQQ__RequiredBy__c from SBQQ__QuoteLine__c where SBQQ__Quote__c=:q.id];
        quoteLines[1].SBQQ__RequiredBy__c = quoteLines[0].Id;
        quoteLines[2].SBQQ__RequiredBy__c = quoteLines[1].Id;
       quoteLines[1].Bill_To_Account__c=NULL; 
        quoteLines[1].Deliver_To_Account__c=NULL; 
        quoteLines[1].Ship_To_Account__c=NULL;
        
        
        update quoteLines;
        
        q.SBQQ__Primary__c = true;
        //update q;
       system.debug(quoteLines);   


    }
        
    @isTest static void test_method_quote2() {
 
        System.runAs(testUser) {
        //ApexPages.Standardcontroller sc;
        
        CreateData2();
        Test.startTest();
        //insert quote
        SBQQ__Quote__c thisQuote = [SELECT Id,SBQQ__Account__c,ShipTo_Site__c FROM SBQQ__Quote__c LIMIT 1];
        
        Customer_Relationship__x mockedRecord = new Customer_Relationship__x(
        PartyId__c = '12456',
        Related_Oracle_Party_ID__c = '789564',
        Bill_To__c=true,
        Ship_To__c=true,
        Status__c = 'Active'
    );
        
         
        PageReference pageRef = Page.AccountsAndSites;
        pageRef.getParameters().put('id', thisQuote.id);
        Test.setCurrentPage(pageRef);
        //AccountsAndSites.mockCustomerRelationships.add(mockedRecord);
        //Customer_Relationship__x request = AccountsAndSites.findById(mockedRecord.Id);
        AccountsAndSites aas = new AccountsAndSites(new ApexPages.StandardController(thisQuote));
        
        //AccountsAndSites aas = new AccountsAndSites();
        aas.linenum=0;
        aas.getPageURL();
        aas.SaveMe();
          aas.RequestedLineDateChanged();   
        aas.BillToAcctChanged();
        //aas.BillToSiteChanged();
        aas.ShipDateChanged();
        aas.ShipToAcctChanged();
        aas.BillToAcctLineChanged();
        //aas.quotelinerelatedshiptosite = thisQuote.id + '-' + thisQuote.ShipTo_Site__c;
        aas.ShipToAcctLineChanged();
        aas.DeliverToAcctLineChanged();
        //aas.ShipToSiteChanged();
        aas.RequestedDateChanged();
        aas.DeliverToAcctChanged();
        //aas.DeliverToSiteChanged();
        system.assert(aas.showCancel);
        aas.Cancel();
        Test.stopTest();
        }
    }
    
    
    

    public static void CreateData2() {
    //insert configuration settings
     TestUtility.setupConfigurationSettings();
                // Create test User
        //insert trigger switch
        Trigger_Switch__c ts = new Trigger_Switch__c();
        ts.Name = 'OpportunityTrigger';
        ts.Active__c = true;
        insert ts;
        
        Trigger_Switch__c ts1 = new Trigger_Switch__c();
        ts1.Name = 'ContractTrigger';
        ts1.Active__c = true;
        insert ts1;
        
        TestUtility.insertCustSetting('sitelocTrigger'); 
  
         // Create Account(s)
        List<Account> accList=new List<Account>();
        for(Integer i=0; i<=3; i++){
            String accName='1234567' + string.valueOf(i);
            accList.add(TestUtility.newAccount(accName, accName));
        }
   Integer k=0;
        for(Account acc:accList){

            acc.Oracle_Party_Id__c=null;
            k++;
        }

        //insert accList;
      
        System.assertNotEquals(accList,null,'success');
        insert accList;
        //insert siteaccount
       siteAccount = TestUtility.newAccount('Site Account', 'testSite', 'ABC Street', accLIst[0].id, GlobalUtility.getRecordTypeId('Account', 'Site'));
        siteAccount.BillingCountryCode = 'US';
        siteAccount.BillingStateCode = 'NY';            
        insert siteAccount;

        //Create Site Locations
        List<Site_Location__c> siteList = new List<Site_Location__c>();
        for(Integer i=0; i<=3; i++){
            String siteName = 'SiteLocation'+string.valueOf(i);
            siteList.add(new Site_Location__c(Name=siteName, Deliver_To__c = true, Bill_To__c = true, Ship_To__c = true, Address_Line_1__c = siteName, Account__c = siteAccount.id, Active__c = true));
        }
        System.assertNotEquals(siteList,null,'success');
        insert siteList;
        
       
        //Create Products
        List<Product2> prodList=new List<Product2>();
        for(Integer i=0; i<=5; i++){
            String prodName='Product ' + string.valueOf(i);
            prodList.add(new Product2(Name = prodName, IsActive = true, Quotable__c = true,Description='test product'));
        }
        prodList[0].CPQ_Bundle__c=true;
        System.assertNotEquals(prodList,null,'success');
        insert prodList;
        

        //Create Price Book Entries
        PriceBook2 pricebook = new Pricebook2(name='Test Pricebook');
        List<PricebookEntry> priceentires=new List<PricebookEntry>();

        for(Integer i=0; i<=5; i++){
          priceentires.add(new PricebookEntry(Pricebook2Id = pricebook.Id, Product2Id = prodList.get(i).id, UnitPrice= 2000.00, IsActive = true));
        }

        //insert priceentires;
        
        //Create Contract(s) for each Account
        List<Contract> contractList=new List<Contract>();
        for(Integer i=0; i<=3; i++){
            String conName='Test Contract ' + string.valueOf(i);
            contractList.add(new Contract(StartDate=system.today().addDays(-5), Accountid=accList.get(i).id, Contract_End_Date__c=system.today().addYears(10),Contract_Source__c = 'test' ));
        }
        System.assertNotEquals(contractList,null,'success');
        insert contractList;


        //Create Pricing Agreement Lines for each Contract
        List<Agreed_Price__c> agree_price_lines=new List<Agreed_Price__c>();
        
        for(Contract con:contractList){
            for(Integer i=0; i<=5; i++){
                agree_price_lines.add(new Agreed_Price__c(Active__c=true, Contract__c=con.id, Start_Date__c=system.today().addDays(-5), End_Date__c=system.today().addDays(10), Price__c=2000.00, Product__c=prodList.get(i).id));
                //insert agree_price_lines;
            }
            con.Status='Activated';
        }   
        if(contractList.size()>0)
          //  update contractList;
        insert agree_price_lines;
        System.assertNotEquals(contractList,null,'success');
        //update contractList;
        System.assertNotEquals(agree_price_lines,null,'success');
        //insert agree_price_lines;
        
        
        system.debug(agree_price_lines);

        //Create Relationship/Predence for an Account (Custom Agreement Relationship)
        List<Customer_Eligible_Contract__c> eligible=new List<Customer_Eligible_Contract__c>();
        for(Integer i=0; i<=3; i++){
            eligible.add(new Customer_Eligible_Contract__c(Selected__c=true, Contract__c=contractList.get(i).id, Effective_Date__c=system.today(),Expiration_Date__c=system.today().addYears(1),  Customer_Account__c=accList.get(0).id, Precedence_Value__c=i));
        }
        System.assertNotEquals(eligible,null,'success');
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
        System.assertEquals('OppTest',newOpp.Name);

        //Create Quote/Quote Lines
        SBQQ__Quote__c q=new SBQQ__Quote__c(Quote_Name__c='OrderConfirmationPageTest Quote', Order_Type__c='DANBURY SYSTEM ORDER', Operating_Unit__c='HOLX_US_OU', SBQQ__Account__c=accList.get(0).id, SBQQ__Opportunity2__c=newOpp.id,SBQQ__PriceBook__c=pricebook.Id,Requested_Date__c = system.today());
        insert q;
        System.assertEquals('OrderConfirmationPageTest Quote',q.Quote_Name__c);
        
        q.Bill_To_Account__c=accList[0].id; 
        q.Deliver_To_Account__c=accList[1].id;
        q.Ship_To_Account__c=accList[2].id;
        q.SBQQ__Primary__c = false;
        
        update q;
        
        //q.SBQQ__Primary__c = false;
        //update q;

         System.assertEquals('OrderConfirmationPageTest Quote',q.Quote_Name__c);
        List<SBQQ__QuoteLine__c> quoteLines=new List<SBQQ__QuoteLine__c>();
        set<SBQQ__QuoteLine__c> quoteLineset=new set<SBQQ__QuoteLine__c>();
		//SBQQ__QuoteLine__c q1=new SBQQ__QuoteLine__c();
        
        for(Integer i=0; i<=5; i++){
            quoteLineset.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c=q.Id, Account__c=accList.get(0).id, Include_In_Order__c=true, SBQQ__Product__c=prodList.get(i).Id, SBQQ__ListPrice__c = 100, SBQQ__Quantity__c=1, Bill_To_Account__c=accList.get(1).id, Deliver_To_Account__c=accList.get(2).id, Ship_To_Account__c=accList.get(3).id,SBQQ__Number__c=i+1,BillTo_Site__c= siteList[0].id,ShipTo_Site__c= siteList[0].id,DeliverTo_Site__c= siteList[0].id,Requested_Date__c = system.today()));
        }
         
        quoteLines.addall(quoteLineset);
        
        //quoteLines.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c=q.Id, Account__c=accList.get(0).id, Include_In_Order__c=true, SBQQ__Product__c=prodList.get(0).Id, SBQQ__ListPrice__c = 100, SBQQ__Quantity__c=1, Bill_To_Account__c=null, Deliver_To_Account__c=null, Ship_To_Account__c=null,SBQQ__Number__c=6,BillTo_Site__c=null,ShipTo_Site__c=null,DeliverTo_Site__c=null,Requested_Date__c = system.today()));
        
        //quotelineMap.putAll(quoteLines);
        
        System.assertNotEquals(quoteLines,null,'success');
        insert quoteLines;
        quoteLines=[Select id,SBQQ__Product__c,SBQQ__ListPrice__c, SBQQ__OriginalPrice__c,SBQQ__RequiredBy__c from SBQQ__QuoteLine__c where SBQQ__Quote__c=:q.id];
        quoteLines[1].SBQQ__RequiredBy__c = quoteLines[0].Id;
        quoteLines[2].SBQQ__RequiredBy__c = quoteLines[1].Id;
       quoteLines[1].Bill_To_Account__c=accList[0].id; 
        quoteLines[1].Deliver_To_Account__c=accList[0].id; 
        quoteLines[1].Ship_To_Account__c=accList[0].id;
        
        
        update quoteLines;
        q.SBQQ__Primary__c = true;
        //update q;
       system.debug(quoteLines);   


    }
     @isTest static void test_method_quote3() {
 
        System.runAs(testUser) {
        //ApexPages.Standardcontroller sc;
        
        CreateData3();
        Test.startTest();
        //insert quote
        SBQQ__Quote__c thisQuote = [SELECT Id,SBQQ__Account__c,ShipTo_Site__c FROM SBQQ__Quote__c  LIMIT 1];
        
        Customer_Relationship__x mockedRecord = new Customer_Relationship__x(
        PartyId__c = '12456',
        Related_Oracle_Party_ID__c = '789564',
        Bill_To__c=true,
        Ship_To__c=true,
        Status__c = 'Active'
    );
        
         
        PageReference pageRef = Page.AccountsAndSites;
        pageRef.getParameters().put('id', thisQuote.id);
        Test.setCurrentPage(pageRef);
        //AccountsAndSites.mockCustomerRelationships.add(mockedRecord);
        //Customer_Relationship__x request = AccountsAndSites.findById(mockedRecord.Id);
        AccountsAndSites aas = new AccountsAndSites(new ApexPages.StandardController(thisQuote));
        
        //AccountsAndSites aas = new AccountsAndSites();
        aas.linenum=0;
        aas.getPageURL();
        aas.SaveMe();
          aas.RequestedLineDateChanged();   
        aas.BillToAcctChanged();
        //aas.BillToSiteChanged();
        aas.ShipDateChanged();
        aas.ShipToAcctChanged();
        aas.BillToAcctLineChanged();
        //aas.quotelinerelatedshiptosite = thisQuote.id + '-' + thisQuote.ShipTo_Site__c;
        aas.ShipToAcctLineChanged();
        aas.DeliverToAcctLineChanged();
        //aas.ShipToSiteChanged();
        aas.RequestedDateChanged();
        aas.DeliverToAcctChanged();
        //aas.DeliverToSiteChanged();
        system.assert(aas.showCancel);
        aas.Cancel();
        Test.stopTest();
        }
    }
    
    
    

    public static void CreateData3() {
    //insert configuration settings
     TestUtility.setupConfigurationSettings();
                // Create test User
        //insert trigger switch
        Trigger_Switch__c ts = new Trigger_Switch__c();
        ts.Name = 'OpportunityTrigger';
        ts.Active__c = true;
        insert ts;
        
        Trigger_Switch__c ts1 = new Trigger_Switch__c();
        ts1.Name = 'ContractTrigger';
        ts1.Active__c = true;
        insert ts1;
        
        TestUtility.insertCustSetting('sitelocTrigger'); 
  
         // Create Account(s)
        List<Account> accList=new List<Account>();
        for(Integer i=0; i<=3; i++){
            String accName='1234567' + string.valueOf(i);
            accList.add(TestUtility.newAccount(accName, accName));
        }
   Integer k=0;
        for(Account acc:accList){

            acc.Oracle_Party_Id__c=null;
            k++;
        }

        //insert accList;
      
        System.assertNotEquals(accList,null,'success');
        insert accList;
        //insert siteaccount
       siteAccount = TestUtility.newAccount('Site Account', 'testSite', 'ABC Street', accLIst[0].id, GlobalUtility.getRecordTypeId('Account', 'Site'));
        siteAccount.BillingCountryCode = 'US';
        siteAccount.BillingStateCode = 'NY';            
        insert siteAccount;

        //Create Site Locations
        List<Site_Location__c> siteList = new List<Site_Location__c>();
        for(Integer i=0; i<=3; i++){
            String siteName = 'SiteLocation'+string.valueOf(i);
            siteList.add(new Site_Location__c(Name=siteName, Deliver_To__c = true, Bill_To__c = true, Ship_To__c = true, Address_Line_1__c = siteName, Account__c = siteAccount.id, Active__c = true));
        }
        System.assertNotEquals(siteList,null,'success');
        insert siteList;
        
       
        //Create Products
        List<Product2> prodList=new List<Product2>();
        for(Integer i=0; i<=5; i++){
            String prodName='Product ' + string.valueOf(i);
            prodList.add(new Product2(Name = prodName, IsActive = true, Quotable__c = true,Description='test product'));
        }
        prodList[0].CPQ_Bundle__c=true;
        System.assertNotEquals(prodList,null,'success');
        insert prodList;
        

        //Create Price Book Entries
        PriceBook2 pricebook = new Pricebook2(name='Test Pricebook');
        List<PricebookEntry> priceentires=new List<PricebookEntry>();

        for(Integer i=0; i<=5; i++){
          priceentires.add(new PricebookEntry(Pricebook2Id = pricebook.Id, Product2Id = prodList.get(i).id, UnitPrice= 2000.00, IsActive = true));
        }

        //insert priceentires;
        
        //Create Contract(s) for each Account
        List<Contract> contractList=new List<Contract>();
        for(Integer i=0; i<=3; i++){
            String conName='Test Contract ' + string.valueOf(i);
            contractList.add(new Contract(StartDate=system.today().addDays(-5), Accountid=accList.get(i).id, Contract_End_Date__c=system.today().addYears(10),Contract_Source__c = 'test' ));
        }
        System.assertNotEquals(contractList,null,'success');
        insert contractList;


        //Create Pricing Agreement Lines for each Contract
        List<Agreed_Price__c> agree_price_lines=new List<Agreed_Price__c>();
        
        for(Contract con:contractList){
            for(Integer i=0; i<=5; i++){
                agree_price_lines.add(new Agreed_Price__c(Active__c=true, Contract__c=con.id, Start_Date__c=system.today().addDays(-5), End_Date__c=system.today().addDays(10), Price__c=2000.00, Product__c=prodList.get(i).id));
                //insert agree_price_lines;
            }
            con.Status='Activated';
        }   
        if(contractList.size()>0)
          //  update contractList;
        insert agree_price_lines;
        System.assertNotEquals(contractList,null,'success');
        //update contractList;
        System.assertNotEquals(agree_price_lines,null,'success');
        //insert agree_price_lines;
        
        
        system.debug(agree_price_lines);

        //Create Relationship/Predence for an Account (Custom Agreement Relationship)
        List<Customer_Eligible_Contract__c> eligible=new List<Customer_Eligible_Contract__c>();
        for(Integer i=0; i<=3; i++){
            eligible.add(new Customer_Eligible_Contract__c(Selected__c=true, Contract__c=contractList.get(i).id, Effective_Date__c=system.today(),Expiration_Date__c=system.today().addYears(1),  Customer_Account__c=accList.get(0).id, Precedence_Value__c=i));
        }
        System.assertNotEquals(eligible,null,'success');
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
        System.assertEquals('OppTest',newOpp.Name);

        //Create Quote/Quote Lines
        SBQQ__Quote__c q=new SBQQ__Quote__c(Quote_Name__c='OrderConfirmationPageTest Quote', Order_Type__c='DANBURY SYSTEM ORDER', Operating_Unit__c='HOLX_US_OU', SBQQ__Account__c=accList.get(0).id, SBQQ__Opportunity2__c=newOpp.id,SBQQ__PriceBook__c=pricebook.Id,Requested_Date__c = system.today());
        insert q;
        System.assertEquals('OrderConfirmationPageTest Quote',q.Quote_Name__c);
        
       
        q.SBQQ__Primary__c = false;
        
        update q;
        
        
        //q.SBQQ__Primary__c = false;
        //update q;

         System.assertEquals('OrderConfirmationPageTest Quote',q.Quote_Name__c);
        List<SBQQ__QuoteLine__c> quoteLines=new List<SBQQ__QuoteLine__c>();
        set<SBQQ__QuoteLine__c> quoteLineset=new set<SBQQ__QuoteLine__c>();
		//SBQQ__QuoteLine__c q1=new SBQQ__QuoteLine__c();
        
        for(Integer i=0; i<=5; i++){
            quoteLineset.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c=q.Id, Account__c=accList.get(0).id, Include_In_Order__c=true, SBQQ__Product__c=prodList.get(i).Id, SBQQ__ListPrice__c = 100, SBQQ__Quantity__c=1,SBQQ__Number__c=i+1,Requested_Date__c = system.today()));
        }
         
        quoteLines.addall(quoteLineset);
        
        //quoteLines.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c=q.Id, Account__c=accList.get(0).id, Include_In_Order__c=true, SBQQ__Product__c=prodList.get(0).Id, SBQQ__ListPrice__c = 100, SBQQ__Quantity__c=1, Bill_To_Account__c=null, Deliver_To_Account__c=null, Ship_To_Account__c=null,SBQQ__Number__c=6,BillTo_Site__c=null,ShipTo_Site__c=null,DeliverTo_Site__c=null,Requested_Date__c = system.today()));
        
        //quotelineMap.putAll(quoteLines);
        
        System.assertNotEquals(quoteLines,null,'success');
        insert quoteLines;
        quoteLines=[Select id,SBQQ__Product__c,SBQQ__ListPrice__c, SBQQ__OriginalPrice__c,SBQQ__RequiredBy__c from SBQQ__QuoteLine__c where SBQQ__Quote__c=:q.id];
        quoteLines[1].SBQQ__RequiredBy__c = quoteLines[0].Id;
        quoteLines[2].SBQQ__RequiredBy__c = quoteLines[1].Id;
     
        
        
        update quoteLines;
        q.SBQQ__Primary__c = true;
        //update q;
       system.debug(quoteLines);   


    }
    
  }