global class EBSCalloutHelper {
	
	public static void sendProductConsumedIDs(List<Id> pcIds){
		List<ProductConsumed__e> pcEvents = new List<ProductConsumed__e>();
    
	    for(Id pcId : pcIds) {
	    	ProductConsumed__e pcEvent = new ProductConsumed__e();
	    	pcEvent.ObjId__c = pcId;
	        pcEvents.add(pcEvent);
	    }
	    
	    
	    // Call method to publish events
	    List<Database.SaveResult> results = EventBus.publish(pcEvents);
	    
	    // Inspect publishing result for each event
	    for (Database.SaveResult sr : results) {
	        if (sr.isSuccess()) {
	            System.debug('Successfully published event.');
	        } else {
	            for(Database.Error err : sr.getErrors()) {
	                System.debug('Error returned: ' +
	                            err.getStatusCode() +
	                            ' - ' +
	                            err.getMessage());
	            }
	        }      
	    }
	}
	
	/*
	@future(callout=true)
	webservice static void sendProductConsumedIDs(List<Id> pcIds){
		HttpRequest req = new HttpRequest();
		req.setEndpoint('callout:EBS_Endpoint_Product_Consumed');
		req.setHeader('Content-Type', 'application/json');
		req.setMethod('POST');
		
		List<DataWrapperLine> lines = new List<DataWrapperLine>();
		for(Id pcId : pcIds){
			lines.add(new DataWrapperLine('ProductConsumed', pcId));
		}
		DataWrapper wrapper = new DataWrapper(UserInfo.getOrganizationId(), lines);
		req.setBody(JSON.serialize(wrapper));
		
		HttpResponse resp = new Http().send(req);
	}

	private class DataWrapper {
		Id OrganizationId						{get;set;}
		List<DataWrapperLine> Notifications		{get;set;}
		
		private DataWrapper(Id orgId, List<DataWrapperLine> lines){
			this.OrganizationId = orgId;
			this.Notifications 	= lines;
		}
	}
	
	private class DataWrapperLine {
		String ObjType	{get;set;}
		Id ObjId		{get;set;}
		
		private DataWrapperLine(String sObjectName, Id recId){
			this.ObjType 	= sObjectName;
			this.ObjId 		= recId;
		}
	}
	*/
}