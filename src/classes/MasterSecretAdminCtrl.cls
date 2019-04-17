/*--------------------------------------------------------------------------------------------------------------
Author:         Alex Powning
Description:    Controller for Master Secret Admin VF Page

History:
<Date>          <Authors Name>      <Brief Description of Change>
25-Feb-19       Alex Powning        Initial Creation

----------------------------------------------------------------------------------------------------------------*/
public class MasterSecretAdminCtrl {
    
    //private variables
    private static Master_Secret_Admin_App_Settings__c appSettings = Master_Secret_Admin_App_Settings__c.getOrgDefaults();
    private integer lim = 10;
    private integer offset;
    private string searchURL;
    private list<string> softwareNames;
    //private string namesEnvUrl;
    //private string getEnvUrl;
    //private string postEnvUrl;
    //private string orgName = [select name from Organization limit 1].name;
    
    //public variables
    public string softwareName {get;set;}
    public string softwareVersion {get;set;}
    public list<msDetail> msDetails {get;set;}
    public string operationType {get;set;}
    public string generateStatus {get;set;}
    public string generateSecret {get;set;}
    public integer numSearchResults {get;set;}
    public integer numSearchPages {get;set;}
    public integer currentSearchPage {get;set;}
    public string currentSearchSortCol {get;set;}
    public string currentSearchSortDir {get;set;}
    public list<SelectOption> filteredsoftwareNames {get;set;}
    public string filteredSoftwareName {get;set;}

    //function that validates input text fields
    private boolean validInput(){
        
        boolean valid = true;
        
        if (string.isBlank(softwareName)){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,'Must enter a string for software name'));
            valid = false;
        }
        if (string.isBlank(softwareVersion)){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,'Must enter a value for software version'));
            valid = false;
        } else if (!Pattern.compile('[0-9.*]*').matcher(softwareVersion).matches()){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,'Software version can only contain numbers, periods, or \'*\' if searching'));
            valid = false;
        }
                 
        return valid;
    }
    
    //function that takes in url, method -> calls API
    private HttpResponse callAPI(string url, string method){
        
        //test
        system.debug('************************URL: ' + url);
        //
        
        //create request
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        
        //replace '+' with '%20' in url
        url = url.replace('+', '%20');
        
        //set endpoint and method
        request.setEndpoint(url);
        request.setMethod(method);
        
        //create header w/ id + secret
        Blob headerValue = Blob.valueOf(appSettings.clientId__c + ':' + appSettings.clientSecret__c);
        String authHeader = 'Basic ' + EncodingUtil.base64Encode(headerValue);
        request.setHeader('Authorization', authHeader);
        request.setHeader('Content-Type', 'application/x-www-form-urlencoded');

        //call API
        HttpResponse response = http.send(request);        
        
        return response;
    }
    
    //generates the secret
    public void generateMS(){
        
        //set operation type
        operationType = 'generate';
        
        //validate input
        if (!validInput()){
            operationType = '';
            return;
        }
        
        //call /kms-ux/generate API
        HttpResponse response = callAPI('callout:holx_dxlab_dashb_kms_ux_post/' + EncodingUtil.urlEncode(softwareName, 'UTF-8') + '/' + softwareVersion, 'POST');

        if (response.getStatusCode() == 200){
            
            //deserialize json response  
        	Map<String, Object> results = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            
            //check statusCode
            if ((string)results.get('statusCode') != 'E') {
            	//get results
            	generateStatus = softwareName + ', ' + softwareVersion + ' -> ' + (string)results.get('statusMessage');
            	Map<string, object> key = (Map<string, object>)results.get('key');
            	generateSecret = (string)key.get('masterSecret');
            
            	//regenerate software names for list
        		getSoftwareNames();
            } else {
                generateStatus = (string)results.get('statusCode') + ' -> ' + (string)results.get('statusMessage');
                generateSecret = '';
            }
            
        }
        else {
            //get error
            generateStatus = 'Generate Failed -> ' + response.getStatusCode() + ' error code';
            generateSecret = '';
        }
        
        //reset name, version, list
        softwareName = '*';
        softwareVersion = '0.0';
        filterSoftwareNames();
    }
    
    //searches for secret
    public void searchMS(){
        
        //set operation type & #rows to return
        operationType = 'search';
        
        //validate input
        if (!validInput()){
            operationType = '';
            return;
        }
        
        //set search url
        searchURL = 'callout:holx_dxlab_dashb_kms_ux_get/' + EncodingUtil.urlEncode(softwareName, 'UTF-8') + '/' + softwareVersion + '?offset=' + offset + '&limit=' + lim;

        if (currentSearchSortCol != null && currentSearchSortDir != null){
            if (currentSearchSortDir == '+'){
                searchURL += '&sortBy=' + currentSearchSortCol;
            }
            else{
                searchURL += '&sortBy=' + currentSearchSortDir + currentSearchSortCol;
            }
        }
        
        //call /kms-ux/search API
        HttpResponse response = 
            callAPI(searchURL, 'GET');
        
        //reset details
        msDetails = new List<msDetail>(); 
        
        if (response.getStatusCode() == 200){
            //deserialize json response  
            Map<String, Object> results = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            generateStatus = (string)results.get('statusMessage');
            
            //if number of results has changed, reassign variables
            if (numSearchResults != (integer)results.get('total')){
                numSearchResults = (integer)results.get('total');
                numSearchPages = (integer)Math.ceil(decimal.valueof(numSearchResults).divide(lim, 1));
            }
            
            List<object> keys = (List<object>)results.get('keys');
            for (object key : keys){
                map<string, object> keyMap = (map<string, object>)key;
                msDetail currentKey = new msDetail();
                
                currentKey.name = (string)keyMap.get('name');
                currentKey.version = (string)keyMap.get('version');
                currentKey.masterSecret = (string)keyMap.get('masterSecret');
                currentKey.dateCreated = (string)keyMap.get('created');
                
                msDetails.add(currentKey);
            }
        }
        else {
            generateStatus = 'Search Failed -> ' + response.getStatusCode() + ' error code';
            generateSecret = 'Null';          
        }   
    }
    
    //************************************pagination******************************************
    public void searchMSFirst(){
        
        //set pagination vars & call api
        offset = 1;
        searchMS();
        
        //set current page
        if (numSearchPages != 0){
            currentSearchPage = 1;
        }
        else {
            currentSearchPage = 0;
        }
    }
    
    public void searchMSLast(){
        
        //set pagination vars & call api
        offset = ((numSearchPages - 1) * lim) + 1;
        currentSearchPage = numSearchPages;
        searchMS();
    }
    
    public void searchMSNext(){
        
        //set pagination vars & call api
        offset += lim;
        currentSearchPage += 1;
        searchMS();
    }
    
    public void searchMSPrevious(){
        
        //set pagination vars & call api
        offset -= lim;
        currentSearchPage -= 1;
        searchMS();
    }
    
    public void searchMSSortBy (){
        
        //set search direction
        if (currentSearchSortDir == null || currentSearchSortDir == '-'){
            currentSearchSortDir = '+';
        }
        else{
            currentSearchSortDir = '-';
        }
        
        //set pagination vars & call api
        offset = 1;
        currentSearchPage = 1;
        searchMS();
    }
    //***************************************************************************
    
    //***************************software names**********************************
    
    //get software names from api
    public void getSoftwareNames(){
        //initialize list
        softwareNames = new list<string>();
        
        //call /kms-ux/names API
        HttpResponse response = callAPI('callout:holx_dxlab_dashb_kms_ux_names/', 'GET');
        
        if (response.getStatusCode() == 200){
            //deserialize json response  
            Map<String, Object> results = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            List<object> names = (List<object>)results.get('names');
            for (object name : names){
                softwareNames.add((string)name);
            }
        }
    }
    
    //Dynamically filter software names
    public void filterSoftwareNames(){
        
        filteredsoftwareNames = new list<SelectOption>();
        
        if (softwareName == '*'){
            for (string name : softwareNames){
                filteredsoftwareNames.add(new SelectOption(name, name));
            }
        }
        else {
            for (string name : softwareNames){
                if (name.toLowerCase().contains(softwareName.toLowerCase())){
                    filteredsoftwareNames.add(new SelectOption(name, name));
                }
            }
        }
    }
    
    //set software name equal to selected name from filtered list
    public void setSoftwareNameForList(){
        
        softwareName = filteredSoftwareName;
    }
    //**************************************************************************
    
    //Initialize page
    public void initializePage(){
        
        //set endpoints for environment
        /*if(orgName.containsIgnoreCase('DEV') || orgName.containsIgnoreCase('TEST')) {
            namesEnvUrl = 'callout:holx_dxlab_dashb_kms_ux_names/';
        	getEnvUrl = 'callout:holx_dxlab_dashb_kms_ux_get/';
        	postEnvUrl = 'callout:holx_dxlab_dashb_kms_ux_post/';
        }
        else if(orgName.containsIgnoreCase('UAT')) {
            namesEnvUrl = 'callout:holx_dxlab_dashb_kms_ux_names_uat/';
        	getEnvUrl = 'callout:holx_dxlab_dashb_kms_ux_get_uat/';
        	postEnvUrl = 'callout:holx_dxlab_dashb_kms_ux_post_uat/';        
        }
        else {
            namesEnvUrl = 'callout:holx_dxlab_dashb_kms_ux_names_prd/';
        	getEnvUrl = 'callout:holx_dxlab_dashb_kms_ux_get_prd/';
        	postEnvUrl = 'callout:holx_dxlab_dashb_kms_ux_post_prd/';
        }*/
        
        //set default name and version
        softwareName = '*';
        softwareVersion = '0.0';
        
        //get software names for list
        getSoftwareNames();
        filterSoftwareNames();
    }
    
    //******************************wrapper classes******************************
    
    //class that defines search output table
    public class msDetail {
        public string name {get;set;}
        public string version {get;set;}
        public string masterSecret {get;set;}
        public string dateCreated {get;set;}
    }
    //***************************************************************************
}