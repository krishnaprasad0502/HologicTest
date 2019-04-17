/*------------------------------------------------------------
Author:         Mani Sundaresan
Description:    HTTPMockResponse to be used by GenerateQRCode_Test to validate the JSON reponse from Azure via Mulesoft

History:
<Date>          <Authors Name>      <Brief Description of Change>
03/13/2019      Mani Sundaresan      Initial Creation
-------------------------------------------------------------*/
@isTest
global class SecretKeyVersionHTTPResponseGenerator implements HttpCalloutMock {

    //Interface method
    global HTTPResponse respond(HTTPRequest req) {
    
        System.assertEquals('GET', req.getMethod());
        
        String body = '{'+
               '"statusCode": "Y",'+
               '"statusMessage": "Successful",'+
               '"issuers": ['+
               '"Dashboard Command v1.0"'+
               ']'+
               '}';
        
        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody(body);
        res.setStatusCode(200);
        return res;
        
    }
}