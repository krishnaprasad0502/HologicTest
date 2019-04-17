@isTest
private class AccountsAndSitesClassMobile_test {
    private static User testUser;
    private static List<Account> accList=new List<Account>();
    private static Account siteAccount;
    static {
        
        List<Profile> userProfile = [SELECT Id FROM profile WHERE Name='System Administrator' LIMIT 1];
        testUser = TestUtility.newUser(userProfile[0].Id,'GetTaxIn');
        testUser.Operating_Unit__c = 'HOLX_US_OU';    
        insert testUser;
        
        
    }
    @isTest static void test_method_quote() {
        
        System.runAs(testUser) {
            TestUtility.insertCustSetting('ContractTrigger');
            TestUtility.setupConfigurationSettings();
            //ApexPages.Standardcontroller sc;
            CreateData();
            
            Test.startTest();
            SBQQ__Quote__c thisQuote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
            SBQQ__QuoteLine__c thisQuoteLine = [SELECT Id,ship_date__c FROM SBQQ__QuoteLine__c LIMIT 1];
            PageReference pageRef = Page.AccountsAndSitesPageMobile;
            pageRef.getParameters().put('id', thisQuote.id);
            Test.setCurrentPage(pageRef);
            AccountsAndSitesClassMobile aas1 = new AccountsAndSitesClassMobile(new ApexPages.StandardController(thisQuote));
            AccountsAndSitesClassMobile aas = new AccountsAndSitesClassMobile();
            aas.getPageURL();
            aas.reloadNeeded=false;
            aas.show=true;
            aas.SaveMe();
            
            thisQuote.SBQQ__Primary__c = false;
            update thisQuote;
            thisQuoteLine.Requested_Date__c=system.today();
            thisQuoteLIne.Ship_Date__c=system.today()+10;
            update thisQuoteLine;
            aas.SaveMe();
            thisQuote.SBQQ__Primary__c = true;
            update thisQuote;
            
            
            aas.redirectToVf();
            // String productNameDescription=aas.productNameDescription;
            aas.BillToAcctChanged();
            aas.BillToSiteChanged();
            aas.ShipDateChanged();
            aas.ShipToAcctChanged();
            aas.ShipToSiteChanged();
            aas.RequestedDateChanged();
            aas.DeliverToAcctChanged();
            aas.DeliverToSiteChanged();
            aas.linenum=1;
            aas.RequestedLineDateChanged();
            aas.index='1';
            aas.BillToAcctChanged();
            aas.ShipToAcctChanged(); 
            aas.DeliverToAcctChanged();
            system.assert(aas.showCancel);
            aas.parentAccMapBill.add(accList[0].id);
            aas.parentAccMapShip.add(accList[0].id);
            aas.parentAccMapDeliver.add(accList[0].id);
            List<Id> accIds=new List<Id>();
            accIds.add(accLIst[0].id);
            aas.RefreshBillToSiteOptions(accIds);
            aas.RefreshShipToSiteOptions(accIds);
            aas.RefreshDeliverToSiteOptions(accIds);
            aas.RefreshBillToSiteOptions1(accLIst[0].id);
            aas.RefreshShipToSiteOptions1(accLIst[0].id);
            aas.RefreshDeliverToSiteOptions1(accLIst[0].id);
            aas.Cancel();
            Test.stopTest();
        }
    }
    @isTest static void test_method_quote1() {
        
        System.runAs(testUser) {
            //ApexPages.Standardcontroller sc;
            CreateData1();
            Test.startTest();
            SBQQ__Quote__c thisQuote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
            SBQQ__QuoteLine__c thisQuoteLine = [SELECT Id,ship_date__c FROM SBQQ__QuoteLine__c LIMIT 1];
            PageReference pageRef = Page.AccountsAndSitesPageMobile;
            pageRef.getParameters().put('id', thisQuote.id);
            Test.setCurrentPage(pageRef);
            AccountsAndSitesClassMobile aas1 = new AccountsAndSitesClassMobile(new ApexPages.StandardController(thisQuote));
            AccountsAndSitesClassMobile aas = new AccountsAndSitesClassMobile();
            aas.getPageURL();
            aas.reloadNeeded=false;
            aas.show=true;
            aas.SaveMe();
            
            aas.redirectToVf();
            // String productNameDescription=aas.productNameDescription;
            aas.BillToAcctChanged();
            aas.BillToSiteChanged();
            aas.ShipDateChanged();
            aas.ShipToAcctChanged();
            aas.ShipToSiteChanged();
            aas.RequestedDateChanged();
            aas.DeliverToAcctChanged();
            aas.DeliverToSiteChanged();
            aas.linenum=1;
            aas.RequestedLineDateChanged();
            aas.index='1';
            aas.BillToAcctChanged();
            aas.ShipToAcctChanged(); 
            aas.DeliverToAcctChanged();
            system.assert(aas.showCancel);
            aas.parentAccMapBill.add(accList[0].id);
            aas.parentAccMapShip.add(accList[0].id);
            aas.parentAccMapDeliver.add(accList[0].id);
            List<Id> accIds=new List<Id>();
            accIds.add(accLIst[0].id);
            aas.RefreshBillToSiteOptions(accIds);
            aas.RefreshShipToSiteOptions(accIds);
            aas.RefreshDeliverToSiteOptions(accIds);
            aas.RefreshBillToSiteOptions1(accLIst[0].id);
            aas.RefreshShipToSiteOptions1(accLIst[0].id);
            aas.RefreshDeliverToSiteOptions1(accLIst[0].id);
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
        SBQQ__QuoteLine__c thisQuoteLine = [SELECT Id FROM SBQQ__QuoteLine__c LIMIT 1];
        
        PageReference pageRef = Page.AccountsAndSitesPageMobile;
        pageRef.getParameters().put('id', thisQuoteLine.id);
        Test.setCurrentPage(pageRef);
        
        AccountsAndSitesClassMobile aas = new AccountsAndSitesClassMobile();
        aas.getPageURL();
        aas.SaveMe();
        system.assertEquals(aas.showCancel,false);
        aas.Cancel();
        Test.stopTest();
        }     
    }
    public static void CreateData1() {
        TestUtility.setupConfigurationSettings();
        // Create test User
        
        Trigger_Switch__c ts = new Trigger_Switch__c();
        ts.Name = 'OpportunityTrigger';
        ts.Active__c = true;
        insert ts;
        
        Trigger_Switch__c ts1 = new Trigger_Switch__c();
        ts1.Name = 'ContractTrigger';
        ts1.Active__c = true;
        insert ts1;
        
        // Create Account(s)
        
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
        accList[1].Oracle_Party_Id__c='';
        accList[1].ParentId=accList[0].id;
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
        siteList.add(new Site_Location__c(Name='siteName', Deliver_To__c = true, Bill_To__c = true, Ship_To__c = true, Address_Line_1__c = 'SiteLocation', Account__c = accList[0].id, Active__c = true));
        siteList.add(new Site_Location__c(Name='siteName1', Deliver_To__c = true, Bill_To__c = true, Ship_To__c = true, Address_Line_1__c = 'SiteLocation', Account__c = accList[1].id, Active__c = true));
        
        
        insert siteList;        
        
        
        //Id pricebookId = Test.getStandardPricebookId();
        //Create Products
        List<Product2> prodList=new List<Product2>();
        for(Integer i=0; i<=5; i++){
            String prodName='Product ' + string.valueOf(i);
            prodList.add(new Product2(Name = prodName, IsActive = true, Quotable__c = true));
        }
        prodList[0].CPQ_Bundle__c=true;
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
        
        if(contractList.size()>0)
          //  update contractList;
        insert agree_price_lines;
        
        
        system.debug(agree_price_lines);
        
        //Create Relationship/Predence for an Account (Custom Agreement Relationship)
        List<Customer_Eligible_Contract__c> eligible=new List<Customer_Eligible_Contract__c>();
        for(Integer i=0; i<=3; i++){
            eligible.add(new Customer_Eligible_Contract__c(Selected__c=true, Contract__c=contractList.get(i).id, Effective_Date__c=system.today(),Expiration_Date__c=system.today().addYears(1),  Customer_Account__c=accList.get(0).id, Precedence_Value__c=i));
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
        SBQQ__Quote__c q=new SBQQ__Quote__c(Quote_Name__c='OrderConfirmationPageTest Quote', Order_Type__c='DANBURY SYSTEM ORDER', Operating_Unit__c='HOLX_US_OU', SBQQ__Account__c=accList.get(0).id, SBQQ__Opportunity2__c=newOpp.id,SBQQ__PriceBook__c=pricebook.Id, Bill_To_Account__c=accList.get(1).id, Deliver_To_Account__c=accList.get(2).id, Ship_To_Account__c=accList.get(3).id,BillTo_Site__c= siteList[0].id,ShipTo_Site__c= siteList[0].id,DeliverTo_Site__c= siteList[0].id,Requested_Date__c = system.today());
        system.debug('q1---'+q.CurrencyIsoCode);
        insert q;
        
        q.SBQQ__Primary__c = false;
        
        update q;
        
        SBQQ__Quote__c q1=new SBQQ__Quote__c(Quote_Name__c='OrderConfirmationPageTest Quote', SBQQ__Account__c=accList.get(0).id, SBQQ__Opportunity2__c=newOpp.id,SBQQ__PriceBook__c=pricebook.Id, Bill_To_Account__c=accList.get(1).id, Deliver_To_Account__c=accList.get(2).id, Ship_To_Account__c=accList.get(3).id,BillTo_Site__c= siteList[0].id,ShipTo_Site__c= siteList[0].id,DeliverTo_Site__c= siteList[0].id,Requested_Date__c = system.today());
        system.debug('q1---'+q.CurrencyIsoCode);
        insert q1;
        
        
        //q.SBQQ__Primary__c = false;
        //update q;
        
        System.assertEquals('OrderConfirmationPageTest Quote',q.Quote_Name__c);
        List<SBQQ__QuoteLine__c> quoteLines=new List<SBQQ__QuoteLine__c>();
        set<SBQQ__QuoteLine__c> quoteLineset=new set<SBQQ__QuoteLine__c>();
        //SBQQ__QuoteLine__c q1=new SBQQ__QuoteLine__c();
        
        for(Integer i=0; i<=5; i++){
            quoteLineset.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c=q.Id, Account__c=accList.get(0).id, Include_In_Order__c=true, SBQQ__Product__c=prodList.get(i).Id, SBQQ__ListPrice__c = 100, SBQQ__Quantity__c=1,SBQQ__Number__c=i+1,Requested_Date__c = system.today()));
        }
        quoteLineset.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c=q.Id, Account__c=accList.get(1).id, Include_In_Order__c=true, SBQQ__Product__c=prodList.get(1).Id, SBQQ__ListPrice__c = 100, SBQQ__Quantity__c=1,SBQQ__Number__c=10,Requested_Date__c = system.today(),Ship_Date__c=system.today()+3));
        //quoteLineset.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c=q.Id, Account__c=accList.get(1).id, Include_In_Order__c=true, SBQQ__Product__c=prodList.get(1).Id, SBQQ__ListPrice__c = 100, SBQQ__Quantity__c=1,SBQQ__Number__c=10,Requested_Date__c = system.today(),Ship_Date__c=system.today()+3));
        
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
        update q;
        system.debug(quoteLines);    
        
        
    }
    public static void CreateData() {
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com', 
                          EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                          LocaleSidKey='en_US', ProfileId = p.Id, 
                          TimeZoneSidKey='America/Los_Angeles', UserName='testAccountsAndSitestandarduser@testAccountsAndSitesorg.com');
        insert u;
        
        // Create test User
        
        Trigger_Switch__c ts = new Trigger_Switch__c();
        ts.Name = 'OpportunityTrigger';
        ts.Active__c = true;
        insert ts;
        
        Trigger_Switch__c ts1 = new Trigger_Switch__c();
        ts1.Name = 'ContractTrigger';
        ts1.Active__c = true;
        insert ts1;
            
        // Create Account(s)
        
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
        accList[1].Oracle_Party_Id__c='';
        accList[1].ParentId=accList[0].id;
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
        siteList.add(new Site_Location__c(Name='siteName', Deliver_To__c = true, Bill_To__c = true, Ship_To__c = true, Address_Line_1__c = 'SiteLocation', Account__c = accList[0].id, Active__c = true));
        siteList.add(new Site_Location__c(Name='siteName1', Deliver_To__c = true, Bill_To__c = true, Ship_To__c = true, Address_Line_1__c = 'SiteLocation', Account__c = accList[1].id, Active__c = true));
        
        
        insert siteList;        
        
        
        //Id pricebookId = Test.getStandardPricebookId();
        //Create Products
        List<Product2> prodList=new List<Product2>();
        for(Integer i=0; i<=5; i++){
            String prodName='Product ' + string.valueOf(i);
            prodList.add(new Product2(Name = prodName, IsActive = true, Quotable__c = true));
        }
        prodList[0].CPQ_Bundle__c=true;
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
        
        IF(contractList.SIZE()>0)
           // update contractList;
        insert agree_price_lines;
        
        
        system.debug(agree_price_lines);
        
        //Create Relationship/Predence for an Account (Custom Agreement Relationship)
        List<Customer_Eligible_Contract__c> eligible=new List<Customer_Eligible_Contract__c>();
        for(Integer i=0; i<=3; i++){
            eligible.add(new Customer_Eligible_Contract__c(Selected__c=true, Contract__c=contractList.get(i).id, Effective_Date__c=system.today(),Expiration_Date__c=system.today().addYears(1),  Customer_Account__c=accList.get(0).id, Precedence_Value__c=i));
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
        SBQQ__Quote__c q=new SBQQ__Quote__c(Quote_Name__c='OrderConfirmationPageTest Quote', Order_Type__c='DANBURY SYSTEM ORDER', Operating_Unit__c='HOLX_US_OU', SBQQ__Account__c=accList.get(0).id, SBQQ__Opportunity2__c=newOpp.id,SBQQ__PriceBook__c=pricebook.Id, Bill_To_Account__c=accList.get(1).id, Deliver_To_Account__c=accList.get(2).id, Ship_To_Account__c=accList.get(3).id,BillTo_Site__c= siteList[0].id,ShipTo_Site__c= siteList[0].id,DeliverTo_Site__c= siteList[0].id,Requested_Date__c = system.today());
        system.debug('q1---'+q.CurrencyIsoCode);
        insert q;
        
        q.SBQQ__Primary__c = false;
        
        update q;
        
        SBQQ__Quote__c q1=new SBQQ__Quote__c(Quote_Name__c='OrderConfirmationPageTest Quote', SBQQ__Account__c=accList.get(0).id, SBQQ__Opportunity2__c=newOpp.id,SBQQ__PriceBook__c=pricebook.Id, Bill_To_Account__c=accList.get(1).id, Deliver_To_Account__c=accList.get(2).id, Ship_To_Account__c=accList.get(3).id,BillTo_Site__c= siteList[0].id,ShipTo_Site__c= siteList[0].id,DeliverTo_Site__c= siteList[0].id,Requested_Date__c = system.today());
        system.debug('q1---'+q.CurrencyIsoCode);
        insert q1;
        
        
        //q.SBQQ__Primary__c = false;
        //update q;
        
        System.assertEquals('OrderConfirmationPageTest Quote',q.Quote_Name__c);
        List<SBQQ__QuoteLine__c> quoteLines=new List<SBQQ__QuoteLine__c>();
        set<SBQQ__QuoteLine__c> quoteLineset=new set<SBQQ__QuoteLine__c>();
        //SBQQ__QuoteLine__c q1=new SBQQ__QuoteLine__c();
        
        for(Integer i=0; i<=5; i++){
            quoteLineset.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c=q.Id, Account__c=accList.get(0).id, Include_In_Order__c=true, SBQQ__Product__c=prodList.get(i).Id, SBQQ__ListPrice__c = 100, SBQQ__Quantity__c=1,SBQQ__Number__c=i+1,Requested_Date__c = system.today()));
        }
        quoteLineset.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c=q.Id, Account__c=accList.get(1).id, Include_In_Order__c=true, SBQQ__Product__c=prodList.get(1).Id, SBQQ__ListPrice__c = 100, SBQQ__Quantity__c=1,SBQQ__Number__c=10,Requested_Date__c = system.today()));
        //quoteLineset.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c=q.Id, Account__c=accList.get(1).id, Include_In_Order__c=true, SBQQ__Product__c=prodList.get(1).Id, SBQQ__ListPrice__c = 100, SBQQ__Quantity__c=1,SBQQ__Number__c=10,Requested_Date__c = system.today(),Ship_Date__c=system.today()+3));
        
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
        update q;
        system.debug(quoteLines);    
        
        
    }
    
}