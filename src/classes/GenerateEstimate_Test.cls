/*------------------------------------------------------------
Author:         Kasmoor Reddy
Company:        Apps Associates
Description:    Test class to validate GenerateEstimate
                Tests Excecuted:
                
                TestGenerateestimate - This method to validate the the pdf document generated 
                on click of the button on Work order which is having the list of workorderlineitems with recordtype "Estimate".
                
                
History:
<Date>          <Authors Name>      <Brief Description of Change>
08/22/2017      Kasmoor Reddy       Initial Creation(US3314)
------------------------------------------------------------*/
@isTest(seealldata=false)
public class GenerateEstimate_Test {
    //Variable declarations
private static Configuration_Settings__c orgDefaults;
    private static Record_Type_IDs__c rtIds;
    private static Account custAccount;
    private static Account siteAccount;
    private static Contact defaultContact;
    private static Contact applicationContact;
    private static Contact connectivityContact;
    private static List<Product2> products;
    private static List<Asset> assets;
    private static List<Case> cases = new List<Case>();
    private static Pricebook2 pricebook;
    private static WorkOrder wrkordr;
    private static List<WorkOrder> wrkordrs;
    private static WorkOrder wrkordr1;
    private static List<WorkOrderLineItem> worklineitems;
    private static List<PriceBookEntry> pbeList;
    private static User integrationUser;
    private static User sysAdminUser;
    private static Product_Source_Division__c psd;
    private static List<Coverage_Template__c> coverageTemplates;
    private static Coverage_Group__c coverageGroup;
    private static List<Entitlement> workorderEntitlements;
    private static Map<Id, List<Entitlement>> assetToEntitlement;
    private static Map<Id, Id> assetToProduct = new Map<Id, Id>();
    private static Map<Id, Map<Id, PricebookEntry>> pricebookToProductToPricebookEntry = new Map<Id, Map<Id, PricebookEntry>>();
    private static List<Coverage_Group_Product__c> coverageGroupProducts = new List<Coverage_Group_Product__c>();
    private static List<Entitlement> entitlements = new List<Entitlement>();
    private static List<Pricebook2> pricebooks = new List<Pricebook2>();
    private static List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();

static testMethod void TestGenerateestimate(){
        
        //setuping the custom settings
        orgDefaults = TestUtility.setupConfigurationSettings();
        rtIds = TestUtility.setupRecordTypeIds();
        
        // inserting the custom settings
        TestUtility.insertCustSetting('WorkOrderTrigger');   
        
        TestUtility.insertCustSetting('WorkOrderPM');
        
        TestUtility.insertCustSetting('DeleteZeroQtyStock');
        
        //Update of additional Custom Settings 
                       
        TestUtility.insertCustSetting('PMPlans');         
        TestUtility.insertCustSetting('CaseTrigger');   
        TestUtility.insertCustSetting('OrderLineProductReplacement');
        TestUtility.insertCustSetting('sitelocTrigger');
        
        // insert pricebooks
        pricebook = TestUtility.newPricebook('Test Pricebook');
        insert new List<Pricebook2> {pricebook};
        System.assertEquals('Test Pricebook', pricebook.Name);    
        
        // insert an account
        custAccount = TestUtility.newAccount('Customer Account', 'testCust', 'ABC Street', null, GlobalUtility.getRecordTypeId('Account', 'Customer'));
        custAccount.BillingCountryCode = 'US';
        custAccount.BillingStateCode = 'NY';        
        insert new List<Account>{custAccount};
        System.assertEquals('Customer Account', custAccount.Name);
        
        siteAccount = TestUtility.newAccount('Site Account', 'testSite', 'ABC Street', custAccount.Id, GlobalUtility.getRecordTypeId('Account', 'Site'));
        siteAccount.BillingCountryCode = 'US';
        siteAccount.BillingStateCode = 'NY';            
        insert siteAccount;
        System.assertEquals('Site Account', siteAccount.Name);
        
        // update org defaults
        orgDefaults.Default_B_SH_Parts_Pricebook2Id__c = pricebook.Id;
        //insert contacts
        defaultContact = TestUtility.newContact('Default', 'Contact', custAccount.Id);
        applicationContact = TestUtility.newContact('Application', 'Contact', custAccount.Id);
        connectivityContact = TestUtility.newContact('Connectivity', 'Contact', custAccount.Id);
        insert new List<Contact>{defaultContact, applicationContact, connectivityContact};
        System.assertEquals('Contact', defaultContact.LastName);

        //insert product source division
        Product_Source_Division__c psd = TestUtility.newProductSourceDivision('1234','MAMMOGRAPHY');
        Insert psd;
        System.assertEquals('1234', psd.Name);
        
        Product_Source_Division__c psd1 = TestUtility.newProductSourceDivision('12345','MOLECULAR');
        Insert psd1;
        System.assertEquals('12345', psd1.Name);

        //insert products
        Product2 prod = TestUtility.newProduct('Product 03');
        insert prod;
        System.assertEquals('Product 03', prod.Name);        
        products = new List<Product2>();
        products.add(TestUtility.newProduct('Product 01'));
        products.add(TestUtility.newProduct('Product 02'));
        //adding product source division to product
        products[0].Product_Source_Division__c = psd.id;
        products[1].Product_Source_Division__c = psd1.id;
        products[0].PM_Product__c = prod.Id;
        products[1].PM_Product__c = prod.Id;
        insert products;
        //updating the products.
        update products[0];
        update products[1];
        products.add(prod);
        
       //insert pricebookentry
        pbeList = new List<PriceBookEntry>();
        for(Product2 pd : products){
            PriceBookEntry pbe = new PriceBookEntry();
            pbe.Product2Id = pd.Id;
            pbe.Pricebook2Id = pricebook.Id;
            pbe.unitprice=1.0;
            pbe.isActive = true;
            pbeList.add(pbe);
        }
        insert pbeList;
    
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
        
       
        //insert assets
        assets = new List<Asset>();
        for(Integer i = 0; i < 10; i++){
            Asset a1=TestUtility.newAsset(siteAccount.Name + ' Asset 01', siteAccount.Id, custAccount.Id, products[0].Id);
            a1.ContactId= defaultContact.Id;
            assets.add(a1);
            Asset a2= TestUtility.newAsset(siteAccount.Name + ' Asset 02', siteAccount.Id, custAccount.Id, products[1].Id);
            a2.ContactId= defaultContact.Id;
            assets.add(a2);
        }
        insert assets;
        
        //insert sitelocation
        Site_Location__c shipLocation= TestUtility.newSiteLocation('123 A Street Suite 1', '123 A Street', 'Suite 1', null, null,
            'Some City', 'MA', '11111', 'US',
            custAccount.Oracle_Party_Id__c, siteAccount.Id, true);
            shipLocation.Bill_To__c = true;
            shipLocation.Ship_To__c = true;
            insert shipLocation;
            System.assertEquals('123 A Street Suite 1', shipLocation.Name);
           // insert cases
           for(Asset a : assets){
            assetToProduct.put(a.Id, a.Product2Id);
            cases.add(TestUtility.newCase(siteAccount.Id, null, a.Id, null, GlobalUtility.getRecordTypeId('Case', 'B_SH_Service'), 'Issue', 'New', 'Low', 'Phone'));
            //cases[0].Agreed_Move_Price__c= 50;
        }
        insert cases;
    
        SlaProcess workOrderEntitlementProcess;
        try{
            workOrderEntitlementProcess = [Select Id, Name From SlaProcess Where SObjectType = 'WorkOrder' Limit 1];
        }
        catch(Exception e){}
        System.assertNotEquals(null, workOrderEntitlementProcess, 'SETUP ERROR: test cannot proceed, no Work Order SLA Processes were found.');
        
        // create Business Hours
        BusinessHours businessHours;
        try{
            businessHours = [Select Id, Name From BusinessHours Limit 1];
        }
        catch(Exception e){}
        System.assertNotEquals(null, businessHours, 'SETUP ERROR: test cannot proceed, no Business Hours were found.');
        
        // create Coverage Group
        coverageGroup = TestUtility.newCoverageGroup('Test Coverage Group');
        insert coverageGroup;
        
        // create Coverage Template
        coverageTemplates = new List<Coverage_Template__c>();
        for(Integer i = 1; i <= 5; i++){
            coverageTemplates.add(TestUtility.newCoverageTemplate('Test Coverage Template '+i, coverageGroup.Id, GlobalUtility.getRecordTypeId('Coverage_Template__c', 'B_SH_SLA'), null, null, null, String.valueOf(i), null, workOrderEntitlementProcess.Name, null));
        }
        insert coverageTemplates;
        
        // create Entitlement
        workorderEntitlements = new List<Entitlement>();
        assetToEntitlement = new Map<Id, List<Entitlement>>();
        for(Asset a : assets){
            assetToEntitlement.put(a.Id, new List<Entitlement>());
            for(Coverage_Template__c ct : coverageTemplates){
                Entitlement e = TestUtility.newEntitlement('Test ' + a.Name, businessHours.Id, workOrderEntitlementProcess.Id, a.AccountId, a.Id, ct.Id, System.today().addDays(-30), System.today().addDays(365));
                workorderEntitlements.add(e);
                assetToEntitlement.get(a.Id).add(e);
            }
        }
        insert workorderEntitlements;
       
        wrkordrs = new List<WorkOrder>();
        for(Integer i = 0; i < 2; i++){
                WorkOrder wrkordr1=TestUtility.newWorkOrder(siteAccount.Id, cases[0].Id, null, GlobalUtility.getRecordTypeId('WorkOrder', 'B_SH_Billable_PM'), 'New');
                wrkordr1.Pricebook2Id = pricebooks[0].Id;
                wrkordr1.AssetId = assets[0].id;
                wrkordr1.EntitlementId = workorderEntitlements[0].id;
                wrkordrs.add(wrkordr1);
                WorkOrder wrkordr2= TestUtility.newWorkOrder(siteAccount.Id, cases[0].Id, null, GlobalUtility.getRecordTypeId('WorkOrder', 'B_SH_Billable_PM'), 'New');
                wrkordr2.Pricebook2Id = pricebooks[0].Id;
                wrkordr2.AssetId = assets[0].id;
                wrkordrs.add(wrkordr2);
        }
        insert wrkordrs;
        system.debug('wrkordrs======'+wrkordrs);
        WorkOrder postInsertWO = [Select Id,Caseid,AssetId,Pricebook2Id From WorkOrder where Id=: wrkordrs[0].id];
        system.debug('postInsertWO======'+postInsertWO);
         
        // insert workorderlineitems
        worklineitems = new List<WorkOrderLineItem>();
        for(Integer i = 0; i < 7; i++){
            worklineitems.add(TestUtility.newWorkOrderLineItem(postInsertWO.id,assets[0].id,GlobalUtility.getRecordTypeId('WorkOrderLineItem', 'Estimate'),'New'+i));
            Id product2Id = assetToProduct.get(postInsertWO.AssetId);
            //worklineitems[i].PricebookEntryId = pricebookToProductToPricebookEntry.get(postInsertWO.Pricebook2Id).get(product2Id).Id;
            worklineitems[i].Quantity = 1;
            worklineitems[i].Entitlement__c = workorderEntitlements[0].id;
        }
        insert worklineitems;
        System.assertEquals(7, worklineitems.Size());    
        
        //Page reference
        PageReference pageRef = Page.GenerateEstimatePdf;
        pageRef.getParameters().put('id',postInsertWO.id);
        Test.setCurrentPage(pageRef);
        
        //Passing methods
        ApexPages.StandardController sc = new ApexPages.StandardController(postInsertWO);
        ApexPages.currentPage().getParameters().put('parentWorkOrder',postInsertWO.id);
        GenerateEstimate CC = new GenerateEstimate(sc);
        CC.totalcount = 1;
        
   }//End of testmethod
    
}//End of testclass