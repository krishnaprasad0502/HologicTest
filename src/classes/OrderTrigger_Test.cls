/*------------------------------------------------------------
Author:         Marc Goldstein
Company:        Salesforce.com
Description:    Test class to validate AccountTrigger
                Tests Excecuted:
                
                insertOrderStreetAddress - verify that on insert of Order, the ShippingStreet are parsed out into the custom 1-3 fields
                
                updateOrderStreetAddress - verify that on update of Order, the custom 1-3 fields are updated to match what's in the ShippingStreet
                
                insertCustomerAddress - verify that on insert of Order, the Shipping Address is the SiteLocation's address
                
                insertUserAddress - verify that on insert of Order, the Shipping Address is the Owner's address
                
                updateRelatedCase_insert - verify that on insert of an Order not in 'Draft' status, the related Case.SYS_Has_Service_Orders_Not_Draft__c is set to true
                
                updateRelatedCase_update - verify that on update of an Order in 'Draft' status to another status, the related Case.SYS_Has_Service_Orders_Not_Draft__c is set to true
History:
<Date>          <Authors Name>      <Brief Description of Change>
08/09/2016      Marc Goldstein      Initial Creation
11/08/2016      Denise Bacher       Added unit tests for updateRelatedCase (US-0001169)
------------------------------------------------------------*/

//User and site location parts test needed
@isTest
private class OrderTrigger_Test {
    
    public static String streetLine = 'Line 1\nLine 2\nLine 3\nLine 4\nLine 5\nLine 6';
    private static Configuration_Settings__c orgDefaults;
    private static Account houseAccount;
    private static Account custAccount;
    private static Account siteAccount;
    private static Site_Location__c siteLocation;
    private static Product2 product;
    private static Pricebook2 pricebook;
    private static PricebookEntry pricebookEntry;
    private static WorkOrder aWorkOrder;
    private static Case aCase;
    private static Asset anAsset;
    private static Case_Effort_Validation_Status__c caseEffortVR;
    private static Account customerAccount;
    private static Product_Source_Division__c psd;
    private static Product2 prod;
   // private static Account siteAccount;
    private static List<Product2> products = new List<Product2>();
    private static List<Asset> assets = new List<Asset>();
    private static Map<Id, Id> assetToProduct = new Map<Id, Id>();
    private static List<Case> cases = new List<Case>();
    private static Contact defaultContact;
    private static Contact applicationContact;
    private static Contact connectivityContact;
    
    private static User integrationUser;
    private static User sysAdminUser;
    
    private static List<Pricebook2> pricebooks = new List<Pricebook2>();
    private static List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();
    private static Map<Id, Map<Id, PricebookEntry>> pricebookToProductToPricebookEntry = new Map<Id, Map<Id,PricebookEntry>>();
    
    private static Coverage_Group__c coverageGroup;
    private static List<Coverage_Group_Product__c> coverageGroupProducts = new List<Coverage_Group_Product__c>();
    private static List<Coverage_Template__c> coverageTemplates = new List<Coverage_Template__c>();
    private static List<Entitlement> entitlements = new List<Entitlement>();
    
    private static void doStaticSetup(){    
        orgDefaults = TestUtility.setupConfigurationSettings();
        TestUtility.insertAllTriggerCustSettings();
        
        caseEffortVR = TestUtility.caseEffortVR();
        insert caseEffortVR;
        
        // insert an accounts
        houseAccount = TestUtility.newAccount('House Account', 'houseAcc', 'Holgoic Street', null, GlobalUtility.getRecordTypeId('Account', 'Customer'));
        insert houseAccount;
        custAccount = TestUtility.newAccount('Customer Account', 'testCust', 'ABC Street', houseAccount.Id, GlobalUtility.getRecordTypeId('Account', 'Customer'));
        insert custAccount;
        
        orgDefaults.Default_B_SH_House_AccountId__c = houseAccount.Oracle_Party_Id__c;
        update orgDefaults;
    
        siteAccount = TestUtility.newAccount('Site Account', 'testSite', '100 Shipping Street', custAccount.Id, GlobalUtility.getRecordTypeId('Account', 'Site'));
        insert siteAccount;
        
        siteLocation = TestUtility.newSiteLocation('Site Location', '100 Shipping Street', 'Suite 2', '', ''
            , 'Philadelphia', 'PA','19107', 'US'
            , custAccount.oracle_party_id__c, siteaccount.Id, true);
        siteLocation.Bill_To__c = true;
        siteLocation.Ship_To__c = true;
        insert siteLocation;

        anAsset = TestUtility.newAsset('1234', siteLocation.Id, 'UnitTest Asset');
        insert anAsset;
        
        product = TestUtility.newProduct('Test Product');
        insert product;

        aCase = TestUtility.newCase(custAccount.Id, null, anAsset.Id, product.Id, GlobalUtility.getRecordTypeId('Case', 'B_SH_Service'), null, null, null, null);
        insert aCase;

        aWorkOrder = TestUtility.newWorkOrderWithAddress(custAccount.Id, aCase.Id, anAsset.Id, '100 Shipping Street', 'Philadelphia', '19107', 'PA','US');      
        insert aWorkOrder;
        
        pricebook = TestUtility.newPricebook('Test Pricebook');
        insert pricebook;
        
        pricebookEntry = TestUtility.newPricebookEntry(pricebook.Id, product.Id, 100);
        insert pricebookEntry;
         Product_Source_Division__c psd = TestUtility.newProductSourceDivision('1234','MAMMOGRAPHY');
        Insert psd;
        system.debug('psd===='+psd);
        Product_Source_Division__c psd1 = TestUtility.newProductSourceDivision('12345','MOLECULAR');
        Insert psd1;
         Product2 prod = TestUtility.newProduct('Prodrec');
        insert prod;
        for(Integer i = 0; i < 1; i++){
            products.add(TestUtility.newProduct('Product '+i));
            products[i].Product_Source_Division__c = psd.id;
            products[i].Replacement_Part__c = prod.id;
        }
        insert products;
        system.debug('products:::'+products);
        
        for(Product2 p : products){
            Asset a1=TestUtility.newAsset(siteAccount.Name + ' Asset ' + p.Name, siteAccount.Id, custAccount.Id,p.Id);
            //a1.ContactId= defaultContact.Id;
            assets.add(a1);
            
        }
        insert assets;
        
        for(Asset a : assets){
            assetToProduct.put(a.Id, a.Product2Id);
            cases.add(TestUtility.newCase(siteAccount.Id, null, a.Id, null,GlobalUtility.getRecordTypeId('Case','B_SH_Service'), 'Applications', 'New', 'Low', 'Phone'));
        }
        insert cases;
        system.debug('cases:::'+cases);
       

    }
    
    static private void setupPricebookRecords(){
        // create Price Book
        pricebooks.add(TestUtility.newPricebook('Test Pricebook1'));
        pricebooks.add(TestUtility.newPricebook('Test Pricebook2'));
        insert pricebooks;
        
        for(Pricebook2 pb : pricebooks){
            pricebookToProductToPricebookEntry.put(pb.Id, new Map<Id, PricebookEntry>());
        }
        
        // create Price Book entry
        for(Product2 p : products){
            PricebookEntry pbe1 = TestUtility.newPricebookEntry(pricebooks[0].Id, p.Replacement_Part__c, 500);
            PricebookEntry pbe2 = TestUtility.newPricebookEntry(pricebooks[1].Id, p.Id, 100);
            
            pricebookEntries.add(pbe1);
            pricebookEntries.add(pbe2);
            pricebookToProductToPricebookEntry.get(pricebooks[0].Id).put(p.id, pbe1);
            pricebookToProductToPricebookEntry.get(pricebooks[1].Id).put(p.Id, pbe2);
        }
        
        insert pricebookEntries;
         system.debug('pricebookEntries:::'+pricebookEntries);
        
    }
    
    static private void setupEntitlementRelatedRecords(){
        // create Business Hours
        BusinessHours businessHours = [Select Id, Name From BusinessHours Limit 1];
        System.assertNotEquals(null, businessHours, 'SETUP ERROR: test cannot proceed, no Business Hours were found.');
        
        // create Coverage Group
        coverageGroup = TestUtility.newCoverageGroup('Test Coverage Group');
        insert coverageGroup;
        
        // create Coverage Template
        Map<Id, List<Coverage_Template__c>> productToCoverageTemplate = new Map<Id, List<Coverage_Template__c>>();
        for(Integer i = 0; i < products.size(); i++){
            Product2 p = products[i];
            
            productToCoverageTemplate.put(p.Id, new List<Coverage_Template__c>());
            productToCoverageTemplate.get(p.Id).add(TestUtility.newCoverageTemplate(p.Name + ' PM', coverageGroup.Id,GlobalUtility.getRecordTypeId('Coverage_Template__c', 'B_SH_PM'), p.Id, null, null, String.valueOf(Math.mod(i, 5) + 1),null, null, null));
            productToCoverageTemplate.get(p.Id).add(TestUtility.newCoverageTemplate(p.Name + ' Discount', coverageGroup.Id,GlobalUtility.getRecordTypeId('Coverage_Template__c', 'B_SH_Discount'), p.Id, 20, null, String.valueOf(Math.mod(i, 5) + 1),null, null, null));
            productToCoverageTemplate.get(p.Id).add(TestUtility.newCoverageTemplate(p.Name + ' Max Amount',coverageGroup.Id, GlobalUtility.getRecordTypeId('Coverage_Template__c', 'B_SH_Discount'), p.Id, null, 50, String.valueOf(Math.mod(i, 5) + 1), null, null, null));
            productToCoverageTemplate.get(p.Id).add(TestUtility.newCoverageTemplate(p.Name + ' Other', coverageGroup.Id,GlobalUtility.getRecordTypeId('Coverage_Template__c', 'B_SH_Other'), p.Id, null, null, String.valueOf(Math.mod(i, 5) + 1),null, null, null));
            coverageTemplates.addAll(productToCoverageTemplate.get(p.Id));
            coverageGroupProducts.add(TestUtility.newCoverageGroupProduct(coverageGroup.Id, p.Id));
        }
        insert coverageTemplates;
        insert coverageGroupProducts;
        
        // create Entitlement
        for(Asset a : assets){
            List<Coverage_Template__c> prodCoverageTemplates = productToCoverageTemplate.get(a.Product2Id);
            for(Coverage_Template__c ct : prodCoverageTemplates){
                String recordTypeName = GlobalUtility.getRecordTypeDeveloperName('Coverage_Template__c', ct.RecordTypeId);
                 Entitlement e1 = TestUtility.newEntitlement(a.Name + ' ' + ct.Name, businessHours.Id, null, a.AccountId,a.Id, coverageGroup.Id, ct.Id, GlobalUtility.getRecordTypeId('Entitlement', recordTypeName), System.today().addDays(-30), System.today().addDays(365), 30, null);
                Entitlement e = TestUtility.newEntitlement(a.Name + ' ' + ct.Name, businessHours.Id, null, a.AccountId,a.Id, coverageGroup.Id, ct.Id, GlobalUtility.getRecordTypeId('Entitlement', recordTypeName), System.today().addDays(-30), System.today().addDays(365), null, 40);
                
                //e.Discount__c=10;
                 entitlements.add(e1);
                    entitlements.add(e);
                
            }
        }
        insert entitlements;
        system.debug(entitlements[0]);
    }
    
    static testMethod void updateRelatedCase_insert(){
        doStaticSetup();
        
        List<Case> cases = new List<Case>();
        for(Integer i = 0; i < 10; i++){
            cases.add(TestUtility.newCase(custAccount.Id, null, anAsset.Id, product.Id, GlobalUtility.getRecordTypeId('Case', 'B_SH_Service'), null, null, null, null));
        }
        insert cases;
        cases.add(aCase);
        
        List<Order> orderInserts = new List<Order>();
        for(Case c : cases){
            orderInserts.add(TestUtility.newOrder(siteAccount.Id, pricebook.Id, c.Id, GlobalUtility.getRecordTypeId('Order', 'B_SH_Service_Order'), 'CLOSED', 'Field Service', System.today()));
        }
        
        Test.startTest();
            insert orderInserts;
        Test.stopTest();
        
        cases = [Select Id, SYS_Has_Service_Orders_Not_Draft__c From Case];
       // System.assertEquals(200, cases.size());
        for(Case c : cases){
          //  System.assertEquals(true, c.SYS_Has_Service_Orders_Not_Draft__c);
        }
        
    }
    
    static testMethod void updateRelatedCase_update(){
        doStaticSetup();
        
        List<Case> cases = new List<Case>();
        for(Integer i = 0; i < 10; i++){
            cases.add(TestUtility.newCase(custAccount.Id, null, anAsset.Id, product.Id, GlobalUtility.getRecordTypeId('Case', 'B_SH_Service'), null, null, null, null));
        }
        insert cases;
        cases.add(aCase);
        
        List<Order> orderInserts = new List<Order>();
        for(Case c : cases){
            orderInserts.add(TestUtility.newOrder(siteAccount.Id, pricebook.Id, c.Id, GlobalUtility.getRecordTypeId('Order', 'B_SH_Service_Order'), 'DRAFT', 'Field Service', System.today()));
        }
        insert orderInserts;
        
        cases = [Select Id, SYS_Has_Service_Orders_Not_Draft__c From Case];
        //System.assertEquals(200, cases.size());
        for(Case c : cases){
            System.assertEquals(false, c.SYS_Has_Service_Orders_Not_Draft__c);
        }
        
        Test.startTest();
            for(Order o : orderInserts){
                o.Status = 'CLOSED';
            }
            update orderInserts;
        Test.stopTest();
        
        cases = [Select Id, SYS_Has_Service_Orders_Not_Draft__c From Case];
       // System.assertEquals(200, cases.size());
        for(Case c : cases){
         //   System.assertEquals(true, c.SYS_Has_Service_Orders_Not_Draft__c);
        }
    }
    
    static testMethod void testUpdateRelatedAssets(){
        //Create data
        TestUtility.setupConfigurationSettings();
        
        Account acc = TestUtility.newAccount('Test Account', null);
        insert acc;
        
        Product_Source_Division__c psd = new Product_Source_Division__c();
        psd.Name = '700';
        insert psd;
        
        Product2 prod = TestUtility.newProduct('Test Product');
        prod.Product_Source_Division__c = psd.Id;
        insert prod;
        
        Asset asst = TestUtility.newAsset('TestAsset', acc.Id, acc.Id, prod.Id);
        insert asst;
        
        Pricebook2 pb = TestUtility.newPricebook('Test Pricebook');
        insert pb;
        
        PricebookEntry pbe = TestUtility.newPricebookEntry(pb.Id, prod.Id, 100);
        insert pbe;
        
        Order ord = new Order();
        ord.AccountId = acc.Id;
        ord.Pricebook2Id = pb.Id;
        ord.EffectiveDate = Date.today();
        ord.Status = 'DRAFT';
        ord.RecordTypeId = GlobalUtility.getRecordTypeId('Order', 'B_SH_Service_Order');
        insert ord;
        
        OrderItem oi = new OrderItem();
        oi.OrderId = ord.Id;
        oi.PricebookEntryId = pbe.Id;
        oi.Quantity = -5;
        oi.UnitPrice = 27;
        oi.Returned_Asset__c = asst.Id;
        oi.Line_Type__c = 'RMA';
        insert oi;
        
        //Start test
        Test.startTest();
        
        //Update Order to ENTERED status
        ord.Status = 'ENTERED';
        update ord;
        
        //Stop test
        Test.stopTest();
        
        //Validate data
        asst = [
            SELECT Id
                  ,Status
              FROM Asset
             WHERE Id = :asst.Id
        ];
        System.assertEquals('PENDING RETURN', asst.Status);
    }
    
    static testMethod void testCreateWorkOrdersInstall(){
        //Create data
        orgDefaults = TestUtility.setupConfigurationSettings();
        
        Account acc = TestUtility.newAccount('Test Account', null);
        insert acc;
        
        Contact con = TestUtility.newContact('Test', 'Contact', acc.Id);
        
        Opportunity opp = TestUtility.newOpportunity('Test Opportunity', acc.Id, Date.today(), 'Qualification', null);
        opp.Mammography_MRI_Manager__c = con.Id;
        opp.IT_PACS_Administrator__c = con.Id;
        insert opp;
        
        SBQQ__Quote__c quot = new SBQQ__Quote__c();
        quot.SBQQ__Primary__c = true;
        quot.SBQQ__Opportunity2__c = opp.Id;
        insert quot;
        
        Pricebook2 pb = TestUtility.newPricebook('Test Pricebook');
        insert pb;
        
        orgDefaults.Service_Pricebook_USD__c = pb.Id;
        orgDefaults.Sales_Order_Record_Type_ID__c = [SELECT Id FROM RecordType WHERE SObjectType = 'Order' AND IsActive = true LIMIT 1].Id;
        orgDefaults.Install_Upgrade_WO_RecordTypeID__c = GlobalUtility.getRecordTypeId('WorkOrder', 'B_SH_FE_Install_Upgrade_Move');
        orgDefaults.Labor_WOLI_RecordTypeID__c = GlobalUtility.getRecordTypeId('WorkOrderLineItem', 'Labor');
        update orgDefaults;
        
        WorkType wtInstallParent = new WorkType();
        wtInstallParent.Name = 'Work Type Install Parent';
        wtInstallParent.EstimatedDuration = 8;
        insert wtInstallParent;
        
        WorkType wtInstallChild = new WorkType();
        wtInstallChild.Parent_Work_Type__c = wtInstallParent.Id;
        wtInstallChild.Name = 'Work Type Install Child';
        wtInstallChild.EstimatedDuration = 8;
        insert wtInstallChild;
        
        Product2 prodInstall = TestUtility.newProduct('Test Install Product');
        prodInstall.Install_Work_Type__c = wtInstallChild.Id;
        prodInstall.Install_Case_Required__c = true;
        insert prodInstall;
        
        Product2 prodMisc0 = TestUtility.newProduct('Test Product Misc 0');
        insert prodMisc0;
        
        Product2 prodMisc1 = TestUtility.newProduct('Test Product Misc 1');
        insert prodMisc1;
        
        Asset astInstall = TestUtility.newAsset('TestAsset', acc.Id, acc.Id, prodInstall.Id);
        insert astInstall;
        
        PricebookEntry pbeInstall = TestUtility.newPricebookEntry(pb.Id, prodInstall.Id, 100);
        insert pbeInstall;
        
        Site_Location__c loc = new Site_Location__c();
        loc.Account__c = acc.Id;
        loc.Name = 'Test Site Location';
        loc.Address_Line_1__c = '123';
        loc.City__c = 'Chicago';
        loc.State__c = 'IL';
        loc.Zip_Code__c = '60647';
        loc.Country__c = 'US';
        insert loc;
        
        SBQQ__QuoteLine__c parentQuoteLine1 = new SBQQ__QuoteLine__c();
        parentQuoteLine1.SBQQ__Quote__c = quot.Id;
        parentQuoteLine1.SBQQ__Product__c = prodInstall.Id;
        parentQuoteLine1.Order_Group_By__c = '1';
        insert parentQuoteLine1;
        
        Order ord = new Order();
        ord.RecordTypeId = GlobalUtility.getRecordTypeId('Order', 'Sales_Order');
        ord.AccountId = acc.Id;
        ord.OpportunityId = opp.Id;
        ord.EffectiveDate = Date.today();
        ord.Status = 'DRAFT';
        ord.Pricebook2Id = pb.Id;
        ord.SBQQ__Quote__c = quot.Id;
        insert ord;
        
        OrderItem oiInstall = new OrderItem();
        oiInstall.OrderId = ord.Id;
        oiInstall.PricebookEntryId = pbeInstall.Id;
        oiInstall.Quantity = 5;
        oiInstall.UnitPrice = 20;
        oiInstall.Request_Date__c = Date.today();
        oiInstall.Ship_To_Site_Location__c = loc.Id;
        oiInstall.SBQQ__Asset__c = astInstall.Id;
        insert oiInstall;
        
        //Start test
        Test.startTest();
        
        //Update Order to non-booked status
        ord.Status = 'ENTERED';
        update ord;
        
        //Update Order to booked status
        ord.Status = 'BOOKED';
        update ord;
        
        //Stop test
        Test.stopTest();
        
        //Validate data
        WorkOrder woInstall = [
            SELECT Id
                  ,AccountId
                  ,Street
                  ,City
                  ,StateCode
                  ,PostalCode
                  ,CountryCode
                  ,Pricebook2Id
                  ,Opportunity__c
                  ,ContactId
                  ,Subject
                  ,Description
                  ,Applications_Contact__c
                  ,Connectivity_Contact__c
                  ,WorkTypeId
                  ,Product__c
              FROM WorkOrder
             LIMIT 1
        ];
        System.assertEquals(loc.Address_Line_1__c                   , woInstall.Street);
        System.assertEquals(loc.City__c                             , woInstall.City);
        System.assertEquals(loc.State__c                            , woInstall.StateCode);
        System.assertEquals(loc.Zip_Code__c                         , woInstall.PostalCode);
        System.assertEquals(loc.Country__c                          , woInstall.CountryCode);
        System.assertEquals(pb.Id                                   , woInstall.Pricebook2Id);
        System.assertEquals(opp.Id                                  , woInstall.Opportunity__c);
        System.assertEquals(con.Id                                  , woInstall.Applications_Contact__c);
        System.assertEquals(con.Id                                  , woInstall.Connectivity_Contact__c);
        System.assertEquals(wtInstallChild.Id                       , woInstall.WorkTypeId);
        System.assertEquals(prodInstall.Id                          , woInstall.Product__c);
    }
    
    static testMethod void testCreateWorkOrdersUpgrade(){
        //Create data
        orgDefaults = TestUtility.setupConfigurationSettings();
        
        Account acc = TestUtility.newAccount('Test Account', null);
        insert acc;
        
        Contact con = TestUtility.newContact('Test', 'Contact', acc.Id);
        
        Opportunity opp = TestUtility.newOpportunity('Test Opportunity', acc.Id, Date.today(), 'Qualification', null);
        //opp.Additional_Primary_Contact__c = con.Id;
        opp.Mammography_MRI_Manager__c = con.Id;
        opp.IT_PACS_Administrator__c = con.Id;
        insert opp;
        
        Pricebook2 pb = TestUtility.newPricebook('Test Pricebook');
        insert pb;
        
        orgDefaults.Service_Pricebook_USD__c = pb.Id;
        orgDefaults.Sales_Order_Record_Type_ID__c = [SELECT Id FROM RecordType WHERE SObjectType = 'Order' AND IsActive = true LIMIT 1].Id;
        orgDefaults.Install_Upgrade_WO_RecordTypeID__c = GlobalUtility.getRecordTypeId('WorkOrder', 'B_SH_FE_Install_Upgrade_Move');
        orgDefaults.Labor_WOLI_RecordTypeID__c = GlobalUtility.getRecordTypeId('WorkOrderLineItem', 'Labor');
        update orgDefaults;
        
        WorkType wtInstallParent = new WorkType();
        wtInstallParent.Name = 'Work Type Install Parent';
        wtInstallParent.EstimatedDuration = 8;
        insert wtInstallParent;
        
        WorkType wtInstallChild = new WorkType();
        wtInstallChild.Parent_Work_Type__c = wtInstallParent.Id;
        wtInstallChild.Name = 'Work Type Install Child';
        wtInstallChild.EstimatedDuration = 8;
        insert wtInstallChild;
        
        Product2 prodInstall = TestUtility.newProduct('Test Install Product');
        prodInstall.Install_Work_Type__c = wtInstallChild.Id;
        prodInstall.Install_Case_Required__c = true;
        insert prodInstall;
        
        Asset astInstall = TestUtility.newAsset('TestAsset', acc.Id, acc.Id, prodInstall.Id);
        insert astInstall;
        
        PricebookEntry pbeInstall = TestUtility.newPricebookEntry(pb.Id, prodInstall.Id, 100);
        insert pbeInstall;
        
        Site_Location__c loc = new Site_Location__c();
        loc.Account__c = acc.Id;
        loc.Name = 'Test Site Location';
        loc.Address_Line_1__c = '123';
        loc.City__c = 'Chicago';
        loc.State__c = 'IL';
        loc.Zip_Code__c = '60647';
        loc.Country__c = 'US';
        insert loc;
        
        SBQQ__Quote__c quo1 = TestUtility.newQuote(acc.Id, opp.Id);
        insert quo1;
        
        SBQQ__QuoteLine__c qLine1 = TestUtility.newQuoteLine(quo1.Id, prodInstall.Id, 10, 10);
        qLine1.SBQQ__UpgradedAsset__c = astInstall.Id;
        insert qLine1;
        
        Order ord = new Order();
        ord.RecordTypeId = GlobalUtility.getRecordTypeId('Order', 'Sales_Order');
        ord.AccountId = acc.Id;
        ord.OpportunityId = opp.Id;
        ord.EffectiveDate = Date.today();
        ord.Status = 'DRAFT';
        ord.Pricebook2Id = pb.Id;
        insert ord;
        
        OrderItem oiUpgrade = new OrderItem();
        oiUpgrade.OrderId = ord.Id;
        oiUpgrade.PricebookEntryId = pbeInstall.Id;
        oiUpgrade.Quantity = 5;
        oiUpgrade.UnitPrice = 20;
        oiUpgrade.Request_Date__c = Date.today();
        oiUpgrade.Ship_To_Site_Location__c = loc.Id;
        oiUpgrade.SBQQ__Asset__c = astInstall.Id;
        oiUpgrade.Quote_Line__c = qLine1.Id;
        insert oiUpgrade;
        
        //Start test
        Test.startTest();
        
        //Update Order to non-booked status
        ord.Status = 'ENTERED';
        update ord;
        
        //Update Order to booked status
        ord.Status = 'BOOKED';
        update ord;
        
        //Stop test
        Test.stopTest();
        
        //Validate data
        WorkOrder woUpgrade = [
            SELECT Id
                  ,AccountId
                  ,Street
                  ,City
                  ,StateCode
                  ,PostalCode
                  ,CountryCode
                  ,Pricebook2Id
                  ,Opportunity__c
                  ,ContactId
                  ,Subject
                  ,Description
                  ,Applications_Contact__c
                  ,Connectivity_Contact__c
                  ,WorkTypeId
              FROM WorkOrder
             LIMIT 1
        ];
        System.assertEquals(loc.Address_Line_1__c                   , woUpgrade.Street);
        System.assertEquals(loc.City__c                             , woUpgrade.City);
        System.assertEquals(loc.State__c                            , woUpgrade.StateCode);
        System.assertEquals(loc.Zip_Code__c                         , woUpgrade.PostalCode);
        System.assertEquals(loc.Country__c                          , woUpgrade.CountryCode);
        System.assertEquals(pb.Id                                   , woUpgrade.Pricebook2Id);
        System.assertEquals(opp.Id                                  , woUpgrade.Opportunity__c);
        System.assertEquals(con.Id                                  , woUpgrade.Applications_Contact__c);
        System.assertEquals(con.Id                                  , woUpgrade.Connectivity_Contact__c);
        System.assertEquals(wtInstallChild.Id                      , woUpgrade.WorkTypeId);
    }
    
    static testMethod void testCreateWorkOrdersTradeIn(){
        //Create data
        orgDefaults = TestUtility.setupConfigurationSettings();
        
        Account acc = TestUtility.newAccount('Test Account', null);
        insert acc;
        
        Contact con = TestUtility.newContact('Test', 'Contact', acc.Id);
        
        Opportunity opp = TestUtility.newOpportunity('Test Opportunity', acc.Id, Date.today(), 'Qualification', null);
        //opp.Additional_Primary_Contact__c = con.Id;
        opp.Mammography_MRI_Manager__c = con.Id;
        opp.IT_PACS_Administrator__c = con.Id;
        insert opp;
        
        Pricebook2 pb = TestUtility.newPricebook('Test Pricebook');
        insert pb;
        
        orgDefaults.Service_Pricebook_USD__c = pb.Id;
        orgDefaults.Sales_Order_Record_Type_ID__c = [SELECT Id FROM RecordType WHERE SObjectType = 'Order' AND IsActive = true LIMIT 1].Id;
        orgDefaults.Install_Upgrade_WO_RecordTypeID__c = GlobalUtility.getRecordTypeId('WorkOrder', 'B_SH_FE_Install_Upgrade_Move');
        orgDefaults.Labor_WOLI_RecordTypeID__c = GlobalUtility.getRecordTypeId('WorkOrderLineItem', 'Labor');
        update orgDefaults;
        
        WorkType wtInstallParent = new WorkType();
        wtInstallParent.Name = 'Work Type Install Parent';
        wtInstallParent.EstimatedDuration = 8;
        insert wtInstallParent;
        
        WorkType wtInstallChild = new WorkType();
        wtInstallChild.Parent_Work_Type__c = wtInstallParent.Id;
        wtInstallChild.Name = 'Work Type Install Child';
        wtInstallChild.EstimatedDuration = 8;
        insert wtInstallChild;
        
        Product2 prodInstall = TestUtility.newProduct('Test Install Product');
        prodInstall.Install_Work_Type__c = wtInstallChild.Id;
        prodInstall.Install_Case_Required__c = true;
        insert prodInstall;
        
        Asset astInstall = TestUtility.newAsset('TestAsset', acc.Id, acc.Id, prodInstall.Id);
        insert astInstall;
        
        PricebookEntry pbeInstall = TestUtility.newPricebookEntry(pb.Id, prodInstall.Id, 100);
        insert pbeInstall;
        
        Site_Location__c loc = new Site_Location__c();
        loc.Account__c = acc.Id;
        loc.Name = 'Test Site Location';
        loc.Address_Line_1__c = '123';
        loc.City__c = 'Chicago';
        loc.State__c = 'IL';
        loc.Zip_Code__c = '60647';
        loc.Country__c = 'US';
        insert loc;
        
        SBQQ__Quote__c quo2 = TestUtility.newQuote(acc.Id, opp.Id);
        insert quo2;
        
        SBQQ__QuoteLine__c qLine2 = TestUtility.newQuoteLine(quo2.Id, prodInstall.Id, 10, 10);
        qLine2.Account__c = acc.Id;
        qLine2.Trade_In_Asset__c = astInstall.Id;
        qLine2.Trade_In_Product__c = true;
        insert qLine2;
        
        Order ord = new Order();
        ord.RecordTypeId = GlobalUtility.getRecordTypeId('Order', 'Sales_Order');
        ord.AccountId = acc.Id;
        ord.OpportunityId = opp.Id;
        ord.EffectiveDate = Date.today();
        ord.Status = 'DRAFT';
        ord.Pricebook2Id = pb.Id;
        insert ord;
        
        OrderItem oiTradeIn = new OrderItem();
        oiTradeIn.OrderId = ord.Id;
        oiTradeIn.PricebookEntryId = pbeInstall.Id;
        oiTradeIn.Quantity = 5;
        oiTradeIn.UnitPrice = 20;
        oiTradeIn.Request_Date__c = Date.today();
        oiTradeIn.Ship_To_Site_Location__c = loc.Id;
        oiTradeIn.SBQQ__Asset__c = astInstall.Id;
        oiTradeIn.Quote_Line__c = qLine2.Id;
        insert oiTradeIn;
        
        //Start test
        Test.startTest();
        
        //Update Order to non-booked status
        ord.Status = 'ENTERED';
        update ord;
        
        //Update Order to booked status
        ord.Status = 'BOOKED';
        update ord;
        
        //Stop test
        Test.stopTest();
        
        //Validate data
        WorkOrder woTradeIn = [
            SELECT Id
                  ,AccountId
                  ,Street
                  ,City
                  ,StateCode
                  ,PostalCode
                  ,CountryCode
                  ,Pricebook2Id
                  ,Opportunity__c
                  ,ContactId
                  ,Subject
                  ,Description
                  ,Applications_Contact__c
                  ,Connectivity_Contact__c
                  ,WorkTypeId
              FROM WorkOrder
        ];
        System.assertEquals(loc.Address_Line_1__c                   , woTradeIn.Street);
        System.assertEquals(loc.City__c                             , woTradeIn.City);
        System.assertEquals(loc.State__c                            , woTradeIn.StateCode);
        System.assertEquals(loc.Zip_Code__c                         , woTradeIn.PostalCode);
        System.assertEquals(loc.Country__c                          , woTradeIn.CountryCode);
        System.assertEquals(pb.Id                                   , woTradeIn.Pricebook2Id);
        System.assertEquals(opp.Id                                  , woTradeIn.Opportunity__c);
        System.assertEquals(con.Id                                  , woTradeIn.Applications_Contact__c);
        System.assertEquals(con.Id                                  , woTradeIn.Connectivity_Contact__c);
        System.assertEquals(wtInstallChild.Id                      , woTradeIn.WorkTypeId);
    }
    
    static testMethod void testCreateWorkOrdersClinical(){
        //Create data
        orgDefaults = TestUtility.setupConfigurationSettings();
        
        Account acc = TestUtility.newAccount('Test Account', null);
        insert acc;
        
        Contact con = TestUtility.newContact('Test', 'Contact', acc.Id);
        
        Opportunity opp = TestUtility.newOpportunity('Test Opportunity', acc.Id, Date.today(), 'Qualification', null);
        //opp.Additional_Primary_Contact__c = con.Id;
        opp.Mammography_MRI_Manager__c = con.Id;
        opp.IT_PACS_Administrator__c = con.Id;
        insert opp;
        
        Pricebook2 pb = TestUtility.newPricebook('Test Pricebook');
        insert pb;
        
        orgDefaults.Service_Pricebook_USD__c = pb.Id;
        orgDefaults.Sales_Order_Record_Type_ID__c = [SELECT Id FROM RecordType WHERE SObjectType = 'Order' AND IsActive = true LIMIT 1].Id;
        orgDefaults.Install_Upgrade_WO_RecordTypeID__c = GlobalUtility.getRecordTypeId('WorkOrder', 'B_SH_FE_Install_Upgrade_Move');
        orgDefaults.Clinical_WO_RecordTypeID__c = GlobalUtility.getRecordTypeId('WorkOrder', 'B_SH_Applications');
        orgDefaults.Labor_WOLI_RecordTypeID__c = GlobalUtility.getRecordTypeId('WorkOrderLineItem', 'Labor');
        update orgDefaults;
        
        WorkType wtInstallParent = new WorkType();
        wtInstallParent.Name = 'Work Type Install Parent';
        wtInstallParent.EstimatedDuration = 8;
        insert wtInstallParent;
        
        WorkType wtInstallChild = new WorkType();
        wtInstallChild.Parent_Work_Type__c = wtInstallParent.Id;
        wtInstallChild.Name = 'Work Type Install Child';
        wtInstallChild.EstimatedDuration = 8;
        insert wtInstallChild;
        
        WorkType wtClinicalParent = new WorkType();
        wtClinicalParent.Name = 'Work Type Clinical Parent';
        wtClinicalParent.EstimatedDuration = 8;
        insert wtClinicalParent;
        
        WorkType wtClinicalChild = new WorkType();
        wtClinicalChild.Parent_Work_Type__c = wtClinicalParent.Id;
        wtClinicalChild.Name = 'Work Type Clinical Child';
        wtClinicalChild.EstimatedDuration = 8;
        insert wtClinicalChild;
        
        Product2 prodClinical = TestUtility.newProduct('Test Clinical Product');
        prodClinical.Install_Work_Type__c = wtInstallChild.Id;
        prodClinical.Clinical_Work_Type__c = wtClinicalChild.Id;
        prodClinical.Install_Case_Required__c = true;
        insert prodClinical;
        
        Asset astClinical = TestUtility.newAsset('TestAsset', acc.Id, acc.Id, prodClinical.Id);
        insert astClinical;
        
        PricebookEntry pbeClinical = TestUtility.newPricebookEntry(pb.Id, prodClinical.Id, 100);
        insert pbeClinical;
        
        Site_Location__c loc = new Site_Location__c();
        loc.Account__c = acc.Id;
        loc.Name = 'Test Site Location';
        loc.Address_Line_1__c = '123';
        loc.City__c = 'Chicago';
        loc.State__c = 'IL';
        loc.Zip_Code__c = '60647';
        loc.Country__c = 'US';
        insert loc;
        
        Order ord = new Order();
        ord.RecordTypeId = GlobalUtility.getRecordTypeId('Order', 'Sales_Order');
        ord.AccountId = acc.Id;
        //ord.OpportunityId = opp.Id;
        ord.EffectiveDate = Date.today();
        ord.Status = 'DRAFT';
        ord.Pricebook2Id = pb.Id;
        insert ord;
        
        OrderItem oiClinical = new OrderItem();
        oiClinical.OrderId = ord.Id;
        oiClinical.PricebookEntryId = pbeClinical.Id;
        oiClinical.Quantity = 5;
        oiClinical.UnitPrice = 20;
        oiClinical.Request_Date__c = Date.today();
        oiClinical.Ship_To_Site_Location__c = loc.Id;
        oiClinical.SBQQ__Asset__c = astClinical.Id;
        insert oiClinical;
        
        //Start test
        Test.startTest();
        
        //Update Order to non-booked status
        ord.Status = 'ENTERED';
        update ord;
        
        //Update Order to booked status
        ord.Status = 'BOOKED';
        update ord;
        
        //Stop test
        Test.stopTest();
        
        //Validate data
        WorkOrder woClinical = [
            SELECT Id
                  ,AccountId
                  ,Street
                  ,City
                  ,StateCode
                  ,PostalCode
                  ,CountryCode
                  ,Pricebook2Id
                  ,Opportunity__c
                  ,ContactId
                  ,Subject
                  ,Description
                  ,Applications_Contact__c
                  ,Connectivity_Contact__c
                  ,WorkTypeId
                  ,ParentWorkOrderId
              FROM WorkOrder
             WHERE RecordType.DeveloperName = 'B_SH_Applications'
             LIMIT 1
        ];
        System.assertEquals(loc.Address_Line_1__c                   , woClinical.Street);
        System.assertEquals(loc.City__c                             , woClinical.City);
        System.assertEquals(loc.State__c                            , woClinical.StateCode);
        System.assertEquals(loc.Zip_Code__c                         , woClinical.PostalCode);
        System.assertEquals(loc.Country__c                          , woClinical.CountryCode);
        System.assertEquals(pb.Id                                   , woClinical.Pricebook2Id);
        //System.assertEquals(opp.Id                                  , woClinical.Opportunity__c);
        System.assertEquals(con.Id                                  , woClinical.Applications_Contact__c);
        System.assertEquals(con.Id                                  , woClinical.Connectivity_Contact__c);
        System.assertNotEquals(null                                 , woClinical.ParentWorkOrderId);
    }
    
    static testMethod void testCreateWorkOrdersPreceptorship(){
        //Create data
        orgDefaults = TestUtility.setupConfigurationSettings();
        
        Account acc = TestUtility.newAccount('Test Account', null);
        insert acc;
        
        Contact con = TestUtility.newContact('Test', 'Contact', acc.Id);
        
        Opportunity opp = TestUtility.newOpportunity('Test Opportunity', acc.Id, Date.today(), 'Qualification', null);
        //opp.Additional_Primary_Contact__c = con.Id;
        opp.Mammography_MRI_Manager__c = con.Id;
        opp.IT_PACS_Administrator__c = con.Id;
        insert opp;
        
        Pricebook2 pb = TestUtility.newPricebook('Test Pricebook');
        insert pb;
        
        orgDefaults.Service_Pricebook_USD__c = pb.Id;
        orgDefaults.Sales_Order_Record_Type_ID__c = [SELECT Id FROM RecordType WHERE SObjectType = 'Order' AND IsActive = true LIMIT 1].Id;
        orgDefaults.Clinical_WO_RecordTypeID__c = GlobalUtility.getRecordTypeId('WorkOrder', 'B_SH_Applications');
        orgDefaults.Labor_WOLI_RecordTypeID__c = GlobalUtility.getRecordTypeId('WorkOrderLineItem', 'Labor');
        update orgDefaults;
        
        WorkType wtPreceptorshipParent = new WorkType();
        wtPreceptorshipParent.Name = 'Work Type Preceptorship Parent';
        wtPreceptorshipParent.EstimatedDuration = 8;
        insert wtPreceptorshipParent;
        
        WorkType wtPreceptorshipChild = new WorkType();
        wtPreceptorshipChild.Parent_Work_Type__c = wtPreceptorshipParent.Id;
        wtPreceptorshipChild.Name = 'Work Type Preceptorship Child';
        wtPreceptorshipChild.EstimatedDuration = 8;
        insert wtPreceptorshipChild;
        
        Product2 prodPreceptorship = TestUtility.newProduct('Test Preceptorship Product');
        prodPreceptorship.Preceptorship_Work_Type__c = wtPreceptorshipChild.Id;
        prodPreceptorship.Preceptorship_Case_Required__c = true;
        insert prodPreceptorship;
        
        Asset astPreceptorship = TestUtility.newAsset('TestAsset', acc.Id, acc.Id, prodPreceptorship.Id);
        insert astPreceptorship;
        
        PricebookEntry pbePreceptorship = TestUtility.newPricebookEntry(pb.Id, prodPreceptorship.Id, 100);
        insert pbePreceptorship;
        
        Site_Location__c loc = new Site_Location__c();
        loc.Account__c = acc.Id;
        loc.Name = 'Test Site Location';
        loc.Address_Line_1__c = '123';
        loc.City__c = 'Chicago';
        loc.State__c = 'IL';
        loc.Zip_Code__c = '60647';
        loc.Country__c = 'US';
        insert loc;
        
        Order ord = new Order();
        ord.RecordTypeId = GlobalUtility.getRecordTypeId('Order', 'Sales_Order');
        ord.AccountId = acc.Id;
        //ord.OpportunityId = opp.Id;
        ord.EffectiveDate = Date.today();
        ord.Status = 'DRAFT';
        ord.Pricebook2Id = pb.Id;
        insert ord;
        
        OrderItem oiPreceptorship = new OrderItem();
        oiPreceptorship.OrderId = ord.Id;
        oiPreceptorship.PricebookEntryId = pbePreceptorship.Id;
        oiPreceptorship.Quantity = 5;
        oiPreceptorship.UnitPrice = 20;
        oiPreceptorship.Request_Date__c = Date.today();
        oiPreceptorship.Ship_To_Site_Location__c = loc.Id;
        oiPreceptorship.SBQQ__Asset__c = astPreceptorship.Id;
        insert oiPreceptorship;
        
        //Start test
        Test.startTest();
        
        //Update Order to non-booked status
        ord.Status = 'ENTERED';
        update ord;
        
        //Update Order to booked status
        ord.Status = 'BOOKED';
        update ord;
        
        //Stop test
        Test.stopTest();
        
        //Validate data
        WorkOrder woPreceptorship = [
            SELECT Id
                  ,AccountId
                  ,Street
                  ,City
                  ,StateCode
                  ,PostalCode
                  ,CountryCode
                  ,Pricebook2Id
                  ,Opportunity__c
                  ,ContactId
                  ,Subject
                  ,Description
                  ,Applications_Contact__c
                  ,Connectivity_Contact__c
                  ,WorkTypeId
              FROM WorkOrder
        ];
        System.assertEquals(loc.Address_Line_1__c                   , woPreceptorship.Street);
        System.assertEquals(loc.City__c                             , woPreceptorship.City);
        System.assertEquals(loc.State__c                            , woPreceptorship.StateCode);
        System.assertEquals(loc.Zip_Code__c                         , woPreceptorship.PostalCode);
        System.assertEquals(loc.Country__c                          , woPreceptorship.CountryCode);
        System.assertEquals(pb.Id                                   , woPreceptorship.Pricebook2Id);
        //System.assertEquals(opp.Id                                  , woPreceptorship.Opportunity__c);
        System.assertEquals(con.Id                                  , woPreceptorship.Applications_Contact__c);
        System.assertEquals(con.Id                                  , woPreceptorship.Connectivity_Contact__c);
    }
    
    private static testMethod void testServiceOrderFromQuote() {                
        orgDefaults = TestUtility.setupConfigurationSettings();
                        
        TestUtility.insertCustSetting('OrderTrigger');

        Account acc = TestUtility.newAccount('Test Account', null);
        acc.BillingCountry = 'United States';
        acc.Oracle_Customer_Number__c = '999999';
        insert acc;
                
        Pricebook2 pb = TestUtility.newPricebook('Test Pricebook');
        insert pb;        
        
        orgDefaults.Service_Pricebook_USD__c = pb.Id;
        orgDefaults.Sales_Pricebook_USD__c = pb.id;
        orgDefaults.Service_Pricebook_CAD__c = pb.id;
        orgDefaults.Standard_Pricebook__c = pb.id;
        update orgDefaults;        
                        
        Opportunity opp = TestUtility.newOpportunity('Test Opportunity', acc.Id, System.Today(), 'Target', 'Omitted');
        opp.Pricebook2Id = pb.id;
        opp.SBQQ__QuotePricebookId__c = pb.id;
        insert opp;
                                
        Product2 prod1 = TestUtility.newProduct('Disposable Product No Service Subscription');
        prod1.Quote_Product_Type__c = 'DISPOSABLE';
        prod1.Service_Subscription__c = false;
        insert prod1;

        PricebookEntry pbe1 = TestUtility.newPricebookEntry(pb.Id, prod1.Id, 100);
        insert pbe1;
        
        Product2 prod2 = TestUtility.newProduct('Non-Disposable Product');
        prod2.Quote_Product_Type__c = 'EQUIPMENT';
        prod2.Service_Subscription__c = false;
        insert prod2;

        PricebookEntry pbe2 = TestUtility.newPricebookEntry(pb.Id, prod2.Id, 5000);
        insert pbe2;
        
        Product2 prod3 = TestUtility.newProduct('Disposable Product with Service Subscription');
        prod3.Quote_Product_Type__c = 'DISPOSABLE';
        prod3.Service_Subscription__c = true;
        insert prod3;
        
        PricebookEntry pbe3 = TestUtility.newPricebookEntry(pb.Id, prod3.Id, 200);
        insert pbe3;

        Product2 prod4 = TestUtility.newProduct('Disposable Product No Service Subscription Two');
        prod4.Quote_Product_Type__c = 'DISPOSABLE';
        prod4.Service_Subscription__c = false;
        insert prod4;

        PricebookEntry pbe4 = TestUtility.newPricebookEntry(pb.Id, prod4.Id, 125);
        insert pbe4;        
        
        SBQQ__Quote__c quote1 = new SBQQ__Quote__c();
        RecordType recTypeQuote = [SELECT ID FROM RecordType WHERE sObjectType = 'SBQQ__Quote__c' AND Name = 'Draft' LIMIT 1];  
        quote1.Quote_Name__c = 'Test Quote';
        quote1.SBQQ__Opportunity2__c = opp.id;
        quote1.RecordTypeId = recTypeQuote.ID;        
        quote1.SBQQ__Account__c = acc.id;        
        quote1.SBQQ__PriceBook__c = pb.id;
        quote1.SBQQ__Primary__c = true;
        insert quote1;               
        
        List<SBQQ__QuoteLine__c> quoteLines = new List<SBQQ__QuoteLine__c>();        
        // INSERT MULTIPLE QUOTE LINES ( MUST BE SINGLE INSERT )
        //newQuoteLine(QuoteID, ProductID, ListPrice, Quantity)
        SBQQ__QuoteLine__c qLine1 = TestUtility.newQuoteLine(quote1.Id, prod1.Id, 100.75, 10);        
        SBQQ__QuoteLine__c qLine2 = TestUtility.newQuoteLine(quote1.Id, prod2.Id, 50.99, 1);        
        SBQQ__QuoteLine__c qLine3 = TestUtility.newQuoteLine(quote1.Id, prod3.Id, 200.01, 3);
        quoteLines.add(qLine1);
        quoteLines.add(qLine2);
        quoteLines.add(qLine3);        
        insert quoteLines;
        
        Order ord = new Order();        
        RecordType recTypeOrder = [SELECT ID FROM RecordType WHERE sObjectType = 'Order' AND Name = 'Service Order' LIMIT 1];  
        ord.RecordTypeId = recTypeOrder.ID;
        ord.AccountId = quote1.SBQQ__Account__c;
        ord.OpportunityId = opp.Id;
        ord.Bill_To_Account__c = quote1.Bill_To_Account__c;
        ord.Bill_To_Site_Location__c = quote1.BillTo_Site__c;
        ord.EffectiveDate = Date.today();
        ord.Name = 'Consumable Order for Quote: ' + quote1.Name;
        ord.Pricebook2Id = pb.Id;
        ord.Ship_To_Account__c = quote1.Ship_To_Account__c;
        ord.Ship_To_Site_Location__c = quote1.ShipTo_Site__c;
        ord.Status = 'DRAFT';
        ord.SBQQ__Quote__c = quote1.id;
        ord.Owner_Oracle_Customer_Number__c = quote1.SBQQ__Account__r.Oracle_Customer_Number__c;
        ord.Type = 'Standard Order';        
        
        Test.startTest();
        
        insert ord;

        Test.stopTest();
        
        List<OrderItem> ordItm = [SELECT AvailableQuantity, Description, EndDate, Id, ListPrice, OrderId, OrderItemNumber, OriginalOrderItemId, 
                                  PricebookEntryId, Product2Id, Quantity, Quote_Line__c
                                  FROM OrderItem 
                                  WHERE OrderId =: ord.id];
        Integer cntLns = -1;
        if (ordItm != NULL) {
            cntLns = ordItm.size();
            System.assertEquals(1, cntLns);
            OrderItem oi = ordItm[0];
            System.assertEquals(qLine1.SBQQ__Product__c, oi.Product2Id);
            System.assertEquals(qLine1.SBQQ__Quantity__c, oi.Quantity);
        } else {
            System.assert(false);
        }        
    }
    
    static testMethod void testCreateWorkOrdersAdvancedExchange(){
        //Create data
        orgDefaults = TestUtility.setupConfigurationSettings();
        
        Account acc = TestUtility.newAccount('Test Account', null);
        insert acc;
        
        Contact con = TestUtility.newContact('Test', 'Contact', acc.Id);
        
        Opportunity opp = TestUtility.newOpportunity('Test Opportunity', acc.Id, Date.today(), 'Qualification', null);
        opp.Mammography_MRI_Manager__c = con.Id;
        opp.IT_PACS_Administrator__c = con.Id;
        insert opp;
        
        SBQQ__Quote__c quot = new SBQQ__Quote__c();
        quot.SBQQ__Primary__c = true;
        quot.SBQQ__Opportunity2__c = opp.Id;
        insert quot;
        
        Pricebook2 pb = TestUtility.newPricebook('Test Pricebook');
        insert pb;
        
        orgDefaults.Service_Pricebook_USD__c = pb.Id;
        orgDefaults.Sales_Order_Record_Type_ID__c = [SELECT Id FROM RecordType WHERE SObjectType = 'Order' AND IsActive = true LIMIT 1].Id;
        orgDefaults.Install_Upgrade_WO_RecordTypeID__c = GlobalUtility.getRecordTypeId('WorkOrder', 'B_SH_FE_Install_Upgrade_Move');
        orgDefaults.Labor_WOLI_RecordTypeID__c = GlobalUtility.getRecordTypeId('WorkOrderLineItem', 'Labor');
        update orgDefaults;
        
        WorkType wtInstallParent = new WorkType();
        wtInstallParent.Name = 'Work Type Install Parent';
        wtInstallParent.EstimatedDuration = 8;
        insert wtInstallParent;
        
        WorkType wtInstallChild = new WorkType();
        wtInstallChild.Parent_Work_Type__c = wtInstallParent.Id;
        wtInstallChild.Name = 'Work Type Install Child';
        wtInstallChild.EstimatedDuration = 8;
        insert wtInstallChild;
        
        Product2 prodInstall = TestUtility.newProduct('Test Install Product');
        prodInstall.Install_Work_Type__c = wtInstallChild.Id;
        prodInstall.Install_Case_Required__c = true;
        insert prodInstall;
        
        Product2 prodMisc0 = TestUtility.newProduct('Test Product Misc 0');
        insert prodMisc0;
        
        Product2 prodMisc1 = TestUtility.newProduct('Test Product Misc 1');
        insert prodMisc1;
        
        Asset astInstall = TestUtility.newAsset('TestAsset', acc.Id, acc.Id, prodInstall.Id);
        insert astInstall;
        
        PricebookEntry pbeInstall = TestUtility.newPricebookEntry(pb.Id, prodInstall.Id, 100);
        insert pbeInstall;
        
        Site_Location__c loc = new Site_Location__c();
        loc.Account__c = acc.Id;
        loc.Name = 'Test Site Location';
        loc.Address_Line_1__c = '123';
        loc.City__c = 'Chicago';
        loc.State__c = 'IL';
        loc.Zip_Code__c = '60647';
        loc.Country__c = 'US';
        insert loc;
        
        SBQQ__QuoteLine__c parentQuoteLine1 = new SBQQ__QuoteLine__c();
        parentQuoteLine1.SBQQ__Quote__c = quot.Id;
        parentQuoteLine1.SBQQ__Product__c = prodInstall.Id;
        parentQuoteLine1.Order_Group_By__c = '1';
        insert parentQuoteLine1;
        
        Order ord = new Order();
        ord.RecordTypeId = GlobalUtility.getRecordTypeId('Order', 'B_SH_Service_Order_RO');
        ord.Type = 'Advanced Exchange';
        ord.AccountId = acc.Id;
        ord.OpportunityId = opp.Id;
        ord.EffectiveDate = Date.today();
        ord.Status = 'DRAFT';
        ord.Pricebook2Id = pb.Id;
        ord.SBQQ__Quote__c = quot.Id;
        insert ord;
        
        OrderItem oiInstall = new OrderItem();
        oiInstall.Line_Type__c = 'Shipment';
        oiInstall.OrderId = ord.Id;
        oiInstall.PricebookEntryId = pbeInstall.Id;
        oiInstall.Quantity = 5;
        oiInstall.UnitPrice = 20;
        oiInstall.Request_Date__c = Date.today();
        oiInstall.SBQQ__Asset__c = astInstall.Id;
        oiInstall.Returned_Asset__c = astInstall.Id;
        insert oiInstall;
        
        //Start test
        Test.startTest();
        
        //Update Order to non-booked status
        ord.Status = 'ENTERED';
        update ord;
        
        //Update Order to booked status
        ord.Status = 'BOOKED';
        update ord;
        
        //Stop test
        Test.stopTest();
        
        //Validate data
        WorkOrder woInstall = [
            SELECT Id
                  ,AccountId
                  ,Street
                  ,City
                  ,StateCode
                  ,PostalCode
                  ,CountryCode
                  ,Pricebook2Id
                  ,Opportunity__c
                  ,ContactId
                  ,Subject
                  ,Description
                  ,Applications_Contact__c
                  ,Connectivity_Contact__c
                  ,WorkTypeId
                  ,Product__c
              FROM WorkOrder
             LIMIT 1
        ];
        System.assertEquals(acc.Id                                  , woInstall.AccountId);
        System.assertEquals(pb.Id                                   , woInstall.Pricebook2Id);
        System.assertEquals(opp.Id                                  , woInstall.Opportunity__c);
        System.assertEquals(con.Id                                  , woInstall.Applications_Contact__c);
        System.assertEquals(con.Id                                  , woInstall.Connectivity_Contact__c);
        System.assertEquals(wtInstallChild.Id                       , woInstall.WorkTypeId);
        System.assertEquals(prodInstall.Id                          , woInstall.Product__c);
    }

    
}