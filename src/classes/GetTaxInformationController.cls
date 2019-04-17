/*------------------------------------------------------------
Author:         Ramkumar Pitchai
Company:        Salesforce.com
Description:    Controller class used in Visualforce page that implements the Continuation pattern to invoke an external web service
Test Class:     GetTaxInformationTest

History:
<Date>        <Authors Name>        <Brief Description of Change>
13 Jun 2016   Ramkumar Pitchai      Initial Creation
26 Mar 2018   Lori Gilchrist        Exclude Medical Aesthetic Capital quotes from approval validation
------------------------------------------------------------*/

/**
 * Controller class of the Visualforce page named 'CalculateTax'. The Visualforce
 * page itself is invoked via a custom button on the Quote object record page.
 * This class implements the Continuation pattern to invoke an external web service
 * which provides the tax calculation information for the given Quote/Quote Lines.
 * The received tax calculation information is updated in the respective Quote/
 * Quote Lines records.
 */
public  with sharing class GetTaxInformationController {
    
    // Variables for Continuation call to the webservice, the URL and the callout request label
    public String taxInformationCalloutId;

    // Variable to hold the response of the tax calculation operation
    public String taxInformationStatus { get; set; }
    
    // Variable to hold the ID of the Quote record from which tax calculation request was initiated
    public ID quoteId { get; set; }
    
    // Variable to hold the approval status of the Quote. Only approved quotes can be initiated for tax calculation
    public String approvalStatus{ get; set; }
    
    // Variable to store the response from the Synchronous service
    public String syncResponse{get; set;}
    
    // Variable to store Opportunity Record Type
    public String OpptyRecordType{get; set;}
    
    // Standard Constructor
    public GetTaxInformationController(ApexPages.StandardController controller) {
        SBQQ__Quote__c quote = (SBQQ__Quote__c)controller.getRecord();
        this.quoteId = quote.id;
        this.approvalStatus = quote.ApprovalStatus__c;
        this.OpptyRecordType = Quote.Opportunity_Record_Type__c;
        System.debug('constructor called - '+quoteId+'-'+approvalStatus);
    }
    
    /**
     * Method to construct the request JSON message from the Quote/Quote Lines 
     * retrieved from the database
     *
     * @return    the generated JSON message
     */
    private String generateRequestJSON(){
        String requestJSON;
        
        List<SBQQ__QuoteLine__c> quoteLineDetails;
        
        // Check if the Quote has been Approved
        if((approvalStatus!=null && approvalStatus=='Approved') || OpptyRecordType =='Medical Aesthetics Capital Sales Opportunity'){
            System.debug('Quote is in approval status. Fetching quote/quote lines data for Quote - '+quoteId);
            
            // Fetch the Quote Line details of the Quote that initiated the tax calculation
            quoteLineDetails = [SELECT Name, SBQQ__Quote__r.Name
                                ,SBQQ__Quote__r.Operating_Unit__c
                                ,ID,SBQQ__Product__r.Oracle_Product_Id__c
                                ,SBQQ__Product__r.ProductCode,SBQQ__Quantity__c,SBQQ__NetPrice__c
                                ,SBQQ__Quote__r.ShipTo_Site__r.Oracle_Party_Site_ID__c
                                ,ShipTo_Site__r.Oracle_Party_Site_ID__c 
                                ,SBQQ__Quote__r.BillTo_Site__r.Oracle_Party_Site_ID__c
                                ,BillTo_Site__r.Oracle_Party_Site_ID__c
                                FROM SBQQ__QuoteLine__c 
                                WHERE SBQQ__Quote__c=:quoteId];
        } else {
            System.debug('Quote is not approved. Tax can be calculated only for APPROVED quotes. Please submit the quote for approval prior to initiating tax generation. Approval status of the quote is - '+approvalStatus);
        
            // Return ERROR message to the Visualforce page            
            return 'VALIDATION ERROR :: Quote is not approved. Tax can be calculated only for APPROVED quotes. Please submit the quote for approval prior to initiating tax generation. Approval status of the quote is - '+approvalStatus;
        }
    
        // Get an instance of the JSON Request Serializer custom classes (header and lines)
        GetTaxInformationRequestSerializer.QuoteHeader quoteHeader = new GetTaxInformationRequestSerializer.QuoteHeader();
        List<GetTaxInformationRequestSerializer.QuoteLines> quoteLines = new List<GetTaxInformationRequestSerializer.QuoteLines>();
        
        // Container Lists & Maps to send the header and lines field values for validation
        List<Map<String,String>> headerFieldsValidationList = new List<Map<String,String>>();
        List<Map<String,String>> linesFieldsValidationList = new List<Map<String,String>>();
        
        // Retrieve Quote Line Details
        if(quoteLineDetails != null && quoteLineDetails.size()>0){
            for(Integer i=0;i<quoteLineDetails.size();i++){
                SBQQ__QuoteLine__c line = quoteLineDetails[i];
                /* 
                    As the query traverses child-parent relationship, fetch the parent Quote
                    details only from one of the child records, here from the 1st record
                */
                if(i==0){
                    // Retrieve Quote Details
                    String quoteNumber = line.SBQQ__Quote__r.Name;
                    String operatingUnit = line.SBQQ__Quote__r.Operating_Unit__c;
                    
                    // Create QuoteHeader and populate the quote details
                    quoteHeader.headerId = quoteNumber;
                    quoteHeader.orgCode = operatingUnit;
                    
                    // Validate the fields - return error message if any of the fields are null or empty
                    Map<String,String> headerFieldValidationMap = new Map<String,String>();
                    headerFieldValidationMap.put('Name',quoteNumber);
                    headerFieldValidationMap.put('Operating Unit',operatingUnit);
                    
                    headerFieldsValidationList.add(headerFieldValidationMap);
                }
                
                // Create the QuoteLines
                GetTaxInformationRequestSerializer.QuoteLines quoteLine = new GetTaxInformationRequestSerializer.QuoteLines();
                
                // Capture the Quote Line details in variables
                String quoteLineNumber = line.Name;
                Integer itemId;
                if(line.SBQQ__Product__r.Oracle_Product_Id__c!=null){
                    itemId = Integer.valueOf(line.SBQQ__Product__r.Oracle_Product_Id__c);
                }
                
                String itemNumber = line.SBQQ__Product__r.ProductCode;
                Double quantity = line.SBQQ__Quantity__c;
                Double netPrice = line.SBQQ__NetPrice__c;
                
                Integer shipToId;
                if(line.ShipTo_Site__r.Oracle_Party_Site_ID__c!=null){
                    shipToId = Integer.valueOf(line.ShipTo_Site__r.Oracle_Party_Site_ID__c);
                }
                else{
                    if(line.SBQQ__Quote__r.ShipTo_Site__r.Oracle_Party_Site_ID__c != null){
                        shipToId = Integer.valueOf(line.SBQQ__Quote__r.ShipTo_Site__r.Oracle_Party_Site_ID__c);
                    }
                }

                Integer invoiceToId;
                if(line.BillTo_Site__r.Oracle_Party_Site_ID__c!=null){
                    invoiceToId = Integer.valueOf(line.BillTo_Site__r.Oracle_Party_Site_ID__c);
                }
                else{
                    if(line.SBQQ__Quote__r.BillTo_Site__r.Oracle_Party_Site_ID__c != null){
                        invoiceToId = Integer.valueOf(line.SBQQ__Quote__r.BillTo_Site__r.Oracle_Party_Site_ID__c);
                    }
                }
                                            
                // A single quote line JSON object
                quoteLine.lineId = quoteLineNumber;
                quoteLine.itemId = itemId;
                quoteLine.itemNumber = itemNumber;
                quoteLine.qty = quantity;
                quoteLine.price = netPrice;
                quoteLine.shipToId = shipToId;
                quoteLine.invoiceToId = invoiceToId;                
                
                // Add the quote line to the QuoteLines list
                quoteLines.add(quoteLine);
                
                // Add the fields and their values to the validation Map to perform validation
                Map<String,String> quotelineFieldsValidationMap = new Map<String,String>();
                quotelineFieldsValidationMap.put('Name',quoteLineNumber);
                quotelineFieldsValidationMap.put('Product Id',String.valueOf(itemId));
                quotelineFieldsValidationMap.put('Product Code',itemNumber);
                quotelineFieldsValidationMap.put('Quantity',String.valueOf(quantity));
                quotelineFieldsValidationMap.put('Net Price',String.valueOf(netPrice));
                quotelineFieldsValidationMap.put('Ship to Site Id',String.valueOf(shipToId));
                quotelineFieldsValidationMap.put('Invoice to Site Id',String.valueOf(invoiceToId));
                
                linesFieldsValidationList.add(quotelineFieldsValidationMap);
                
            }
            
            // Validate Quote Header Fields
            String validationMessage = validateFields('Quote - ',headerFieldsValidationList);
            System.debug('VALIDATION MSG FOR QUOTE : '+validationMessage);
            
            if(validationMessage.contains('Successful')){
            // Validate Quote Lines Fields
                validationMessage = validateFields('QuoteLines - ',linesFieldsValidationList);
                System.debug('VALIDATION MSG FOR QUOTE LINES : '+validationMessage);
            
            if(validationMessage.contains('ERROR')){
                requestJSON = validationMessage;
            } else {     
                GetTaxInformationRequestSerializer requestSerializer = new GetTaxInformationRequestSerializer();
                requestSerializer.header = quoteHeader;
                requestSerializer.lines = quoteLines;
    
                System.debug('%%%%'+JSON.serialize(requestSerializer));
        
                // Return the request as JSON String
                requestJSON = JSON.serialize(requestSerializer);
                }               
            } else {
                requestJSON = validationMessage;
                return requestJSON;
            }
           
        } else {
            System.debug('ERROR - No data returned for quote id - '+quoteId+'. Please check');
            requestJSON = 'ERROR - No data returned for quote id - '+quoteId+'. Please check';
        }
        
        System.debug('requestJSON is - '+requestJSON);
        return requestJSON;
    }
    
    /**
     * Method which implements the Continuation pattern and invokes the tax information web service
     * and passes in the request message
     * 
     * @param    taxCalculationRequest    the request JSON message for a given quote/quote lines
     * 
     * @return    the continuation object
     */
    public Object invokeAsynchronousTaxService(){
        String taxInformationRequest = generateRequestJSON();
        
        System.debug('Async Service - AAA0'+taxInformationRequest);
        System.debug('Async Service - CONTAINS ERROR - '+taxInformationRequest.contains('ERROR'));
        
        // Asynchronous Callout (Continuation)
        if(taxInformationRequest!=null && taxInformationRequest.contains('ERROR')){
            System.debug('Async Service - '+taxInformationRequest);
            setVFPageResponse(taxInformationRequest);
            return null;
        } else {
            System.debug('Async Service - AAA $$$$'+taxInformationRequest);
            
            // Create the callout
            HttpRequest httpRequest = new HttpRequest();
            httpRequest.setEndpoint('callout:Tax_Service');
            httpRequest.setMethod('POST');
            httpRequest.setHeader('content-type','application/json');
            httpRequest.setHeader('accept','application/json');
            httpRequest.setBody(taxInformationRequest);
            
            // Create the Continuation instance
            Continuation taxInformationContinuation = new Continuation(120);
            
            // Set the callback for the Continuation
            taxInformationContinuation.continuationMethod = 'fetchTaxInformation';
            
            // Add the callout to the Continuation
            this.taxInformationCalloutId = taxInformationContinuation.addHttpRequest(httpRequest);
           
            System.debug('Async Service - callout id is - '+taxInformationCalloutId);
            System.debug('Async Service - continuation object is - '+taxInformationContinuation);
            System.debug('Async Service - continuation requests size is - '+taxInformationContinuation.getRequests().size());
            
            // Return the Continuation
            return taxInformationContinuation;   
        }
    }

    public void invokeSynchronousTaxService(){
        String taxInformationRequest = generateRequestJSON();
        
        System.debug('Sync Service - AAA0'+taxInformationRequest);
        System.debug('Sync Service - CONTAINS ERROR - '+taxInformationRequest.contains('ERROR'));
        
        // Asynchronous Callout (Continuation)
        if(taxInformationRequest!=null && taxInformationRequest.contains('ERROR')){
            System.debug('Sync Service - '+taxInformationRequest);
            setVFPageResponse(taxInformationRequest);
        } else {
            System.debug('Sync Service - AAA $$$$'+taxInformationRequest);
            
            // Create the callout
            Http http = new Http();
            HttpRequest httpRequest = new HttpRequest();
            httpRequest.setTimeout(120000);
            httpRequest.setEndpoint('callout:Tax_Service');
            httpRequest.setMethod('POST');
            httpRequest.setHeader('content-type','application/json');
            httpRequest.setHeader('accept','application/json');
            httpRequest.setBody(taxInformationRequest);    

            HttpResponse response = http.send(httpRequest);
            System.debug('Sync Service - Response is - '+response.getBody());           

            this.syncResponse = response.getBody();  

            fetchTaxInformation();  
        }
    }
        
    /**
     * Callback method that is invoked when a response is received for the request that was sent via
     * 'invokeTaxCalculation' method above
     *
     * This method parses the response and updates the following fields:
     *        Tax_Calculated__c in SBQQ_Quote__c
     *        Tax_Rate__c in SBQQ__QuoteLines__c
     * 
     * @return    the PageReference object of the page where the user has to be taken after processing the response
     */

    public Object fetchTaxInformation(){
        System.debug('INSIDE FETCH TAX - '+taxInformationCalloutId);
        String taxInformationResponse;
        HttpResponse httpResponse;
        
        // Check if Sync service was called or Async Service was called and fetch the response accordingly
        if(syncResponse!=null){
            taxInformationResponse = syncResponse;
        } else {
            // Fetch the response from the Continuation callout using the callback label
            httpResponse = Continuation.getResponse(this.taxInformationCalloutId);
            
            // Check if HTTP status is 200 (SUCCESS) or 0 (Status returned by the testMockService for code coverage)
            if(httpResponse != null && (httpResponse.getStatusCode() == 200 || httpResponse.getStatusCode() == 0)){
                taxInformationResponse = httpResponse.getBody();
            } else {
                // HTTP RESPONSE CODE IS NOT == 200
                System.debug('HTTP response does not contain success status. Status received is - '+httpResponse.getStatusCode()+'. Please check with \'calculate-tax\' service provider.');
                setVFPageResponse('HTTP response does not contain success status. Status received is - '+httpResponse.getStatusCode()+'. Please check with \'calculate-tax\' service provider.');
                return null;
            }
        }
            
        // Instantiate collection objects to store the response (Quote Header & Quote Lines)
        Map<String,String> lineFields;
        Map<String,Map<String,String>> linesMap = new Map<String,Map<String,String>>();
        
        //System.debug('TAX INFORMATION RESPONSE FROM CONTINUATION IS - '+taxInformationResponse);
        
        if(taxInformationResponse != null){
            GetTaxInformationResponseDeserializer responseDeserializer;
            try{
            // Retrieve the quote & quote lines response fields from GetTaxInformationResponseDeserializer
                 responseDeserializer = GetTaxInformationResponseDeserializer.parse(taxInformationResponse);
            //System.debug('DESERIALIZED RESPONSE IS - '+responseDeserializer.toString());
            } catch(JSONException je) {
                    System.debug('Invalid JSON Response. '+je.getMessage());
                    setVFPageResponse('Invalid JSON Response. '+je.getMessage());
                    
                    return null;
            }
            
                // Fetch the Quote header elements
                String quoteNumber = responseDeserializer.header.headerId;
                String status = responseDeserializer.header.status;
                String statusMsg = responseDeserializer.header.statusMsg;
        
                // Store quote line details from the response into a Map
                List<GetTaxInformationResponseDeserializer.QuoteLines> qls = responseDeserializer.lines;
        
                for(GetTaxInformationResponseDeserializer.QuoteLines ql : qls){
                    lineFields = new Map<String,String>();
                    lineFields.put('lineId',ql.lineId);
                    lineFields.put('taxRate',String.valueOf(ql.taxRate));
                    lineFields.put('taxAmount',String.valueOf(ql.taxAmount));
                    
                    linesMap.put(ql.lineId,lineFields);
                }
        
                // Flag to indicate if the tax rate was updated in the Quote Lines successfully or not
                boolean taxUpdated = false;
        
                // If the tax calculation response status is not ERROR (E), then update the Quote Lines with the tax rates
                if(status!=null && status!='E'){
                    // Fetch the Quote Lines for the given Quote for updating
                    List<SBQQ__QuoteLine__c> quoteLines = [SELECT Name, Tax_Rate__c FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c=:quoteId]; 
             
                    for(SBQQ__QuoteLine__c line : quoteLines){
                        // System.debug('UPDATE - line id retrieved is - '+line.Name);
                        if(linesMap.get(line.Name) != null){
                            Decimal taxRate = Decimal.valueOf(linesMap.get(line.Name).get('taxRate'));
                            line.Tax_Rate__c = taxRate;
                        }
                    }
                    
                    // Update the Quote Lines with the updated tax rate    
                    try{
                        update quoteLines;
                        taxUpdated = true;
                    } catch (DMLException dmle){
                        System.debug('DML Exception while trying to update tax rates in Quote Lines. Error is - '+dmle.getMessage());
                        setVFPageResponse('DML Exception while trying to update tax rates in Quote Lines. Error is - '+dmle.getMessage());
                        
                        return null;
                    }
                    
                    /*
                       Update the Parent Quote field (Tax_Calculated__c checkbox) if the tax rates have been
                       successfully updated to the Child Quote Lines
                    */
                    if(taxUpdated){
                        try{
                            // Update Quote checkbox field and also select show tax
                            List<SBQQ__Quote__c> quote= [SELECT id, Tax_Calculated__c FROM SBQQ__Quote__c WHERE id=:quoteId];
                            if(quote.size()==1){
                                quote[0].Tax_Calculated__c = true;
                                quote[0].Show_Tax__c = true;
                                update quote;
                            } else {
                                System.debug('Updating \'Tax_Calculated__c\' failed as quote with id : '+quoteId+' did not return any rows for updating');
                                setVFPageResponse('Updating \'Tax_Calculated__c\' failed as quote with id : '+quoteId+' did not return any rows for updating');
                                
                                return null;
                            }
                        
                            // Set the tax calculation response that will be displayed in the Visualforce page        
                            System.debug('Tax information updated successfully');
                            setVFPageResponse('Tax information updated successfully');
                        } catch (DMLException dmle){
                            System.debug('DML Exception while trying to update Tax Calculated in Quote. Error is - '+dmle.getMessage());
                            setVFPageResponse('DML Exception while trying to update Tax Calculated in Quote. Error is - '+dmle.getMessage());
                        
                            return null;
                        }
                    }

                } else {
                    // JSON RESPONSE HEADER STATUS IS 'E'
                    System.debug('Error received from calculate-tax service. Error is - '+statusMsg);
                    setVFPageResponse('Error received from calculate-tax service. Error is - '+statusMsg);
            } 
        } else {
            // taxInformationResponse IS NULL
            System.debug('Received null response from calculate-tax service. Response received is - '+taxInformationResponse+'. Please check with \'calculate-tax\' service provider.');
            setVFPageResponse('Received null response from calculate-tax service. Response received is - '+taxInformationResponse+'. Please check with \'calculate-tax\' service provider.');                
        }
        
        // Return to the calling Visualforce page
        return null;
    }    
    
    /**
     * Method to help traverse users from the Tax Information Visualforce page to the Quote record page
     * 
     * @return    reference to the page where the users have to be redirected
     */
    public PageReference backToQuote(){
        PageReference returnPage = new PageReference('/'+quoteId);
        System.debug('Return page is - '+returnPage.getUrl());
        return returnPage;
    }
    
    private PageReference setVFPageResponse(String response){
        this.taxInformationStatus = response;
        return null;
    }
    
    private String validateFields(String objectName, List<Map<String,String>> fieldValidationList){
        String message;
        integer countValidationFailure = 0;
        // Iterate through the list of objects and the fields within and validate them for Null or Empty
        for(integer i=0;i<fieldValidationList.size();i++){
            Map<String,String> fieldsMap = fieldValidationList[i];
            
            Set<String> keys = fieldsMap.keyset();
            for(String fieldName : keys){
                String value = fieldsMap.get(fieldName);
                System.debug('1'+fieldName+' - '+value);
                if(value==null || (value!=null && value.length()==0)){
                    System.debug('2'+fieldName+' - '+value);
                    countValidationFailure++;
                    if(countValidationFailure==1){
                        message = objectName+'VALIDATION ERROR - The following mandatory fields for tax generation are Null or Empty, please fix these errors and resubmit - ';
                    }
                    message += fieldName+'='+value+'. ';
                }
            }
        }
        
        // If after checking all fields, 'message' variable is null, it means a successful validation
        if(message == null){
             message = objectName+'Validation Successful.';
        }

        return message;
    }   
}