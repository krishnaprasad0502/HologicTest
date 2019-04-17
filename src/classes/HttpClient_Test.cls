/*------------------------------------------------------------
Author: Mani Sundaresan

Description: Test Class for HttpClient used for Salesforce NTLM Authentication

History:
<Date>          <Authors Name>      <Brief Description of Change>
07/17/2018      Mani Sundaresan      Initial Creation (US-0004314)
------------------------------------------------------------*/
@isTest
public class HttpClient_Test {
    @isTest static void testSend() {
        Test.setMock(HttpCalloutMock.class, new NTLMHttpCalloutMockImpl());
        HTTPRequest r = new HTTPRequest();
        string endpointurl = 'http://testNTLM.com';
        r.setEndpoint(endpointurl);
        r.setMethod('GET');
        r.setBody('TEST');

        HttpClient client = new HttpClient('domain\\username', 'password');
        

        HTTPResponse res = client.send(r);

        system.debug(res.getHeader('Content-Type'));
        System.assertEquals(200, res.getStatusCode());

        String contentType = res.getHeader('Content-Type');
        System.assert(contentType == 'application/json');
        
    String actualValue = res.getBody();
        system.debug(actualValue);
        String expectedValue = '{"foo":"bar"}';
        System.assertEquals(actualValue, expectedValue);
    }
    
    @isTest static void testSend2() {
    
        Test.setMock(HttpCalloutMock.class, new NTLMHttpCalloutMockImpl());
        HTTPRequest r = new HTTPRequest();
        string endpointurl = 'http://testNTLM.com';
        r.setEndpoint(endpointurl);
        r.setMethod('GET');
        r.setBody('TEST');
        r.setHeader('TEST', 'TEST');

        HttpClient client = new HttpClient('domain\\username', 'password');
        client.setIsPreAuthenticate(true);

        HTTPResponse res = client.send(r);

        system.debug(res.getHeader('Content-Type'));
        System.assertEquals(200, res.getStatusCode());

        String contentType = res.getHeader('Content-Type');
        System.assert(contentType == 'application/json');
        
        String actualValue = res.getBody();
        system.debug(actualValue);
        String expectedValue = '{"foo":"bar"}';
        System.assertEquals(actualValue, expectedValue);
    }
    
    
}