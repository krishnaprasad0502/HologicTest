/*------------------------------------------------------------
	Description:    	Class for ProductRquestTrigger
	Returns:        	N/A
	Test Class(es):		ProductRequestTriggerActions_Test
     <Date> 		<Authors Name>		<Brief Description of Change>
	--                 --           	Initial Creation 
    02/07/2019      Kasmoor Reddy       Update Service Resource field in Product Request (US-0006381)
	------------------------------------------------------------*/
public class ProductRequestTriggerActions {
	
	/*------------------------------------------------------------
	Author:         	Dave Mansell, Salesforce
	Description:    	Sets several field values based on parent and related records
	Inputs:         	List of records
	Returns:        	N/A
	Test Class(es):		ProductRequestTriggerActions_Test.testSetFieldValues
 	------------------------------------------------------------*/
	public static void setFieldValues(List<ProductRequest> preqs){
		//Gather parent IDs
		Map<Id, ProductRequest> preqsBySRId = new Map<Id, ProductRequest>();
		Map<Id, User> ownersById = new Map<Id, User>();
		Map<Id, WorkOrder> wosById = new Map<Id, WorkOrder>();
		Map<Id, Schema.Address> destsById = new Map<Id, Schema.Address>();
		for(ProductRequest preq : preqs){
			ownersById.put(preq.OwnerId, null);
			if(preq.Service_Resource__c != null){
				preqsBySRId.put(preq.Service_Resource__c, preq);
			}
			if(preq.Address_Type__c == 'Work Order Address' && preq.WorkOrderId != null){
				wosById.put(preq.WorkOrderId, null);
			} else if(preq.Address_Type__c == 'Existing Address' && preq.Destination_Address__c != null){
				destsById.put(preq.Destination_Address__c, null);
			}
		}
		
		//Query for service resources
		if(preqsBySRId.size() > 0){
			for(ServiceResource sr : [
				SELECT Id
					  ,RelatedRecordId
				  FROM ServiceResource
				 WHERE Id IN :preqsBySRId.keySet()
			]){
				ProductRequest preq = preqsBySRId.get(sr.Id);
				preq.OwnerId = sr.RelatedRecordId;
				ownersById.put(sr.RelatedRecordId, null);
			}
		}
		
		//Query for owner users
		ownersById = new Map<Id, User>([
			SELECT Id
				  ,Street
				  ,City
				  ,StateCode
				  ,PostalCode
				  ,CountryCode
			  FROM User
			 WHERE Id IN :ownersById.keySet()
		]);
		
		//Query for work orders, if needed
		if(wosById.size() > 0){
			wosById = new Map<Id, WorkOrder>([
				SELECT Id
					  ,Street
					  ,City
					  ,StateCode
					  ,PostalCode
					  ,CountryCode
					  ,AccountId
					  ,Account.Parent.Name
					  ,Account.ParentId
				  FROM WorkOrder
				 WHERE Id IN :wosById.keySet()
			]);
		}
		
		//Query for destination addresses, if needed
		if(destsById.size() > 0){
			destsById = new Map<Id, Schema.Address>([
				SELECT Id
					  ,Street
					  ,City
					  ,StateCode
					  ,PostalCode
					  ,CountryCode
				  FROM Address
				 WHERE Id IN :destsById.keySet()
			]);
		}
		
		for(ProductRequest preq : preqs){
			WorkOrder wo = wosById.get(preq.WorkOrderId);
			if(wo != null && wo.AccountId != null && wo.Account.ParentId != null){
				preq.AccountId = wo.Account.ParentId;
			}
			
			User owner = ownersById.get(preq.OwnerId);
			
			if(preq.Address_Type__c == 'Home Address' && owner != null){
				preq.ShipToStreet			= owner.Street;
				preq.ShipToCity				= owner.City;
				preq.ShipToStateCode		= owner.StateCode;
				preq.ShipToPostalCode		= owner.PostalCode;
				preq.ShipToCountryCode		= owner.CountryCode;
			} else if(preq.Address_Type__c == 'Work Order Address' && wo != null){
				preq.ShipToStreet			= wo.Account.Parent.Name
											  + '\r\n'
											  + wo.Street;
				preq.ShipToCity				= wo.City;
				preq.ShipToStateCode		= wo.StateCode;
				preq.ShipToPostalCode		= wo.PostalCode;
				preq.ShipToCountryCode		= wo.CountryCode;
			} else if(preq.Address_Type__c == 'Existing Address' && preq.Destination_Address__c != null){
				Schema.Address addr = destsById.get(preq.Destination_Address__c);
				preq.ShipToStreet			= addr.Street;
				preq.ShipToCity				= addr.City;
				preq.ShipToStateCode		= addr.StateCode;
				preq.ShipToPostalCode		= addr.PostalCode;
				preq.ShipToCountryCode		= addr.CountryCode;
			}
			if(preq.ShipToStreet != null){
				List<String> finalStreetArray = new List<String>();
				for(String line : preq.ShipToStreet.split('\r\n')){
					if(line.length() > 50){
						line = line.substring(0, 50);
					}
					finalStreetArray.add(line);
				}
				preq.ShipToStreet = String.join(finalStreetArray, '\r\n');
			}
		}
	}
	
	/*------------------------------------------------------------
	Author:         	Dave Mansell, Salesforce
	Description:    	Clears Destination Address if certain conditions are true
	Inputs:         	List of records, Map of old records
	Returns:        	N/A
	Test Class(es):		ProductRequestTriggerActions_Test.testCheckToClearDestinationAddress
	------------------------------------------------------------*/
	public static void checkToClearDestinationAddress(List<ProductRequest> preqs, Map<Id, ProductRequest> oldPreqs){
		for(ProductRequest preq : preqs){
			ProductRequest oldPreq = oldPreqs.get(preq.Id);
			if(preq.Destination_Address__c != null &&
			   (preq.ShipToStreet 		!= oldPreq.ShipToStreet ||
			    preq.ShipToCity 		!= oldPreq.ShipToCity ||
			    preq.ShipToStateCode 	!= oldPreq.ShipToStateCode ||
			    preq.ShipToPostalCode 	!= oldPreq.ShipToPostalCode ||
			    preq.ShipToCountryCode 	!= oldPreq.ShipToCountryCode)
			){
				preq.Destination_Address__c = null;
				preq.Address_Type__c = 'New Address';
			}
		}
	}
	
	/*------------------------------------------------------------
	Author:         	Dave Mansell, Salesforce
	Description:    	Compiles and writes address fields on the ProductRequest record(s)
	Inputs:         	List of records
	Returns:        	N/A
	Test Class(es):		ProductRequestTriggerActions_Test.testCreateNewAddress
	------------------------------------------------------------*/
	public static void createNewAddress(List<ProductRequest> preqs){
		List<Schema.Address> addressesToInsert = new List<Schema.Address>();
		
		Map<Id, ProductRequest> preqWithLocationInfoById = new Map<Id, ProductRequest>([
			SELECT Id
				  ,Service_Resource__c
				  ,Service_Resource__r.LocationId
			  FROM ProductRequest
			 WHERE Id IN :preqs
		]);
		
		//Query for user's inventory location
		List<Schema.Location> invLocations = [
			SELECT Id
			  FROM Location
			 WHERE OwnerId = :UserInfo.getUserId()
			 LIMIT 1
		];
		
		for(ProductRequest preq : preqs){
			if(preq.Address_Type__c == 'New Address' &&
			   (preq.ShipToStreet!= null ||preq.ShipToCity!= null ||preq.ShipToStateCode!= null ||preq.ShipToPostalCode!= null || preq.ShipToCountryCode 	!= null)
			){
				Schema.Address addr = new Schema.Address();
				
				ProductRequest preqWithLocationInfo = preqWithLocationInfoById.get(preq.Id);
				if(preqWithLocationInfo != null && preqWithLocationInfo.Service_Resource__c != null && preqWithLocationInfo.Service_Resource__r.LocationId != null){
					addr.ParentId = preqWithLocationInfo.Service_Resource__r.LocationId;
				} else if(preq.DestinationLocationId != null){
					addr.ParentId 		= preq.DestinationLocationId;
				} else if(addr.ParentId == null && invLocations.size() > 0){
					addr.ParentId = invLocations[0].Id;
				}
				addr.Description	= preq.ShipToStreet;
				addr.Street 		= preq.ShipToStreet;
				addr.City 			= preq.ShipToCity;
				addr.StateCode 		= preq.ShipToStateCode;
				addr.PostalCode 	= preq.ShipToPostalCode;
				addr.CountryCode 	= preq.ShipToCountryCode;
				addr.LocationType	= 'Site';
				addr.AddressType	= 'Shipping';
				addr.Active__c		= true;
				
				addressesToInsert.add(addr);
			}
		}
		
		insert addressesToInsert;
	}
    	/*------------------------------------------------------------
	Author:         	Kasmoor Reddy,Apps Associates
	Description:    	Update ServiceResource field based on owner of ProductRequest
	Inputs:         	List of updated/created records
	Returns:        	N/A
	Test Class(es):		ProductRequestTriggerActions_Test.testUpdateServiceResource
 	------------------------------------------------------------*/
    public static void UpdateServiceResourceField(List<ProductRequest> NewProductRequestList,Map<Id,ProductRequest> OldProductRequestMap)
    {
      Map<Id,Id> UserServiceId=new Map<Id,Id>();
      List<Id> OwnerId=new List<Id>();
      for(ProductRequest ProdReq:NewProductRequestList)
      {
          if(!OwnerId.contains(ProdReq.ownerId))
          OwnerId.add(ProdReq.ownerId);
      }
      List<ServiceResource> servResourceList=new List<ServiceResource>([Select id,RelatedRecordId,RelatedRecord.name from ServiceResource where RelatedRecordId in: OwnerId]);
      for(ServiceResource sr:servResourceList)
      {
        UserServiceId.put(sr.RelatedRecordId,sr.id);  
      }
      for(ProductRequest ProdReq:NewProductRequestList)
      {
          if(ProdReq.Service_Resource__c==null)
          {
              if(UserServiceId.containsKey(ProdReq.ownerId))
                  ProdReq.Service_Resource__c=UserServiceId.get(ProdReq.ownerId);
              
          }
      }
    }
	
}