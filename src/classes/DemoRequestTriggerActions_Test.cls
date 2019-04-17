/*------------------------------------------------------------
Author          Dave Mansell
Company:        Salesforce.com
Description:    Tests functions related to DemoRequest records

History:
<Date           <Authors Name>      <Brief Description of Change>
05/22/2018      Dave Mansell        Initial Creation (US-0004234)
------------------------------------------------------------*/

@isTest
private class DemoRequestTriggerActions_Test {
	
    private static testMethod void testSetDestinationAddress1() {
        //Create test data
        TestUtility.setupConfigurationSettings();
        delete [SELECT Id FROM Trigger_Switch__c WHERE Name = 'sitelocTrigger'];
        
        Account pacc = TestUtility.newAccount('Parent Account', null);
        insert pacc;
        
        Account acc = TestUtility.newAccount('Test Account', null);
        acc.ParentId = pacc.Id;
        insert acc;
        
        Site_Location__c siteLoc = new Site_Location__c();
        siteLoc.Account__c = acc.Id;
        siteLoc.Name = 'Test Site Location';
        siteLoc.Address_Line_1__c = '123';
        siteLoc.Address_Line_2__c = 'Van';
        siteLoc.Address_Line_3__c = 'Buren';
        siteLoc.Address_Line_4__c = 'Ave';
        siteLoc.City__c = 'Chicago';
        siteLoc.State__c = 'IL';
        siteLoc.Zip_Code__c = '60647';
        siteLoc.Country__c = 'US';
        insert siteLoc;
        
        Schema.Location destLoc = new Schema.Location();
        destLoc.Name = 'Test Location';
        destLoc.IsInventoryLocation = true;
        insert destLoc;
        
        Schema.Address addr = new Schema.Address();
        addr.Street = '123 Van Buren Ave';
        addr.City = 'Chicago';
        addr.StateCode = 'IL';
        addr.PostalCode = '60647';
        addr.CountryCode = 'US';
        addr.ParentId = destLoc.Id;
        addr.Site_Location__c = siteLoc.Id;
        insert addr;
        
        destLoc.VisitorAddressId = addr.Id;
        update destLoc;
        
        Demo_Request__c req = new Demo_Request__c();
        req.Destination_Location__c = destLoc.Id;
        req.End_Customer_Location__c = siteLoc.Id;
        req.End_Customer_Account__c = pacc.Id;
        
        //Start test
        Test.startTest();
        
        //Insert DR
        insert req;
        
        //Stop test
        Test.stopTest();
        
        //Validate results
        req = [
            SELECT Id
                  ,Destination_Address__c
              FROM Demo_Request__c
             WHERE Id = :req.Id
        ];
        System.assertEquals(addr.Id, req.Destination_Address__c);
        
    }

    private static testMethod void testSetDestinationAddress2() {
        //Create test data
        TestUtility.setupConfigurationSettings();
        delete [SELECT Id FROM Trigger_Switch__c WHERE Name = 'sitelocTrigger'];
        
        Account pacc = TestUtility.newAccount('Parent Account', null);
        insert pacc;
        
        Account acc = TestUtility.newAccount('Test Account', null);
        acc.ParentId = pacc.Id;
        insert acc;
        
        Site_Location__c siteLoc = new Site_Location__c();
        siteLoc.Account__c = acc.Id;
        siteLoc.Name = 'Test Site Location';
        siteLoc.Address_Line_1__c = '123';
        siteLoc.City__c = 'Chicago';
        siteLoc.State__c = 'IL';
        siteLoc.Zip_Code__c = '60647';
        siteLoc.Country__c = 'US';
        insert siteLoc;
        
        Schema.Location destLoc = new Schema.Location();
        destLoc.Name = 'Test Location';
        destLoc.IsInventoryLocation = true;
        insert destLoc;
        
        Schema.Address addr = new Schema.Address();
        addr.Street = '456 Main St';
        addr.City = 'Calgary';
        addr.StateCode = 'AB';
        addr.PostalCode = '456789';
        addr.CountryCode = 'CA';
        addr.ParentId = destLoc.Id;
        insert addr;
        
        destLoc.VisitorAddressId = addr.Id;
        update destLoc;
        
        Demo_Request__c req = new Demo_Request__c();
        req.Destination_Location__c = destLoc.Id;
        req.End_Customer_Location__c = siteLoc.Id;
        req.End_Customer_Account__c = pacc.Id;
        
        //Start test
        Test.startTest();
        
        //Insert DR
        insert req;
        
        //Stop test
        Test.stopTest();
        
        //Validate results
        req = [
            SELECT Id
                  ,Destination_Address__c
              FROM Demo_Request__c
             WHERE Id = :req.Id
        ];
        System.assertNotEquals(null, req.Destination_Address__c);
        System.assertNotEquals(addr.Id, req.Destination_Address__c);
        
    }

    private static testMethod void testCheckForApproval() {
        //Create test data
        Configuration_Settings__c orgDefaults = TestUtility.setupConfigurationSettings();
        delete [SELECT Id FROM Trigger_Switch__c WHERE Name = 'sitelocTrigger'];
        
        Account pacc = TestUtility.newAccount('Parent Account', null);
        insert pacc;
        
        Account acc = TestUtility.newAccount('Test Account', null);
        acc.ParentId = pacc.Id;
        insert acc;
        
        Pricebook2 pb = TestUtility.newPricebook('Test Pricebook');
        insert pb;
        
        orgDefaults.Default_Internal_Account__c = acc.Id;
        orgDefaults.Standard_Pricebook__c = pb.Id;
        update orgDefaults;
        
        Site_Location__c siteLoc = new Site_Location__c();
        siteLoc.Account__c = acc.Id;
        siteLoc.Name = 'Test Site Location';
        siteLoc.Address_Line_1__c = '123';
        siteLoc.City__c = 'Chicago';
        siteLoc.State__c = 'IL';
        siteLoc.Zip_Code__c = '60647';
        siteLoc.Country__c = 'US';
        insert siteLoc;
        
        Schema.Location destLoc = new Schema.Location();
        destLoc.Name = 'Test Location';
        destLoc.IsInventoryLocation = true;
        insert destLoc;
        
        Schema.Address addr = new Schema.Address();
        addr.Street = '456 Main St';
        addr.City = 'Calgary';
        addr.StateCode = 'AB';
        addr.PostalCode = '456789';
        addr.CountryCode = 'CA';
        addr.ParentId = destLoc.Id;
        insert addr;
        
        destLoc.VisitorAddressId = addr.Id;
        update destLoc;
        
        Product2 reqProd = TestUtility.newProduct('F - Test REQ Product');
        reqProd.Demo_Product__c = true;
        insert reqProd;
        
        Product2 driProd = TestUtility.newProduct('Test DRI Product');
        driProd.Demo_Product__c = true;
        insert driProd;
        
        PricebookEntry reqPBE = TestUtility.newPricebookEntry(pb.Id, reqProd.Id, 27);
        insert reqPBE;
        
        PricebookEntry driPBE = TestUtility.newPricebookEntry(pb.Id, driProd.Id, 27);
        insert driPBE;
        
        Asset asst = TestUtility.newAsset('Test Asset', acc.Id, acc.Id, reqProd.Id);
        insert asst;
        
        Demo_Request__c req = new Demo_Request__c();
        req.Destination_Location__c = destLoc.Id;
        req.End_Customer_Location__c = siteLoc.Id;
        req.End_Customer_Account__c = pacc.Id;
        req.Asset__c = asst.Id;
        req.Product__c = reqProd.Id;
        insert req;
        update req;
        
        Demo_Request_Item__c dri = new Demo_Request_Item__c();
        dri.Parent__c = req.Id;
        dri.Product__c = driProd.Id;
        dri.Quantity__c = 27;
        insert dri;
        
        //Start test
        Test.startTest();
        
        //Update req
        req.Status__c = 'Approved';
        update req;
        
        //Stop test
        Test.stopTest();
        
        //Validate results
        req = [
            SELECT Id
                  ,Destination_Address__c
                  ,Destination_Location__r.VisitorAddressId
                  ,End_Customer_Location__c
              FROM Demo_Request__c
             WHERE Id = :req.Id
        ];
        
        asst = [
            SELECT Id
                  ,Product2.Product_Source_Division__r.Source_Product_Line__r.Default_Location__c
                  ,Bill_To_Location__c
                  ,Ship_To_Location__c
                  ,Install_Location__c
                  ,Ship_To_Address__c
                  ,Install_Address__c
                  ,Bill_To_Address__c
              FROM Asset
             WHERE Id = :asst.Id
        ];
        System.assertEquals(req.End_Customer_Location__c,                   asst.Install_Location__c);
        System.assertEquals(req.Destination_Address__c,                     asst.Ship_To_Address__c);
        System.assertEquals(req.Destination_Address__c,                     asst.Install_Address__c);
        System.assertEquals(req.Destination_Location__r.VisitorAddressId,   asst.Bill_To_Address__c);
        
        Order ord = [
            SELECT Id
                  ,(SELECT Id FROM OrderItems)
              FROM Order
             WHERE Demo_Request__c = :req.Id
        ];
        System.assertNotEquals(null, ord.Id);
        System.assertEquals(2, ord.OrderItems.size());
        
    }
	
}