/*------------------------------------------------------------
Author:         Mani Sundaresan
Description:    HTTPMockResponse to be used by GenerateQRCode_Test to validate the JSON reponse from Azure via Mulesoft

History:
<Date>          <Authors Name>      <Brief Description of Change>
03/13/2019      Mani Sundaresan      Initial Creation
-------------------------------------------------------------*/
@isTest
global class QRCodeHTTPResponseGenerator implements HttpCalloutMock {

    //Interface method
    global HTTPResponse respond(HTTPRequest req) {
    
        System.assertEquals('POST', req.getMethod());
        
        String body = 
            '{'+
                '"statusCode": "Y",'+
                '"statusMessage": "Created QR URIs.",'+
                '"codes": ['+
                   '{'+
                        '"account": "Mar 2019 - ALaack",'+
                        '"issuer": "TEST2",'+
                        '"secret": "V4VV NW4T 4SIG A726 Z5OW I64Z 6IUA N7FG",'+
                        '"uri": "otpauth://totp/TEST2:Mar%202019%20-%20ALaack?secret=V4VVNW4T4SIGA726Z5OWI64Z6IUAN7FG&algorithm=SHA1&issuer=TEST2",'+
                        '"validFrom": "02/22/2019",'+
                        '"validTo": "04/07/2019",'+
                        '"statusCode": "Y",'+
                        '"statusMsg": "Success."'+
                    '},'+
                    '{'+
                        '"account": "Mar 2019 - ALaack",'+
                        '"issuer": "TEST3",'+
                        '"secret": "2255 B5SK DEC7 T56D A2AT TUCU 2H4P 7HK3",'+
                        '"uri": "otpauth://totp/TEST3:Mar%202019%20-%20ALaack?secret=2255B5SKDEC7T56DA2ATTUCU2H4P7HK3&algorithm=SHA1&issuer=TEST3",'+
                        '"validFrom": "02/22/2019",'+
                        '"validTo": "04/07/2019",'+
                        '"statusCode": "Y",'+
                        '"statusMsg": "Success."'+
                    '}'+
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