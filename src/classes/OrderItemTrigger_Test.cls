/*------------------------------------------------------------
Author:         Denise Bacher
Company:        Salesforce.com
Description:    Test class to validate OrderItemTrigger
                Tests Excecuted:
                
                setEntitlementAndUnitPrice_insert - verify that on insert of a OrderItem, the entitlement and unit price are set
                
                setEntitlementAndUnitPrice_insertHologicOwned - verify that on insert of a OrderItem where the asset is owned by Hologic, no entitlement is set and unit price is 0
                
                preventDML_integrationUserInsert - run insert as an Integration User, where Order RT is Parts RO, Service RO, Sales
                
                preventDML_integrationUserUpdate - run update as an Integration User, where Order RT is Parts RO, Service RO, Sales
                
                preventDML_integrationUserDelete - run delete as an Integration User, where Order RT is Parts RO, Service RO, Sales
                
                preventDML_systemAdminInsert - run insert as a System Administrator, where Order RT is Parts RO, Service RO, Sales
                
                preventDML_systemAdminUpdate - run update as a System Administrator, where Order RT is Parts RO, Service RO, Sales
                
                preventDML_systemAdminAllowUpdate - run update as a System Administrator, where Order RT is Parts RO, Service RO, Sales, but case field is updated
                
                preventDML_systemAdminDelete - run delete as a System Administrator, where Order RT is Parts RO, Service RO, Sales
History:
<Date>          <Authors Name>      <Brief Description of Change>
07/22/2016      Denise Bacher       Initial Creation (US1387)
08/09/2016      Denise Bacher       Added preventDML (US1448)
05/12/2017      Amarendra Nagireddy Updated the record type from 'B_SH_Sales_Order' to 'Sales_Order' Merged this test class in to OrderItemTriggerActions_Test(US-0002638)
07/14/2017      Kasmoor Reddy       Added logic for creating the product source divison record by new method for TestUtility class (US3025)
------------------------------------------------------------*/
@isTest
private class OrderItemTrigger_Test {
    private static Account customerAccount;
    private static Product_Source_Division__c psd;
    private static Product2 prod;
    private static Account siteAccount;
    private static List<Product2> products = new List<Product2>();
    private static List<Asset> assets = new List<Asset>();
    private static Map<Id, Id> assetToProduct = new Map<Id, Id>();
    private static List<Case> cases = new List<Case>();
    private static Contact defaultContact;
    private static Contact applicationContact;
    private static Contact connectivityContact;
    
    //private static User integrationUser;
    //private static User sysAdminUser;
    
    private static List<Pricebook2> pricebooks = new List<Pricebook2>();
    private static List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();
    private static Map<Id, Map<Id, PricebookEntry>> pricebookToProductToPricebookEntry = new Map<Id, Map<Id,PricebookEntry>>();
    
    private static Coverage_Group__c coverageGroup;
    private static List<Coverage_Group_Product__c> coverageGroupProducts = new List<Coverage_Group_Product__c>();
    private static List<Coverage_Template__c> coverageTemplates = new List<Coverage_Template__c>();
    private static List<Entitlement> entitlements = new List<Entitlement>();
    
    static {
        TestUtility.setupConfigurationSettings();
        TestUtility.insertAllTriggerCustSettings();
        
        // 05-08-2017-(Amarendra Nagireddy)-Added trigger switch to run case and product related triggers while inserting the test records (US-0002505)
        TestUtility.insertCustSetting('OrderLineProductReplacement'); 
        TestUtility.insertCustSetting('CaseTrigger');         
        
        //integrationUser = TestUtility.newUser([Select Id From Profile Where Name = 'Integration API User' Limit 1].Id,'tstother');
        //sysAdminUser = TestUtility.newUser([Select Id From Profile Where Name = 'System Administrator' Limit 1].Id,'tstadmin');
        //insert new List<User>{integrationUser, sysAdminUser};
        
        customerAccount = TestUtility.newAccount('Customer Account', 'testCust', null, null, GlobalUtility.getRecordTypeId('Account', 'Customer'));
        insert customerAccount;
        
        siteAccount = TestUtility.newAccount('Site Account', 'testSite', 'ABC Street', customerAccount.Id,GlobalUtility.getRecordTypeId('Account', 'Site'));
        insert siteAccount;
        
        //create Contact
        defaultContact = TestUtility.newContact('Default', 'Contact', customerAccount.Id);
        applicationContact = TestUtility.newContact('Application', 'Contact', customerAccount.Id);
        connectivityContact = TestUtility.newContact('Connectivity', 'Contact', customerAccount.Id);
        insert new List<Contact>{defaultContact, applicationContact, connectivityContact};
        //07/14/2017-(Kasmoor Reddy)- created a new product source division record from new method in TestUtility class as part of US-00003025.
        Product_Source_Division__c psd = TestUtility.newProductSourceDivision('1234','MAMMOGRAPHY');
        psd.Sunshine_Act__c =true;
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
            Asset a1=TestUtility.newAsset(siteAccount.Name + ' Asset ' + p.Name, siteAccount.Id, customerAccount.Id,p.Id);
            a1.ContactId= defaultContact.Id;
            assets.add(a1);
            
        }
        insert assets;
        
        for(Asset a : assets){
            assetToProduct.put(a.Id, a.Product2Id);
          /*  case cc = new case();
             cc.AccountId = siteAccount.Id;
            cc.ContactId = null;
            cc.AssetId = a.id;
            cc.ProductId = null;
          // cc.RecordTypeId = GlobalUtility.getRecordTypeId('Case','B_SH_Service');
           cc.Type = 'Applications';
            cc.Status = 'New';
           cc.Priority = 'Low';
            cc.Origin = 'Phone';
            cc.Billable__c = false;
            cc.Bill_to_Customer__c =customerAccount.id;
            cases.add(cc); */
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
            PricebookEntry pbe1 = TestUtility.newPricebookEntry(pricebooks[0].Id, p.Id, 500);
            PricebookEntry pbe2 = TestUtility.newPricebookEntry(pricebooks[1].Id, p.Id, 100);
            
            pricebookEntries.add(pbe1);
            pricebookEntries.add(pbe2);
            pricebookToProductToPricebookEntry.get(pricebooks[0].Id).put(p.Id, pbe1);
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
                Entitlement e = TestUtility.newEntitlement(a.Name + ' ' + ct.Name, businessHours.Id, null, a.AccountId,a.Id, coverageGroup.Id, ct.Id, GlobalUtility.getRecordTypeId('Entitlement', recordTypeName), System.today().addDays(-30), System.today().addDays(365), (Double)ct.Discount__c, (Double)ct.Max_Covered_Amount__c);
                entitlements.add(e);
            }
        }
        insert entitlements;
    }
    
    static testMethod void setEntitlementAndUnitPrice_insert(){
        setupPricebookRecords();
        setupEntitlementRelatedRecords();
        
        Integer i = 0;
        Map<Id, Id> caseToAsset = new Map<Id, Id>();
        List<Order> orderList = new List<Order>();
        for(Case c : cases){
            caseToAsset.put(c.Id, c.AssetId);
            for(Pricebook2 pb : pricebooks){
               Integer mathModI = Math.mod(i, 3);
                if(mathModI == 0){
                    orderList.add(TestUtility.newOrder(siteAccount.Id, pb.Id, c.Id, GlobalUtility.getRecordTypeId('Order','B_SH_Service_Order'), 'DRAFT','Field Service',  System.today()));
                }
                else if(mathModI == 1){
                    orderList.add(TestUtility.newOrder(siteAccount.Id, pb.Id, c.Id, GlobalUtility.getRecordTypeId('Order','B_SH_Service_Order'), 'DRAFT','Field Service', System.today()));
                }
                else if(mathModI == 2){
                    orderList.add(TestUtility.newOrder(siteAccount.Id, pb.Id, c.Id, GlobalUtility.getRecordTypeId('Order','B_SH_Service_Order'), 'DRAFT','Field Service', System.today()));
                }
                
                i++;
            }
        }
        system.debug('orderList:in::'+orderList);
        insert orderList;
        system.debug('orderList:out::'+orderList);
        
        List<OrderItem> orderItems = new List<OrderItem>();
        for(Order o : orderList){
            OrderItem orderItem = TestUtility.newOrderItem(o.Id, null, pricebookToProductToPricebookEntry.get(o.Pricebook2Id).get(assetToProduct.get(caseToAsset.get(o.Case__c))).Id,1, 1);
            orderItems.add(orderItem);
            orderItems[0].Line_Type__c = 'Shipment';
            system.debug('PROID:in::'+pricebookToProductToPricebookEntry.get(o.Pricebook2Id).get(assetToProduct.get(caseToAsset.get(o.Case__c))).Id);
            system.debug('***cadeid:'+ o.Case__c);
        }
        
        Test.startTest();
          
         system.debug('orderItems:in::'+orderItems);
            insert orderItems;
         system.debug('orderItems:out::'+orderItems);
        Test.stopTest();
        
        List<OrderItem> postInsertOrderItems = [Select Id, OrderId, Entitlement__c, Entitlement__r.Name, UnitPrice,Net_Price__c From OrderItem];
        //System.assertEquals(200, postInsertOrderItems.size());
        for(OrderItem orderItem : postInsertOrderItems){
            //System.assertNotEquals(null, orderItem.Entitlement__c);
            if(orderItem.Entitlement__c != null){
                if(orderItem.Entitlement__r.Name.contains('Discount')){
                    //System.assertEquals(400, orderItem.UnitPrice);
                }
                else{
                   // System.assertEquals(50, orderItem.UnitPrice);
                }
            }
            //System.assertEquals(orderItem.UnitPrice, orderItem.Net_Price__c);
        }
    }
    
    static testMethod void setEntitlementAndUnitPrice_insertHologicOwned(){
        setupPricebookRecords();
        setupEntitlementRelatedRecords();
        
        insert TestUtility.newInternalAccount('testCust');
        
        Integer i = 0;
        Map<Id, Id> caseToAsset = new Map<Id, Id>();
        List<Order> orderList = new List<Order>();
        for(Case c : cases){
            caseToAsset.put(c.Id, c.AssetId);
            for(Pricebook2 pb : pricebooks){
                Integer mathModI = Math.mod(i, 3);
                //updated valid record types
                if(mathModI == 0){
                    orderList.add(TestUtility.newOrder(siteAccount.Id, pb.Id, c.Id, GlobalUtility.getRecordTypeId('Order','B_SH_Parts_Order'), 'DRAFT','Field Service', System.today()));
                }
                else if(mathModI == 1){
                    orderList.add(TestUtility.newOrder(siteAccount.Id, pb.Id, c.Id, GlobalUtility.getRecordTypeId('Order','B_SH_Service_Order'),'DRAFT','Field Service', System.today()));
                }
                else if(mathModI == 2){
                    orderList.add(TestUtility.newOrder(siteAccount.Id, pb.Id, c.Id, GlobalUtility.getRecordTypeId('Order','B_SH_Service_Order'),'DRAFT','Field Service', System.today()));
                }
                
                i++;
            }
        }
        insert orderList;
        
        List<OrderItem> orderItems = new List<OrderItem>();
        for(Order o : orderList){
            OrderItem orderItem = TestUtility.newOrderItem(o.Id, null, pricebookToProductToPricebookEntry.get(o.Pricebook2Id).get(assetToProduct.get(caseToAsset.get(o.Case__c))).Id, 1, 1);
            orderItems.add(orderItem);
        }
        
        Test.startTest();
            insert orderItems;
        Test.stopTest();
        
        List<OrderItem> postInsertOrderItems = [Select Id, OrderId, Entitlement__c, Entitlement__r.Name, UnitPrice,Net_Price__c From OrderItem];
        //System.assertEquals(200, postInsertOrderItems.size());
        for(OrderItem orderItem : postInsertOrderItems){
            //System.assertEquals(null, orderItem.Entitlement__c);
            //System.assertEquals(0, orderItem.UnitPrice);
            //System.assertEquals(0, orderItem.Net_Price__c);
        }
    }
    
    /*static testMethod void testSunShine(){
    
        setupPricebookRecords();
        
        Order ord = TestUtility.newOrder(customerAccount.Id, pricebooks[0].Id, null, GlobalUtility.getRecordTypeId('Order','B_SH_Parts_Order'), 'DRAFT','Field Service', System.today());
        insert ord;
        
        
        OrderItem orderItem = TestUtility.newOrderItem(ord.Id, null, 1, 1);
        
        Test.startTest();
        insert orderItem;
        Test.stopTest();
        
    }*/
    /*
    static testMethod void preventDML_integrationUserInsert(){
        setupPricebookRecords();
        
        Integer i = 0;
        Map<Id, Id> caseToAsset = new Map<Id, Id>();
        List<Order> orderList = new List<Order>();
        for(Case c : cases){
            caseToAsset.put(c.Id, c.AssetId);
            for(Pricebook2 pb : pricebooks){
                Integer mathModI = Math.mod(i, 3);
                //updated valid record types
                if(mathModI == 0){
                    orderList.add(TestUtility.newOrder(siteAccount.Id, pb.Id, c.Id, GlobalUtility.getRecordTypeId('Order','B_SH_Service_Order_RO'), 'DRAFT','Field Service', System.today()));
                }
                else if(mathModI == 1){
                    orderList.add(TestUtility.newOrder(siteAccount.Id, pb.Id, c.Id, GlobalUtility.getRecordTypeId('Order','B_SH_Parts_Order_RO'), 'DRAFT','Field Service', System.today()));
                }
                //12/05/2017 Amarendra Nagireddy Updated the record type from 'B_SH_Sales_Order' to 'Sales_Order' Merged this test class in to OrderItemTriggerActions_Test(US-0002638)

                else if(mathModI == 2){
                    orderList.add(TestUtility.newOrder(siteAccount.Id, pb.Id, c.Id, GlobalUtility.getRecordTypeId('Order','Sales_Order'), 'DRAFT', null, System.today()));
                }
                
                i++;
            }
        }
        
        System.runAs(integrationUser) {
            insert orderList;
            
            List<OrderItem> orderItems = new List<OrderItem>();
            for(Order o : orderList){
                OrderItem orderItem = TestUtility.newOrderItem(o.Id, null, pricebookToProductToPricebookEntry.get(o.Pricebook2Id).get(assetToProduct.get(caseToAsset.get(o.Case__c))).Id, 1, 0);
                orderItems.add(orderItem);
            }
            
            Test.startTest();
                insert orderItems;
            Test.stopTest();
        }
        
        List<OrderItem> postOrderItems = [Select Id From OrderItem];
        //System.assertEquals(200, postOrderItems.size());
    }
    
    static testMethod void preventDML_integrationUserUpdate(){
        setupPricebookRecords();
        
        Integer i = 0;
        Map<Id, Id> caseToAsset = new Map<Id, Id>();
        List<Order> orderList = new List<Order>();
        for(Case c : cases){
            caseToAsset.put(c.Id, c.AssetId);
            for(Pricebook2 pb : pricebooks){
                Integer mathModI = Math.mod(i, 3);
                //updated valid record types
                if(mathModI == 0){
                    orderList.add(TestUtility.newOrder(siteAccount.Id, pb.Id, c.Id, GlobalUtility.getRecordTypeId('Order','B_SH_Service_Order_RO'), 'Draft', 'Customer', System.today()));
                }
                else if(mathModI == 1){
                    orderList.add(TestUtility.newOrder(siteAccount.Id, pb.Id, c.Id, GlobalUtility.getRecordTypeId('Order','B_SH_Parts_Order_RO'), 'Draft', 'Move', System.today()));
                }
               // 12/05/2017 Amarendra Nagireddy Updated the record type from 'B_SH_Sales_Order' to 'Sales_Order' Merged this test class in to OrderItemTriggerActions_Test(US-0002638)

                else if(mathModI == 2){
                    orderList.add(TestUtility.newOrder(siteAccount.Id, pb.Id, c.Id, GlobalUtility.getRecordTypeId('Order','Sales_Order'), 'Draft', null, System.today()));
                }
                
                i++;
            }
        }
        
        System.runAs(integrationUser) {
            insert orderList;
            
            List<OrderItem> orderItems = new List<OrderItem>();
            for(Order o : orderList){
                OrderItem orderItem = TestUtility.newOrderItem(o.Id, null, pricebookToProductToPricebookEntry.get(o.Pricebook2Id).get(assetToProduct.get(caseToAsset.get(o.Case__c))).Id, 1, 0);
                orderItems.add(orderItem);
            }
            insert orderItems;
            
            Test.startTest();
                update orderItems;
            Test.stopTest();
        }
        
        List<OrderItem> postOrderItems = [Select Id From OrderItem];
        //System.assertEquals(200, postOrderItems.size());
    }
    
    static testMethod void preventDML_integrationUserDelete(){
        setupPricebookRecords();
        
        Integer i = 0;
        Map<Id, Id> caseToAsset = new Map<Id, Id>();
        List<Order> orderList = new List<Order>();
        for(Case c : cases){
            caseToAsset.put(c.Id, c.AssetId);
            for(Pricebook2 pb : pricebooks){
                Integer mathModI = Math.mod(i, 2);
                //updated valid record types
                if(mathModI == 0){
                    orderList.add(TestUtility.newOrder(siteAccount.Id, pb.Id, c.Id, GlobalUtility.getRecordTypeId('Order','B_SH_Service_Order_RO'), 'Draft', 'Customer', System.today()));
                }
                else if(mathModI == 1){
                    orderList.add(TestUtility.newOrder(siteAccount.Id, pb.Id, c.Id, GlobalUtility.getRecordTypeId('Order','B_SH_Parts_Order_RO'), 'Draft', 'Move', System.today()));
                }
                //12/05/2017 Amarendra Nagireddy Updated the record type from 'B_SH_Sales_Order' to 'Sales_Order' Merged this test class in to OrderItemTriggerActions_Test(US-0002638)

                else if(mathModI == 2){
                    orderList.add(TestUtility.newOrder(siteAccount.Id, pb.Id, c.Id, GlobalUtility.getRecordTypeId('Order','Sales_Order'), 'Draft', null, System.today()));
                }
                
                i++;
            }
        }
        
        System.runAs(integrationUser) {
            insert orderList;
          
            
            List<OrderItem> orderItems = new List<OrderItem>();
            for(Order o : orderList){
                OrderItem orderItem = TestUtility.newOrderItem(o.Id, null, pricebookToProductToPricebookEntry.get(o.Pricebook2Id).get(assetToProduct.get(caseToAsset.get(o.Case__c))).Id, 1, 0);
                orderItems.add(orderItem);
            }
            
            
            
            Test.startTest();
                insert orderItems;
                delete orderItems;
            Test.stopTest();
        }
        
        List<OrderItem> postOrderItems = [Select Id From OrderItem];
        //System.assertEquals(0, postOrderItems.size());
    }
    
    static testMethod void preventDML_systemAdminInsert(){
        setupPricebookRecords();
        
        Integer i = 0;
        Map<Id, Id> caseToAsset = new Map<Id, Id>();
        List<Order> orderList = new List<Order>();
        for(Case c : cases){
            caseToAsset.put(c.Id, c.AssetId);
            for(Pricebook2 pb : pricebooks){
                Integer mathModI = Math.mod(i, 3);
                //updated valid record types
                if(mathModI == 0){
                    orderList.add(TestUtility.newOrder(siteAccount.Id, pb.Id, c.Id, GlobalUtility.getRecordTypeId('Order','B_SH_Service_Order_RO'), 'Draft', 'Customer', System.today()));
                }
                else if(mathModI == 1){
                    orderList.add(TestUtility.newOrder(siteAccount.Id, pb.Id, c.Id, GlobalUtility.getRecordTypeId('Order','B_SH_Parts_Order_RO'), 'Draft', 'Move', System.today()));
                }
                //12/05/2017 Amarendra Nagireddy Updated the record type from 'B_SH_Sales_Order' to 'Sales_Order' Merged this test class in to OrderItemTriggerActions_Test(US-0002638)

                else if(mathModI == 2){
                    orderList.add(TestUtility.newOrder(siteAccount.Id, pb.Id, c.Id, GlobalUtility.getRecordTypeId('Order','Sales_Order'), 'Draft', null, System.today()));
                }
                
                i++;
            }
        }
        
        System.runAs(integrationUser) {
            insert orderList;
        }
            
        List<OrderItem> orderItems = new List<OrderItem>();
        for(Order o : orderList){
            OrderItem orderItem = TestUtility.newOrderItem(o.Id, null, pricebookToProductToPricebookEntry.get(o.Pricebook2Id).get(assetToProduct.get(caseToAsset.get(o.Case__c))).Id, 1, 0);
            orderItems.add(orderItem);
        }
        
        System.runAs(sysAdminUser) { 
            OrderItemTriggerActions.userProfile = null;
            Test.startTest();
                try{
                    insert orderItems;
                    //System.assert(false, 'Insert: Should not be here.');
                }
                catch(Exception e){}
            Test.stopTest();
        }
        
        List<OrderItem> postOrderItems = [Select Id From OrderItem];
       // System.assertEquals(0, postOrderItems.size());
    }
    
    static testMethod void preventDML_systemAdminUpdate(){
        setupPricebookRecords();
        
        Integer i = 0;
        Map<Id, Id> caseToAsset = new Map<Id, Id>();
        List<Order> orderList = new List<Order>();
        for(Case c : cases){
            caseToAsset.put(c.Id, c.AssetId);
            for(Pricebook2 pb : pricebooks){
                Integer mathModI = Math.mod(i, 3);
                //updated valid record types
                if(mathModI == 0){
                    orderList.add(TestUtility.newOrder(siteAccount.Id, pb.Id, c.Id, GlobalUtility.getRecordTypeId('Order','B_SH_Service_Order_RO'), 'Draft', 'Customer', System.today()));
                }
                else if(mathModI == 1){
                    orderList.add(TestUtility.newOrder(siteAccount.Id, pb.Id, c.Id, GlobalUtility.getRecordTypeId('Order','B_SH_Parts_Order_RO'), 'Draft', 'Move', System.today()));
                }
                //12/05/2017 Amarendra Nagireddy Updated the record type from 'B_SH_Sales_Order' to 'Sales_Order' Merged this test class in to OrderItemTriggerActions_Test(US-0002638)

                else if(mathModI == 2){
                    orderList.add(TestUtility.newOrder(siteAccount.Id, pb.Id, c.Id, GlobalUtility.getRecordTypeId('Order','Sales_Order'), 'Draft', null, System.today()));
                }
                
                i++;
            }
        }
        
        List<OrderItem> orderItems = new List<OrderItem>();
        System.runAs(integrationUser) {
            insert orderList;
            
            for(Order o : orderList){
                OrderItem orderItem = TestUtility.newOrderItem(o.Id, null, pricebookToProductToPricebookEntry.get(o.Pricebook2Id).get(assetToProduct.get(caseToAsset.get(o.Case__c))).Id, 1, 0);
                orderItems.add(orderItem);
            }
            insert orderItems;
        }
            
        System.runAs(sysAdminUser) { 
            OrderItemTriggerActions.userProfile = null;
            Test.startTest();
                try{
                    update orderItems;
                    //System.assert(false, 'Update: Should not be here.');
                }
                catch(Exception e){}
            Test.stopTest();
        }
        
        List<OrderItem> postOrderItems = [Select Id From OrderItem];
       // System.assertEquals(200, postOrderItems.size());
    }
    
    static testMethod void preventDML_systemAdminAllowUpdate(){
        setupPricebookRecords();
        
        Integer i = 0;
        Map<Id, Id> caseToAsset = new Map<Id, Id>();
        List<Order> orderList = new List<Order>();
        for(Case c : cases){
            caseToAsset.put(c.Id, c.AssetId);
            for(Pricebook2 pb : pricebooks){
                Integer mathModI = Math.mod(i, 3);
                //updated valid record types
                if(mathModI == 0){
                    orderList.add(TestUtility.newOrder(siteAccount.Id, pb.Id, c.Id, GlobalUtility.getRecordTypeId('Order','B_SH_Service_Order_RO'), 'Draft', 'Customer', System.today()));
                }
                else if(mathModI == 1){
                    orderList.add(TestUtility.newOrder(siteAccount.Id, pb.Id, c.Id, GlobalUtility.getRecordTypeId('Order','B_SH_Parts_Order_RO'), 'Draft', 'Move', System.today()));
                }
                //12/05/2017 Amarendra Nagireddy Updated the record type from 'B_SH_Sales_Order' to 'Sales_Order' Merged this test class in to OrderItemTriggerActions_Test(US-0002638)

                else if(mathModI == 2){
                    orderList.add(TestUtility.newOrder(siteAccount.Id, pb.Id, c.Id, GlobalUtility.getRecordTypeId('Order','Sales_Order'), 'Draft', null, System.today()));
                }
                
                i++;
            }
        }
        
        List<OrderItem> orderItems = new List<OrderItem>();
        System.runAs(integrationUser) {
            insert orderList;
            
            for(Order o : orderList){
                OrderItem orderItem = TestUtility.newOrderItem(o.Id, null, pricebookToProductToPricebookEntry.get(o.Pricebook2Id).get(assetToProduct.get(caseToAsset.get(o.Case__c))).Id, 1, 0);
                orderItems.add(orderItem);
            }
            insert orderItems;
        }
            
        System.runAs(sysAdminUser) { 
            OrderItemTriggerActions.userProfile = null;
            Test.startTest();
                try{
                    for(OrderItem oi : orderItems){
                        oi.Case__c = cases[0].Id;
                    }
                    
                    update orderItems;
                }
                catch(Exception e){
                    System.assert(false, 'Allow Update: Should not be here.');
                }
            Test.stopTest();
        }
        
        List<OrderItem> postOrderItems = [Select Id From OrderItem];
       // System.assertEquals(200, postOrderItems.size());
    }
    
    static testMethod void preventDML_systemAdminDelete(){
        setupPricebookRecords();
        
        Integer i = 0;
        Map<Id, Id> caseToAsset = new Map<Id, Id>();
        List<Order> orderList = new List<Order>();
        for(Case c : cases){
            caseToAsset.put(c.Id, c.AssetId);
            for(Pricebook2 pb : pricebooks){
                Integer mathModI = Math.mod(i, 3);
                //updated valid record types
                if(mathModI == 0){
                    orderList.add(TestUtility.newOrder(siteAccount.Id, pb.Id, c.Id, GlobalUtility.getRecordTypeId('Order','B_SH_Service_Order_RO'), 'Draft', 'Customer', System.today()));
                }
                else if(mathModI == 1){
                    orderList.add(TestUtility.newOrder(siteAccount.Id, pb.Id, c.Id, GlobalUtility.getRecordTypeId('Order','B_SH_Parts_Order_RO'), 'Draft', 'Move', System.today()));
                }
                //12/05/2017 Amarendra Nagireddy Updated the record type from 'B_SH_Sales_Order' to 'Sales_Order' Merged this test class in to OrderItemTriggerActions_Test(US-0002638)

                else if(mathModI == 2){
                    orderList.add(TestUtility.newOrder(siteAccount.Id, pb.Id, c.Id, GlobalUtility.getRecordTypeId('Order','Sales_Order'), 'Draft', null, System.today()));
                }
                
                i++;
            }
        }
        
        List<OrderItem> orderItems = new List<OrderItem>();
        System.runAs(integrationUser) {
            insert orderList;
            
            for(Order o : orderList){
                OrderItem orderItem = TestUtility.newOrderItem(o.Id, null, pricebookToProductToPricebookEntry.get

(o.Pricebook2Id).get(assetToProduct.get(caseToAsset.get(o.Case__c))).Id, 1, 0);
                orderItems.add(orderItem);
            }
            insert orderItems;
        }
            
        System.runAs(sysAdminUser) { 
            OrderItemTriggerActions.userProfile = null;
            Test.startTest();
                try{
                    delete orderItems;
                    //System.assert(false, 'Delete: Should not be here.');
                }
                catch(Exception e){}
            Test.stopTest();
        }
        
        List<OrderItem> postOrderItems = [Select Id From OrderItem];
       // System.assertEquals(200, postOrderItems.size());
    }
    */
    static testMethod void testCreateWorkOrders(){
        //Create data
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
        
        Configuration_Settings__c orgDefaults = Configuration_Settings__c.getInstance();
        orgDefaults.Service_Pricebook_USD__c = pb.Id;
        orgDefaults.Sales_Order_Record_Type_ID__c = [SELECT Id FROM RecordType WHERE SObjectType = 'Order' AND IsActive = true LIMIT 1].Id;
        orgDefaults.Install_Upgrade_WO_RecordTypeID__c = GlobalUtility.getRecordTypeId('WorkOrder', 'B_SH_FE_Install_Upgrade_Move');
        orgDefaults.Clinical_WO_RecordTypeID__c = GlobalUtility.getRecordTypeId('WorkOrder', 'B_SH_Applications');
        orgDefaults.Labor_WOLI_RecordTypeID__c = GlobalUtility.getRecordTypeId('WorkOrderLineItem', 'Labor');
        insert orgDefaults;
        
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
        
        Product2 prodInstall = TestUtility.newProduct('Test Install Product');
        prodInstall.Install_Work_Type__c = wtInstallChild.Id;
        prodInstall.Install_Case_Required__c = true;
        insert prodInstall;
        
        Product2 prodClinical = TestUtility.newProduct('Test Clinical Product');
        prodClinical.Clinical_Work_Type__c = wtClinicalChild.Id;
        prodClinical.Install_Case_Required__c = true;
        insert prodClinical;
        
        Asset astInstall = TestUtility.newAsset('TestAsset', acc.Id, acc.Id, prodInstall.Id);
        insert astInstall;
        
        Asset astClinical = TestUtility.newAsset('TestAsset', acc.Id, acc.Id, prodClinical.Id);
        insert astClinical;
        
        PricebookEntry pbeInstall = TestUtility.newPricebookEntry(pb.Id, prodInstall.Id, 100);
        insert pbeInstall;
        
        PricebookEntry pbeClinical = TestUtility.newPricebookEntry(pb.Id, prodClinical.Id, 100);
        insert pbeClinical;
        
        Site_Location__c loc = new Site_Location__c();
        loc.Account__c = acc.Id;
        loc.Name = 'Test Site Location';
        loc.Address_Line_1__c = '123';
        //loc.Address_Line_2__c = 'Main St';
        //loc.Address_Line_3__c = 'Apt 4';
        loc.City__c = 'Chicago';
        loc.State__c = 'IL';
        loc.Zip_Code__c = '60647';
        loc.Country__c = 'US';
        insert loc;
        
        Order ord = new Order();
        ord.RecordTypeId = Configuration_Settings__c.getInstance().Sales_Order_Record_Type_ID__c;
        ord.AccountId = acc.Id;
        ord.EffectiveDate = Date.today();
        ord.Status = 'BOOKED';
        ord.Pricebook2Id = pb.Id;
        insert ord;
        
        List<OrderItem> oisToInsert = new List<OrderItem>();
        
        OrderItem oiInstall = new OrderItem();
        oiInstall.OrderId = ord.Id;
        oiInstall.PricebookEntryId = pbeInstall.Id;
        oiInstall.Quantity = 5;
        oiInstall.UnitPrice = 20;
        oiInstall.Request_Date__c = Date.today();
        oiInstall.Ship_To_Site_Location__c = loc.Id;
        oiInstall.SBQQ__Asset__c = astInstall.Id;
        oisToInsert.add(oiInstall);
        
        OrderItem oiClinical = new OrderItem();
        oiClinical.OrderId = ord.Id;
        oiClinical.PricebookEntryId = pbeClinical.Id;
        oiClinical.Quantity = 5;
        oiClinical.UnitPrice = 20;
        oiClinical.Request_Date__c = Date.today();
        oiClinical.Ship_To_Site_Location__c = loc.Id;
        oiClinical.SBQQ__Asset__c = astClinical.Id;
        oisToInsert.add(oiClinical);
        
        //Start test
        Test.startTest();
        
        insert oisToInsert;
        
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
              FROM WorkOrder
             WHERE WorkTypeId = :wtInstallChild.Id
             LIMIT 1
        ];
        System.assertEquals(loc.Address_Line_1__c                   , woInstall.Street);
        System.assertEquals(loc.City__c                             , woInstall.City);
        System.assertEquals(loc.State__c                            , woInstall.StateCode);
        System.assertEquals(loc.Zip_Code__c                         , woInstall.PostalCode);
        System.assertEquals(loc.Country__c                          , woInstall.CountryCode);
        System.assertEquals(pb.Id                                   , woInstall.Pricebook2Id);
        System.assertEquals(con.Id                                  , woInstall.Applications_Contact__c);
        System.assertEquals(con.Id                                  , woInstall.Connectivity_Contact__c);
        System.assertEquals(wtInstallChild.Id                       , woInstall.WorkTypeId);
        
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
              FROM WorkOrder
             WHERE WorkTypeId = :wtClinicalChild.Id
             LIMIT 1
        ];
        System.assertEquals(loc.Address_Line_1__c                   , woClinical.Street);
        System.assertEquals(loc.City__c                             , woClinical.City);
        System.assertEquals(loc.State__c                            , woClinical.StateCode);
        System.assertEquals(loc.Zip_Code__c                         , woClinical.PostalCode);
        System.assertEquals(loc.Country__c                          , woClinical.CountryCode);
        System.assertEquals(pb.Id                                   , woClinical.Pricebook2Id);
        System.assertEquals(con.Id                                  , woClinical.Applications_Contact__c);
        System.assertEquals(con.Id                                  , woClinical.Connectivity_Contact__c);
        System.assertEquals(wtClinicalChild.Id                      , woClinical.WorkTypeId);
    }   
}