/*------------------------------------------------------------
Author:         Denise Bacher
Company:        Salesforce.com
Description:    Test class to validate AssetTrigger
                Tests Excecuted:
                
                setAccountLookups_insert - verify that on insert of an asset with an oracle party id, and a install location, the customer and site accounts are populated
                
                setAccountLookups_update - verify that on update of an asset if the install location changes, the site account is updated

                setQuoteLineLookups_insert - verify that on insert of an asset, that the quote line is updated from the order line item
                
                setQuoteLineLookups_update - verify that on update of an asset, that the quote line is updated from the order line item
                
                updateCaseWorkOrderAssetLookups_insert - verify that on insert of an asset, cases and work orders (related via Order Item) are updated with the asset id
                
                createServiceContracts_insert - verify that on insert of an asset, service contract, contract line items are created for the asset
                
                createServiceContracts_disabled - verify that on insert of an asset, service contract, contract line items are not created for the asset
                
                createServiceContracts_noOrderOrQuote - verify that on insert of an asset with no order/quote, only the warranty service contract, contract line items are created for the asset
History:
<Date>          <Authors Name>      <Brief Description of Change>
04/27/2016      Denise Bacher       Initial Creation (US762)
06/21/2016      Marc Goldstein      Added setQuoteLineLookups_insert test case (US1316)
07/13/2016      Denise Bacher       Added unit tests for new functions (US1072 & US142)
11/04/2016      Denise Bacher       Added unit test for createServiceContracts updates (US-0001141)
05/17/2017      Kasmoor             Added Logic to for Trigger Switch address Order Line and Case (US-0002505 & US-0002764)
05/22/2017      Raj Sharan          Update Logic with Trigger Switch address to call Test Utility Order Line and Case (US-0002764)
08/31/2017      Kasmoor             Update for setAdvancedExchange_Test US-0002764
03/22/2018      Raviraj Reddy       Added unit test for AMPS Merchant Track Method (US3819)
04/02/2018      Chris Jongbloed     Added unit test to create and/or Update an Account_Product_Family__c record to reflect what Product Families are owned by the Account (US3843)

06/20/2018   Ryan Lambert    Remove all code / reference to FSLIS
25/02/2019   Alex Powning    Removed AMPS Tasks -> moved to account
------------------------------------------------------------*/
@isTest
private class AssetTrigger_Test {
    private static Integer ASSETTRIGGERTEST_PRODUCT_COUNT = 1;
    private static Integer ASSETTRIGGERTEST_QUOTE_COUNT = 1;
    private static Integer ASSETTRIGGERTEST_QUOTELINE_COUNT = 1; 
    private static Integer ASSETTRIGGERTEST_INSERTEDASSET_COUNT = 3;
    private static Integer ASSETTRIGGERTEST_INSERTEDSERVICECONTEACT_COUNT = 3;
    private static Integer ASSETTRIGGERTEST_INSERTEDCONTRACTLINE_COUNT = 3;
    
    public static Configuration_Settings__c orgDefaults;
    public static Id accountCustomerRecordTypeId = GlobalUtility.getRecordTypeId('Account', 'Customer');
    public static Id accountSiteRecordTypeId = GlobalUtility.getRecordTypeId('Account', 'Site');
    public static Pricebook2 pricebook;
    public static contact con;
    public static Order newOrder;
    public static OrderItem neworderitem;
    public static Order newOrder1;
    public static OrderItem neworderitem1;
    public static OrderItem neworderitem2;
    public static Asset asset1;
    public static Asset asset2;
    public static Case case1;
    public static Case case2;
    private static Account siteAccount;
    private static Account custAccount;
    private static Account siteAccount1;
    private static Account custAccount1;
    private static List<PriceBookEntry> pbeList;
    private static User integrationUser;
    private static User sysAdminUser;
    private static ServiceContract serviceContract; 
    
    public static List<Account> customerAccounts = new List<Account>();
    public static List<Site_Location__c> primaryLocations = new List<Site_Location__c>();
    public static List<Site_Location__c> secondaryLocations = new List<Site_Location__c>();
    
    public static Map<Id, Account> customerAccountMap = new Map<Id, Account>();
    public static Map<Id, Site_Location__c> primarySiteLocationMap = new Map<Id, Site_Location__c>();
    public static Map<Id, Site_Location__c> secondarySiteLocationMap = new Map<Id, Site_Location__c>();
    public static Map<Id, Id> customerAccountToSiteAccount = new Map<Id, Id>();
    //08/03/2017-(Amarendra Nagireddy)--Declared new Product_Source_Division
    public static Product_Source_Division__c  psd;
    public static Product_Source_Division__c  psd1;
    public static List<Site_Location__c> siteLocations = new List<Site_Location__c>();
    public static User installationCaseOwner;
    public static User runningUser;
    public static User manager;
    public static User managersManager;
    
    private static void doStaticSetup(){
        orgDefaults = TestUtility.setupConfigurationSettings();
        
        //05-22-2017 Update of Insertion of TriggerSwitch. Raj Sharan (US-0002505 & US-0002764)
        //TestUtility.insertCustSetting('OpportunityTrigger'); 
       
        //17/05/2017-(Kasmoor Reddy)- created instance to parse the triggers as part of US-0002505 & US-0002764. 
        TestUtility.insertCustSetting('OrderLineProductReplacement'); 
        //TestUtility.insertCustSetting('CaseSummaryTrigger'); 
        
        // End of update for (US-0002505 & US-0002764)

        // INSERTED BY RL 04/03/2018
        //TestUtility.insertCustSetting('sitelocTrigger');
        delete [SELECT Id FROM Trigger_Switch__c WHERE Name = 'siteLocTrigger'];
      
        // create Price Book
        pricebook = TestUtility.newPricebook('Test Pricebook');
        insert pricebook;
        // Installation Case Creation User (US-0002764)
        installationCaseOwner = TestUtility.newUser(UserInfo.getProfileId(), 'csOwner');
        insert installationCaseOwner;

        // update the org defaults
        orgDefaults.Diagnostic_Install_Upgrade_Case_Queue_Id__c = installationCaseOwner.Id;
        orgDefaults.Service_Pricebook_USD__c = pricebook.Id;
        update orgDefaults;
        
        // insert an account
        custAccount = TestUtility.newAccount('Customer Account', 'testCust', 'ABC Street', null, GlobalUtility.getRecordTypeId('Account', 'Customer'));
        custAccount.BillingCountryCode = 'US';
        custAccount.BillingStateCode = 'NY';
        custAccount.Internal__c = true;        
        insert new List<Account>{custAccount};
        
        for(Integer i = 0; i <2 ; i++){
            customerAccounts.add(TestUtility.newAccount('CustAccount-'+i, 'custParty'+i, null, null, accountCustomerRecordTypeId));
        }
        insert customerAccounts;
        
        siteAccount = TestUtility.newAccount('Site Account', 'testSite', 'ABC Street', customerAccounts[0].Id, GlobalUtility.getRecordTypeId('Account', 'Site'));
        siteAccount.BillingCountryCode = 'US';
        siteAccount.BillingStateCode = 'NY';
        siteAccount.Internal__c = false;
        insert siteAccount;
        
         Con = TestUtility.newContact('Firstname ','Lastname ', customerAccounts[1].id);
         con.Phone = '+(999) 999-9999';
         insert con;
        
        for(Account a : customerAccounts){
            customerAccountMap.put(a.Id, a);
        }       
        
        for(Account a : customerAccounts){
            primaryLocations.add(TestUtility.newSiteLocation('123 A Street Suite 1', '123 A Street', 'Suite 1', null, null,
                'Some City', 'MA', '11111', 'US',
                a.Oracle_Party_Id__c, a.Id, true));
                
            secondaryLocations.add(TestUtility.newSiteLocation('125 A Street Suite 2', '125 A Street', 'Suite 2', null, null,
                'Some City', 'MA', '11111', 'US',
                a.Oracle_Party_Id__c, a.Id, true));
        }
        List<Site_Location__c> temp = new List<Site_Location__c>();
        temp.addAll(primaryLocations);
        temp.addAll(secondaryLocations);
        insert temp;
        
        for(Site_Location__c l : [Select Id, Account__c, Account__r.ParentId From Site_Location__c Where Id IN: primaryLocations]){
            primarySiteLocationMap.put(l.Id, l);
            customerAccountToSiteAccount.put(l.Account__r.ParentId, l.Account__c);
        }
        
        for(Site_Location__c l : [Select Id, Account__c, Account__r.ParentId From Site_Location__c Where Id IN: secondaryLocations]){
            secondarySiteLocationMap.put(l.Id, l);
        }
        
         //08/03/2017-(Amarendra Nagireddy)- created a new product source division record from new method in TestUtility class 
        psd = TestUtility.newProductSourceDivision('1234','MAMMOGRAPHY');
        Insert psd;
        psd1 = TestUtility.newProductSourceDivision('12345','MOLECULAR');
        Insert psd1;
        Site_Location__c sl1 = TestUtility.newSiteLocation('123 A Street Suite 1', '123 A Street', 'Suite 1', null, null,
                'Some City', 'MA', '11111', 'US',
                customerAccounts[0].Oracle_Party_Id__c, null, true);
            sl1.Bill_To__c = true;
            sl1.Account__c = siteAccount.Id;
            siteLocations.add(sl1);
                
            Site_Location__c sl2 = TestUtility.newSiteLocation('456 B Street Suite 1', '456 B Street', 'Suite 1', null, null,
                'Some City', 'MA', '11111', 'US',
                customerAccounts[0].Oracle_Party_Id__c, null, true);
            sl2.Ship_To__c = true;
            sl2.Account__c = siteAccount.Id;
            siteLocations.add(sl2);
            
            insert siteLocations;
            
        runningUser = TestUtility.newUser(UserInfo.getProfileId(), 'usr');
        manager = TestUtility.newUser(UserInfo.getProfileId(), 'mgr');
        managersManager = TestUtility.newUser(UserInfo.getProfileId(), 'mgrmgr');
        insert new List<User>{runningUser, manager, managersManager};
    }
    
    public static List<Product2> products = new List<Product2>();
    public static List<Product2> products1 = new List<Product2>();
    public static List<Product2> warrantyProducts = new List<Product2>();
    public static List<Product2> extendedWarrantyProducts = new List<Product2>();
    public static List<Product2> allProducts = new List<Product2>();
    public static List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();
    public static Map<Id, PricebookEntry> productToPricebookEntry = new Map<Id, PricebookEntry>();
    public static List<SBQQ__Quote__c> quotes = new List<SBQQ__Quote__c>();
    public static List<SBQQ__QuoteLine__c> quoteLines = new List<SBQQ__QuoteLine__c>();
    public static List<SBQQ__QuoteLine__c> extQuoteLines = new List<SBQQ__QuoteLine__c>();
    public static Map<Id, SBQQ__QuoteLine__c> quoteLineMap = new Map<Id, SBQQ__QuoteLine__c>(); 
    public static Map<Id, Order> quoteIdToOrder = new Map<Id, Order>();
    public static Map<Id, Order> orderMap = new Map<Id, Order>();
    public static List<Order> orders = new List<Order>();
    public static List<OrderItem> orderItems = new List<OrderItem>();
    
    private static void setupProducts(Integer productCount){
        //Create Products
        for(Integer i = 0; i < productCount; i++){
            Product2 prod = TestUtility.newProduct('Warranty ' + i);
            prod.Service_Subscription__c = true;
            prod.Term_months__c = 12;
            prod.Description = 'Description for warranty product';
            prod.Service_Type__c = 'Warranty';
            //08/03/2017-(Amarendra Nagireddy)- Mapped Product Source Division id on Product
            prod.Product_Source_Division__c=psd.id;
            warrantyProducts.add(prod);
        }
        allProducts.addAll(warrantyProducts);
        
        for(Integer i = 0; i < productCount; i++){
            Product2 prod = TestUtility.newProduct('Extended Warranty ' + i);
            prod.Service_Subscription__c = true;
            prod.Term_months__c = 18;
            prod.Description = 'Description for extended warranty product';
            prod.Service_Type__c = 'Extended Warranty';
            //08/03/2017-(Amarendra Nagireddy)--Mapped Product Source Division id on Product
            prod.Product_Source_Division__c=psd.id;
            extendedWarrantyProducts.add(prod);
        }
        allProducts.addAll(extendedWarrantyProducts);
        insert allProducts;
        
        for(Integer i = 0; i < productCount; i++){
            Product2 prod = TestUtility.newProduct('Product ' + i);
            //08/03/2017-(Amarendra Nagireddy)--Mapped Product Source Division id on Product
            prod.Product_Source_Division__c=psd.id;
            prod.Warranty_Coverage__c = warrantyProducts[i].Id;
            prod.Internal_Coverage__c = warrantyProducts[i].Id;
            
            products.add(prod);
        }
        insert products;
        allProducts.addAll(products);
        
        // create Price Book entry
        pricebookEntries = new List<PricebookEntry>();
        productToPricebookEntry = new Map<Id, PricebookEntry>();
        for(Product2 p : allProducts){
            PricebookEntry pbe = TestUtility.newPricebookEntry(pricebook.Id, p.Id, 100);
            pricebookEntries.add(pbe);
            productToPricebookEntry.put(p.Id, pbe);
        }
        insert pricebookEntries;
    }
    
    private static void setupQuotesAndOrders(Integer productCount, Integer quoteCount, Integer quoteLineCount){
        setupProducts(productCount);
        // create Quotes
        for(Integer i = 0; i < quoteCount; i++){
            SBQQ__Quote__c q = TestUtility.newQuote(customerAccounts[i].Id, null);
            q.SBQQ__PriceBookId__c = pricebook.Id;
            q.Bill_To_Account__c=customerAccounts[0].id;
            q.BillTo_Site__c=siteLocations[0].id;
            q.Ship_To_Account__c=customerAccounts[1].id;
            q.ShipTo_Site__c=siteLocations[1].id;
            q.Operating_Unit__c='HOLX_US_OU';
            q.Internal_Contact__c=runningUser.id;
            q.SBQQ__PaymentTerms__c='30 NET';
            q.District_Service_Manager2__c=manager.id;
            q.Account_Manager__c=managersManager.id;
            q.OSS_Rep__c=runningUser.id;
            q.PO_Number__c='PO_Number__c';
            q.SBQQ__PrimaryContact__c=con.id;
            quotes.add(q);
        }
        insert quotes;
        system.debug('quotes========='+quotes);
        
        // create quote lines and orders
        for(SBQQ__Quote__c q : quotes){
            Order newOrder = TestUtility.newOrder(q.SBQQ__Account__c, pricebook.Id, q.Id, 'Draft', System.today());
            orders.add(newOrder);
            quoteIdToOrder.put(q.Id, newOrder);
            
            for(Product2 p : products){
                SBQQ__QuoteLine__c ql = TestUtility.newQuoteLine(q.Id, p.Id, 10, 1);
                ql.SBQQ__DefaultSubscriptionTerm__c = null;
                quoteLines.add(ql);
            }
        }
        insert quoteLines;
        insert orders;
            
        for(SBQQ__QuoteLine__c ql : quoteLines){
            //ql.SBQQ__DefaultSubscriptionTerm__c = 1;
            quoteLineMap.put(ql.Id, ql);
        }
        
        for(Order o : orders){
            orderMap.put(o.Id, o);
        }
        
        for(SBQQ__QuoteLine__c ql : quoteLines){
            for(Product2 p : extendedWarrantyProducts){
                SBQQ__QuoteLine__c exQL = TestUtility.newQuoteLine(ql.SBQQ__Quote__c, p.Id, 100,1);
                exQL.SBQQ__RequiredBy__c = ql.Id;
                exQL.SBQQ__DefaultSubscriptionTerm__c = 12;
                extQuoteLines.add(exQL);
            }
        }
        insert extQuoteLines;
        
        // create order lines - one for each asset that will later be generated
        for(SBQQ__QuoteLine__c ql : quoteLines){
            for(Integer i = 0; i < ql.SBQQ__Quantity__c; i++){
                orderItems.add(TestUtility.newOrderItem(quoteIdToOrder.get(ql.SBQQ__Quote__c).Id, ql.Id, productToPricebookEntry.get(ql.SBQQ__Product__c).Id, 1, ql.SBQQ__ListPrice__c));
            }
        }
        insert orderItems;
    }
    
    private static void setupOrders(Integer productCount, Integer orderCount){
        setupProducts(productCount);
        
        Integer custAcc = customerAccounts.size();      
        Order newOrder;
        // create Orders
        for(Integer i = 0; i < orderCount; i++){
             if(orderCount <= customerAccounts.size())                  
                newOrder = TestUtility.newOrder(customerAccounts[i].Id, pricebook.Id, null, 'Draft', System.today());       
            else        
                newOrder = TestUtility.newOrder(customerAccounts[0].Id, pricebook.Id, null, 'Draft', System.today());
                
                orders.add(newOrder);
        }
        insert orders;
        
        // create Order Items
        for(Order o : orders){
            for(Product2 p : products){
                orderMap.put(o.Id, o);
                
                OrderItem oi = TestUtility.newOrderItem(o.Id, null, productToPricebookEntry.get(p.Id).Id, 1, 100);
                oi.PricebookEntry = productToPricebookEntry.get(p.Id);
                orderItems.add(oi);
            }
        }
        insert orderItems;
    }

    static testMethod void setAccountLookups_insert(){
        doStaticSetup();
        
        List<Asset> assets = new List<Asset>();
        List<Asset> insertassets = new List<Asset>();
        
        for(Integer i = 0; i < customerAccounts.size(); i++){
            insertassets.add(TestUtility.newAsset(customerAccounts[i].Oracle_Party_Id__c, primaryLocations[i].Id, 'Asset-'+i));
        }
        for(asset a:insertassets){
            a.Accountid=customerAccounts[0].id;
            a.Contactid=Con.id;
            a.status = 'Return';
            assets.add(a);
        }
        
        Test.startTest();
            insert assets;
        Test.stopTest();
        
        List<Asset> updatedAssets = [Select Id, Name, Install_Location__c, AccountId, Oracle_Party_Id__c, Customer_Account__c From Asset];
        //System.assertEquals(25, updatedAssets.size());
        
        for(Asset a : updatedAssets){
            //System.assertNotEquals(null, a.AccountId, 'Site Account is null');
           // System.assertNotEquals(null, a.Customer_Account__c, 'Customer Account is null');
            
           // System.assert(customerAccountMap.containsKey(a.Customer_Account__c), 'Customer Account Missing');
           // System.assertEquals(customerAccountMap.get(a.Customer_Account__c).Oracle_Party_Id__c, a.Oracle_Party_Id__c);
            
            //System.assert(primarySiteLocationMap.containsKey(a.Install_Location__c), 'Install Location Missing');
            //System.assertEquals(primarySiteLocationMap.get(a.Install_Location__c).Account__c, a.AccountId);
        }
    }
     static testMethod void AssetForBillToAddressUpdate(){
        doStaticSetup();
        Schema.Location loc=new Schema.Location(Name='testLoc',CloseDate=system.today());
         insert loc;
         system.debug('loc'+loc+'id'+loc.id);
        Schema.Address add=new Schema.Address(ParentId=loc.id,AddressType='Mailing');
         insert add;
          
         system.debug('add'+add+'add parent'+add.parentId);
        List<Asset> assets = new List<Asset>();
        List<Asset> insertassets = new List<Asset>();
        
        for(Integer i = 0; i < customerAccounts.size(); i++){
            insertassets.add(TestUtility.newAsset(customerAccounts[i].Oracle_Party_Id__c, primaryLocations[i].Id, 'Asset-'+i));
        }
        for(asset a:insertassets){
            a.Accountid=customerAccounts[0].id;
            a.Contactid=Con.id;
            a.status = 'Return';
            a.Bill_To_Address__c=add.id;
            assets.add(a);
        }
        assets[0].Bill_To_Address__c=null; 
        system.debug(assets[0].Bill_To_Address__r.parentId);
        Test.startTest();
            insert assets;
        Test.stopTest();
        
       
    }
    
    static testMethod void setAccountLookups_update(){
        doStaticSetup();
        
        List<Asset> assets = new List<Asset>();
// RL TEST
        System.debug('AssetTrigger_Test >> ENTERING setAccountLookups_update *****************************************');        
        Test.startTest();
        for(Integer i = 0; i < 2; i++){
            System.debug('AssetTrigger_Test >> inside loop ['+i+']');  
            assets.add(TestUtility.newAsset(customerAccounts[i].Oracle_Party_Id__c, primaryLocations[i].Id, 'Asset-'+i));
            System.debug('AssetTrigger_Test >> assets added : '+assets); 
        }
        System.debug('AssetTrigger_Test >> assets before insert'); 
        insert assets;
        System.debug('AssetTrigger_Test >> assets after insert'); 
        
        System.debug('AssetTrigger_Test >> Test.startTest');         
        
            for(Integer i = 0; i < assets.size(); i++){
                assets[i].Install_Location__c = secondaryLocations[i].Id;
                assets[i].Customer_Account__c = null; // set to null, oracle id should repopulate it
            }
            System.debug('AssetTrigger_Test >> update assets');                 
            update assets;
        System.debug('AssetTrigger_Test >> Test.stopTest');         
        Test.stopTest();
        
        System.debug('AssetTrigger_Test >> about to query asset');                 
        List<Asset> updatedAssets = [Select Id, Name, Install_Location__c, AccountId, Oracle_Party_Id__c, Customer_Account__c From Asset];
        //System.assertEquals(25, updatedAssets.size());
        if (updatedAssets != null) {
            System.debug('AssetTrigger_Test >> after query asset - rows : ' + updatedAssets.size());                 
        } else {
            System.debug('AssetTrigger_Test >> after query asset - rows : ' + updatedAssets);                 
        }
        
        System.debug('AssetTrigger_Test >> loop through updatedAssets');         
        for(Asset a : updatedAssets){
            System.assertNotEquals(null, a.AccountId, 'Site Account is null');
            System.assertNotEquals(null, a.Customer_Account__c, 'Customer Account is null');
            
            System.assert(customerAccountMap.containsKey(a.Customer_Account__c), 'Customer Account Missing');
            System.assertEquals(customerAccountMap.get(a.Customer_Account__c).Oracle_Party_Id__c, a.Oracle_Party_Id__c);
            
            System.assert(secondarySiteLocationMap.containsKey(a.Install_Location__c), 'Install Location Missing');
            System.assertEquals(secondarySiteLocationMap.get(a.Install_Location__c).Account__c, a.AccountId);
        }
        System.debug('AssetTrigger_Test >> done');                 
    }
     
    static testMethod void setQuoteLineLookups_insert(){
        doStaticSetup();

        Test.startTest();
        List<Asset> assets = new List<Asset>();
        //TestUtility.insertCustSetting('OpportunityTrigger');
        recordtype[] tt = [Select  r.Id, r.SobjectType, r.Name From RecordType r where sobjecttype ='Opportunity' and Name = 'B&SH Sales Open Opportunity'];
        Opportunity newOpp = TestUtility.newOpportunity('OppTest', customerAccounts.get(0).Id, System.today(), 'Target', 'Pipeline'); 
        newOpp.Pricebook2Id = pricebook.Id;
        newOpp.RecordTypeId =  tt[0].Id;
         insert newOpp;
        system.debug('newOpp========='+newOpp);

        //Create Products
        List<Product2> prodList = new List<Product2>();
        for(Integer i = 0; i <= 2; i++){
            Product2 prod1=TestUtility.newProduct('Product ' + i);
            //08/03/2017-(Amarendra Nagireddy)--Mapped Product Source Division id on Product
            prod1.Product_Source_Division__c=psd.id;
            prodList.add(prod1);
        }
        insert prodList;
        
        // create Price Book entry
        pricebookEntries = new List<PricebookEntry>();
        for(Product2 p : prodList){
            pricebookEntries.add(TestUtility.newPricebookEntry(pricebook.Id, p.Id, 100));
        }
        insert pricebookEntries;
        
        SBQQ__Quote__c quote = TestUtility.newQuote(customerAccounts[0].Id, newOpp.id);
            quote.Bill_To_Account__c=customerAccounts[0].id;
            quote.BillTo_Site__c=siteLocations[0].id;
            quote.Ship_To_Account__c=customerAccounts[1].id;
            quote.ShipTo_Site__c=siteLocations[1].id;
            quote.Operating_Unit__c='HOLX_US_OU';
            quote.Internal_Contact__c=runningUser.id;
            quote.SBQQ__PaymentTerms__c='30 NET';
            quote.District_Service_Manager2__c=manager.id;
            quote.Account_Manager__c=managersManager.id;
            quote.OSS_Rep__c=runningUser.id;
            quote.PO_Number__c='PO_Number__c';
            quote.SBQQ__PrimaryContact__c=con.id;
          insert quote;
        system.debug('quote========='+quote);

        SBQQ__QuoteLine__c quoteLine = TestUtility.newQuoteLine(quote.Id, prodList[0].Id, 100, 1);
         insert quoteLine;

        Order newOrder = TestUtility.newOrder(customerAccounts[0].Id, pricebook.Id, 'Draft', System.today());
         insert newOrder;
        
        List<OrderItem> currOrderItems = new List<OrderItem>();
        for(Integer i = 0; i < customerAccounts.size(); i++){
            currOrderItems.add(TestUtility.newOrderItem(newOrder.Id, quoteLine.Id, pricebookEntries[0].Id, 1, 100));
        }
         insert currOrderItems;
    
        for(Integer i = 0; i < customerAccounts.size(); i++){
            assets.add(TestUtility.newAsset(customerAccounts[0].Oracle_Party_Id__c, primaryLocations[i].Id, 'Asset-'+i, currOrderItems[i].id));
        }
        
        
           insert assets;
        Test.stopTest();
        
        List<Asset> updatedAssets = [Select Id, Name, Install_Location__c, AccountId, Oracle_Party_Id__c, Customer_Account__c, SBQQ__QuoteLine__c, Order_Line_Item__r.Quote_Line__c 
            From Asset
            Where ID IN: assets];
        // System.assertEquals(2, updatedAssets.size());
        
        for(Asset a : updatedAssets){
            System.assertNotEquals(null, a.SBQQ__QuoteLine__c);
            System.assertNotEquals(null, a.Order_Line_Item__r.Quote_Line__c);
            System.assertEquals(a.SBQQ__QuoteLine__c, a.Order_Line_Item__r.Quote_Line__c);
        }
    }
      static testMethod void test_ServiceContdactUtility(){
        doStaticSetup();
          TestUtility.insertCustSetting('ContractLineItemTrigger'); 
        //List<ContractLineItem> insertContractLinesList = new List<ContractLineItem>();
         Account acc = TestUtility.newAccount('Test Account', null);
        insert acc;
        
        Pricebook2 pb = TestUtility.newPricebook('Test Pricebook');
        insert pb;
        
        Product2 prod = TestUtility.newProduct('Test Product');
        insert prod;
        
        PricebookEntry pbe = TestUtility.newPricebookEntry(pb.Id, prod.Id, 27);
        insert pbe;
        
        ServiceContract servCon = new ServiceContract();
        servCon.Name = 'Test Service Contract';
        servCon.AccountId = acc.Id;
        servCon.Pricebook2Id = pb.Id;
        insert servCon;    
        Asset asst = TestUtility.newAsset('Test Asset', acc.Id, acc.Id, prod.Id);
        asst.Shipped_on_Date__c=system.today()+10;
      
        insert asst;
         List<Asset> assList=[select id,Shipped_on_Date__c from Asset];
          system.debug('assList'+assList);
          asst.Shipped_on_Date__c=system.today()+20;
          update asst;
        
        ContractLineItem cli = new ContractLineItem();
        cli.ServiceContractId = servCon.Id;
        cli.PricebookEntryId = pbe.Id;
        cli.Quantity = 27;
        cli.UnitPrice = 27;
        //cli.Status='Active';
        cli.StartDate = Date.today().addMonths(-6);
        cli.EndDate = Date.today().addYears(1);
        cli.AssetId = asst.Id;
          cli.Description='test description';
        
        //Start test
        Test.startTest();
        
        //Insert ContractLineItem
        insert cli;
       
           cli.AssetId = asst.Id;
          update cli;
        //Stop test
        Test.stopTest();
           List<contractLineItem> cliList=new List<contractLineItem>([select id,AssetId,EndDate,ServiceContractId from contractLineItem]);
         // cliList.add(cli);
          system.debug(cliList);
          Service_Billing_Schedule__c sbSchedule1 = TestUtility.newservicebilling('PM Plan', cli.Id, 1); 
          sbSchedule1.Contract_Line_Item__c=cli.Id;
          
            insert sbSchedule1;
                Service_Billing_Schedule__c sbSchedule=[select id,name,Sequence__c,Number_of_Periods__c,Period__c,Amount__c,End_Date__c,Start_Date__c,Contract_Line_Item__c,Contract_Line_Item__r.AssetId from Service_Billing_Schedule__c limit 1];
         //system.debug(sbList);
          //system.debug(sbList[0].Contract_Line_Item__r.AssetId);
          system.debug('sbSchedule'+sbSchedule.Contract_Line_Item__r.AssetId);
          Map<Id,contractLineItem> cliMap=new Map<Id,contractLineItem>();
          cliMap.put(cli.id,cli);
         
          Map<Id,Asset> AssetMap=new Map<Id,Asset>();
          AssetMap.put(asst.id,asst);
            
          Map<Id,Service_Billing_Schedule__c> sbScheduleMap=new  Map<Id,Service_Billing_Schedule__c>();
          
           sbScheduleMap.put(sbSchedule.Id,sbSchedule);
          
           Entitlement ent = new Entitlement();
        ent.Name = 'Test Entitlement';
        ent.AccountId = acc.Id;
        ent.AssetId = asst.Id;
        ent.RecordTypeId = GlobalUtility.getRecordTypeId('Entitlement', 'B_SH_PM');
        ent.ContractLineItemId = cli.Id;
        insert ent;
         List<Id> assetIdList=new List<Id>();
          assetIdList.add(asst.Id);
          Set<Id> assetId=new Set<Id>();
          assetId.add(asst.Id);
          Set<Id> accId=new Set<Id>();
          accId.add(acc.Id);
          system.debug(asst.id);
           Map<Id,Id> assetExchangeId=new Map<Id,Id>();
          assetExchangeId.put(asst.id,asst.id);
        ServiceContractUtility.copyContractLines(cliMap,assetExchangeId,AssetMap);
          ServiceContractUtility.createBillingSchedule(sbScheduleMap,cliList,assetExchangeId,AssetMap,cliMap);
          ServiceContractUtility.cancelContractLines(cliMap,assetExchangeId,AssetMap);
          ServiceContractUtility.cancelEntitlements(assetIdList,assetExchangeId,AssetMap,assetId,accId);
         ServiceContractUtility.cancelBillingSchedules(sbScheduleMap, assetExchangeId, AssetMap);
          ServiceContractUtility.cancelPreventiveMaintenancePlans(assetIdList, assetExchangeId, AssetMap);
    }
    static testMethod void setQuoteLineLookups_update(){
        doStaticSetup();
        
        Test.startTest();
        List<Asset> assets = new List<Asset>();
        //TestUtility.insertCustSetting('OpportunityTrigger');
        recordtype[] tt = [Select  r.Id, r.SobjectType, r.Name From RecordType r where sobjecttype ='Opportunity' and Name = 'B&SH Sales Open Opportunity'];
        Opportunity newOpp = TestUtility.newOpportunity('OppTest', customerAccounts.get(0).Id, System.today(), 'Target', 'Pipeline'); 
        newOpp.Pricebook2Id = pricebook.Id;
        newOpp.RecordTypeId =  tt[0].Id;
        insert newOpp;
        
        
        
        //Create Products
        List<Product2> prodList = new List<Product2>();
        for(Integer i = 0; i <= 2; i++){
            Product2 prod=TestUtility.newProduct('Product ' + i);
            prod.Product_Source_Division__c=psd.id;
            prodList.add(prod);
        }
        insert prodList;
        
        // create Price Book entry
        pricebookEntries = new List<PricebookEntry>();
        for(Product2 p : prodList){
            pricebookEntries.add(TestUtility.newPricebookEntry(pricebook.Id, p.Id, 100));
        }
        insert pricebookEntries;
        
        SBQQ__Quote__c quote = TestUtility.newQuote(customerAccounts[0].Id, newOpp.id);
            quote.Bill_To_Account__c=customerAccounts[0].id;
            quote.BillTo_Site__c=siteLocations[0].id;
            quote.Ship_To_Account__c=customerAccounts[1].id;
            quote.ShipTo_Site__c=siteLocations[1].id;
            quote.Operating_Unit__c='HOLX_US_OU';
            quote.Internal_Contact__c=runningUser.id;
            quote.SBQQ__PaymentTerms__c='30 NET';
            quote.District_Service_Manager2__c=manager.id;
            quote.Account_Manager__c=managersManager.id;
            quote.OSS_Rep__c=runningUser.id;
            quote.PO_Number__c='PO_Number__c';
            quote.SBQQ__PrimaryContact__c=con.id;
        insert quote;
        system.debug('quote========='+quote);

        SBQQ__QuoteLine__c quoteLine = TestUtility.newQuoteLine(quote.Id, prodList[0].Id, 100, 1);
        insert quoteLine;

        Order newOrder = TestUtility.newOrder(customerAccounts[0].Id, pricebook.Id, 'Draft', System.today());
        insert newOrder;
        
        List<OrderItem> currOrderItems = new List<OrderItem>();
        for(Integer i = 0; i < customerAccounts.size(); i++){
            currOrderItems.add(TestUtility.newOrderItem(newOrder.Id, quoteLine.Id, pricebookEntries[0].Id, 1, 100));
        }
        insert currOrderItems;
    
        for(Integer i = 0; i < customerAccounts.size(); i++){
            assets.add(TestUtility.newAsset(customerAccounts[0].Oracle_Party_Id__c, primaryLocations[i].Id, 'Asset-'+i, null));
        }
        insert assets;
        
        List<Asset> insertedAssets = [Select Id, Name, SBQQ__QuoteLine__c, Order_Line_Item__c 
            From Asset
            Where ID IN: assets];
        System.assertEquals(2, insertedAssets.size());
        
        for(Asset a : insertedAssets){
            System.assertEquals(null, a.SBQQ__QuoteLine__c);
            System.assertEquals(null, a.Order_Line_Item__c);
        }
        
            for(Integer i = 0; i < assets.size(); i++){
                assets[i].Order_Line_Item__c = currOrderItems[i].Id;
            }
            update assets;
        Test.stopTest();
        
        List<Asset> updatedAssets = [Select Id, Name, SBQQ__QuoteLine__c, Order_Line_Item__c, Order_Line_Item__r.Quote_Line__c 
            From Asset
            Where ID IN: assets];
        System.assertEquals(2, updatedAssets.size());
        
        for(Asset a : updatedAssets){
            System.assertNotEquals(null, a.SBQQ__QuoteLine__c);
            System.assertNotEquals(null, a.Order_Line_Item__c);
            System.assertNotEquals(null, a.Order_Line_Item__r.Quote_Line__c);
            System.assertEquals(a.SBQQ__QuoteLine__c, a.Order_Line_Item__r.Quote_Line__c);
        }
    }
    
    
    static testMethod void createServiceContracts_insert(){
        doStaticSetup();
        
        setupQuotesAndOrders(ASSETTRIGGERTEST_PRODUCT_COUNT, ASSETTRIGGERTEST_QUOTE_COUNT, ASSETTRIGGERTEST_QUOTELINE_COUNT);
        
        List<Asset> assets = new List<Asset>();
        Integer i = 0;
//        List<OrderItem> oiList = new List<OrderItem>();
//        for(Integer j=0;j<2;j++)
//            oiList.add(orderItems[j]);
            
        for(OrderItem oi : orderItems){
            Asset a = TestUtility.newAsset('TestAsset', customerAccountToSiteAccount.get(orderMap.get(oi.OrderId).AccountId), orderMap.get(oi.OrderId).AccountId, quoteLineMap.get(oi.Quote_Line__c).SBQQ__Product__c);
            a.RecordTypeId = GlobalUtility.getRecordTypeId('Asset', 'System');
            a.Order_Line_Item__c = oi.Id;
            a.SerialNumber = String.valueOf(i);
            a.Shipped_on_Date__c = System.today().addDays(i);
            a.ContactId= Con.id;
            a.Owner_Account__c = custAccount.id;
            assets.add(a);
            i++;
        }
        
        Test.startTest();
            insert assets;
            assets[0].Owner_Account__c = siteAccount.id;
            update assets;
        Test.stopTest();
        
        List<Asset> postInsertAssets = [Select Id, Name, AccountId, SerialNumber, Shipped_on_Date__c, Product2Id, Product2.Warranty_Coverage__r.Term_months__c
            , (Select Id, LineItemNumber, Service_Type__c, StartDate, EndDate, ParentContractLineItemId, ServiceContractId
                , PricebookEntryId, PricebookEntry.Product2Id, PricebookEntry.Product2.Term_months__c, Asset_Created__c
                , ServiceContract.SBQQSC__Quote__r.SBQQ__StartDate__c, ServiceContract.SBQQSC__Quote__r.SBQQ__EndDate__c
                From ContractLineItems)
            From Asset];
        
        //System.assertEquals(5,postInsertAssets.size());
        for(Asset a : postInsertAssets){
            //System.assertEquals(ASSETTRIGGERTEST_INSERTEDCONTRACTLINE_COUNT, a.ContractLineItems.size());
            
            for(ContractLineItem c : a.ContractLineItems){
                if(c.Service_Type__c == 'Warranty'){
                    System.assertEquals(null, c.ParentContractLineItemId);
                    System.assertNotEquals(null, c.ServiceContractId);
                    System.assertEquals(true, c.Asset_Created__c);
                    System.assertEquals(a.Shipped_on_Date__c, c.StartDate);
                    System.assertEquals(a.Shipped_on_Date__c.addMonths((Integer)a.Product2.Warranty_Coverage__r.Term_months__c), c.EndDate);
                }
                else if(c.Service_Type__c == 'Extended Warranty'){
                    System.assertEquals(null, c.ParentContractLineItemId);
                    System.assertNotEquals(null, c.ServiceContractId);
                    System.assertEquals(true, c.Asset_Created__c);
                    System.assertEquals(a.Shipped_on_Date__c.addMonths((Integer)a.Product2.Warranty_Coverage__r.Term_months__c).addDays(1), c.StartDate);
                    //System.assertEquals(a.Shipped_on_Date__c.addMonths((Integer)a.Product2.Warranty_Coverage__r.Term_months__c).addDays(1 + c.ServiceContract.SBQQSC__Quote__r.SBQQ__StartDate__c.daysBetween(c.ServiceContract.SBQQSC__Quote__r.SBQQ__EndDate__c)), c.EndDate);
                }
                /*else{
                    System.assert(false, 'Unknown ContractLineItem Type '+c);
                }*/
            }
        }
        
        List<ServiceContract> serviceContracts = [Select Id, ApprovalStatus, Count_Warranty_Lines__c From ServiceContract];
        //System.assertEquals(ASSETTRIGGERTEST_INSERTEDSERVICECONTEACT_COUNT, serviceContracts.size());
        for(ServiceContract sc : serviceContracts){
            if(sc.Count_Warranty_Lines__c > 0){
                //System.assertEquals('Activated', sc.ApprovalStatus);
            }
            else{
                //System.assertEquals('Draft', sc.ApprovalStatus);
            }
        }
    }
    static testMethod void createServiceContracts_insert1(){
        doStaticSetup();
        
        setupQuotesAndOrders(ASSETTRIGGERTEST_PRODUCT_COUNT, ASSETTRIGGERTEST_QUOTE_COUNT, ASSETTRIGGERTEST_QUOTELINE_COUNT);
        
        List<Asset> assets = new List<Asset>();
        Integer i = 0;
//        List<OrderItem> oiList = new List<OrderItem>();
//        for(Integer j=0;j<2;j++)
//            oiList.add(orderItems[j]);
            
        for(OrderItem oi : orderItems){
            
            Asset a1 = TestUtility.newAsset('TestAsset111', customerAccountToSiteAccount.get(orderMap.get(oi.OrderId).AccountId), orderMap.get(oi.OrderId).AccountId, quoteLineMap.get(oi.Quote_Line__c).SBQQ__Product__c);
            a1.RecordTypeId = GlobalUtility.getRecordTypeId('Asset', 'System');
            a1.Order_Line_Item__c = oi.Id;
            a1.SerialNumber = String.valueOf(i);
            a1.Shipped_on_Date__c = System.today().addDays(i);
            a1.ContactId= Con.id;
            a1.Owner_Account__c = siteAccount.id;
            assets.add(a1);
            i++;
        }
        
        Test.startTest();
            insert assets;
            assets[0].Owner_Account__c = siteAccount.id;
            update assets;
        Test.stopTest();
        
        List<Asset> postInsertAssets = [Select Id, Name, AccountId, SerialNumber, Shipped_on_Date__c, Product2Id, Product2.Warranty_Coverage__r.Term_months__c
            , (Select Id, LineItemNumber, Service_Type__c, StartDate, EndDate, ParentContractLineItemId, ServiceContractId
                , PricebookEntryId, PricebookEntry.Product2Id, PricebookEntry.Product2.Term_months__c, Asset_Created__c
                , ServiceContract.SBQQSC__Quote__r.SBQQ__StartDate__c, ServiceContract.SBQQSC__Quote__r.SBQQ__EndDate__c
                From ContractLineItems)
            From Asset];
        
        //System.assertEquals(5,postInsertAssets.size());
        for(Asset a : postInsertAssets){
            //System.assertEquals(ASSETTRIGGERTEST_INSERTEDCONTRACTLINE_COUNT, a.ContractLineItems.size());
            
            for(ContractLineItem c : a.ContractLineItems){
                if(c.Service_Type__c == 'Warranty'){
                    System.assertEquals(null, c.ParentContractLineItemId);
                    System.assertNotEquals(null, c.ServiceContractId);
                    System.assertEquals(true, c.Asset_Created__c);
                    System.assertEquals(a.Shipped_on_Date__c, c.StartDate);
                    System.assertEquals(a.Shipped_on_Date__c.addMonths((Integer)a.Product2.Warranty_Coverage__r.Term_months__c), c.EndDate);
                }
                else if(c.Service_Type__c == 'Extended Warranty'){
                    System.assertEquals(null, c.ParentContractLineItemId);
                    System.assertNotEquals(null, c.ServiceContractId);
                    System.assertEquals(true, c.Asset_Created__c);
                    System.assertEquals(a.Shipped_on_Date__c.addMonths((Integer)a.Product2.Warranty_Coverage__r.Term_months__c).addDays(1), c.StartDate);
                    //System.assertEquals(a.Shipped_on_Date__c.addMonths((Integer)a.Product2.Warranty_Coverage__r.Term_months__c).addDays(1 + c.ServiceContract.SBQQSC__Quote__r.SBQQ__StartDate__c.daysBetween(c.ServiceContract.SBQQSC__Quote__r.SBQQ__EndDate__c)), c.EndDate);
                }
                /*else{
                    System.assert(false, 'Unknown ContractLineItem Type '+c);
                }*/
            }
        }
        
        List<ServiceContract> serviceContracts = [Select Id, ApprovalStatus, Count_Warranty_Lines__c From ServiceContract];
        //System.assertEquals(ASSETTRIGGERTEST_INSERTEDSERVICECONTEACT_COUNT, serviceContracts.size());
        for(ServiceContract sc : serviceContracts){
            if(sc.Count_Warranty_Lines__c > 0){
                //System.assertEquals('Activated', sc.ApprovalStatus);
            }
            else{
                //System.assertEquals('Draft', sc.ApprovalStatus);
            }
        }
    }
     
    static testMethod void createServiceContracts_disabled(){
        doStaticSetup();
        
        orgDefaults.Disable_Auto_SC_Creation__c = true;
        update orgDefaults;
        
        setupOrders(4, 50);
        
        List<Asset> assets = new List<Asset>();
        Integer i = 0;
//        List<OrderItem> oiList = new List<OrderItem>();
//        for(Integer j=0;j<5;j++)
//            oiList.add(orderItems[j]);
        for(OrderItem oi : orderItems){
            Asset a = TestUtility.newAsset('TestAsset', customerAccountToSiteAccount.get(orderMap.get(oi.OrderId).AccountId), orderMap.get(oi.OrderId).AccountId, oi.PricebookEntry.Product2Id);
            a.RecordTypeId = GlobalUtility.getRecordTypeId('Asset', 'System');
            a.Order_Line_Item__c = oi.Id;
            a.SerialNumber = String.valueOf(i);
            a.Shipped_on_Date__c = System.today().addDays(i);
            a.ContactId= Con.id; 
            assets.add(a);
            
            i++;
        }
        
        Test.startTest();
            insert assets;
        Test.stopTest();
        
        List<Asset> postInsertAssets = [Select Id, Name, AccountId, SerialNumber, Shipped_on_Date__c, Product2Id, Product2.Warranty_Coverage__r.Term_months__c
            , (Select Id, LineItemNumber, Service_Type__c, StartDate, EndDate, ParentContractLineItemId, ServiceContractId
                , PricebookEntryId, PricebookEntry.Product2Id, PricebookEntry.Product2.Term_months__c, Asset_Created__c
                , ServiceContract.SBQQSC__Quote__r.SBQQ__StartDate__c, ServiceContract.SBQQSC__Quote__r.SBQQ__EndDate__c
                From ContractLineItems)
            From Asset];
        
        System.assertEquals(200, postInsertAssets.size());
        for(Asset a : postInsertAssets){
            System.assertEquals(0, a.ContractLineItems.size());
        }
        
        List<ServiceContract> serviceContracts = [Select Id, ApprovalStatus, Count_Warranty_Lines__c From ServiceContract];
        System.assertEquals(0, serviceContracts.size());
        
        List<ContractLineItem> contractLineItems = [Select Id, LineItemNumber, Service_Type__c, StartDate, EndDate, ParentContractLineItemId, ServiceContractId
            , PricebookEntryId, PricebookEntry.Product2Id, PricebookEntry.Product2.Term_months__c, Asset_Created__c
            , ServiceContract.SBQQSC__Quote__r.SBQQ__StartDate__c, ServiceContract.SBQQSC__Quote__r.SBQQ__EndDate__c
            From ContractLineItem];
        System.assertEquals(0, contractLineItems.size());
    }
    
    static testMethod void createServiceContracts_noOrderOrQuote(){
        doStaticSetup();
        
        Test.startTest();
        setupProducts(10);
        
        List<Asset> assets = new List<Asset>();
        Integer i = 0;
        for(Product2 p : products){
            Asset a1 = TestUtility.newAsset('TestAsset', customerAccountToSiteAccount.get(customerAccounts[0].Id), customerAccounts[0].Id, p.Id);
            a1.RecordTypeId = GlobalUtility.getRecordTypeId('Asset', 'System');
            a1.SerialNumber = String.valueOf(i);
            a1.Shipped_on_Date__c = System.today().addDays(i);
            a1.ContactId= Con.id; 
            assets.add(a1);
            
            Asset a2 = TestUtility.newAsset('TestAsset', customerAccountToSiteAccount.get(customerAccounts[1].Id), customerAccounts[1].Id, p.Id);
            a2.RecordTypeId = GlobalUtility.getRecordTypeId('Asset', 'System');
            a2.SerialNumber = String.valueOf(i++);
            a2.Shipped_on_Date__c = System.today().addDays(i);
            a2.ContactId= Con.id; 
            assets.add(a2);
            
            i++;
        }
        
            insert assets;
        Test.stopTest();
        
        List<Asset> postInsertAssets = [Select Id, Name, AccountId, SerialNumber, Shipped_on_Date__c, Product2Id, Product2.Warranty_Coverage__r.Term_months__c
            , (Select Id, LineItemNumber, Service_Type__c, StartDate, EndDate, ParentContractLineItemId, ServiceContractId
                , PricebookEntryId, PricebookEntry.Product2Id, PricebookEntry.Product2.Term_months__c, Asset_Created__c
                , ServiceContract.SBQQSC__Quote__r.SBQQ__StartDate__c, ServiceContract.SBQQSC__Quote__r.SBQQ__EndDate__c
                From ContractLineItems)
            From Asset];
        
        //System.assertEquals(5, postInsertAssets.size());
        for(Asset a : postInsertAssets){
            //System.assertEquals(1, a.ContractLineItems.size());
            
            for(ContractLineItem c : a.ContractLineItems){
                if(c.Service_Type__c == 'Warranty'){
                    System.assertEquals(null, c.ParentContractLineItemId);
                    System.assertNotEquals(null, c.ServiceContractId);
                    System.assertEquals(true, c.Asset_Created__c);
                    System.assertEquals(a.Shipped_on_Date__c, c.StartDate);
                    System.assertEquals(a.Shipped_on_Date__c.addMonths((Integer)a.Product2.Warranty_Coverage__r.Term_months__c), c.EndDate);
                }
                /*else{
                    System.assert(false, 'Unknown ContractLineItem Type '+c);
                }*/
            }
        }
        
        List<ServiceContract> serviceContracts = [Select Id, ApprovalStatus, Count_Warranty_Lines__c From ServiceContract];
        System.assertEquals(20, serviceContracts.size());
        for(ServiceContract sc : serviceContracts){
            if(sc.Count_Warranty_Lines__c > 0){
                System.assertEquals('Activated', sc.ApprovalStatus);
            }
                else{
                   
                 //   System.assert(false, 'Missing Warranty Lines '+sc);
                    
                }
        }
    }
    
    static testMethod void setAdvancedExchange_Test(){
        doStaticSetup();
        
        integrationUser = TestUtility.newUser([Select Id From Profile Where Name = 'Integration API User' Limit 1].Id, 'tstother');
        sysAdminUser = TestUtility.newUser([Select Id From Profile Where Name = 'System Administrator' Limit 1].Id, 'tstadmin');
        insert new List<User>{integrationUser, sysAdminUser};
        List<Asset> assetList = new List<Asset>();
        
        System.runAs(integrationUser) { 
    
            Date Today = System.Today(); 
            String pmPlanText = 'PM Plan';
            
            //insert products
            Product2 prodWarranty = TestUtility.newProduct('Product Warranty');
            insert prodWarranty;
    
            PriceBookEntry pbeWarranty = new PriceBookEntry();
                pbeWarranty.Product2Id = prodWarranty.Id;
                pbeWarranty.Pricebook2Id = pricebook.Id;
                pbeWarranty.unitprice=1.0;
                pbeWarranty.isActive = true;
            insert pbeWarranty;
    
            prodWarranty.Term_months__c = 120;
            update prodWarranty;
    
            Product2 prod = TestUtility.newProduct('Product 03');
            insert prod;
            
            products1 = new List<Product2>();
            products1.add(TestUtility.newProduct('Product 01'));
            products1.add(TestUtility.newProduct('Product 02'));
            products1[0].Product_Source_Division__c = psd.id;
            products1[1].Product_Source_Division__c = psd1.id;
            products1[0].Internal_Coverage__c =  prodWarranty.Id;
            products1[0].Warranty_Coverage__c =  prodWarranty.Id;
            products1[1].Internal_Coverage__c =  prodWarranty.Id;
            products1[1].Warranty_Coverage__c =  prodWarranty.Id;
            products1[0].PM_Product__c = prod.Id;
            products1[1].PM_Product__c = prod.Id;
            products1[0].System__c = TRUE; 
            products1[1].System__c = TRUE;
            // products1[0].Install_Case_Required__c = TRUE; 
            // products1[1].Install_Case_Required__c = TRUE;
            insert products1;
            update products1[0];
            update products1[1];
            products1.add(prod);
           
            system.debug(' PSD 0 = ' + products1[0].Product_Source_Division__r.Name);
            system.debug(' PSD ID = ' + psd.Name);
            system.debug(' PSD 1 = ' + products1[1].Product_Source_Division__r.Name); 
            system.debug(' PSD1 ID = ' + psd1.Name);
     
            //insert pricebookentry
            pbeList = new List<PriceBookEntry>();
            for(Product2 pd : products1){
                PriceBookEntry pbe = new PriceBookEntry();
                pbe.Product2Id = pd.Id;
                pbe.Pricebook2Id = pricebook.Id;
                pbe.unitprice=1.0;
                pbe.isActive = true;
                pbeList.add(pbe);
            }
            insert pbeList;
            
            Test.startTest();
            
            //insert asset1
            asset1 = TestUtility.newAsset('TestAsset', siteAccount.id, custAccount.id,products1[0].id);
            asset1.ContactId= Con.id;
            insert asset1;
            
            
    
            
            //insert second case
            case1 = TestUtility.newCase(customerAccounts[1].id, con.id,null,products1[0].id, GlobalUtility.getRecordTypeId('Case', 'B_SH_Install'), 'Complaint', 'New', 'Low', 'Sales Order');
            case1.Complaint__c = 'Yes';
            insert case1; 
            
             //insert order
            newOrder1 = TestUtility.newOrder(custAccount.Id, pricebook.Id,case1.id,GlobalUtility.getRecordTypeId('Order', 'B_SH_Service_Order'), 'Draft','Advanced Exchange',System.today());
            newOrder1.Type = 'Advanced Exchange';
            insert newOrder1;
    
            system.debug('Order Info '  + newOrder1);
            
            
            
           
    
            //insert orderitems
            neworderitem1 = TestUtility.newOrderItem(newOrder1.id,null,pbeList[0].id, 1, 100);
            neworderitem1.Line_Type__c = 'Shipment';
            neworderitem1.Pricebookentryid = pbeList[0].id;
            neworderitem1.Returned_Asset__c = asset1.id;
            insert neworderitem1;
            
            neworderitem2 = TestUtility.newOrderItem(newOrder1.id,null,pbeList[0].id, -1, 100);
            neworderitem2.Line_Type__c = 'RMA';
            neworderitem2.Pricebookentryid = pbeList[0].id;
           // neworderitem1.Asset__c = asset1.id;
            neworderitem2.Returned_Asset__c = asset1.id;
            insert neworderitem2;
            system.debug(neworderitem2.id);
            //update asset1;
         
            
    
            serviceContract = TestUtility.newServiceContract(custAccount.Id + ' Service Contract', custAccount.Id, 
            GlobalUtility.getRecordTypeId('ServiceContract', 'B_SH_Service_Contract'), pricebook.Id, 
            Today.addDays(-1), Today.addDays(365));
            serviceContract.ApprovalStatus = 'Activated';
            insert serviceContract;
            
            ContractLineItem cli = TestUtility.newContractLineItem(serviceContract.Id, pbeWarranty.Id, 1, 100, asset1.Id);
       
            cli.SBQQSC__Account__c = custAccount.Id; 
            cli.StartDate = Today.addDays(-1); 
            cli.EndDate = Today.addDays(365); 
            
            insert cli;
    
            //Entitlement ent1 = TestUtility.newEntitlement(pmPlanText, NULL, NULL, custAccount.Id, asset1.Id, NULL, Today.addDays(-1), Today.addDays(365));
            //insert ent1;
     
            Service_Billing_Schedule__c sbSchedule = TestUtility.newservicebilling(pmPlanText, cli.Id, 1); 
            insert sbSchedule;
                            
            //update asset
            asset1.Shipped_on_Date__c = Today.addDays(-10); 
            asset1.Bill_To_Location__c = siteLocations[0].Id; 
            asset1.Ship_To_Location__c = siteLocations[1].Id; 
            asset1.Install_Location__c = siteLocations[1].Id; 
            //update asset1;
            assetList.add(asset1);
            system.debug('asset1====='+asset1);
    
            //Test.startTest();
            //insert second asset
            asset2 = TestUtility.newAsset('TestAsset', siteAccount.id, custAccount.Id, products1[0].id);
            asset2.ContactId= Con.id; 
            insert asset2;
            
            //Test.stopTest();
            
          
            //Test.startTest();
            /*//insert second case
            case1 = TestUtility.newCase(customerAccounts[1].id, con.id,asset1.id,products1[0].id, GlobalUtility.getRecordTypeId('Case', 'Diagnostic_Service'), 'Complaint', 'New', 'Low', 'Sales Order');
            case1.Complaint__c = 'Yes';
            insert case1;*/ 
            
            //insert order
            newOrder1 = TestUtility.newOrder(custAccount.Id, pricebook.Id,null,GlobalUtility.getRecordTypeId('Order', 'B_SH_Service_Order'), 'Draft','Advanced Exchange',System.today());
            newOrder1.Type = 'Advanced Exchange';
            insert newOrder1;
    
            system.debug('Order Info '  + newOrder1);
    
            //insert orderitems
            neworderitem1 = TestUtility.newOrderItem(newOrder1.id,null,pbeList[0].id, 1, 100);
            neworderitem1.Line_Type__c = 'Shipment';
            neworderitem1.Pricebookentryid = pbeList[0].id;
            neworderitem1.Returned_Asset__c = asset1.id;
            insert neworderitem1;
        
            system.debug('neworderitem1 = ' + neworderitem1);
                
            neworderitem2 = TestUtility.newOrderItem(newOrder1.id,null,pbeList[0].id, -1, 100);
            neworderitem2.Line_Type__c = 'RMA';
            neworderitem2.Pricebookentryid = pbeList[0].id;
          // neworderitem1.Asset__c = asset1.id;
            neworderitem2.Returned_Asset__c = asset2.id;
            //insert neworderitem2;
    
            
            system.debug('New Order Order_Price_Book__c = ' + neworderitem1.Order_Price_Book__c);
    
            newOrder1.Status = 'ENTERED'; 
            update newOrder1;
            Test.stopTest();
    
            //update orderitem
            //neworderitem1.Status__c = 'Awaiting Shipping';
            //update neworderitem1;
    
            //update asset
            ContractLineItem cli2 = TestUtility.newContractLineItem(serviceContract.Id, pbeWarranty.Id, 1, 100, asset2.Id);
            cli2.SBQQSC__Account__c = custAccount.Id; 
            cli2.StartDate = Today.addDays(-1); 
            cli2.EndDate = Today.addDays(365); 
            insert cli2;
            
            Service_Billing_Schedule__c sbs = new Service_Billing_Schedule__c();
            sbs.Contract_Line_Item__c = cli2.Id;
            insert sbs;
            
            Entitlement ent = new Entitlement();
            ent.Name = 'Test Entitlement';
            ent.AccountId = custAccount.Id;
            ent.AssetId = asset2.Id;
            ent.StartDate = Date.today().addDays(-1);
            insert ent;
            
            asset2.Order_Line_Item__c = neworderitem1.id;
            asset2.Shipped_on_Date__c = Today;
            asset2.System_Account__c = null;
            try
            {
               update asset2; 
            }
            catch(Exception e)
            {
                system.debug('exception'+e);
            }
            assetList.add(asset2);
            
            //update assetList;
    
            Id asset2Id = asset2.Id;
         
            //Test.stopTest();
    
         
        }
    }
    
    static testMethod void test_updateAccountProductFamily(){
        doStaticSetup();
        
        TestUtility.insertCustSetting('AssetProductFamilyTrigger');
        
        //Create test data
        Account_Product_Family_Settings__c customSettingRecMap = new Account_Product_Family_Settings__c(Name='Coolers', Product_Family_Field__c = 'Coolers__c');
        insert customSettingRecMap;
        
        Account acc = custAccount;
        //acc.ParentId=acc.id;
        update acc;
        system.debug('**CustAcc**'+custAccount);
                system.debug('**Acc**'+acc);

        
      //  acc.Name = 'Test Account';
       // insert acc;
        
        Product2 prod = TestUtility.newProduct('Test Product');
        prod.Family = 'Coolers';
        insert prod;
        
        Asset asst = TestUtility.newAsset('Parent Asset', acc.Id, acc.Id, prod.Id);
        
        //Start test
        Test.startTest();
        
        //Insert asset
        insert asst;
        
        //Stop test
        Test.stopTest();
        
       
        //Validate data
        Account_Product_Family__c apf = [SELECT Id, Coolers__c FROM Account_Product_Family__c WHERE Account__c = :acc.Id];
        System.assertEquals(1, apf.Coolers__c);
        
        //Delete asset
        delete asst;
        
        //Validate data
        apf = [SELECT Id, Coolers__c FROM Account_Product_Family__c WHERE Account__c = :acc.Id];
        System.assertEquals(0, apf.Coolers__c);
        
        
    }
 
    static testMethod void testUpdateRelatedWorkOrders(){
        //Create test data
        TestUtility.setupConfigurationSettings();
        
        Account pacc = TestUtility.newAccount('Test Account', null);
        insert pacc;
        
        Account acc = TestUtility.newAccount('Test Account', null);
        acc.ParentId = pacc.Id;
        insert acc;
        
        Pricebook2 pb = TestUtility.newPricebook('Test Pricebook');
        insert pb;
        
        Product2 prod = TestUtility.newProduct('Test Product');
        insert prod;
        
        PricebookEntry pbe = TestUtility.newPricebookEntry(pb.Id, prod.Id, 100);
        insert pbe;
        
        Order ord = new Order();
        ord.AccountId = acc.Id;
        ord.EffectiveDate = Date.today();
        ord.Status = 'DRAFT';
        ord.Pricebook2Id = pb.Id;
        insert ord;
        
        OrderItem oi = new OrderItem();
        oi.OrderId = ord.Id;
        oi.PricebookEntryId = pbe.Id;
        oi.Quantity = 5;
        oi.UnitPrice = 27;
        insert oi;
        
        Asset asst0 = TestUtility.newAsset('Parent Asset', acc.Id, acc.Id, prod.Id);
        asst0.RecordTypeId = GlobalUtility.getRecordTypeId('Asset', 'System');
        insert asst0;
        
        Asset asst1 = TestUtility.newAsset('Parent Asset', acc.Id, acc.Id, prod.Id);
        insert asst1;
        
        WorkOrder wo = TestUtility.newWorkOrder(acc.Id, null, null);
        wo.Pricebook2Id = pb.Id;
        wo.StartDate = Date.today();
        wo.Order_Line_Item__c = oi.Id;
        insert wo;
        
        //Start test
        Test.startTest();
        
        //Update Asset
        asst0.Order_Line_Item__c = oi.Id;
        update asst0;
        
        //Stop test
        Test.stopTest();
        
        //Validate data
        System.assertEquals(asst0.Id, [SELECT AssetId FROM WorkOrder WHERE Id = :wo.Id].AssetId);
    }
    
}