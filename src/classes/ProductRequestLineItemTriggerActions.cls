public class ProductRequestLineItemTriggerActions {
	
	/*------------------------------------------------------------
	Author:         	Dave Mansell, Salesforce
	Description:    	Sets field values on ProductRequestLineItem records based on parent values
	Inputs:         	List of records
	Returns:        	N/A
	Test Class(es):		ProductRequestLineItemTriggerActns_Test.testCopyFieldValuesFromParents
	------------------------------------------------------------*/
	public static void copyFieldValuesFromParents(List<ProductRequestLineItem> prlis){
		//Gather parent IDs
		Map<Id, ProductRequest> prsById = new Map<Id, ProductRequest>();
		Map<Id, Product2> prodsById = new Map<Id, Product2>();
		for(ProductRequestLineItem prli : prlis){
			prsById.put(prli.ParentId, null);
			prodsById.put(prli.Product2Id, null);
		}
		
		//Query for ProductRequests
		Set<Id> ownerIds = new Set<Id>();
		prsById = new Map<Id, ProductRequest>([
			SELECT Id
				  ,NeedByDate
				  ,ShipmentType
				  ,OwnerId
			  FROM ProductRequest
			 WHERE Id IN :prsById.keySet()
		]);
		for(ProductRequest preq : prsById.values()){
			ownerIds.add(preq.OwnerId);
		}
		
		//Query for Product2s
		prodsById = new Map<Id, Product2>([
			SELECT Id
				  ,Service_Order_Warehouse_FSL__c
			  FROM Product2
			 WHERE Id IN :prodsById.keySet()
		]);
		
		//Query for owner's inventory location
		Map<Id, Schema.Location> invLocationsByOwnerId = new Map<Id, Schema.Location>();
		for(Schema.Location loc : [
			SELECT Id, OwnerId
			  FROM Location
			 WHERE OwnerId IN :ownerIds
			 LIMIT 1
		]){
			invLocationsByOwnerId.put(loc.OwnerId, loc);
		}
		
		//Copy values onto PRLIs
		for(ProductRequestLineItem prli : prlis){
			ProductRequest pr = prsById.get(prli.ParentId);
			Product2 prod = prodsById.get(prli.Product2Id);
			
			prli.NeedByDate = pr.NeedByDate;
			prli.ShipmentType = pr.ShipmentType;
			prli.Source_Org__c = prod.Service_Order_Warehouse_FSL__c;
			if(invLocationsByOwnerId.size() > 0){
				prli.DestinationLocationId = invLocationsByOwnerId.get(pr.OwnerId).Id;
			}
		}
	}

}