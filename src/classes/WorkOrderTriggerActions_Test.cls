/*------------------------------------------------------------
Author          Dave Mansell
Company:        Salesforce.com
Description:    Tests functions related to WorkOrder records

History:
<Date           <Authors Name       <Brief Description of Change>
04/09/2018      Dave Mansell        Initial Creation (US-0004278)
06/25/2018      Rob Strickler       Adding test for Matching parent ServiceAppointment status with WO status 
------------------------------------------------------------*/

@isTest
private class WorkOrderTriggerActions_Test {
    private static final String TEST_ZIP                        = '60606';
    private static final String TEST_STATE                      = 'IL';
    private static final String TEST_COUNTRY                    = 'US';
    private static final String TEST_DIVISION                   = 'Breast Skeletal Health';
    private static final String TEST_SERVICE_TERRITORY_TYPE     = 'Clinical';
    private static final Double TEST_UNIT_PRICE                 = 27;
    private static final Double TEST_QUANTITY                   = 45;
    static void  WorkOrderTriggerActions_Test (){
     list<WoSa_Status__mdt> CustomMetas = new list<WoSa_Status__mdt>();
        WoSa_Status__mdt cmdt123 = new WoSa_Status__mdt();
        cmdt123.MasterLabel = 'New';
        cmdt123.DeveloperName    = 'New';
        cmdt123.Object_id__c = '0WO';
        cmdt123.SA_Status__c = 'None';
        cmdt123.WO_Status__c = 'Closed';       
        CustomMetas.add(cmdt123);
        
        
        string jsonstr = JSON.serialize(CustomMetas);
        Context_Test.WoSaStatusData = (List<WoSa_Status__mdt>) JSON.deserialize(jsonstr , list<WoSa_Status__mdt>.class );

    }
    private static testMethod void testCheckToSetOwnership() {
        //Create test data
        TestUtility.setupConfigurationSettings();
        
        Account acc = TestUtility.newAccount('Test Account', null);
        insert acc;
        
        OperatingHours opHours = new OperatingHours();
        opHours.Name = 'Test Operating Hours';
        insert opHours;
        
        ServiceTerritory pTerr = new ServiceTerritory();
        pTerr.Name = TEST_DIVISION;
        pTerr.OperatingHoursId = opHours.Id;
        insert pTerr;
        
        ServiceTerritory sTerr = new ServiceTerritory();
        sTerr.Name = 'Test Service Territory';
        sTerr.ParentTerritoryId = pTerr.Id;
        sTerr.Service_Territory_Type__c = TEST_SERVICE_TERRITORY_TYPE;
        sTerr.OperatingHoursId = opHours.Id;
        sTerr.isActive = true;
        insert sTerr;
        
        Product_Source_Division__c psd0 = TestUtility.newProductSourceDivision('Test Product Source Division', null);
        psd0.Service_Territory__c = sTerr.Id;
        psd0.Division__c = 'BSH';
        insert psd0;
        
        Product_Source_Division__c psd1 = TestUtility.newProductSourceDivision('Test Product Source Division', null);
        psd1.Service_Territory__c = sTerr.Id;
        psd1.Division__c = 'Diagnostics';
        insert psd1;
        
        Product_Source_Division__c psd2 = TestUtility.newProductSourceDivision('Test Product Source Division', null);
        psd2.Service_Territory__c = sTerr.Id;
        psd2.Division__c = 'Medical Aesthetics';
        insert psd2;
        
        Product2 prod0 = TestUtility.newProduct('Test Product');
        prod0.Product_Source_Division__c = psd0.Id;
        insert prod0;
        
        Product2 prod1 = TestUtility.newProduct('Test Product');
        prod1.Product_Source_Division__c = psd1.Id;
        insert prod1;
        
        Product2 prod2 = TestUtility.newProduct('Test Product');
        prod2.Product_Source_Division__c = psd2.Id;
        insert prod2;
        
        List<WorkOrder> wos = new List<WorkOrder>();
        
        WorkOrder wo0 = TestUtility.newWorkOrderWithAddress(acc.Id, null, null, null, null, TEST_ZIP, TEST_STATE, TEST_COUNTRY);
        wo0.RecordTypeId = GlobalUtility.getRecordTypeId('WorkOrder', 'B_SH_FE_Install_Upgrade_Move');
        
        wos.add(wo0);
        
        WorkOrder wo1 = TestUtility.newWorkOrderWithAddress(acc.Id, null, null, null, null, TEST_ZIP, TEST_STATE, TEST_COUNTRY);
        wo1.RecordTypeId = GlobalUtility.getRecordTypeId('WorkOrder', 'B_SH_FE_Install_Upgrade_Move');
        wos.add(wo1);
        
        WorkOrder wo2 = TestUtility.newWorkOrderWithAddress(acc.Id, null, null, null, null, TEST_ZIP, TEST_STATE, TEST_COUNTRY);
        wo2.RecordTypeId = GlobalUtility.getRecordTypeId('WorkOrder', 'B_SH_FE_Install_Upgrade_Move');
        wos.add(wo2);
        
        WorkOrder wo3 = TestUtility.newWorkOrderWithAddress(acc.Id, null, null, null, null, TEST_ZIP, TEST_STATE, TEST_COUNTRY);
        wo3.RecordTypeId = GlobalUtility.getRecordTypeId('WorkOrder', 'B_SH_Applications');
        wos.add(wo3);
        
        insert wos;
        
        //Start test
        Test.startTest();
        
        //Update work orders
        wo0.Product__c = prod0.Id;
        //wo0.SuggestedMaintenanceDate = System.today() +1;
        wo1.Product__c = prod1.Id;
        wo2.Product__c = prod2.Id;
        wo3.Product__c = prod2.Id;
        update wos;
        
        //Stop test
        Test.stopTest();
        
        Group queue0 = [SELECT Id FROM Group WHERE DeveloperName = 'B_SH_Install_Upgrade_Case_Queue'];
        Group queue1 = [SELECT Id FROM Group WHERE DeveloperName = 'Diagnostic_Install_Coordinator'];
        Group queue2 = [SELECT Id FROM Group WHERE DeveloperName = 'Installation_MA'];
        Group queue3 = [SELECT Id FROM Group WHERE DeveloperName = 'Clinical_Installs_MA'];
        
        System.assertEquals(queue0.Id, [SELECT OwnerId FROM WorkOrder WHERE Id = :wo0.Id].OwnerId);
        System.assertEquals(queue1.Id, [SELECT OwnerId FROM WorkOrder WHERE Id = :wo1.Id].OwnerId);
        System.assertEquals(queue2.Id, [SELECT OwnerId FROM WorkOrder WHERE Id = :wo2.Id].OwnerId);
        System.assertEquals(queue3.Id, [SELECT OwnerId FROM WorkOrder WHERE Id = :wo3.Id].OwnerId);
    }
    
    private static testMethod void testSetAddress() {
        //Create test data
        TestUtility.setupConfigurationSettings();
        delete [SELECT Id FROM Trigger_Switch__c WHERE Name = 'sitelocTrigger'];
        
        Account acc = TestUtility.newAccount('Test Account', null);
        insert acc;
        
        Product2 prod = TestUtility.newProduct('Test Product');
        insert prod;
        
        Site_Location__c siteLoc = new Site_Location__c();
        siteLoc.Account__c = acc.Id;
        siteLoc.Name = 'Test Site Location';
        siteLoc.Address_Line_1__c = '123456789';
        siteLoc.Address_Line_2__c = '123456789';
        siteLoc.Address_Line_3__c = '123456789';
        siteLoc.Address_Line_4__c = '123456789';
        siteLoc.City__c = 'Chicago';
        siteLoc.State__c = 'IL';
        siteLoc.Zip_Code__c = '60647';
        siteLoc.Country__c = 'US';
        insert siteLoc;
        
        Asset asst = TestUtility.newAsset('Child Asset', acc.Id, acc.Id, prod.Id);
        asst.Install_Location__c = siteLoc.Id;
        asst.Ship_To_Location__c = siteLoc.Id;
        insert asst;
        
// US-0005530 {08242018} - EDIT BY RYAN - DAVE TO CHECK        
        Contact con = TestUtility.newContact('Test', 'Contact', acc.Id);
        con.Phone = '+(999) 999-9999';
        insert con;        
        
        Case cas = new Case();
        cas.AccountId = acc.Id;
        cas.AssetId = asst.Id;
        cas.Priority = 'High';
// US-0005530 {08242018} - EDIT BY RYAN - DAVE TO CHECK
        cas.ContactId = con.id;        
        insert cas;
        
        Case_Summary__c cSumm = new Case_Summary__c();
        cSumm.Case__c = cas.Id;
        insert cSumm;
        
        cas.Case_Summary__c = cSumm.Id;
        update cas;
        
        List<WorkOrder> wos = new List<WorkOrder>();
        
        WorkOrder wo1 = TestUtility.newWorkOrderWithAddress(acc.Id, cas.Id, asst.Id, null, null, TEST_ZIP, TEST_STATE, TEST_COUNTRY);
        wos.add(wo1);
        
        WorkOrder wo2 = TestUtility.newWorkOrderWithAddress(acc.Id, cas.Id, null, null, null, TEST_ZIP, TEST_STATE, TEST_COUNTRY);
        wos.add(wo2);
        
        //Start test
        Test.startTest();
        
        //Insert work order
        insert wos;
        
        //Stop test
        Test.stopTest();
        
        System.assertEquals('123456789 123456789 123456789 12345', [SELECT Id, Street FROM WorkOrder WHERE Id = :wo1.Id].Street);

// US-0005530 {08242018} - EDIT BY RYAN - DAVE TO CHECK        
        System.assertEquals('High', [SELECT Priority FROM WorkOrder WHERE Id = :wo1.Id].Priority);
        System.assertEquals(con.id, [SELECT ContactId FROM WorkOrder WHERE Id = :wo1.Id].ContactId);        
    }
    
    private static testMethod void testAssignServiceTerritoryWithWOInsert() {
        //Create test data
        TestUtility.setupConfigurationSettings();
        
        Account acc = TestUtility.newAccount('Test Account', null);
        insert acc;
        
        OperatingHours opHours = new OperatingHours();
        opHours.Name = 'Test Operating Hours';
        insert opHours;
        
        ServiceTerritory pTerr = new ServiceTerritory();
        pTerr.Name = TEST_DIVISION;
        pTerr.OperatingHoursId = opHours.Id;
        insert pTerr;
        
        ServiceTerritory sTerr = new ServiceTerritory();
        sTerr.Name = 'Test Service Territory';
        sTerr.ParentTerritoryId = pTerr.Id;
        sTerr.Service_Territory_Type__c = TEST_SERVICE_TERRITORY_TYPE;
        sTerr.OperatingHoursId = opHours.Id;
        sTerr.isActive = true;
        insert sTerr;
        
        Product_Source_Division__c psd = TestUtility.newProductSourceDivision('Test Product Source Division', null);
        psd.Service_Territory__c = sTerr.Id;
        insert psd;
        
        Product2 prod = TestUtility.newProduct('Test Product');
        prod.Product_Source_Division__c = psd.Id;
        insert prod;
        
        Asset asst = TestUtility.newAsset('Child Asset', acc.Id, acc.Id, prod.Id);
        insert asst;
        
        Service_Geography__c geo0 = new Service_Geography__c();
        geo0.Type__c = 'Postal Code';
        geo0.PostalCode__c = TEST_ZIP;
        geo0.Breast_Skeletal_Health_Clinical__c = sTerr.Id;
        geo0.Priority__c = 1;
        insert geo0;
        
        WorkType wType = new WorkType();
        wType.Service_Territory_Type__c = TEST_SERVICE_TERRITORY_TYPE;
        wType.EstimatedDuration = 8;
        wType.Name = 'Test Work Type';
        insert wType;
        
        WorkOrder wo = TestUtility.newWorkOrderWithAddress(acc.Id, null, asst.Id, null, null, TEST_ZIP + '-1234', TEST_STATE, TEST_COUNTRY);
        wo.WorkTypeId = wType.Id;
        
        //Start test
        Test.startTest();
        
        //Insert work order
        insert wo;
        
        //Stop test
        Test.stopTest();
        
        //Validate data
        wo = [SELECT Id, ServiceTerritoryId FROM WorkOrder WHERE Id = :wo.Id];
        System.assertEquals(sTerr.Id, wo.ServiceTerritoryId);
    }
    
    private static testMethod void testAssignServiceTerritoryWithWOUpdate() {
        //Create test data
        TestUtility.setupConfigurationSettings();
        
        Account acc = TestUtility.newAccount('Test Account', null);
        insert acc;
        
        OperatingHours opHours = new OperatingHours();
        opHours.Name = 'Test Operating Hours';
        insert opHours;
        
        ServiceTerritory pTerr = new ServiceTerritory();
        pTerr.Name = TEST_DIVISION;
        pTerr.OperatingHoursId = opHours.Id;
        insert pTerr;
        
        ServiceTerritory sTerr = new ServiceTerritory();
        sTerr.Name = 'Test Service Territory';
        sTerr.ParentTerritoryId = pTerr.Id;
        sTerr.Service_Territory_Type__c = TEST_SERVICE_TERRITORY_TYPE;
        sTerr.OperatingHoursId = opHours.Id;
        sTerr.isActive = true;
        insert sTerr;
        
        Product_Source_Division__c psd = TestUtility.newProductSourceDivision('Test Product Source Division', null);
        psd.Service_Territory__c = sTerr.Id;
        insert psd;
        
        Product2 prod = TestUtility.newProduct('Test Product');
        prod.Product_Source_Division__c = psd.Id;
        insert prod;
        
        Asset asst = TestUtility.newAsset('Child Asset', acc.Id, acc.Id, prod.Id);
        insert asst;
        
        Service_Geography__c geo0 = new Service_Geography__c();
        geo0.Type__c = 'Postal Code';
        geo0.PostalCode__c = TEST_ZIP;
        geo0.Breast_Skeletal_Health_Clinical__c = sTerr.Id;
        geo0.Priority__c = 1;
        insert geo0;
        
        WorkType wType = new WorkType();
        wType.Service_Territory_Type__c = TEST_SERVICE_TERRITORY_TYPE;
        wType.EstimatedDuration = 8;
        wType.Name = 'Test Work Type';
        insert wType;
        
        WorkOrder wo = TestUtility.newWorkOrderWithAddress(acc.Id, null, asst.Id, null, null, TEST_ZIP, TEST_STATE, TEST_COUNTRY);
        insert wo;
        wo = [SELECT Id, ServiceTerritoryId FROM WorkOrder WHERE Id = :wo.Id];
        System.assertEquals(null, wo.ServiceTerritoryId);
        
        //Start test
        Test.startTest();
        
        //Update work order
        wo.WorkTypeId = wType.Id;
        update wo;
        
        //Stop test
        Test.stopTest();
        
        //Validate data
        wo = [SELECT Id, ServiceTerritoryId FROM WorkOrder WHERE Id = :wo.Id];
        System.assertEquals(sTerr.Id, wo.ServiceTerritoryId);
    }

    private static testMethod void testCheckForWSTCapitalWorkOrderInsert() {
        //Create test data
        TestUtility.setupConfigurationSettings();
        
        Account acc = TestUtility.newAccount('Test Account', null);
        insert acc;
        
        Product2 prod = TestUtility.newProduct('Test Product');
        insert prod;
        
        Asset asst = TestUtility.newAsset('Child Asset', acc.Id, acc.Id, prod.Id);
        insert asst;
        
        Order ord = new Order();
        ord.AccountId = acc.Id;
        ord.EffectiveDate = Date.today();
        ord.Status = 'DRAFT';
        ord.Oracle_Order_Type__c = 'WST CAPITAL';
        insert ord;
        
        WorkType wTypeParent = new WorkType();
        wTypeParent.Service_Territory_Type__c = TEST_SERVICE_TERRITORY_TYPE;
        wTypeParent.EstimatedDuration = 8;
        wTypeParent.Name = 'Test Work Type Parent';
        insert wTypeParent;
        
        WorkType wTypeChild = new WorkType();
        wTypeChild.Parent_Work_Type__c = wTypeParent.Id;
        wTypeChild.Service_Territory_Type__c = TEST_SERVICE_TERRITORY_TYPE;
        wTypeChild.EstimatedDuration = 8;
        wTypeChild.Name = 'Test Work Type Child';
        insert wTypeChild;
        
        List<WorkOrder> wos = new List<WorkOrder>();
        
        WorkOrder wo0 = TestUtility.newWorkOrderWithAddress(acc.Id, null, asst.Id, null, null, TEST_ZIP, TEST_STATE, TEST_COUNTRY);
        wo0.RecordTypeId = GlobalUtility.getRecordTypeId('WorkOrder', 'B_SH_FE_Install_Upgrade_Move');
        wo0.Type__c = 'New Install';
        wo0.Order__c = ord.Id;
        wo0.WorkTypeId = wTypeParent.Id;
        wos.add(wo0);
        
        WorkOrder wo1 = TestUtility.newWorkOrderWithAddress(acc.Id, null, asst.Id, null, null, TEST_ZIP, TEST_STATE, TEST_COUNTRY);
        wo1.RecordTypeId = GlobalUtility.getRecordTypeId('WorkOrder', 'B_SH_FE_Install_Upgrade_Move');
        wo1.Type__c = 'New Install';
        wo1.Order__c = ord.Id;
        wo1.WorkTypeId = wTypeChild.Id;
        wos.add(wo1);
        
        //Start test
        Test.startTest();
        
        //Insert work orders
        insert wos;
        
        //Stop test
        Test.stopTest();
        
        //Validate data
        Id queueId = [SELECT Id FROM Group WHERE Type = 'Queue' AND Name = 'Medical Aesthetics Installation'].Id;
        wo1 = [SELECT Id, OwnerId, ParentWorkOrderId FROM WorkOrder WHERE Id = :wo1.Id];
        System.assertEquals(queueId, wo1.OwnerId);
        System.assertEquals(wo0.id, wo1.ParentWorkOrderId);
    }
    
    private static testMethod void testCheckForWSTCapitalWorkOrderUpdate() {
        //Create test data
        TestUtility.setupConfigurationSettings();
        
        Account acc = TestUtility.newAccount('Test Account', null);
        insert acc;
        
        Product2 prod = TestUtility.newProduct('Test Product');
        insert prod;
        
        Asset asst = TestUtility.newAsset('Child Asset', acc.Id, acc.Id, prod.Id);
        insert asst;
        
        Order ord = new Order();
        ord.AccountId = acc.Id;
        ord.EffectiveDate = Date.today();
        ord.Status = 'DRAFT';
        ord.Oracle_Order_Type__c = 'WST CAPITAL';
        insert ord;
        
        WorkOrder wo = TestUtility.newWorkOrderWithAddress(acc.Id, null, asst.Id, null, null, TEST_ZIP, TEST_STATE, TEST_COUNTRY);
        wo.RecordTypeId = GlobalUtility.getRecordTypeId('WorkOrder', 'B_SH_FE_Install_Upgrade_Move');
        wo.Type__c = 'New Install';
        insert wo;
        
        //Start test
        Test.startTest();
        
        //Update work order
        wo.Order__c = ord.Id;
        update wo;
        
        //Stop test
        Test.stopTest();
        
        //Validate data
        Id queueId = [SELECT Id FROM Group WHERE Type = 'Queue' AND Name = 'Medical Aesthetics Installation'].Id;
        wo = [SELECT Id, OwnerId FROM WorkOrder WHERE Id = :wo.Id];
        System.assertEquals(queueId, wo.OwnerId);
    }
    
    /*private static testMethod void testLinkEntitlements() {
        //Create test data
        TestUtility.setupConfigurationSettings();
        //delete [SELECT Id FROM Trigger_Switch__c WHERE Name = 'EntitlementTrigger'];
        
        Account acc = TestUtility.newAccount('Test Account', null);
        insert acc;
        
        Pricebook2 pb = TestUtility.newPricebook('Test Pricebook');
        insert pb;
        
        Product2 prod = TestUtility.newProduct('Test Product');
        insert prod;
        
        PricebookEntry pbe = TestUtility.newPricebookEntry(pb.Id, prod.Id, TEST_UNIT_PRICE);
        insert pbe;
        
        Schema.Location loc = new Schema.Location();
        loc.Name = 'Test Location';
        loc.IsInventoryLocation = true;
        insert loc;
        
        Schema.Address addr = new Schema.Address();
        addr.ParentId = loc.Id;
        addr.Street = '456 Main St';
        addr.City = 'Calgary';
        addr.StateCode = 'AB';
        addr.PostalCode = '456789';
        addr.CountryCode = 'CA';
        insert addr;
        
        Asset parentAsset = TestUtility.newAsset('Parent Asset', acc.Id, acc.Id, prod.Id);
        parentAsset.Bill_To_Address__c = addr.Id;
        insert parentAsset;
        
        Asset childAsset = TestUtility.newAsset('Child Asset', acc.Id, acc.Id, prod.Id);
        childAsset.ParentId = parentAsset.Id;
        childAsset.Bill_To_Address__c = addr.Id;
        insert childAsset;
        
        Coverage_Group__c cg = TestUtility.newCoverageGroup('Test Coverage Group');
        insert cg;
        
        ServiceContract servCon = new ServiceContract();
        servCon.Name = 'Test Service Contract';
        servCon.AccountId = acc.Id;
        servCon.Pricebook2Id = pb.Id;
        insert servCon;
        
        Entitlement ent = TestUtility.newEntitlement('Test Entitlement', null, null, acc.Id, childAsset.Id, null, null, GlobalUtility.getRecordTypeId('Entitlement', 'B_SH_SLA'), Date.today().addDays(-1), Date.today().addDays(365), 50, null);
        ent.ServiceContractId = servCon.Id;
        ent.SlaProcessId = [SELECT Id FROM SLAProcess WHERE SObjectType = 'WorkOrder' LIMIT 1].Id;
        insert ent;
        
        WorkOrder wo = TestUtility.newWorkOrder(acc.Id, null, null);
        wo.Pricebook2Id = pb.Id;
        wo.StartDate = Date.today();
        wo.SuggestedMaintenanceDate = system.today();
        wo.AssetId = childAsset.Id;
        
        //Start test
        Test.startTest();
        
        //Insert work order
        insert wo;
        
        //Stop test
        Test.stopTest();
        
        //Validate data
        wo = [
            SELECT Id
                  ,EntitlementId
                  ,ServiceContractId
              FROM WorkOrder
             WHERE Id = :wo.Id
        ];
        
        wo.SuggestedMaintenanceDate = system.today().addmonths(5);
        update wo;
        System.assertEquals(ent.Id, wo.EntitlementId);
        System.assertEquals(servCon.Id, wo.ServiceContractId);
    }*/
    
    private static testMethod void testCheckForPricingAgreement() {
        //Create test data
        TestUtility.setupConfigurationSettings();
        
        Account pacc = TestUtility.newAccount('Parent Test Account', null);
        insert pacc;
        
        Account acc = TestUtility.newAccount('Test Account', null);
        acc.ParentId = pacc.Id;
        insert acc;
        
        Product_Source_Division__c psd = TestUtility.newProductSourceDivision('Test Product Source Division', 'BONE');
        psd.Division__c = 'Medical Aesthetics';
        insert psd;
        
        Pricebook2 pb = TestUtility.newPricebook('Test Pricebook');
        insert pb;
        
        Product2 prod = TestUtility.newProduct('Test Product');
        prod.Product_Source_Division__c = psd.Id;
        prod.Name = 'MEDA-LUMINARY (Category)';
        insert prod;
        
        Asset asst = TestUtility.newAsset('Test Asset', acc.Id, acc.Id, prod.Id);
        insert asst;
        
        Contract cont = new Contract();
        cont.AccountId = acc.Id;
        cont.Contract_End_Date__c = Date.today().addDays(10);
        cont.Status = 'Draft';
        cont.Marketing_Program__c = 'MEDA-Luminary Discounts';
        insert cont;
        cont.Status = 'Activated';
        update cont;
        
        Customer_Eligible_Contract__c cec = new Customer_Eligible_Contract__c();
        cec.Customer_Account__c = pacc.Id;
        cec.Contract__c = cont.Id;
        cec.Effective_Date__c = Date.today();
        cec.Expiration_Date__c = Date.today().addDays(1);
        cec.Selected__c = true;
        insert cec;
        
        Agreed_Price__c agreedPrice = new Agreed_Price__c();
        agreedPrice.Contract__c = cont.Id;
        agreedPrice.Product__c = prod.Id;
        insert agreedPrice;
        
        WorkOrder wo = TestUtility.newWorkOrder(acc.Id, null, null);
        wo.Pricebook2Id = pb.Id;
        wo.StartDate = Date.today();
        wo.AssetId = asst.Id;
        
        //Start test
        Test.startTest();
        
        //Insert work order
        insert wo;
        
        //Stop test
        Test.stopTest();
        
        //Validate data
        wo = [
            SELECT Id
                  ,Luminary_Discount_Agreed_Price__c
              FROM WorkOrder
             WHERE Id = :wo.Id
        ];
        System.assertEquals(agreedPrice.Id, wo.Luminary_Discount_Agreed_Price__c);
    }
    
    private static testMethod void testCreateOrdersAndOrderLines() {
        //Set mock callout class
        Test.setmock(HttpCalloutMock.class, new EBSCalloutHelperMockGenerator());
        
        //Create test data
        TestUtility.setupConfigurationSettings();
        
        Account pacc = TestUtility.newAccount('Test Account', null);
        insert pacc;
        
        Account acc = TestUtility.newAccount('Test Account', null);
        acc.ParentId = pacc.Id;
        insert acc;
        
        Pricebook2 pb = TestUtility.newPricebook('Test Pricebook');
        insert pb;
        
        Configuration_Settings__c orgDefaults = Configuration_Settings__c.getInstance();
        orgDefaults.Service_Pricebook_USD__c = pb.Id;
        insert orgDefaults;
        
        OperatingHours opHours = new OperatingHours();
        opHours.Name = 'Test Operating Hours';
        insert opHours;
        
        ServiceTerritory sTerr = new ServiceTerritory();
        sTerr.Name = 'Test Service Territory';
        sTerr.OperatingHoursId = opHours.Id;
        sTerr.isActive = true;
        insert sTerr;
        
        Product_Source_Division__c psd = TestUtility.newProductSourceDivision('Test Product Source Division', null);
        psd.Service_Territory__c = sTerr.Id;
        psd.Division__c = 'Medical Aesthetics';
        insert psd;
        
        Product2 prod = TestUtility.newProduct('Test Product');
        prod.Product_Source_Division__c = psd.Id;
        insert prod;
        
        PricebookEntry pbe = TestUtility.newPricebookEntry(pb.Id, prod.Id, TEST_UNIT_PRICE);
        insert pbe;
        
        Asset asst = TestUtility.newAsset('Parent Asset', acc.Id, acc.Id, prod.Id);
        insert asst;
        
        WorkOrder wo = TestUtility.newWorkOrder(acc.Id, null, null);
        wo.Pricebook2Id = pb.Id;
        wo.StartDate = Date.today();
        wo.AssetId = asst.Id;
        insert wo;
        
        Payment__c payment = new Payment__c();
        payment.Work_Order__c = wo.Id;
        insert payment;
        
        WorkOrderLineItem woli = TestUtility.newWorkOrderLineItem(wo.Id, asst.Id, GlobalUtility.getRecordTypeId('WorkOrderLineItem', 'Part_Billing'), null);
        woli.PricebookEntryId = pbe.Id;
        woli.Labor_Qty__c = TEST_QUANTITY;
        woli.Quantity = TEST_QUANTITY;
        insert woli;
        
        Schema.Location loc = new Schema.Location();
        loc.Name = 'Test Location';
        loc.IsInventoryLocation = true;
        insert loc;
        
        ProductItem prit = new ProductItem();
        prit.Product2Id = prod.Id;
        prit.QuantityOnHand = TEST_QUANTITY;
        prit.LocationId = loc.Id;
        insert prit;
        
        ProductConsumed pc = new ProductConsumed();
        pc.WorkOrderId = wo.Id;
        pc.PricebookEntryId = pbe.Id;
        pc.QuantityConsumed = TEST_QUANTITY;
        pc.Return_Product__c = prod.Id;
        pc.ProductItemId = prit.Id;
        insert pc;
        
        //Start test
        Test.startTest();
        
        //Update work order
        wo.Status = 'Closed';
        update wo;
        
        //Stop test
        Test.stopTest();
        
        //Validate data
        wo = [
            SELECT Id
                  ,Order__c
                  ,WorkOrderNumber
                  ,OwnerId
                  ,CurrencyIsoCode
                  ,Description
              FROM WorkOrder
             WHERE Id = :wo.Id
        ];
        System.assertNotEquals(null, wo.Order__c);
        
        Order ord = [
            SELECT Id
                  ,Name
                  ,OwnerId
                  ,RecordTypeId
                  ,AccountId
                  ,EffectiveDate
                  ,Status
                  ,Pricebook2Id
                  ,CurrencyIsoCode
                  ,Description
                  ,Type
              FROM Order
             WHERE Id = :wo.Order__c
        ];
        System.assertEquals('Generated from Work Order: ' + wo.WorkOrderNumber,             ord.Name);
        System.assertEquals(wo.OwnerId,                                                     ord.OwnerId);
        //System.assertEquals(GlobalUtility.getRecordTypeId('Order', 'B_SH_Service_Order'),   ord.RecordTypeId);
        System.assertEquals(pacc.Id,                                                        ord.AccountId);
        System.assertEquals(Date.today(),                                                   ord.EffectiveDate);
        System.assertEquals('BOOKED',                                                       ord.Status);
        System.assertEquals(pb.Id,                                                          ord.Pricebook2Id);
        System.assertEquals(wo.CurrencyIsoCode,                                             ord.CurrencyIsoCode);
        System.assertEquals(wo.Description,                                                 ord.Description);
        System.assertEquals('Field Service',                                                ord.Type);
        
        OrderItem oi0 = [
            SELECT Id
              FROM OrderItem
             WHERE OrderId = :ord.Id
               AND Work_Order_Line_Item__c = :woli.Id
        ];
        System.assertNotEquals(null, oi0);
        
        /*OrderItem oi1 = [
            SELECT Id
              FROM OrderItem
             WHERE OrderId = :ord.Id
               AND Product_Consumed__c = :pc.Id
               AND Line_Type__c = 'Add Part'
        ];
        System.assertNotEquals(null, oi1);*/
        
        OrderItem oi2 = [
            SELECT Id
              FROM OrderItem
             WHERE OrderId = :ord.Id
               AND Product_Consumed__c = :pc.Id
               AND Line_Type__c = 'RMA'
        ];
        System.assertNotEquals(null, oi2);
        
        payment = [
            SELECT Id
                  ,Order__c
              FROM Payment__c
             WHERE Id = :payment.Id
        ];
        System.assertEquals(ord.Id, payment.Order__c);
    }
    
    private static testMethod void testCreateOrdersAndOrderLinesWithCase() {
        //Set mock callout class
        Test.setmock(HttpCalloutMock.class, new EBSCalloutHelperMockGenerator());
        
        //Create test data
        TestUtility.setupConfigurationSettings();
        
        Account pacc = TestUtility.newAccount('Test Account', null);
        insert pacc;
        
        Account acc = TestUtility.newAccount('Test Account', null);
        acc.ParentId = pacc.Id;
        acc.BillingCity = 'Test City';
        insert acc;
        
        Pricebook2 pb = TestUtility.newPricebook('Test Pricebook');
        pb.CurrencyIsoCode = 'USD';
        insert pb;
        
        Configuration_Settings__c orgDefaults = Configuration_Settings__c.getInstance();
        orgDefaults.Service_Pricebook_USD__c = pb.Id;
        orgDefaults.Service_Report_Generation_URL__c = 'http://testurl.com';
        insert orgDefaults;
        
        Product2 prod = TestUtility.newProduct('Test Product');
        insert prod;
        
        PricebookEntry pbe = TestUtility.newPricebookEntry(pb.Id, prod.Id, TEST_UNIT_PRICE);
        pbe.CurrencyIsoCode = 'USD';
        insert pbe;
        
        Asset asst = TestUtility.newAsset('Parent Asset', acc.Id, acc.Id, prod.Id);
        insert asst;
        
        Case cas = new Case();
        cas.AccountId = acc.Id;
        cas.Priority = 'High';
        insert cas;
        
        Case_Summary__c caseSummary = new Case_Summary__c();
        caseSummary.Case__c = cas.Id;
        insert caseSummary;
        
        WorkOrder wo = TestUtility.newWorkOrder(acc.Id, null, null);
        wo.Pricebook2Id = pb.Id;
        wo.CurrencyIsoCode = 'USD';
        wo.StartDate = Date.today();
        wo.CaseId = cas.Id;
        insert wo;
        
        WorkOrderLineItem woli = TestUtility.newWorkOrderLineItem(wo.Id, asst.Id, GlobalUtility.getRecordTypeId('WorkOrderLineItem', 'Billable_Event'), null);
        woli.PricebookEntryId = pbe.Id;
        woli.Labor_Qty__c = TEST_QUANTITY;
        woli.Quantity = TEST_QUANTITY;
        insert woli;
        
        Schema.Location loc = new Schema.Location();
        loc.Name = 'Test Location';
        loc.IsInventoryLocation = true;
        insert loc;
        
        ProductItem prit = new ProductItem();
        prit.Product2Id = prod.Id;
        prit.QuantityOnHand = TEST_QUANTITY;
        prit.LocationId = loc.Id;
        insert prit;
        
        ProductConsumed pc = new ProductConsumed();
        pc.WorkOrderId = wo.Id;
        pc.PricebookEntryId = pbe.Id;
        pc.QuantityConsumed = TEST_QUANTITY;
        pc.Return_Product__c = prod.Id;
        pc.ProductItemId = prit.Id;
        insert pc;
        
        //Start test
        Test.startTest();
        
        //Update work order
        wo.Status = 'Closed';
        update wo;
        
        //Stop test
        Test.stopTest();
        
        //Validate data
        cas = [
            SELECT Id
                  ,Case_Summary__r.Has_Work_Orders__c
                  ,Case_Summary__r.Has_Service_Orders__c
              FROM Case
             WHERE Id = :cas.Id
        ];
        
        List<ContentDocumentLink> links = [
            SELECT Id
              FROM ContentDocumentLink
             WHERE LinkedEntityId = :cas.Id
        ];
        System.assertEquals(2, links.size());
    }
    
    private static testMethod void testCreateTasks() {
        //Create test data
        TestUtility.setupConfigurationSettings();
        
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
        
        ContractLineItem cli = new ContractLineItem();
        cli.ServiceContractId = servCon.Id;
        cli.PricebookEntryId = pbe.Id;
        cli.Quantity = 27;
        cli.UnitPrice = 27;
        cli.StartDate = Date.today().addMonths(-6);
        cli.EndDate = Date.today().addYears(1);
        insert cli;
        
        Asset asst = TestUtility.newAsset('Test Asset', acc.Id, acc.Id, prod.Id);
        asst.SBQQSC__CurrentContractLineItem__c = cli.Id;
        insert asst;
        
        User use = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        use.Division = 'Breast & Skeletal Health';
        update use;
        
        WorkOrder wo = TestUtility.newWorkOrder(acc.Id, null, null);
        wo.Pricebook2Id = pb.Id;
        wo.StartDate = Date.today();
        wo.AssetId = asst.Id;
        wo.RecordTypeId = GlobalUtility.getRecordTypeId('WorkOrder', 'B_SH_FE_Install_Upgrade_Move');
        wo.Type__c = 'De-Install';
        insert wo;
        
        //Start test
        Test.startTest();
        
        //Update work order
        wo.Status = 'Closed';
        update wo;
        
        //Stop test
        Test.stopTest();
        
        //Validate data
        List<Task> tasks = [SELECT Id FROM Task];
        System.assertNotEquals(0, tasks.size());
    }
    
    private static testMethod void testCreateResourcePreferences() {
        //Create test data
        TestUtility.setupConfigurationSettings();
        
        Account acc = TestUtility.newAccount('Test Account', null);
        insert acc;
        
        Product2 prod = TestUtility.newProduct('Test Product');
        insert prod;
        
        Asset asst = TestUtility.newAsset('Parent Asset', acc.Id, acc.Id, prod.Id);
        insert asst;
        
        Id profId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id;
        
        User primaryUser = TestUtility.newUser(profId, 'prim');
        insert primaryUser;
        
        User secondaryUser = TestUtility.newUser(profId, 'sec');
        insert secondaryUser;
        
        User tertiaryUser = TestUtility.newUser(profId, 'tert');
        insert tertiaryUser;
        
        ServiceResource primarySR = new ServiceResource();
        primarySR.Name = 'Primary SR';
        primarySR.RelatedRecordId = primaryUser.Id;
        primarySR.IsActive = true;
        insert primarySR;
        
        ServiceResource secondarySR = new ServiceResource();
        secondarySR.Name = 'Secondary SR';
        secondarySR.RelatedRecordId = secondaryUser.Id;
        secondarySR.IsActive = true;
        insert secondarySR;
        
        ServiceResource tertiarySR = new ServiceResource();
        tertiarySR.Name = 'Tertiary SR';
        tertiarySR.RelatedRecordId = tertiaryUser.Id;
        tertiarySR.IsActive = true;
        insert tertiarySR;
        
        Asset_Team__c primaryTeam = new Asset_Team__c();
        primaryTeam.Asset__c = asst.Id;
        primaryTeam.User__c = primaryUser.Id;
        primaryTeam.Relationship__c = 'Primary Field Engineer';
        insert primaryTeam;
        
        Asset_Team__c secondaryTeam = new Asset_Team__c();
        secondaryTeam.Asset__c = asst.Id;
        secondaryTeam.User__c = secondaryUser.Id;
        secondaryTeam.Relationship__c = 'Secondary Field Engineer';
        insert secondaryTeam;
        
        Asset_Team__c tertiaryTeam = new Asset_Team__c();
        tertiaryTeam.Asset__c = asst.Id;
        tertiaryTeam.User__c = tertiaryUser.Id;
        tertiaryTeam.Relationship__c = 'Tertiary Field Engineer';
        insert tertiaryTeam;
        
        WorkOrder wo = TestUtility.newWorkOrder(acc.Id, null, null);
        wo.AssetId = asst.Id;
        
        //Start test
        Test.startTest();
        
        //Insert work order
        insert wo;
        
        //Stop test
        Test.stopTest();
        
        //Validate data
        ResourcePreference primaryPref = [
            SELECT Id
                  ,ServiceResourceId
                  ,PreferenceType
              FROM ResourcePreference
             WHERE RelatedRecordId = :wo.Id
               AND Rank__c = 'Primary'
        ];
        System.assertEquals(primarySR.Id,   primaryPref.ServiceResourceId);
        System.assertEquals('Preferred',    primaryPref.PreferenceType);
        
        ResourcePreference secondaryPref = [
            SELECT Id
                  ,ServiceResourceId
                  ,PreferenceType
              FROM ResourcePreference
             WHERE RelatedRecordId = :wo.Id
               AND Rank__c = 'Secondary'
        ];
        System.assertEquals(secondarySR.Id, secondaryPref.ServiceResourceId);
        System.assertEquals('Preferred',    secondaryPref.PreferenceType);
        
        ResourcePreference tertiaryPref = [
            SELECT Id
                  ,ServiceResourceId
                  ,PreferenceType
              FROM ResourcePreference
             WHERE RelatedRecordId = :wo.Id
               AND Rank__c = 'Tertiary'
        ];
        System.assertEquals(tertiarySR.Id,  tertiaryPref.ServiceResourceId);
        System.assertEquals('Preferred',    tertiaryPref.PreferenceType);
    }
    
    private static testMethod void testCheckForClosedStatus() {
        //Set mock callout class
        Test.setmock(HttpCalloutMock.class, new EBSCalloutHelperMockGenerator());
        
        //Create test data
        TestUtility.setupConfigurationSettings();
        
        Account pacc = TestUtility.newAccount('Test Account', null);
        insert pacc;
        
        Account acc = TestUtility.newAccount('Test Account', null);
        acc.ParentId = pacc.Id;
        insert acc;
        
        Contact con = TestUtility.newContact('Test', 'Contact', acc.Id);
        con.Phone = '+(999) 999-9999';
        insert con;
        
        Pricebook2 pb = TestUtility.newPricebook('Test Pricebook');
        insert pb;
        
        Product2 prod = TestUtility.newProduct('Test Product');
        insert prod;
        
        PricebookEntry pbe = TestUtility.newPricebookEntry(pb.Id, prod.Id, TEST_UNIT_PRICE);
        insert pbe;
        
        Asset asst = TestUtility.newAsset('Parent Asset', acc.Id, acc.Id, prod.Id);
        insert asst;
        
        Tech_Bulletin__c tb = new Tech_Bulletin__c();
        insert tb;
        
        Asset_Tech_Bulletin__c atb = new Asset_Tech_Bulletin__c();
        atb.Tech_Bulletin__c = tb.Id;
        insert atb;
        
        Case cas = new Case();
        cas.AccountId = acc.Id;
        cas.Priority = 'High';
        insert cas;
        
        CaseContactRole ccr = new CaseContactRole();
        ccr.ContactId = con.Id;
        ccr.CasesId = cas.Id;
        ccr.Role = 'FSR Recipient';
        insert ccr;
        
        WorkOrder wo = TestUtility.newWorkOrder(acc.Id, null, null);
        wo.Pricebook2Id = pb.Id;
        wo.StartDate = Date.today();
        wo.CaseId = cas.Id;
        wo.ContactId = con.Id;
        wo.Asset_Tech_Bulletin__c = atb.Id;
        insert wo;
        
        //Start test
        Test.startTest();
        
        //Update work order
        wo.Status = 'Closed';
        update wo;
        
        //Stop test
        Test.stopTest();
        
        //Validate data
        cas = [
            SELECT Id
                  ,Status
              FROM Case
             WHERE Id = :cas.Id
        ];
        System.assertEquals('Closed', cas.Status);
        
        atb = [
            SELECT Id
                  ,Status__c
              FROM Asset_Tech_Bulletin__c
             WHERE Id = :atb.Id
        ];
        System.assertEquals('Closed', atb.Status__c);
    }
    
    private static testMethod void testCheckToUpdateAssets() {
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
        
        Asset asst0 = TestUtility.newAsset('Asset0', acc.Id, acc.Id, prod.Id);
        insert asst0;
        
        Asset asst1 = TestUtility.newAsset('Asset1', acc.Id, acc.Id, prod.Id);
        insert asst1;
        
        Id rtId = GlobalUtility.getRecordTypeId('WorkOrder', 'B_SH_FE_Install_Upgrade_Move');
        
        List<WorkOrder> wos = new List<WorkOrder>();
        
        WorkOrder wo0 = TestUtility.newWorkOrder(acc.Id, null, null);
        wo0.Pricebook2Id = pb.Id;
        wo0.StartDate = Date.today();
        wo0.AssetId = asst0.Id;
        wo0.Completed_Date__c = Datetime.now();
        wo0.RecordTypeId = rtId;
        wo0.Type__c = 'New Install';
        wos.add(wo0);
        
        WorkOrder wo1 = TestUtility.newWorkOrder(acc.Id, null, null);
        wo1.Pricebook2Id = pb.Id;
        wo1.StartDate = Date.today();
        wo1.AssetId = asst1.Id;
        wo1.Completed_Date__c = Datetime.now();
        wo1.RecordTypeId = rtId;
        wo1.Type__c = 'De-Install';
        wos.add(wo1);
        
        insert wos;
        
        //Start test
        Test.startTest();
        
        //Update work orders
        wo0.Status = 'Closed';
        wo1.Status = 'Closed';
        update wos;
        
        //Stop test
        Test.stopTest();
        
        //Validate data
        asst0 = [
            SELECT Id
                  ,Status
                  ,InstallDate
              FROM Asset
             WHERE Id = :asst0.Id
        ];
        System.assertEquals('Installed',        asst0.Status);
        System.assertEquals(Date.today(),       asst0.InstallDate);
        
        asst1 = [
            SELECT Id
                  ,Status
                  ,Uninstall_Date__c
              FROM Asset
             WHERE Id = :asst1.Id
        ];
        System.assertEquals('Uninstalled',      asst1.Status);
        System.assertEquals(Date.today(),       asst1.Uninstall_Date__c);
    }
    
    private static testMethod void testCheckToUpdateParentCases() {
        //Create test data
        TestUtility.setupConfigurationSettings();
        
        Account pacc = TestUtility.newAccount('Test Account', null);
        insert pacc;
        
        Account acc = TestUtility.newAccount('Test Account', null);
        acc.ParentId = pacc.Id;
        insert acc;
        
        Case cas = new Case();
        cas.AccountId = acc.Id;
        cas.Priority = 'High';
        insert cas;
        
        Pricebook2 pb = TestUtility.newPricebook('Test Pricebook');
        insert pb;
        
        Product2 prod = TestUtility.newProduct('Test Product');
        insert prod;
        
        Asset asst = TestUtility.newAsset('Asset0', acc.Id, acc.Id, prod.Id);
        insert asst;
        
        Id rtId = GlobalUtility.getRecordTypeId('WorkOrder', 'B_SH_FE_Install_Upgrade_Move');
        
        WorkOrder wo = TestUtility.newWorkOrder(acc.Id, null, null);
        wo.Pricebook2Id = pb.Id;
        wo.StartDate = Date.today();
        wo.AssetId = asst.Id;
        wo.Completed_Date__c = Datetime.now();
        wo.RecordTypeId = rtId;
        wo.CaseId = cas.Id;
        
        //Start test
        Test.startTest();
        
        //Insert work order
        insert wo;
        
        //Stop test
        Test.stopTest();
        
        //Validate data
        cas = [SELECT Id, Work_Order_Associated__c, Number_of_Related_Work_Orders__c FROM Case WHERE Id = :cas.Id];
        System.assertEquals(true, cas.Work_Order_Associated__c);
        System.assertEquals(1, cas.Number_of_Related_Work_Orders__c);
    }
    
    private static testMethod void testCheckToUpdateParentCaseSummaries() {
        //Create test data
        TestUtility.setupConfigurationSettings();
        
        Account pacc = TestUtility.newAccount('Test Account', null);
        insert pacc;
        
        Account acc = TestUtility.newAccount('Test Account', null);
        acc.ParentId = pacc.Id;
        insert acc;
        
        Case cas = new Case();
        cas.AccountId = acc.Id;
        cas.Priority = 'High';
        insert cas;
        
        Case_Summary__c summary = new Case_Summary__c();
        summary.Case__c = cas.Id;
        insert summary;
        
        Pricebook2 pb = TestUtility.newPricebook('Test Pricebook');
        insert pb;
        
        Product2 prod = TestUtility.newProduct('Test Product');
        insert prod;
        
        Asset asst = TestUtility.newAsset('Asset0', acc.Id, acc.Id, prod.Id);
        insert asst;
        
        Id rtId = GlobalUtility.getRecordTypeId('WorkOrder', 'B_SH_FE_Install_Upgrade_Move');
        
        WorkOrder wo0 = TestUtility.newWorkOrder(acc.Id, null, null);
        wo0.Pricebook2Id = pb.Id;
        wo0.StartDate = Date.today();
        wo0.AssetId = asst.Id;
        wo0.Completed_Date__c = Datetime.now();
        wo0.RecordTypeId = rtId;
        wo0.CaseId = cas.Id;
        wo0.Case_Summary__c = summary.Id;
        wo0.FE_Resolution__c = 'test resolution 0';
        wo0.FE_Update__c = 'test update 0';
        wo0.FE_RCC__c = 'test rcc 0';
        
        //Start test
        Test.startTest();
        
        //Insert work order
        insert wo0;
        
        //Update work order
        wo0.FE_Resolution__c = 'test resolution 1';
        wo0.FE_Update__c = 'test update 1';
        wo0.FE_RCC__c = 'test rcc 1';
        update wo0;
        
        //Stop test
        Test.stopTest();
        
        //Validate data
        wo0 = [SELECT Id, Owner.Name, WorkOrderNumber, FE_Resolution__c, FE_Update__c, FE_RCC__c FROM WorkOrder WHERE Id = :wo0.Id];
        
        summary = [SELECT Id, FE_Resolution__c, FE_Update__c, FE_RCC__c FROM Case_Summary__c WHERE Id = :summary.Id];
        //System.assertEquals('[' + wo0.Owner.Name + ' - WO# ' + wo0.WorkOrderNumber + '] ' + wo0.FE_Resolution__c, summary.FE_Resolution__c);
        //System.assertEquals('[' + wo0.Owner.Name + ' - WO# ' + wo0.WorkOrderNumber + '] ' + wo0.FE_Update__c,     summary.FE_Update__c);
        //System.assertEquals('[' + wo0.Owner.Name + ' - WO# ' + wo0.WorkOrderNumber + '] ' + wo0.FE_RCC__c,            summary.FE_RCC__c);
    }
    
    private static testMethod void testCheckToUpdateWorkOrderDetails() {
          TestUtility.setupConfigurationSettings();
        TestUtility.insertCustSetting('EntitlementTriggerFirstTime');
        
        WorkType wt = new WorkType();
        wt.Name = 'PM Auto';
        wt.EstimatedDuration = 1;
        insert wt;
        
        Account acc = TestUtility.newAccount('Test Account', null);
        insert acc;
        
        Pricebook2 pb = TestUtility.newPricebook('Test Pricebook');
        insert pb;
        
        Product2 prod = TestUtility.newProduct('Test Product');
        prod.PM_Work_Type__c = wt.Id;
        insert prod;
        
        PricebookEntry pbe = TestUtility.newPricebookEntry(pb.Id, prod.Id, 27);
        insert pbe;
        
        ServiceContract servCon = new ServiceContract();
        servCon.Name = 'Test Service Contract';
        servCon.AccountId = acc.Id;
        servCon.Pricebook2Id = pb.Id;
        insert servCon;
        
        Asset asst = TestUtility.newAsset('Test Asset', acc.Id, acc.Id, prod.Id);
        insert asst;
        
        ContractLineItem cli = new ContractLineItem();
        cli.ServiceContractId = servCon.Id;
        cli.PricebookEntryId = pbe.Id;
        cli.Quantity = 27;
        cli.UnitPrice = 27;
        cli.StartDate = Date.today().addMonths(-6);
        cli.EndDate = Date.today().addYears(1);
        cli.AssetId = asst.Id;
        insert cli;
        
        Coverage_Group__c cg = TestUtility.newCoverageGroup('Test Coverage Group');
        cg.Maintenance_Frequency__c = 2;
        cg.Maintenance_Frequency_Type__c = 'Months';
        insert cg;
        
        Entitlement ent = new Entitlement();
        ent.Name = 'Test Entitlement';
        ent.AccountId = acc.Id;
        ent.AssetId = asst.Id;
        ent.RecordTypeId = GlobalUtility.getRecordTypeId('Entitlement', 'B_SH_PM');
        ent.ContractLineItemId = cli.Id;
        insert ent;
        
        //Start test
        Test.startTest();
        
        //Update entitlement
        ent.Coverage_Group__c = cg.Id;
        update ent;
        
        //Stop test
        Test.stopTest();
        
        //Validate data
        List<WorkOrder> wos = [
            SELECT Id,MaintenancePlanid,SuggestedMaintenanceDate
              FROM WorkOrder
             WHERE EntitlementId = :ent.Id
        ];
        //System.assertEquals(6, wos.size());
        system.debug('wos---'+wos);
        system.debug('wos[0].MaintenancePlanid---'+wos[0].MaintenancePlanid);
        system.debug('wos[0].SuggestedMaintenanceDate---'+wos[0].SuggestedMaintenanceDate);
        wos[0].SuggestedMaintenanceDate = system.today().addMonths(5);
        update wos;
      
   
        WorkOrderTriggerActionsExtension.addFrequency(Date.today(), 1, 'Days', 2, 'PRE');
        WorkOrderTriggerActionsExtension.addFrequency(Date.today(), 1, 'Days', 2, 'POST');
        WorkOrderTriggerActionsExtension.addFrequency(Date.today(), 1, 'Weeks', 2, 'PRE');
        WorkOrderTriggerActionsExtension.addFrequency(Date.today(), 1, 'Weeks', 2, 'POST');
        WorkOrderTriggerActionsExtension.addFrequency(Date.today(), 1, 'Months', 2, 'PRE');
        WorkOrderTriggerActionsExtension.addFrequency(Date.today(), 1, 'Months', 2, 'POST');
        WorkOrderTriggerActionsExtension.addFrequency(Date.today(), 1, 'Years', 2, 'PRE');
        WorkOrderTriggerActionsExtension.addFrequency(Date.today(), 1, 'Years', 2, 'POST');
        WorkOrderTriggerActionsExtension.addFrequency(Date.today(), 1, null, 2, 'POST');
        WorkOrderTriggerActionsExtension.addFrequency(Date.today(), 1, null, 2, 'PRE');
    }
    
    /*private static testMethod void testCheckToUpdateSAStatusCancelled() {
        //Create test data
        TestUtility.setupConfigurationSettings();
        
        Account acc = TestUtility.newAccount('Test Account', null);
        insert acc;
        
        Pricebook2 pb = TestUtility.newPricebook('Test Pricebook');
        insert pb;
        
        WorkOrder wo = TestUtility.newWorkOrder(acc.Id, null, null);
        wo.Pricebook2Id = pb.Id;
        wo.StartDate = Date.today();
        wo.FE_Resolution__c = 'Test';
        insert wo;
        
        ServiceAppointment sa = TestUtility.newServiceAppointment(wo.id, 'New', wo.Id, DateTime.newInstance(2019, 6, 30), DateTime.newInstance(2018, 6, 1));
        sa.ActualStartTime = DateTime.now();
        sa.ActualEndTime = DateTime.now().addHours(2);
        insert sa;
        
        //Start test
        Test.startTest();
        
        //Update work order
        wo.Status = 'Cancelled';
        wo.Reason_for_Cancellation__c = 'Test Reason';
        update wo;
        
        //Stop test
        Test.stopTest();
    }*/
    
    /*private static testMethod void testCheckToUpdateSAStatusRejected() {
        //Create test data
        TestUtility.setupConfigurationSettings();
        
        Account acc = TestUtility.newAccount('Test Account', null);
        insert acc;
        
        Pricebook2 pb = TestUtility.newPricebook('Test Pricebook');
        insert pb;
        
        WorkOrder wo = TestUtility.newWorkOrder(acc.Id, null, null);
        wo.Pricebook2Id = pb.Id;
        wo.StartDate = Date.today();
        wo.FE_Resolution__c = 'Test';
        insert wo;
        
        ServiceAppointment sa = TestUtility.newServiceAppointment(wo.id, 'Completed', wo.Id, DateTime.newInstance(2019, 6, 30), DateTime.newInstance(2018, 6, 1));
        sa.ActualStartTime = DateTime.now();
        sa.ActualEndTime = DateTime.now().addHours(2);
        insert sa;
        
        //Start test
        Test.startTest();
        
        //Update work order
        wo.Status = 'Rejected';
        update wo;
        
        //Stop test
        Test.stopTest();
    }*/
}