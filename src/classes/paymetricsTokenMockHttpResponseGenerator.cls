/*------------------------------------------------------------
Author:         Mani Sundaresan
Description:    HTTPMockResponse to be used by paymentauthorization to validate the token generation from paymetrics.

History:
<Date>          <Authors Name>      <Brief Description of Change>
07/19/2018      Mani Sundaresan      Initial Creation (US-0004314)
-------------------------------------------------------------*/
@isTest
global class paymetricsTokenMockHttpResponseGenerator implements HttpCalloutMock {

    //Interface method
    global HTTPResponse respond(HTTPRequest req) {
    
        
        
        String body = '<?xml version="1.0" encoding="UTF-8"?><PaymetricResponse xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"><Fields><FormField><Name>Card Type</Name><Value>vi</Value><IsToTokenize>false</IsToTokenize></FormField><FormField><Name>Start Month</Name><IsToTokenize>false</IsToTokenize></FormField><FormField><Name>Start Year</Name><IsToTokenize>false</IsToTokenize></FormField><FormField><Name>Expiration Month</Name><Value>4</Value><IsToTokenize>false</IsToTokenize></FormField><FormField><Name>Expiration Year</Name><Value>2021</Value><IsToTokenize>false</IsToTokenize></FormField><FormField><Name>Card Number</Name><Value>8417834292451111</Value><IsToTokenize>true</IsToTokenize></FormField><FormField><Name>Card Holder Name</Name><Value>test</Value><IsToTokenize>false</IsToTokenize></FormField></Fields></PaymetricResponse>';
        
        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/xml');
        res.setBody(body);
        res.setStatusCode(200);
        return res;
    }
}