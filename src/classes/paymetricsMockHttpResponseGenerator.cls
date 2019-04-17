/*------------------------------------------------------------
Author:         Mani Sundaresan
Description:    HTTPMockResponse to be used by paymentauthorization to validate the XML reponse from paymetrics.

History:
<Date>          <Authors Name>      <Brief Description of Change>
07/19/2018      Mani Sundaresan      Initial Creation (US-0004314)
-------------------------------------------------------------*/
@isTest
global class paymetricsMockHttpResponseGenerator implements HttpCalloutMock {

    //Interface method
    global HTTPResponse respond(HTTPRequest req) {
    
        System.assertEquals('POST', req.getMethod());
        
        String body = '<?xml version="1.0"?>'+
                       '<AccessTokenResponsePacket xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">'+
                           '<ResponsePacket>'+
                               '<MerchantGuid>915ac11d-0288-458c-938a-8b22a0c7d288</MerchantGuid>'+
                               '<AccessToken>46cfa13c-64f0-4b7d-b218-e56346a10e99</AccessToken>'+
                               '<Signature>JTZ80/3YX4BiPJSuVVLHD7vvTQWPP726B3VoIcftnZ0=</Signature>'+
                           '</ResponsePacket>'+
                       '</AccessTokenResponsePacket>';
        
        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/xml');
        res.setBody(body);
        res.setStatusCode(200);
        return res;
    }
}