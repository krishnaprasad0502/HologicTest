/*------------------------------------------------------------
Author          Dave Mansell
Company:        Salesforce.com
Description:    Tests functions related to ProductRequest records

History:
<Date           <Authors Name>      <Brief Description of Change>
04/26/2018      Dave Mansell        Initial Creation (US-0004070)
02/07/2019      Kasmoor Reddy       Update Service Resource field in Product Request (US-0006381)
------------------------------------------------------------*/

@isTest
private class ProductRequestTriggerActions_Test {
    
    private static testMethod void testSetFieldValues() {
        //Create data
        TestUtility.setupConfigurationSettings();
        
        Account pacc = TestUtility.newAccount('Parent Account, now with a really long name', null);
        insert pacc;
        
        Account acc = TestUtility.newAccount('Test Account', null);
        acc.ParentId = pacc.Id;
        insert acc;
        
        Product2 prod = TestUtility.newProduct('Test Product');
        insert prod;
        
        Asset asst = TestUtility.newAsset('Test Asset', acc.Id, acc.Id, prod.Id);
        insert asst;
        
        User use = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        use.Street = '789 Easy St';
        use.City = 'Coolsville';
        use.StateCode = 'IL';
        use.PostalCode = '23456';
        use.CountryCode = 'US';
        update use;
        
        Schema.Location loc = new Schema.Location();
        loc.Name = 'Test Location';
        loc.IsInventoryLocation = true;
        loc.OwnerId = use.Id;
        insert loc;
        
        WorkOrder wo = TestUtility.newWorkOrder(acc.Id, null, asst.Id, null);
        wo.Street = '123 Main St';
        wo.City = 'Chicago';
        wo.StateCode = 'IL';
        wo.PostalCode = '12345';
        wo.CountryCode = 'US';
        wo.AccountId = acc.Id;
        wo.RecordTypeId = GlobalUtility.getRecordTypeId('WorkOrder', 'B_SH_FE_Service');
        insert wo;
        
        Schema.Address addr = new Schema.Address();
        addr.ParentId = loc.Id;
        addr.Street = '456 Main St';
        addr.City = 'Calgary';
        addr.StateCode = 'AB';
        addr.PostalCode = '456789';
        addr.CountryCode = 'CA';
        insert addr;
        
        ServiceResource sr = new ServiceResource();
        sr.Name = 'Primary SR';
        sr.RelatedRecordId = use.Id;
        sr.IsActive = true;
        insert sr;
        
        List<ProductRequest> preqs = new List<ProductRequest>();
        
        ProductRequest preq0 = new ProductRequest();
        preq0.Address_Type__c = 'Home Address';
        preq0.Service_Resource__c = sr.Id;
        preq0.OwnerId=use.Id;
        preqs.add(preq0);
        
        ProductRequest preq1 = new ProductRequest();
        preq1.Address_Type__c = 'Work Order Address';
        preq1.WorkOrderId = wo.Id;
        preq1.Service_Resource__c = sr.Id;
        preq1.OwnerId=use.Id;
        preqs.add(preq1);
        
        ProductRequest preq2 = new ProductRequest();
        preq2.Address_Type__c = 'Existing Address';
        preq2.Destination_Address__c = addr.Id;
        preq2.Service_Resource__c = sr.Id;
        preq2.OwnerId=use.Id;
        preqs.add(preq2);
        system.runAs(use){
        //Start test
        Test.startTest();
        
        //Insert ProductRequests
        insert preqs;
        
        //Stop test
        Test.stopTest();
        }
        //Validate data
        preq0 = [
            SELECT Id
                  ,ShipToStreet
                  ,ShipToCity
                  ,ShipToStateCode
                  ,ShipToPostalCode
                  ,ShipToCountryCode
                  ,OwnerId
             FROM ProductRequest
            WHERE Id = :preq0.Id
        ];
        System.assertEquals(use.Street,         preq0.ShipToStreet);
        System.assertEquals(use.City,           preq0.ShipToCity);
        System.assertEquals(use.StateCode,      preq0.ShipToStateCode);
        System.assertEquals(use.PostalCode,     preq0.ShipToPostalCode);
        System.assertEquals(use.CountryCode,    preq0.ShipToCountryCode);
        System.assertEquals(use.Id,             preq0.OwnerId);
        
        preq1 = [
            SELECT Id
                  ,ShipToStreet
                  ,ShipToCity
                  ,ShipToStateCode
                  ,ShipToPostalCode
                  ,ShipToCountryCode
                  ,AccountId
                  ,OwnerId
             FROM ProductRequest
            WHERE Id = :preq1.Id
        ];
        //System.assertEquals(pacc.Name + '\r\n' + wo.Street, preq1.ShipToStreet);
        System.assertEquals(wo.City,            preq1.ShipToCity);
        System.assertEquals(wo.StateCode,       preq1.ShipToStateCode);
        System.assertEquals(wo.PostalCode,      preq1.ShipToPostalCode);
        System.assertEquals(wo.CountryCode,     preq1.ShipToCountryCode);
        System.assertEquals(pacc.Id,            preq1.AccountId);
        System.assertEquals(use.Id,             preq1.OwnerId);
        
        preq2 = [
            SELECT Id
                  ,ShipToStreet
                  ,ShipToCity
                  ,ShipToStateCode
                  ,ShipToPostalCode
                  ,ShipToCountryCode
                  ,OwnerId
             FROM ProductRequest
            WHERE Id = :preq2.Id
        ];
        System.assertEquals(addr.Street,        preq2.ShipToStreet);
        System.assertEquals(addr.City,          preq2.ShipToCity);
        System.assertEquals(addr.StateCode,     preq2.ShipToStateCode);
        System.assertEquals(addr.PostalCode,    preq2.ShipToPostalCode);
        System.assertEquals(addr.CountryCode,   preq2.ShipToCountryCode);
        System.assertEquals(use.Id,             preq2.OwnerId);
    }
    
    private static testMethod void testCheckToClearDestinationAddress() {
        //Create data
        TestUtility.setupConfigurationSettings();
        
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
        
        ProductRequest preq = new ProductRequest();
        preq.Address_Type__c = 'Existing Address';
        preq.Destination_Address__c = addr.Id;
        insert preq;
        
        //Start test
        Test.startTest();
        
        //Update ProductRequest
        preq.Address_Type__c = 'New Address';
        preq.ShipToCountryCode = 'US';
        update preq;
        
        //Stop test
        Test.stopTest();
        
        //Validate data
        preq = [
            SELECT Id
                  ,Destination_Address__c
             FROM ProductRequest
            WHERE Id = :preq.Id
        ];
        System.assertEquals(null, preq.Destination_Address__c);
    }
    
    private static testMethod void testCreateNewAddress() {
        //Create data
        TestUtility.setupConfigurationSettings();
        
        Schema.Location loc = new Schema.Location();
        loc.Name = 'Test Location';
        loc.IsInventoryLocation = true;
        insert loc;
        
        ProductRequest preq = new ProductRequest();
        preq.Address_Type__c = 'New Address';
        preq.ShipToStreet = '123 Main St';
        
        //Start test
        Test.startTest();
        
        //Insert ProductRequest
        insert preq;
        
        //Stop test
        Test.stopTest();
        
        //Validate data
        Schema.Address addr = [
            SELECT Id
                  ,ParentId
                  ,Street
                  ,City
                  ,StateCode
                  ,PostalCode
                  ,CountryCode
                  ,LocationType
                  ,AddressType
                  ,Active__c
             FROM Address
            WHERE ParentId = :loc.Id
        ];
        System.assertEquals(loc.Id,                     addr.ParentId);
        System.assertEquals(preq.ShipToStreet,          addr.Street);
        System.assertEquals(preq.ShipToCity,            addr.City);
        System.assertEquals(preq.ShipToStateCode,       addr.StateCode);
        System.assertEquals(preq.ShipToPostalCode,      addr.PostalCode);
        System.assertEquals('Site',                     addr.LocationType);
        System.assertEquals('Shipping',                 addr.AddressType);
        System.assertEquals(true,                       addr.Active__c);
    }
     private static testMethod void testUpdateServiceResource() {
        //Create data
        TestUtility.setupConfigurationSettings();
        User use = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        use.Street = '789 Easy St';
        use.City = 'Coolsville';
        use.StateCode = 'IL';
        use.PostalCode = '23456';
        use.CountryCode = 'US';
        update use;
        Schema.Location loc = new Schema.Location();
        loc.Name = 'Test Location';
        loc.IsInventoryLocation = true;
        
        insert loc;
   
        ProductRequest preq = new ProductRequest();
        preq.Address_Type__c = 'New Address';
        preq.DestinationLocationId=loc.id;
        preq.ShipToStreet = '123 Main St';
        preq.ShipToCity='Coolsville';
        preq.OwnerId=use.Id;
        
        //Start test
        Test.startTest();
        
        //Insert ProductRequest
        insert preq;
        
        //Stop test
        Test.stopTest();
        
        //Validate data
        Schema.Address addr = [
            SELECT Id
                  ,ParentId
                  ,Street
                  ,City
                  ,StateCode
                  ,PostalCode
                  ,CountryCode
                  ,LocationType
                  ,AddressType
                  ,Active__c
             FROM Address
            WHERE ParentId = :loc.Id
        ];
        System.assertEquals(loc.Id,                     addr.ParentId);
        System.assertEquals(preq.ShipToStreet,          addr.Street);
        //System.assertEquals(preq.ShipToCity,            addr.City);
        System.assertEquals(preq.ShipToStateCode,       addr.StateCode);
        System.assertEquals(preq.ShipToPostalCode,      addr.PostalCode);
        System.assertEquals('Site',                     addr.LocationType);
        System.assertEquals('Shipping',                 addr.AddressType);
        System.assertEquals(true,                       addr.Active__c);
    }
    
}