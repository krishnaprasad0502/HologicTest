/*--------------------------------------------------------------------------------------------------------------
Author:         Alex Powning
Description:    HTTP Mock responses for Master Secret Admin VF Page Controller Test Class

History:
<Date>          <Authors Name>      <Brief Description of Change>
25-Feb-19       Alex Powning        Initial Creation

----------------------------------------------------------------------------------------------------------------*/
@IsTest
global class DxLabMockHttpResponseGenerator implements HttpCalloutMock {
    
    global HTTPResponse respond(HTTPRequest req){
        
        String body = '';
        
        if (req.getEndpoint().startsWith('callout:holx_dxlab_dashb_kms_ux_post/')){
            
            //set body
            body = 
                '{' +
                    '"statusMessage": "Key Found",'+
                    '"key": {'+
                        '"name": "Dimensions",'+
                        '"version": "1.0",'+
                        '"created": "2019-02-22",'+
                        '"masterSecret": "5NBUOYHSTKH3OXLP5PYKP5YYVH3S7JK35RF6FIMMRBYPNMTTKXAQNQSPKUPW33L5IHVMOMV5LEAZYQWGMCWQK52554TGTI2AVCZR7KI="'+
                    '},'+
                    '"statusCode": "Y"'+
                '}';
            
            // Create a fake response
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody(body);
            res.setStatusCode(200);
            
            return res;
            
        } else if (req.getEndpoint().startsWith('callout:holx_dxlab_dashb_kms_ux_get/')){
            
            //set body
            body = 
                '{' + 
                    '"statusCode": "Y",' + 
                    '"statusMessage": "Success",' +
                    '"subTotal": 5,' +
                    '"total": 14,' + 
                    '"keys": [' +
                        '{' +
                            '"name": "Dimensions",' +
                            '"version": "1.0",' +
                            '"created": "2019-02-22",' +
                            '"masterSecret": "5NBUOYHSTKH3OXLP5PYKP5YYVH3S7JK35RF6FIMMRBYPNMTTKXAQNQSPKUPW33L5IHVMOMV5LEAZYQWGMCWQK52554TGTI2AVCZR7KI="'+
                        '},'+
                        '{'+
                            '"name": "Dimensions",'+
                            '"version": "2.0",'+
                            '"created": "2019-02-22",'+
                            '"masterSecret": "EINRV3WNX3DDZTZ5DH534ZN3V7KAQGZBXF6Z5C4Z7NSGBTUGB2IWSV7LTFPSUTBTF6IS436IVXLPGCMTSNCDOHOEIF23UIUIAQTDSSY="'+
                        '},'+
                        '{'+
                            '"name": "Hologic Dashboard FSE",'+
                            '"version": "1.0",'+
                            '"created": "2019-02-22",'+
                            '"masterSecret": "DEVGU36WCLV7DXRS3TTN5642N3FBWADA5KEBQ4L2O5ISNFUZIKOLEEKSNFNNYNBUA5OUQIF2MYK24OOU2KMVU6GEACQYF5TYXSHZMHY="'+
                        '},'+
                        '{'+
                            '"name": "Hologic Dashboard FSE",'+
                            '"version": "1.1",'+
                            '"created": "2019-02-22",'+
                            '"masterSecret": "Z355CWJXSHD7FOV3RRVOHHYKHAZ6226RZ6ON5VAFALVMCKKTAVO4LIL3QZZTP3VYPXEEHBLV35UJWDSW26K45Q2T6K4F5J7LRXX7AFQ="'+
                        '},'+
                        '{'+
                            '"name": "Hologic Dashboard FSE",'+
                            '"version": "1.2",'+
                            '"created": "2019-02-22",'+
                            '"masterSecret": "CSUQQWC6IKE5O4GX4RMUXDHWKPQ5JN2G5ZCVQWWSYBEKZ7POFYJGHGSUCD6JTM7Z4BDFRLCYNFQD5OZLUA3OFPMZ42562BXL65K6MVY="'+
                        '}'+
                    ']'+
                '}';
            
            // Create a fake response
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody(body);
            res.setStatusCode(200);
            
            return res;
            
        } else if (req.getEndpoint().startsWith('callout:holx_dxlab_dashb_kms_ux_names/')){
            
            //set body
            body = 
                '{'+
                    '"statusCode": "Y",'+
                    '"statusMessage": "Success",'+
                    '"names": ['+
                        '"Dimensions",'+
                        '"Hologic Dashboard FSE",'+
                        '"Panther Fusion"'+
                    ']'+
                '}';
            
            // Create a fake response
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody(body);
            res.setStatusCode(200);
            
            return res;
        }
        
        return null;
    }
}