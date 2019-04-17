/*--------------------------------------------------------------------------------------------------------------------
Author:     Mani Sundaresan & Alex Powning
Description:  Controller used by GenerateQRCode VF page.

History:
<Date>      <Authors Name>    				<Brief Description of Change>
03/21/2019   Mani Sundaresan & Alex Powning    Initial Creation
----------------------------------------------------------------------------------------------------------------------*/
public class GenerateQRCode {

    private static Master_Secret_Admin_App_Settings__c appSettings = Master_Secret_Admin_App_Settings__c.getOrgDefaults();
    public static string imageurl{get;set;}
    public static String key{get; set;}
    public static String googleAuthURL{get; set;}
    public static SecretKeyJsonDeserialize responseDeserializer{get; set;}
    public String data {get; set;}
    public String vVersion {get;set;}
    public String vTimespan {get;set;}
    public String currentUser {get;set;}
    public String otpauth {get;set;}
    public String Account {get; set;}
    public String validFrom {get; set;}
    public String validTo {get; set;}
    
    public static List<String> versionList {get; set;} 
    
    public List<SelectOption> versionOptions {get;set;}
    public List<SelectOption> timespanOptions {get;set;}
    
    public qrCodeInput qrCodeInputs {get; set;}
    public List<qrCodeOutput> qrCodeOutputs {get; set;}
    public string txtDoc {get; set;}
    public List<string> selectedVersions {get; set;}
    
    public string sfTheme {get; set;}
    
    public string downloadId {get; set;}
    public string downloadCompId {get; set;}
    
    public boolean displayOutput {get; set;}
    
    public GenerateQRCode(){
        
    }
    
    //initiate the page -> get list of software names & set boolean vars
    public void generateSoftVersions(){
        
        //initiate bool
        displayOutput = false;
        
        //check salesforce theme
        sfTheme = UserInfo.getUiTheme();
        system.debug('*****************************************************************************sf theme: ' + sfTheme);
        
        String userId = UserInfo.getUserId();
        currentUser = [select FederationIdentifier from User where id = :userId].FederationIdentifier;
    
        //Rest callout to get the versions
        HttpRequest req = new HttpRequest();
        String namedCreds = 'QRAuthenticatorVersions';
        String url = 'callout:' + namedCreds;
        
        req.setEndpoint(url);
        req.setMethod('GET');
        Http http = new Http();
        Blob headerValue = Blob.valueOf(appSettings.clientId__c + ':' + appSettings.clientSecret__c);
        String authHeader = 'Basic ' + EncodingUtil.base64Encode(headerValue);
        req.setHeader('Authorization', authHeader);
        req.setHeader('Content-Type', 'application/json');
        System.debug('request:'+req);
        HTTPResponse response = http.send(req);
        System.debug(response.getBody());
        
        timespanOptions = new List<SelectOption>();
        timespanOptions.add(new SelectOption('current','current'));

		// only display the next option if within 7 days of the start of the next month.        
        Date today = system.today();
        Date future = today.addDays(7);
        if (today.month() != future.month()) {
            timespanOptions.add(new SelectOption('next','next'));
        }
        
        if(response != null && (response.getStatusCode() == 200 || response.getStatusCode() == 0)){
            responseDeserializer = SecretKeyJsonDeserialize.parse(response.getBody());
               System.debug('issuersList:'+responseDeserializer.issuers);
               if(responseDeserializer.issuers.size() > 0){
                   responseDeserializer.issuers.sort();
                   System.debug('size val:'+responseDeserializer.issuers.get(0));
               }
            //versionList = responseDeserializer.issuers;
             versionList = new List<String>();
            // reverse sort
            for(Integer i = responseDeserializer.issuers.size()-1; i>=0;i--) {
                versionList.add(responseDeserializer.issuers.get(i));
            }
                            
            
            versionOptions = new List<SelectOption>();
            
            data = 'size:' + versionList.size() ;
            Integer cnt =0;
            for(String nm : versionList) {
                cnt++;
                versionOptions.add(new SelectOption(nm,nm));
                data = data + nm;
            }
        }
        else{
            System.debug('Unsuccessful Integration:'+'Status received is - '+response.getStatusCode()+'. Please check with Mule and CDM team.'); 
            ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Integration failed!!. Kindly create a Help Me related to this issue.'));   
        }
    }
    
    //make callout to qrcodegenerator api, parse response for display in vf page
    public void generateqr() {
        data = 'saved';
        
        
        //Rest callout to get the versions
        HttpRequest req = new HttpRequest();
        String namedCreds = 'QRAuthenticator';
        String url = 'callout:' + namedCreds ;
        /*
        url += '?username=';
        url += currentUser; //'ALaack';
        url += '&issuer=';
        url += EncodingUtil.urlEncode(vVersion,'UTF-8').replace('+','%20'); //'Hologic%20Dashboard%20FSE%20(version%201.0)';
        url += '&timespan=';
        url += vTimespan; // current
        */
        
        req.setEndpoint(url);
        req.setMethod('POST');
        Http http = new Http();
        Blob headerValue = Blob.valueOf(appSettings.clientId__c + ':' + appSettings.clientSecret__c);
        String authHeader = 'Basic ' + EncodingUtil.base64Encode(headerValue);
        req.setHeader('Authorization', authHeader);
        req.setHeader('Content-Type', 'application/json');
        
        //set body
        qrCodeInputs = new qrCodeInput();
        qrCodeInputs.username = currentUser;
        qrCodeInputs.timespan = vTimespan;
        qrCodeInputs.issuers = selectedVersions;
        req.setBody(json.serialize(qrCodeInputs));
        
        req.setTimeout(30000);
        HTTPResponse response = http.send(req);
    
        qrCodeOutputs = new List<qrCodeOutput>();
        validFrom='';
        validTo='';
        account='';
        if(response != null && (response.getStatusCode() == 200 || response.getStatusCode() == 0)){
            data = 'pass';
            
            responseDeserializer = SecretKeyJsonDeserialize.parse(response.getBody());
            
            integer i = 0;
            
            for (SecretKeyJsonDeserialize.code code : responseDeserializer.codes){
                validFrom = code.validFrom;
                validTo = code.validTo;
				account = code.account;
                
                qrCodeOutputs.add(new qrCodeOutput());
                qrCodeOutputs[i].vVersion = code.issuer;
                qrCodeOutputs[i].key = code.secret;
                
                system.debug('*****************************************************' + appSettings.QRImageUrl__c);
                
                qrCodeOutputs[i].imageurl = appSettings.QRImageUrl__c + '?data=';
            	qrCodeOutputs[i].imageurl += EncodingUtil.urlEncode(code.uri,'UTF-8').replace('+','%20');
            	qrCodeOutputs[i].imageurl += '&code=MobileQRCode&multiplebarcodes=false&translate-esc=false&unit=Fit&dpi=96';
            	qrCodeOutputs[i].imageurl += '&imagetype=Gif&rotation=0&color=%23000000&bgcolor=%23ffffff&qunit=Mm&quiet=0&eclevel=L'; 

                qrCodeOutputs[i].otpauth = 'otpauth://totp/';
            	qrCodeOutputs[i].otpauth += EncodingUtil.urlEncode(code.issuer,'UTF-8').replace('+','%20');//Hologic%20Dashboard%20FSE%20(version%201.0)';
            	qrCodeOutputs[i].otpauth += ':';
            	qrCodeOutputs[i].otpauth += EncodingUtil.urlEncode(code.account,'UTF-8').replace('+','%20'); //'Feb%202019%20-%20ss0616';
            	qrCodeOutputs[i].otpauth += '?secret=';
            	qrCodeOutputs[i].otpauth += code.secret.replace(' ','');//PEII25AD6VEL6WZDUUYZDDKDZEV55HY3';
            	qrCodeOutputs[i].otpauth += '&algorithm=SHA1';
            	qrCodeOutputs[i].otpauth += '&issuer=';
           	 	qrCodeOutputs[i].otpauth += EncodingUtil.urlEncode(code.issuer,'UTF-8').replace('+','%20');//Hologic%20Dashboard%20FSE%20(version%201.0)';
                    
                i++;
            }
            
            downloadTxt();
            
        } else {
            data = 'fail';
            System.debug('Unsuccessful Integration:'+'Status received is - '+response.getStatusCode()+'. Please check with Mule and CDM team.'); 
            ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Integration failed!!. Kindly create a Help Me related to this issue.'));   
        
        }
        
        if (qrCodeOutputs.size() > 0){
            displayOutput = true;
        } else {
        	displayOutput = false;
        }
    }
    
    //generate html doc to download
    public void downloadTxt(){
        
        string tmpStrCon = '';
        string tmpStrDyn = '';
        
        if (qrCodeOutputs.size() > 0) {
            txtDoc = '<HTML><BODY><PRE>===========================================================================\r\n';
            txtDoc += 'Authenticator Codes intended for accessing from mobile phone email. \r\n';
            txtDoc += '\r\n';
            txtDoc += 'Chrome Instructions: To send this to a phone\'s email, download the file using\r\n';
            txtDoc += '  "Print" (ctrl-p) and change the destination to "Save as PDF", then send it as\r\n';
            txtDoc += '  an email attachment. Using copy/paste will not work. Additional steps may be \r\n';
            txtDoc += '  required for other browsers.\r\n';
            txtDoc += '\r\n';
            tmpStrCon = Account + '\r\n';
    		tmpStrCon += validFrom + ' - ' + validTo + '\r\n';
            for (qrCodeOutput code : qrCodeOutputs){

                tmpStrDyn += code.vVersion + '\r\n';
                
                tmpStrDyn += '<a href="'+code.otpauth.substring(0)+'">';
                tmpStrDyn += code.key.replace(' ','') ;
                tmpStrDyn += '</a>\r\n';

                tmpStrDyn += '<img src="' + code.imageurl + '"/>' + '\r\n';
                //<a href="{!outputs.otpauth}"><apex:image url="{!outputs.imageurl}" id="img1"/></a>
                
                tmpStrDyn += '\r\n';
                tmpStrDyn += '\r\n';
                
            }
            txtDoc += tmpStrCon;
            txtDoc += '\r\n';
            txtDoc += tmpStrDyn;
            txtDoc += '</PRE></BODY></HTML>';
            txtDoc = EncodingUtil.base64Encode(Blob.valueOf(txtDoc));
        }
    }
    
    public class qrCodeInput {
        public string username {get; set;}
        public string timespan {get; set;}
        public list<string> issuers {get; set;}
    }
    
    public class qrCodeOutput {
        public string vVersion {get; set;}
        public string otpauth {get; set;}
        public string imageurl {get; set;}
        public string key {get; set;}
    }
}