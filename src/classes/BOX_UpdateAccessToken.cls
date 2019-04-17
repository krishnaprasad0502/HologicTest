/**************************************************************************************
    Author 		 : Nikhil Mutyam
    Company 	 : Hexaware Technologies
	Created Date : 8/13/2018 7:30 AM
    Description  : Schedule class to update Access Token every hour.
	Test Class   : Box_UpdateAccessToken_Test    
	Coverage 	 : 91%	

    History:
    <Date>         	<Author Name>       	<Brief Description of Change> 	<Copa.do US#>
	10/9/2018 	    Nikhil Mutyam			Initial Creation				US-0005861
**************************************************************************************/
global class BOX_UpdateAccessToken implements Schedulable{
	
    /*
     * Method Name: updateAccessToken()
     * Input Param: NA
     * Return: void 
     * Description: Fetch the Box credentials from Box_Auth__c object.
     */
    @future(callout=true)
    public static void updateAccessToken(){
        string str;
        String enterpriseId;
        String publicKeyId;
        String privateKey;
        String clientId;
        String clientSecret;
        BoxPlatformApiConnection api;
        
        String token;
        String folderName;
        
        list<Box_Auth__c> boxMeta = new list<Box_Auth__c>();
        boxMeta = [SELECT Id, Name, Access_Token__c, Client_ID__c, Client_Secret__c, Enterprise_ID__c, Private_Key_ID__c, 
                   Public_Key_ID__c, User_Type__c FROM Box_Auth__c];
        if(boxMeta != Null && boxMeta.size() > 0){
            enterpriseId = boxMeta[0].Enterprise_ID__c;
            publicKeyId = boxMeta[0].Public_Key_ID__c;
            privateKey = boxMeta[0].Private_Key_ID__c;
            clientId = boxMeta[0].Client_ID__c;
            clientSecret = boxMeta[0].Client_Secret__c;
        }

        //Build Request
        BoxJwtEncryptionPreferences preferences = new BoxJwtEncryptionPreferences();
        preferences.setPublicKeyId(publicKeyId);
        preferences.setPrivateKey(privateKey);
        if(!Test.isRunningTest()){
        	api = BoxPlatformApiConnection.getAppEnterpriseConnection(enterpriseId, clientId, clientSecret, preferences);
        }else{
            token = 'test token';
        }
        for(Box_Auth__c BM : boxMeta){
            token = downscopeToken(Test.isRunningTest() ? 'Test Token' : api.getAccessToken(),BM.User_Type__c);   
            if(token != Null && token != ''){
                BM.Access_Token__c = token;
            }    
        }
                   
		update boxMeta;
    }
    
    /*
     * Method Name: execute()
     * Input Param: SchedulableContext
     * Return: void 
     * Description: Invoked updateAccessToken method to fetch access token from box
     */
    global void execute(SchedulableContext SC) {
    	updateAccessToken();
    }    
    
    /*
     * Method Name: downscopeToken()
     * Input Param: string
     * Return: void 
     * Description: Makes a request to Box api to fetch access token
     */
    public static String downscopeToken(String token, string UserType) {
        String accessToken;
        String scopes;
            
        if(UserType == 'Standard'){
            scopes = 'item_download item_upload item_preview item_rename item_share item_delete';
        }else if(UserType == 'Community'){
            scopes = 'item_download item_preview';
        }
        
        String endpoint = 'https://api.box.com/oauth2/token';
        String body = 'scope=' + scopes +
            '&grant_type=urn:ietf:params:oauth:grant-type:token-exchange' +      
            '&subject_token=' + token +
            '&subject_token_type=urn:ietf:params:oauth:token-type:access_token';
        
        // format Box API request to downscope token
        HttpRequest request = new HttpRequest();
        request.setMethod('POST');
        request.setEndpoint(endpoint);
        request.setBody(body);
        
        //Create Http, send request
        Http http = new Http();
        String resBody;
        if(!Test.isRunningTest()){
            HTTPResponse response = http.send(request);
            if(response.getStatusCode() != 200){
            	sendException(response.getStatusCode(),response.getBody());
            	return null;
            }
            resBody = response.getBody();
        }else{
            resBody = '{"access_token":"1!S5D_ZTVj_OcO1RAK9IA7qZZKWS7g8vc3YWowf264StPoO9EoGFv5YlysBGyMjybt32CaQKvyKyn6UCYLkyq2EINGIXEufV-TZiFCGmWmAspaQUYddbUGK6onRHHL5vZGvuXb36vq6SABWmPTgsEobFA60g9720_e5lmJwd1L662SfeLaBfoAi4JIncqQtkf5Dsx_aIJQKiJqWVIvZWB0TwXLelCwFHwe7Ugi4DdAutnBcBfzeyNWnXKhYqUecdBvBNstcMizQI685xU6bUQI2o0l-TB3qRh8mdYzaqU-wblSDHHNrHQ8mL-zhcCdssOwMC_6haF41Fg1hDVq1vvS_HVwVv3w-iJ6y8yG9ueyApp6JAm11FMiLRLC5Xv6FWbJWtCmAJ9AbuwhYNiYznoXEIwI1aa8V66_eQpW0fVSnSklSvHWKfPMD-hFgcFFPYEYiwvunn7OZxegJqIP","expires_in":4192,"token_type":"bearer","restricted_to":[],"issued_token_type":"urn:ietf:params:oauth:token-type:access_token"}';
        }    
        System.debug('Body of refresh response: ' + resBody);
        
        //loop through tokens to be parsed, save access token
        JSONParser parserTokens = JSON.createParser(resBody);
        while (parserTokens.nextToken() != null){
            if (parserTokens.getCurrentToken() == JSONToken.FIELD_Name && parserTokens.getText() == 'access_token'){
                parserTokens.nextToken();
                //save access token
                accessToken = parserTokens.getText();
            }
        }

        return accessToken;        
    }
    
    public static void sendException(integer erorCode, string errorMessage){
    	list<string> toAddressesTest = new list<string>();
		for(User u : [select Id, email from User Where Profile.Name='System Administrator' and isActive = true]){
		    toAddressesTest.add(u.Email);
		}
		Messaging.SingleEmailMessage mailTest = new Messaging.SingleEmailMessage();
		mailTest.setToAddresses(toAddressesTest); 
		mailTest.setSubject('Unexpected Error occured while making a callout to Box. Error Code: '+erorCode);
		mailTest.setHtmlBody(errorMessage);
		Messaging.SendEmail(new Messaging.SingleEmailMessage[] {mailTest});
    }
}