/*------------------------------------------------------------
Author:         Ryan Lambert
Company:        Salesforce.com
Description:    ProductTransfer Trigger functions
Test Class:     ProductTransferTriggerActions_Test

History:
<Date>          <Authors Name>      <Brief Description of Change>
05/09/2018      Ryan Lambert        Initial Creation (FSL OOTB Workaround)
------------------------------------------------------------*/
public with sharing class ProductTransferTriggerActions {
    
    /*------------------------------------------------------------
    Author:         Ryan Lambert
    Company:        Salesforce.com
    Description:    Save the SerialNumber of the Source Product Item and then blank the fields to allow the Product Transfer to proceed.
					Check if there is a potential matching Product Item in the Destination Location (same Product2, same SerialNumber) 
					If found, blank the fields on that Product Item so that the Product Transfer can update rather than create in the Destination.
    Inputs:         ProductTransfer records
    Returns:        N/A
    
    History:
    <Date>          <Authors Name>      <Brief Description of Change>
    05/09/2018      Ryan Lambert        Initial Creation
    ------------------------------------------------------------*/ 
    public static void preserveSerialAndLotNumbers(List<ProductTransfer> prodTrans) {
		System.debug('ProductTransferTrigger - preserveSerialAndLotNumbers');
		        
		//DM: Create set of ProductItem Ids and of destination Ids
		Set<Id> productItemIds = new Set<Id>();
		Set<Id> destinationIds = new Set<Id>();
		for(ProductTransfer pt : prodTrans){
			productItemIds.add(pt.SourceProductItemId);
			destinationIds.add(pt.DestinationLocationId);
		}
		
		//DM: Also create sets for serial numbers and P2Ids (to be used in a moment)
		Set<String> serialNumbers = new Set<String>();
		Set<Id> product2Ids = new Set<Id>();
		
		//DM: Query OUTSIDE of the for loop, mapping those ProductItems by their Id
		Map<Id, ProductItem> pisById = new Map<Id, ProductItem>();
		for(ProductItem pi : [
			SELECT Id, LocationId, SerialNumber, Serial_Number__c, Lot_Number__c, Serial_Lot_Number__c, Master_Override_Transfer__c, 
                   Is_Serialized_Product__c, Is_Lot_Controlled__c, Product2Id
              FROM ProductItem 
             WHERE Id IN :productItemIds
		]){
			pisById.put(pi.Id, pi);
			serialNumbers.add(pi.SerialNumber);
			product2Ids.add(pi.Product2Id);
		}
		
		//DM: This time, we're going to map by something more complicated than an Id,
		//    a key structured like DestinationId|SerialNumber|Product2Id]
		Map<String, ProductItem> pisByKey = new Map<String, ProductItem>();
		for(ProductItem pi : [
			SELECT Id, LocationId, SerialNumber, Serial_Number__c, Lot_Number__c, Serial_Lot_Number__c, Master_Override_Transfer__c, 
            	   Is_Serialized_Product__c, Is_Lot_Controlled__c, Product2Id 
              FROM ProductItem 
             WHERE LocationId IN :destinationIds 
               AND SerialNumber IN :serialNumbers
               AND Product2Id IN :product2Ids
		]){
			String key = pi.LocationId + '|' + pi.SerialNumber + '|' + pi.Product2Id;
			pisByKey.put(key, pi);
		}
		
        List<ProductItem> productItemUpdate = new List<ProductItem>();        
        for(ProductTransfer pt : prodTrans){
            if (pt.SourceProductItemId != NULL) {
                String standardSerialNumber = null;
                String originalSerialNumber = null;
                String originalLotNumber = null;
                ProductItem pi = pisById.get(pt.SourceProductItemId);
                
                if (pi != NULL) {
                    standardSerialNumber = pi.SerialNumber;
                    if (pi.Is_Serialized_Product__c) {
                        originalSerialNumber = pi.SerialNumber;
                        if (originalSerialNumber != NULL) {
                            pi.Master_Override_Transfer__c = true;
                            // BLANK OUT ALL 3 FIELDS AND STORE VALUE IN NEW Serial_Lot_Number__c FIELD
                            pi.SerialNumber = '';
                            pi.Serial_Number__c = '';
                            pi.Lot_Number__c = '';
                            pi.Serial_Lot_Number__c = originalSerialNumber;
                            productItemUpdate.add(pi);
                        }                            
                    } else if (pi.Is_Lot_Controlled__c) {
                        originalLotNumber = pi.SerialNumber;
                        if (originalLotNumber != NULL) {
                            pi.Master_Override_Transfer__c = true;
                            // BLANK OUT ALL 3 FIELDS AND STORE VALUE IN NEW Serial_Lot_Number__c FIELD
                            pi.SerialNumber = '';
                            pi.Serial_Number__c = '';
                            pi.Lot_Number__c = '';
                            pi.Serial_Lot_Number__c = originalLotNumber;
                            productItemUpdate.add(pi);
                        }                                                        
                    }
                    // CHECK DESTINATION FOR MATCHING PRODUCT & LOT NUMBER / SERIAL NUMBER
                    String key = pt.DestinationLocationId + '|' + standardSerialNumber + '|' + pi.Product2Id;
                    ProductItem productItemDestination = pisByKey.get(key);
                    
                    if (productItemDestination == null) {
                        // IF NO MATCH
                        System.debug('ProductTransferTrigger - preserveSerialAndLotNumbers - [DESTINATION] - NO MATCH');                                                                                                                
                    } else {
                        if (productItemDestination.Is_Serialized_Product__c || productItemDestination.Is_Lot_Controlled__c) {
                            // IF MATCH REMOVE SN ON BOTH SOURCE AND DESTINATION PRODUCT ITEM ( source done above )
                            System.debug('ProductTransferTrigger - preserveSerialAndLotNumbers - [DESTINATION] - MATCH & SERIALIZED / LOT CONTROLLED');                                                         
                            productItemDestination.SerialNumber = '';
                            productItemDestination.Lot_Number__c = '';
                            productItemDestination.Serial_Number__c = '';
                            // TRYING TO ADDRESS SRC PI LOC == DST LOC
							productItemDestination.Serial_Lot_Number__c = standardSerialNumber;
                            // THE FOLLOWING IS JUST TO PROTECT AGAINST SELECTING THE SOURCE PRODUCT ITEM LOCATION AS THE DESTINATION WHICH WOULD ERROR.
                            // THIS SHOULD ALLOW THIS BUT RESULTS OF SUCH A TRANSFER ARE UNKNOWN
                            if (productItemUpdate.contains(productItemDestination)) {
                                // DO NOTHING
                                System.debug('ProductTransferTrigger - preserveSerialAndLotNumbers : productItemUpdate already contains pi - the Source PI');                           
                            } else {
                                productItemUpdate.add(productItemDestination);
                            }
                        } else {
                            System.debug('ProductTransferTrigger - preserveSerialAndLotNumbers - [DESTINATION] - MATCH / NO ACTION & NON-SERIALIZED / NON-LOT CONTROLLED');                                                                                     
                        }
                    }                        
                }
            }
        }
        if (productItemUpdate.isEmpty()) {
            // DO NOTHING
            System.debug('ProductTransferTrigger - preserveSerialAndLotNumbers - UPDATE SKIPPED'); 
        } else {
            System.debug('ProductTransferTrigger - preserveSerialAndLotNumbers - UPDATE'); 
            // DEBUGGING - CAN BE REMOVED - HERE JUST TO PROVE A POINT 
            Integer i = 0;
            for (ProductItem pix : productItemUpdate) {
				System.debug('ProductTransferTrigger - preserveSerialAndLotNumbers - UPDATE - DEBUGGING pix['+i+'].id 							: ' + pix.id);               
				System.debug('ProductTransferTrigger - preserveSerialAndLotNumbers - UPDATE - DEBUGGING pix['+i+'].LocationId 					: ' + pix.LocationId);
				System.debug('ProductTransferTrigger - preserveSerialAndLotNumbers - UPDATE - DEBUGGING pix['+i+'].SerialNumber 				: ' + pix.SerialNumber);
				System.debug('ProductTransferTrigger - preserveSerialAndLotNumbers - UPDATE - DEBUGGING pix['+i+'].Serial_Number__c 			: ' + pix.Serial_Number__c);
				System.debug('ProductTransferTrigger - preserveSerialAndLotNumbers - UPDATE - DEBUGGING pix['+i+'].Lot_Number__c 				: ' + pix.Lot_Number__c);
				System.debug('ProductTransferTrigger - preserveSerialAndLotNumbers - UPDATE - DEBUGGING pix['+i+'].Serial_Lot_Number__c 		: ' + pix.Serial_Lot_Number__c);
				System.debug('ProductTransferTrigger - preserveSerialAndLotNumbers - UPDATE - DEBUGGING pix['+i+'].Master_Override_Transfer__c : ' + pix.Master_Override_Transfer__c);
				System.debug('ProductTransferTrigger - preserveSerialAndLotNumbers - UPDATE - DEBUGGING pix['+i+'].Is_Serialized_Product__c 	: ' + pix.Is_Serialized_Product__c);
				System.debug('ProductTransferTrigger - preserveSerialAndLotNumbers - UPDATE - DEBUGGING pix['+i+'].Is_Lot_Controlled__c 		: ' + pix.Is_Lot_Controlled__c);                
				System.debug('ProductTransferTrigger - preserveSerialAndLotNumbers - UPDATE - DEBUGGING pix['+i+'].Product2Id 					: ' + pix.Product2Id);                                
                i++;
            }
            // Serial_Lot_Number__c will be set in one record ( source ) but null in the second ( destination ) 
            // because the source PI will have been updated to set the Serial_Lot_Number__c to match the SerialNumber
            // but this happens after the PI are added to the map so the PI in the map for destination location PI still has Serial_Lot_Number__c = null
            // even though it is technically the SAME record ( same recordID ) !!!
            update productItemUpdate;
        }	
    }

    /*------------------------------------------------------------
    Author:         Ryan Lambert
    Company:        Salesforce.com
    Description:    Restore the SerialNumber of the Source Product Item and the Product Item created / updated in the Destination Location.
    Inputs:         ProductTransfer records
    Returns:        N/A
    
    History:
    <Date>          <Authors Name>      <Brief Description of Change>
    05/09/2018      Ryan Lambert        Initial Creation
    ------------------------------------------------------------*/     
	public static void restoreSerialAndLotNumbersRefactored(List<ProductTransfer> prodTrans) {
		System.debug('ProductTransferTrigger - restoreSerialAndLotNumbersRefactored');
		List<ProductItem> productItemUpdate = new List<ProductItem>();  
        
        Set<Id> productTransferIds = new Set<Id>();
		for(ProductTransfer pt : prodTrans){
			productTransferIds.add(pt.Id);
		}
        
        Set<ProductItem> productItemsTranfered = new Set<ProductItem>();
		String SN = null;
        for(ProductItem pitm : [
        	SELECT Id, LocationId, ProductItemNumber, ProductName, QuantityOnHand, 
            SerialNumber, Serial_Number__c, Lot_Number__c, Serial_Lot_Number__c, 
            Master_Override_Transfer__c, Is_Serialized_Product__c, Is_Lot_Controlled__c, Product2Id 
            FROM ProductItem 
            WHERE ID IN (SELECT ProductItemId FROM ProductItemTransaction WHERE RelatedRecordId IN :productTransferIds)
            ORDER BY Serial_Lot_Number__c NULLS LAST 
        ]){
            // Source Product Item will have a value in Serial_Lot_Number__c when the SN / LN was saved.
            // If Destination Product Item is new then it will not have a value in Serial_Lot_Number__c but will need it.
            // Query above is order by the field holding the value. There should be 2 records in the result set, the first
            // is the Source PI if the Destination PI is new since the Destination PI will have a null value for Serial_Lot_Number__c
            if (pitm.Serial_Lot_Number__c != NULL) {
                SN = pitm.Serial_Lot_Number__c;
            } else {
                if (SN != NULL) {
                 	pitm.Serial_Lot_Number__c = SN;   
                }                
            }
			productItemsTranfered.add(pitm);
        }

		for(ProductItem pi : productItemsTranfered){
			if (pi != NULL) {        
                if (pi.Is_Serialized_Product__c) {
                    if (pi.Serial_Lot_Number__c != NULL) {
                        pi.Master_Override_Transfer__c = false;
                        pi.Lot_Number__c = '';
                        pi.Serial_Number__c = pi.Serial_Lot_Number__c;                                
                        pi.SerialNumber = pi.Serial_Lot_Number__c;                                
						if (productItemUpdate.contains(pi)) {
                            // DO NOTHING
                            System.debug('ProductTransferTrigger - restoreSerialAndLotNumbersRefactored : productItemUpdate already contains pi - the Source PI');
                        } else {
                            productItemUpdate.add(pi);                           
                        }                                                
                    }
                } else if (pi.Is_Lot_Controlled__c) {
                    if (pi.Serial_Lot_Number__c != NULL) {
                        pi.Master_Override_Transfer__c = false;
                        pi.Lot_Number__c = pi.Serial_Lot_Number__c;                                
                        pi.Serial_Number__c = '';
                        pi.SerialNumber = pi.Serial_Lot_Number__c;                                
                        if (productItemUpdate.contains(pi)) {
                            // DO NOTHING
                            System.debug('ProductTransferTrigger - restoreSerialAndLotNumbersRefactored : productItemUpdate already contains pi - the Source PI');
                        } else {
                            productItemUpdate.add(pi);                           
                        }
                    }
                }
            }
		}
        if (productItemUpdate.isEmpty()) {
            // DO NOTHING
            System.debug('ProductTransferTrigger - restoreSerialAndLotNumbersRefactored - UPDATE SKIPPED'); 
        } else {
            System.debug('ProductTransferTrigger - restoreSerialAndLotNumbersRefactored - UPDATE'); 
            update productItemUpdate;
        }      
    }    
}