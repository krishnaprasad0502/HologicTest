@isTest
global class GetTaxInformationHTTPMock implements HttpCalloutMock {
    global HTTPResponse respond(HTTPRequest request){ 
        
        // Generate the response
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');
        response.setBody('Tax information updated successfully');
        response.setStatusCode(200);
        return response;
    }
}