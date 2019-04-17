/*------------------------------------------------------------
Author			Dave Mansell
Company:		Salesforce.com
Description:	Tests functions related to ProductRequestLineItem records

History:
<Date			<Authors Name>		<Brief Description of Change>
04/26/2018		Dave Mansell		Initial Creation (US-0004070)
------------------------------------------------------------*/

@isTest
private class ProductRequestTriggerLineItemActns_Test {
	
	private static testMethod void testCopyFieldValuesFromParents() {
		TestUtility.setupConfigurationSettings();
		
		Account acc = TestUtility.newAccount('Test Account', null);
		insert acc;
		
		Schema.Location loc = new Schema.Location();
		loc.Name = 'Test Location';
		loc.IsInventoryLocation = true;
		insert loc;
		Product2 prod = TestUtility.newProduct('Test Product');
		prod.Service_Order_Warehouse_FSL__c = loc.Id;
        prod.FSL_Mobile_Orderable__c=true;
		insert prod;
		
		ProductRequest preq = new ProductRequest();
		preq.NeedByDate = Date.today();
		preq.ShipmentType = 'Test Shipment Type';
		insert preq;
		
		ProductRequestLineItem prli = new ProductRequestLineItem();
		prli.ParentId = preq.Id;
		prli.Product2Id = prod.Id;
		prli.QuantityRequested = 3;
		
		//Start test
		Test.startTest();
		
		//Insert ProductRequestLineItem
		insert prli;
		
		//Stop test
		Test.stopTest();
		
		//Validate data
		prli = [
			SELECT Id
				  ,NeedByDate
				  ,ShipmentType
				  ,Source_Org__c
				  ,DestinationLocationId
			 FROM ProductRequestLineItem
			WHERE Id = :prli.Id
		];
		System.assertEquals(preq.NeedByDate, 						prli.NeedByDate);
		System.assertEquals(preq.ShipmentType, 						prli.ShipmentType);
		System.assertEquals(prod.Service_Order_Warehouse_FSL__c, 	prli.Source_Org__c);
		System.assertEquals(loc.Id, 								prli.DestinationLocationId);
	}
	
}