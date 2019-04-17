/*------------------------------------------------------------
Author:         Mani Sundaresan
Description:    HTTPMockResponse to be used by CDMExtension_Test to validate the JSON reponse from CDM via Mulesoft

History:
<Date>          <Authors Name>      <Brief Description of Change>
04/10/2018      Mani Sundaresan      Initial Creation (US-4246)
-------------------------------------------------------------*/
@isTest
global class CDMMockHttpResponseGenerator implements HttpCalloutMock {

    //Interface method
    global HTTPResponse respond(HTTPRequest req) {
    
        System.assertEquals('POST', req.getMethod());
        
        String body = '{'+
               '"DataQualityOrg": [{'+
                              '"DataQualityScore": "60",'+
                              '"DataQualityRecordType": "Result",'+
                              '"ResultCode": "COMPLETED",'+
                              '"ResultMessage": "SUCCESS",'+
                              '"AddressLine1": "123 MAIN STREET",'+
                              '"AddressLine2": "STE 123",'+
                              '"AddressLine3": "STE TEST",'+
                              '"AddressLine4": "STE TEST",'+
                              '"City": "CHICAGO",'+
                              '"Country": "US",'+
                              '"CountrySubEntity": "IL",'+
                              '"OrganizationIdentifier": "300000004852019",'+
                              '"OrganizationName": null,'+
                              '"PartySiteId": "300000004852022",'+
                              '"PostalCode": "60093",'+
                              '"PartyName": "TEST",'+
                              '"RegistrationId": "6"'+
               '}]'+
               '}';
        
        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody(body);
        res.setStatusCode(200);
        return res;
        
    }
}