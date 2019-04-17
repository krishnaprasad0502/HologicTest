@RestResource(urlMapping='/CPQPROSPricing/*')
global class CPQPROSCallOut {
    @HttpPost
    global static String getPricing(QuoteLine ql)
    {
    	
        String returnStr;

        Http http = new Http();
        HttpRequest request = new HttpRequest();
        //method/name/Guidance_Method_for_SFDC_WebService/values/key;CUSTOMER=100090;PRODUCT=DAN-TRAVEL-WKDAY
        String accountNumber = ql.account_number;
        String productCode = ql.product_code;
        String baseURL = 'https://sandbox.hologic.proscloud.com/PPSS/external/po/method/name/Guidance_Method_for_SFDC_WebService/values/key;';
        String endPoint = baseURL + 'CUSTOMER=' + accountNumber + ';' + 'PRODUCT=' + productCode;
        //request.setEndpoint('https://sandbox.hologic.proscloud.com/PPSS/external/po/method/name/Guidance_Method_for_SFDC_WebService/values/key;CUSTOMER=100090;PRODUCT=DAN-TRAVEL-WKDAY');
        request.setEndpoint(endPoint);
        request.setMethod('GET');
        request.setHeader('Authorization', getAuthToken());
        request.setHeader('Accept', 'application/json');
        HttpResponse response = http.send(request);
        
        if(response.getStatusCode() == 200){
            returnStr = response.getBody();
        }
        else{
            returnStr = response.getStatus();
        }

        System.debug(response.getBody());
        
        return returnStr;
    }

    /*public static HttpResponse makeGetCallout() {
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        //method/name/Guidance_Method_for_SFDC_WebService/values/key;CUSTOMER=100090;PRODUCT=DAN-TRAVEL-WKDAY
        request.setEndpoint('https://sandbox.hologic.proscloud.com/PPSS/external/po/method/name/Guidance_Method_for_SFDC_WebService/values/key;CUSTOMER=100090;PRODUCT=DAN-TRAVEL-WKDAY');
        request.setMethod('GET');
        request.setHeader('Authorization', authToken);
        request.setHeader('Accept', 'application/json');
        HttpResponse response = http.send(request);

        System.debug(response.getBody());
        // If the request is successful, parse the JSON response.*/
        /*if (response.getStatusCode() == 200) {
            // Deserializes the JSON string into collections of primitive data types.
            Map<String, Object> results = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            // Cast the values in the 'animals' key as a list
            List<Object> animals = (List<Object>) results.get('animals');
            System.debug('Received the following animals:');
            for (Object animal: animals) {
                System.debug(animal);
            }
        }*/


       // return response;
    //}
    private static String getAuthToken(){
        //Query Custom Metadata Record to get PROS Public Key for encryption
        CPQ_Pros_Integration__mdt metadataRecord = [SELECT Symmetric_Key__c, User_Name__c, Password__c, Key_Name__c from CPQ_Pros_Integration__mdt WHERE DeveloperName = 'Sandbox' LIMIT 1];
        //Convert Crpytokey from Hex
        Blob cryptoKey = EncodingUtil.convertFromHex(metadataRecord.Symmetric_Key__c);
        String key = metadataRecord.Key_Name__c;
        String base64Key = EncodingUtil.base64Encode(Blob.valueOf(key));

        String credentials = ''
            + '<Credentials>'
            + '<TimeStamp>' + String.valueOf(datetime.now().getTime()) + '</TimeStamp>'
            + '<UserID>' + metadataRecord.User_Name__c + '</UserID>'
            + '<Password>' + metadataRecord.Password__c + '</Password>'
            + '</Credentials>';
        
        //Encrypt Credentials using symmetric key
        Blob encryptedCredentials = Crypto.encrypt('AES128', cryptoKey, cryptoKey, Blob.valueOf(credentials));
    
        //Convert the Credentials Blob to a Base64-encoded String
        String base64Credentials = EncodingUtil.base64Encode(encryptedCredentials);
           
        String authToken = 'PROS/S ' + base64Key + ' ' + base64Credentials;
        
        return authToken;
    }

    global class QuoteLine
    {
        global Id quote_id               { get; set; }
        global String account_number     { get; set; }
        global String product_code       { get; set; }
    }
}