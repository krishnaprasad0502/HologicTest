@isTest
global class EBSCalloutHelperMockGenerator implements HttpCalloutMock {

	global HttpResponse respond(HttpRequest req){
		//Create a fake response
		HttpResponse resp = new HttpResponse();
		resp.setHeader('Content-Type', 'application/json');
		resp.setBody('{"result":"success"}');
		resp.setStatusCode(200);
		return resp;
	}

}