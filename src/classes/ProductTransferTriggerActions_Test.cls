/*------------------------------------------------------------
Author:         Ryan Lambert
Company:        Salesforce.com
Description:    ProductTransfer Trigger Test

History:
<Date>          <Authors Name>      <Brief Description of Change>
05/09/2018      Ryan Lambert        Initial Creation
------------------------------------------------------------*/
@isTest
private class ProductTransferTriggerActions_Test {

    /*------------------------------------------------------------
    Author:         Ryan Lambert
    Company:        Salesforce.com
    Description:    Create source and destination Locations, 
                    create 1 non-serialized Product,
                    create 1 ProductItem at source Location.
                    Initiate ProductTransfer to destination Location.
                    Test ProductItem in source Location QuantityOnHand reduced by QuantityReceived.
    Inputs:         None
    Returns:        N/A
    
    History:
    <Date>          <Authors Name>      <Brief Description of Change>
    05/09/2018      Ryan Lambert        Initial Creation
    ------------------------------------------------------------*/    
    private static testMethod void testProductTransferNonSerialized() {     
        double ORIGINAL_QUANTITY = 5;
        double TRANSFER_QUANTITY = 3;
        
        TestUtility.insertCustSetting('ProductTransfer');
        
        Schema.Location srcLoc = new Schema.Location();
        srcLoc.Name = 'Source Location';
        srcLoc.IsInventoryLocation = true;
        insert srcLoc;

        Schema.Location dstLoc = new Schema.Location();
        dstLoc.Name = 'Destination Location';
        dstLoc.IsInventoryLocation = true;
        insert dstLoc;
        
        Product2 prod = TestUtility.newProduct('Test Product');
        prod.Serialized__c = false;
        prod.Lot_Controlled__c = false;
        insert prod;
        
        ProductItem piSrc = new ProductItem();
        piSrc.Product2Id = prod.Id;
        piSrc.QuantityOnHand = ORIGINAL_QUANTITY;
        piSrc.LocationId = srcLoc.Id;
        insert piSrc;
        
        ProductTransfer prtrf = new ProductTransfer();
        prtrf.SourceProductItemId = piSrc.id;
        prtrf.DestinationLocationId = dstLoc.id;
        prtrf.IsReceived = true;
        prtrf.QuantityReceived = TRANSFER_QUANTITY;
        prtrf.QuantitySent = TRANSFER_QUANTITY;
                
        Test.startTest();
        
        insert prtrf;
        
        Test.stopTest();
        
        ProductItem piS = [SELECT id, QuantityOnHand, LocationId FROM ProductItem WHERE id =: piSrc.id];
        
        System.assertEquals(piS.QuantityOnHand, ORIGINAL_QUANTITY-TRANSFER_QUANTITY);                
    }

    /*------------------------------------------------------------
    Author:         Ryan Lambert
    Company:        Salesforce.com
    Description:    Create source and destination Locations, 
                    create 1 serialized Product,
                    create 1 ProductItem at source Location.
                    Initiate ProductTransfer to destination Location.
                    Test ProductItem in source Location QuantityOnHand reduced by QuantityReceived (QuantityOnHand=0).
    Inputs:         None
    Returns:        N/A
    
    History:
    <Date>          <Authors Name>      <Brief Description of Change>
    05/09/2018      Ryan Lambert        Initial Creation
    ------------------------------------------------------------*/       
    private static testMethod void testProductTransferSerializedEmptyDestination() {        
        double ORIGINAL_QUANTITY = 1;
        double TRANSFER_QUANTITY = 1;
        String SERIAL_NUMBER = 'SN-TEST-111';

        TestUtility.insertCustSetting('ProductTransfer');        
        
        Schema.Location srcLoc = new Schema.Location();
        srcLoc.Name = 'Source Location';
        srcLoc.IsInventoryLocation = true;
        insert srcLoc;

        Schema.Location dstLoc = new Schema.Location();
        dstLoc.Name = 'Destination Location';
        dstLoc.IsInventoryLocation = true;
        insert dstLoc;
        
        Product2 prod = TestUtility.newProduct('Test Product');
        prod.Serialized__c = true;
        prod.Lot_Controlled__c = false;
        insert prod;
        
        ProductItem piSrc = new ProductItem();
        piSrc.Product2Id = prod.Id;
        piSrc.QuantityOnHand = ORIGINAL_QUANTITY;
        piSrc.LocationId = srcLoc.Id;
        piSrc.SerialNumber = SERIAL_NUMBER;
        piSrc.Serial_Number__c = SERIAL_NUMBER;
        insert piSrc;
        
        ProductTransfer prtrf = new ProductTransfer();
        prtrf.SourceProductItemId = piSrc.id;
        prtrf.DestinationLocationId = dstLoc.id;
        prtrf.IsReceived = true;
        prtrf.QuantityReceived = TRANSFER_QUANTITY;
        prtrf.QuantitySent = TRANSFER_QUANTITY;
                
        Test.startTest();
        
        insert prtrf;
        
        Test.stopTest();
        
        ProductItem piS = [SELECT id, QuantityOnHand, LocationId FROM ProductItem WHERE id =: piSrc.id];
        
        System.assertEquals(piS.QuantityOnHand, ORIGINAL_QUANTITY-TRANSFER_QUANTITY);

        List<ProductItem> pi = [SELECT Id, LocationId, ProductItemNumber, ProductName, QuantityOnHand, 
                                SerialNumber, Serial_Number__c, Lot_Number__c, Serial_Lot_Number__c, Master_Override_Transfer__c, 
                                Is_Serialized_Product__c, Is_Lot_Controlled__c, Product2Id 
                                FROM ProductItem WHERE ID IN (SELECT ProductItemId FROM ProductItemTransaction WHERE RelatedRecordId =: prtrf.id)];            

        ProductItem pi1 = pi[0];
        ProductItem pi2 = pi[1];
        
        System.assertEquals(pi1.SerialNumber, pi2.SerialNumber);
        System.assertEquals(pi1.Serial_Number__c, pi2.Serial_Number__c);
        System.assertEquals(pi1.Lot_Number__c, pi2.Lot_Number__c);
        System.assertEquals(pi1.Serial_Lot_Number__c, pi2.Serial_Lot_Number__c);                    
    }    

    /*------------------------------------------------------------
    Author:         Ryan Lambert
    Company:        Salesforce.com
    Description:    Create source and destination Locations, 
                    create 1 lot controlled Product,
                    create 1 ProductItem at source Location.
                    Initiate ProductTransfer to destination Location.
                    Test ProductItem in source Location QuantityOnHand reduced by QuantityReceived.
    Inputs:         None
    Returns:        N/A
    
    History:
    <Date>          <Authors Name>      <Brief Description of Change>
    05/09/2018      Ryan Lambert        Initial Creation
    ------------------------------------------------------------*/    
    private static testMethod void testProductTransferLotControlledEmptyDestination() {     
        double ORIGINAL_QUANTITY = 1000;
        double TRANSFER_QUANTITY = 100;
        String LOT_NUMBER = 'LN-TEST-111';

        TestUtility.insertCustSetting('ProductTransfer');        
        
        Schema.Location srcLoc = new Schema.Location();
        srcLoc.Name = 'Source Location';
        srcLoc.IsInventoryLocation = true;
        insert srcLoc;

        Schema.Location dstLoc = new Schema.Location();
        dstLoc.Name = 'Destination Location';
        dstLoc.IsInventoryLocation = true;
        insert dstLoc;
        
        Product2 prod = TestUtility.newProduct('Test Product');
        prod.Serialized__c = false;
        prod.Lot_Controlled__c = true;
        insert prod;
        
        ProductItem piSrc = new ProductItem();
        piSrc.Product2Id = prod.Id;
        piSrc.QuantityOnHand = ORIGINAL_QUANTITY;
        piSrc.LocationId = srcLoc.Id;
        piSrc.SerialNumber = LOT_NUMBER;
        piSrc.Lot_Number__c = LOT_NUMBER;
        insert piSrc;
        
        ProductTransfer prtrf = new ProductTransfer();
        prtrf.SourceProductItemId = piSrc.id;
        prtrf.DestinationLocationId = dstLoc.id;
        prtrf.IsReceived = true;
        prtrf.QuantityReceived = TRANSFER_QUANTITY;
        prtrf.QuantitySent = TRANSFER_QUANTITY;
                
        Test.startTest();
        
        insert prtrf;
        
        Test.stopTest();
        
        ProductItem piS = [SELECT id, QuantityOnHand, LocationId FROM ProductItem WHERE id =: piSrc.id];
        
        System.assertEquals(piS.QuantityOnHand, ORIGINAL_QUANTITY-TRANSFER_QUANTITY);   
        
        List<ProductItem> pi = [SELECT Id, LocationId, ProductItemNumber, ProductName, QuantityOnHand, 
                                SerialNumber, Serial_Number__c, Lot_Number__c, Serial_Lot_Number__c, Master_Override_Transfer__c, 
                                Is_Serialized_Product__c, Is_Lot_Controlled__c, Product2Id 
                                FROM ProductItem WHERE ID IN (SELECT ProductItemId FROM ProductItemTransaction WHERE RelatedRecordId =: prtrf.id)];            

        ProductItem pi1 = pi[0];
        ProductItem pi2 = pi[1];
        
        System.assertEquals(pi1.SerialNumber, pi2.SerialNumber);
        System.assertEquals(pi1.Serial_Number__c, pi2.Serial_Number__c);
        System.assertEquals(pi1.Lot_Number__c, pi2.Lot_Number__c);
        System.assertEquals(pi1.Serial_Lot_Number__c, pi2.Serial_Lot_Number__c);                
    }

    /*------------------------------------------------------------
    Author:         Ryan Lambert
    Company:        Salesforce.com
    Description:    Create source and destination Locations, 
                    create 1 serialized Product,
                    create 1 ProductItem at source Location.
                    create 1 ProductItem at destination Location (QuantityOnHand = 0).
                    Initiate ProductTransfer to destination Location.
                    Test ProductItem in source Location QuantityOnHand reduced by QuantityReceived (QuantityOnHand=0).
                    Test ProductItem in destination Location QuantityOnHand increased by QuantityReceived (QuantityOnHand=1).

    Inputs:         None
    Returns:        N/A
    
    History:
    <Date>          <Authors Name>      <Brief Description of Change>
    05/09/2018      Ryan Lambert        Initial Creation
    ------------------------------------------------------------*/
    private static testMethod void testProductTransferSerializedReturn() {      
        double ORIGINAL_QUANTITY = 1;
        double TRANSFER_QUANTITY = 1;
        String SERIAL_NUMBER = 'SN-TEST-111';

        TestUtility.insertCustSetting('ProductTransfer');        
        
        Schema.Location srcLoc = new Schema.Location();
        srcLoc.Name = 'Source Location';
        srcLoc.IsInventoryLocation = true;
        insert srcLoc;

        Schema.Location dstLoc = new Schema.Location();
        dstLoc.Name = 'Destination Location';
        dstLoc.IsInventoryLocation = true;
        insert dstLoc;
        
        Product2 prod = TestUtility.newProduct('Test Product');
        prod.Serialized__c = true;
        prod.Lot_Controlled__c = false;
        insert prod;
        
        ProductItem piSrc = new ProductItem();
        piSrc.Product2Id = prod.Id;
        piSrc.QuantityOnHand = ORIGINAL_QUANTITY;
        piSrc.LocationId = srcLoc.Id;
        piSrc.SerialNumber = SERIAL_NUMBER;
        piSrc.Serial_Number__c = SERIAL_NUMBER;
        insert piSrc;

        ProductItem piDst = new ProductItem();
        piDst.Product2Id = prod.Id;
        piDst.QuantityOnHand = 0;
        piDst.LocationId = dstLoc.Id;
        piDst.SerialNumber = SERIAL_NUMBER;
        piDst.Serial_Number__c = SERIAL_NUMBER;
        insert piDst;
        
        ProductTransfer prtrf = new ProductTransfer();
        prtrf.SourceProductItemId = piSrc.id;
        prtrf.DestinationLocationId = dstLoc.id;
        prtrf.IsReceived = true;
        prtrf.QuantityReceived = TRANSFER_QUANTITY;
        prtrf.QuantitySent = TRANSFER_QUANTITY;
                
        Test.startTest();
        
        insert prtrf;
        
        Test.stopTest();
        
        ProductItem piS = [SELECT id, QuantityOnHand, SerialNumber, Serial_Number__c, Lot_Number__c, Serial_Lot_Number__c FROM ProductItem WHERE id =: piSrc.id];
        ProductItem piD = [SELECT id, QuantityOnHand, SerialNumber, Serial_Number__c, Lot_Number__c, Serial_Lot_Number__c FROM ProductItem WHERE id =: piDst.id];
        
        System.assertEquals(piS.QuantityOnHand, ORIGINAL_QUANTITY-TRANSFER_QUANTITY);                
        System.assertEquals(piD.QuantityOnHand, TRANSFER_QUANTITY);
        System.assertEquals(piS.SerialNumber, piD.SerialNumber);
        System.assertEquals(piS.Serial_Number__c, piD.Serial_Number__c);
        System.assertEquals(piS.Lot_Number__c, piD.Lot_Number__c);
        System.assertEquals(piS.Serial_Lot_Number__c, piD.Serial_Lot_Number__c);                             
    }    

    /*------------------------------------------------------------
    Author:         Ryan Lambert
    Company:        Salesforce.com
    Description:    Create source and destination Locations, 
                    create 1 lot controlled Product,
                    create 1 ProductItem at source Location.
                    create 1 ProductItem at destination Location.
                    Initiate ProductTransfer to destination Location.
                    Test ProductItem in source Location QuantityOnHand reduced by QuantityReceived.
                    Test ProductItem in destination Location QuantityOnHand increased by QuantityReceived.

    Inputs:         None
    Returns:        N/A
    
    History:
    <Date>          <Authors Name>      <Brief Description of Change>
    05/09/2018      Ryan Lambert        Initial Creation
    ------------------------------------------------------------*/    
    private static testMethod void testProductTransferLotControlledConsolidate() {      
        double SOURCE_QUANTITY = 1000;
        double DESTINATION_QUANTITY = 500;        
        double TRANSFER_QUANTITY = 100;
        String LOT_NUMBER = 'LN-TEST-111';

        TestUtility.insertCustSetting('ProductTransfer');        
        
        Schema.Location srcLoc = new Schema.Location();
        srcLoc.Name = 'Source Location';
        srcLoc.IsInventoryLocation = true;
        insert srcLoc;

        Schema.Location dstLoc = new Schema.Location();
        dstLoc.Name = 'Destination Location';
        dstLoc.IsInventoryLocation = true;
        insert dstLoc;
        
        Product2 prod = TestUtility.newProduct('Test Product');
        prod.Serialized__c = false;
        prod.Lot_Controlled__c = true;
        insert prod;
        
        ProductItem piSrc = new ProductItem();
        piSrc.Product2Id = prod.Id;
        piSrc.QuantityOnHand = SOURCE_QUANTITY;
        piSrc.LocationId = srcLoc.Id;
        piSrc.SerialNumber = LOT_NUMBER;
        piSrc.Lot_Number__c = LOT_NUMBER;
        insert piSrc;

        ProductItem piDst = new ProductItem();
        piDst.Product2Id = prod.Id;
        piDst.QuantityOnHand = DESTINATION_QUANTITY;
        piDst.LocationId = dstLoc.Id;
        piDst.SerialNumber = LOT_NUMBER;
        piDst.Lot_Number__c = LOT_NUMBER;
        insert piDst;
        
        ProductTransfer prtrf = new ProductTransfer();
        prtrf.SourceProductItemId = piSrc.id;
        prtrf.DestinationLocationId = dstLoc.id;
        prtrf.IsReceived = true;
        prtrf.QuantityReceived = TRANSFER_QUANTITY;
        prtrf.QuantitySent = TRANSFER_QUANTITY;
                
        Test.startTest();
        
        insert prtrf;
        
        Test.stopTest();
        
        ProductItem piS = [SELECT id, QuantityOnHand, SerialNumber, Serial_Number__c, Lot_Number__c, Serial_Lot_Number__c FROM ProductItem WHERE id =: piSrc.id];
        ProductItem piD = [SELECT id, QuantityOnHand, SerialNumber, Serial_Number__c, Lot_Number__c, Serial_Lot_Number__c FROM ProductItem WHERE id =: piDst.id];
        
        System.assertEquals(piS.QuantityOnHand, SOURCE_QUANTITY-TRANSFER_QUANTITY);
        System.assertEquals(piD.QuantityOnHand, DESTINATION_QUANTITY+TRANSFER_QUANTITY);
        System.assertEquals(piS.SerialNumber, piD.SerialNumber);
        System.assertEquals(piS.Serial_Number__c, piD.Serial_Number__c);
        System.assertEquals(piS.Lot_Number__c, piD.Lot_Number__c);
        System.assertEquals(piS.Serial_Lot_Number__c, piD.Serial_Lot_Number__c);                       
    }     

    /*------------------------------------------------------------
    Author:         Ryan Lambert
    Company:        Salesforce.com
    Description:    Create source and destination Locations, 
                    create 1 lot controlled Product,
                    create 1 ProductItem at source Location.
                    Initiate ProductTransfer to destination Location.
                    Update ProductTransfer ( Integration Status & Integration Message )
                    Test ProductItem in source Location QuantityOnHand reduced by QuantityReceived.
                    This test is really testing what Integration is doing.
                    
    Inputs:         None
    Returns:        N/A
    
    History:
    <Date>          <Authors Name>      <Brief Description of Change>
    05/09/2018      Ryan Lambert        Initial Creation
    ------------------------------------------------------------*/        
    private static testMethod void testProductTransferSerializedEmptyDestinationEdit() {        
        double ORIGINAL_QUANTITY = 1;
        double TRANSFER_QUANTITY = 1;
        String HOLOGIC_INTEGRATION_USER_ALIAS = 'holx_int';
        String SERIAL_NUMBER = 'SN-TEST-111';
        String INT_MSG = 'Integration Message';
        String INT_STATUS = 'Integration Status';

        TestUtility.insertCustSetting('ProductTransfer');        
        
        Schema.Location srcLoc = new Schema.Location();
        srcLoc.Name = 'Source Location';
        srcLoc.IsInventoryLocation = true;
        insert srcLoc;

        Schema.Location dstLoc = new Schema.Location();
        dstLoc.Name = 'Destination Location';
        dstLoc.IsInventoryLocation = true;
        insert dstLoc;
        
        Product2 prod = TestUtility.newProduct('Test Product');
        prod.Serialized__c = true;
        prod.Lot_Controlled__c = false;
        insert prod;
        
        ProductItem piSrc = new ProductItem();
        piSrc.Product2Id = prod.Id;
        piSrc.QuantityOnHand = ORIGINAL_QUANTITY;
        piSrc.LocationId = srcLoc.Id;
        piSrc.SerialNumber = SERIAL_NUMBER;
        piSrc.Serial_Number__c = SERIAL_NUMBER;
        insert piSrc;
        
        ProductTransfer prtrf = new ProductTransfer();
        prtrf.SourceProductItemId = piSrc.id;
        prtrf.DestinationLocationId = dstLoc.id;
        prtrf.IsReceived = true;
        prtrf.QuantityReceived = TRANSFER_QUANTITY;
        prtrf.QuantitySent = TRANSFER_QUANTITY;
        
        Test.startTest();
        
        insert prtrf;
                
        prtrf.Integration_Message__c = INT_MSG;
        prtrf.Integration_Status__c = INT_STATUS;

        // Create a dummy user with the Integration User Alias to pass the validation rule.        
        Profile p = [SELECT Id FROM Profile WHERE Name='Integration API User'];
        User intUser = new User(Alias = HOLOGIC_INTEGRATION_USER_ALIAS, Email='newuser@testorg.com',
         EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
         LocaleSidKey='en_US', ProfileId = p.Id,
         TimeZoneSidKey='America/Los_Angeles', UserName='newuser2018@testorg.com');
      
        System.runAs(intUser) {        
            update prtrf;
        }
        
        Test.stopTest();
        
        ProductItem piS = [SELECT id, QuantityOnHand, LocationId FROM ProductItem WHERE id =: piSrc.id];

        System.assertEquals(piS.QuantityOnHand, ORIGINAL_QUANTITY-TRANSFER_QUANTITY);

        List<ProductItem> pi = [SELECT Id, LocationId, ProductItemNumber, ProductName, QuantityOnHand, 
                                SerialNumber, Serial_Number__c, Lot_Number__c, Serial_Lot_Number__c, Master_Override_Transfer__c, 
                                Is_Serialized_Product__c, Is_Lot_Controlled__c, Product2Id
                                FROM ProductItem WHERE ID IN (SELECT ProductItemId FROM ProductItemTransaction WHERE RelatedRecordId =: prtrf.id)];            

        Integer sz = pi.size();
        ProductItem pi1 = pi[0];
        ProductItem pi2 = pi[1];
               
        System.assertEquals(pi1.SerialNumber, pi2.SerialNumber);
        System.assertEquals(pi1.Serial_Number__c, pi2.Serial_Number__c);
        System.assertEquals(pi1.Lot_Number__c, pi2.Lot_Number__c);
        System.assertEquals(pi1.Serial_Lot_Number__c, pi2.Serial_Lot_Number__c); 
        
        ProductTransfer pt = [SELECT id, Integration_Message__c, Integration_Status__c from ProductTransfer where Id =: prtrf.id];
        
        System.assertEquals(pt.Integration_Message__c, INT_MSG);
        System.assertEquals(pt.Integration_Status__c, INT_STATUS);            
    }
    
    /*------------------------------------------------------------
    Author:         Ryan Lambert
    Company:        Salesforce.com
    Description:    Create destination Location, 
                    create 1 non-Serialized Product,
                    create 1 ProductItem at destination Location.
                    Initiate ProductTransfer to destination Location.
                    Test for same QTY after the Transfer.

    Inputs:         None
    Returns:        N/A
    
    History:
    <Date>          <Authors Name>      <Brief Description of Change>
    05/09/2018      Ryan Lambert        Initial Creation
    ------------------------------------------------------------*/    
    private static testMethod void testProductTransferNonSerializedSameLocation() {     
        double SOURCE_QUANTITY = 1000;
        double TRANSFER_QUANTITY = 100;

        TestUtility.insertCustSetting('ProductTransfer');        
        
        Schema.Location dstLoc = new Schema.Location();
        dstLoc.Name = 'Destination Location';
        dstLoc.IsInventoryLocation = true;
        insert dstLoc;
        
        Product2 prod = TestUtility.newProduct('Test Product');
        prod.Serialized__c = false;
        prod.Lot_Controlled__c = false;
        insert prod;
        
        ProductItem piSrc = new ProductItem();
        piSrc.Product2Id = prod.Id;
        piSrc.QuantityOnHand = SOURCE_QUANTITY;
        piSrc.LocationId = dstLoc.Id;
        insert piSrc;
        
        ProductTransfer prtrf = new ProductTransfer();
        prtrf.SourceProductItemId = piSrc.id;
        prtrf.DestinationLocationId = dstLoc.id;
        prtrf.IsReceived = true;
        prtrf.QuantityReceived = TRANSFER_QUANTITY;
        prtrf.QuantitySent = TRANSFER_QUANTITY;
                
        Test.startTest();
        
        insert prtrf;
        
        Test.stopTest();
        
        ProductItem piS = [SELECT id, QuantityOnHand, SerialNumber, Serial_Number__c, Lot_Number__c, Serial_Lot_Number__c FROM ProductItem WHERE id =: piSrc.id];
        
        System.debug('Product Item Quantity : '+piS.QuantityOnHand);
        System.debug('Product Item SerialNumber : '+piS.SerialNumber);        
        // SOURCE PI QTY - TRANSFER QTY + TRANSFER QTY BECAUSE ITS TO THE SAME LOCATION !!
        System.assertEquals(piS.QuantityOnHand, SOURCE_QUANTITY-TRANSFER_QUANTITY+TRANSFER_QUANTITY);                
        System.assertEquals(piS.SerialNumber, null);                               
    }
    
    /*------------------------------------------------------------
    Author:         Ryan Lambert
    Company:        Salesforce.com
    Description:    Create destination Location, 
                    create 1 Serialized Product,
                    create 1 ProductItem at destination Location.
                    Initiate ProductTransfer to destination Location.
                    Test for same QTY after the Transfer.

    Inputs:         None
    Returns:        N/A
    
    History:
    <Date>          <Authors Name>      <Brief Description of Change>
    05/09/2018      Ryan Lambert        Initial Creation
    ------------------------------------------------------------*/    
    private static testMethod void testProductTransferSerializedSameLocation() {        
        double ORIGINAL_QUANTITY = 1;
        double TRANSFER_QUANTITY = 1;
        String SERIAL_NUMBER = 'SN-TEST-111';

        TestUtility.insertCustSetting('ProductTransfer');        
        
        Schema.Location dstLoc = new Schema.Location();
        dstLoc.Name = 'Destination Location';
        dstLoc.IsInventoryLocation = true;
        insert dstLoc;
        
        Product2 prod = TestUtility.newProduct('Test Product');
        prod.Serialized__c = true;
        prod.Lot_Controlled__c = false;
        insert prod;
        
        ProductItem piSrc = new ProductItem();
        piSrc.Product2Id = prod.Id;
        piSrc.QuantityOnHand = ORIGINAL_QUANTITY;
        piSrc.LocationId = dstLoc.Id;
        piSrc.SerialNumber = SERIAL_NUMBER;
        piSrc.Serial_Number__c = SERIAL_NUMBER;
        insert piSrc;
        
        ProductTransfer prtrf = new ProductTransfer();
        prtrf.SourceProductItemId = piSrc.id;
        prtrf.DestinationLocationId = dstLoc.id;
        prtrf.IsReceived = true;
        prtrf.QuantityReceived = TRANSFER_QUANTITY;
        prtrf.QuantitySent = TRANSFER_QUANTITY;
                
        Test.startTest();
        
        insert prtrf;
        
        Test.stopTest();
        
        ProductItem piS = [SELECT id, QuantityOnHand, SerialNumber, Serial_Number__c, Lot_Number__c, Serial_Lot_Number__c FROM ProductItem WHERE id =: piSrc.id];
        
        System.debug('Product Item Quantity : '+piS.QuantityOnHand);
        System.debug('Product Item SerialNumber : '+piS.SerialNumber);        
        // SOURCE PI QTY - TRANSFER QTY + TRANSFER QTY BECAUSE ITS TO THE SAME LOCATION !!
        System.assertEquals(piS.QuantityOnHand, ORIGINAL_QUANTITY-TRANSFER_QUANTITY+TRANSFER_QUANTITY);                
        System.assertEquals(piS.SerialNumber, SERIAL_NUMBER);                        
       
    }     
}