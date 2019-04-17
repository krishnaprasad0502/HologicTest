@isTest
global class ServiceReportCalloutHelperMockGenerator implements HttpCalloutMock {
	
	global Id woId	{get;set;}
	
	global ServiceReportCalloutHelperMockGenerator(Id woId){
		this.woId = woId;
	}

	global HttpResponse respond(HttpRequest req){
		ContentNote nte = new ContentNote();
		nte.Title = 'Test Doc';
		insert nte;
		
		ContentVersion cv = [
			SELECT Id
			  FROM ContentVersion
			 WHERE ContentDocumentId = :nte.Id
		];
		
		//Create a fake response
		HttpResponse resp = new HttpResponse();
		resp.setHeader('Content-Type', 'application/json');
		resp.setBody('[{"actionName":"createServiceReport","errors":null,"isSuccess":true,"outputValues":{"serviceReportId":"' + woId + '","contentVersionId":"' + cv.Id + '","entityId":"' + woId + '"}}]');
		resp.setStatusCode(200);
		return resp;
	}

}