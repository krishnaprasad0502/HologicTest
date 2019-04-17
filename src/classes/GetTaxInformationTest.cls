@isTest
public class GetTaxInformationTest{
    private static Account testAccount;
    private static Opportunity testOpportunity;
    private static Product2 testProduct;
    private static Site_Location__c billToSite;
    private static Site_Location__c shipToSite;
    private static Site_Location__c invalidShipToSite;
    private static User testUser;
    
    static{
        TestUtility.setupConfigurationSettings();
        // INSERTED BY RL 04/03/2018
        TestUtility.insertCustSetting('sitelocTrigger');
        delete [SELECT Id FROM Trigger_Switch__c WHERE Name = 'sitelocTrigger'];
        
        Trigger_Switch__c tsop= new Trigger_Switch__c();
        tsop.Name = 'OpportunityTrigger';
        tsop.Active__c = true;
        insert tsop;
                        
        // Insert test Account
        testAccount = TestUtility.newAccount('TaxInfo Test Account', '533553355335555');
        insert testAccount;
        
        // Insert test Opportunity
        testOpportunity = TestUtility.newOpportunity('TaxInfo Test Opportunity', testAccount.Id, Date.newInstance(2016,10,10), 'Prospecting','Pipeline');
        insert testOpportunity;
        
        // Insert test Product
        testProduct = TestUtility.newProduct('TaxInfo Test Product');
        testProduct.Oracle_Product_Id__c = '9898';
        testProduct.ProductCode = 'Test Product Code';
        insert testProduct;
        
        // Insert test Bill To Site
        billToSite = TestUtility.newSiteLocation('TaxInfo BillTo Test Site',testAccount.Id,'BillTo Site Test Address');
        billToSite.Bill_To__c = true;
        billToSite.Oracle_Party_Site_ID__c = '1340';
        billToSite.City__c = 'Los Angeles';
        billToSite.State__c = 'CA';
        billToSite.Zip_Code__c = '96025';
        billToSite.Country__c = 'US';
        insert billToSite;
        
        // Insert test Ship To Site
        shipToSite = TestUtility.newSiteLocation('TaxInfo ShipTo Test Site',testAccount.Id,'ShipTo Site Test Address');
        shipToSite.Ship_To__c = true;
        shipToSite.Oracle_Party_Site_ID__c = '1342';
        shipToSite.City__c = 'Los Angeles';
        shipToSite.State__c = 'CA';
        shipToSite.Zip_Code__c = '96025';
        shipToSite.Country__c = 'US';
        insert shipToSite;
        
        // Insert test Ship To Site WITHOUT Oracle_Party_Site_ID__c - to test Mandatory field values
        invalidShipToSite = TestUtility.newSiteLocation('TaxInfo Invalid ShipTo Test Site',testAccount.Id,'Invalid ShipTo Site Test Address');
        invalidShipToSite.Ship_To__c = true;
        invalidShipToSite.Oracle_Party_Site_ID__c = null;
        invalidShipToSite.City__c = 'Los Angeles';
        invalidShipToSite.State__c = 'CA';
        invalidShipToSite.Zip_Code__c = '96025';
        invalidShipToSite.Country__c = 'US';
        insert invalidShipToSite;   
        
        // Create test User
        List<Profile> userProfile = [SELECT Id FROM profile WHERE Name='System Administrator' LIMIT 1];
        testUser = TestUtility.newUser(userProfile[0].Id,'GetTaxIn');
        testUser.Operating_Unit__c = 'HOLX_US_OU';    
    }
    
    static SBQQ__Quote__c createQuoteAndQuoteLines(String operatingUnit, String approvalStatus, boolean createValidQuoteData, boolean createQuoteLines, boolean createValidQuoteLineData){
        // Create Quote
        SBQQ__Quote__c testQuote = TestUtility.newQuote(testAccount.Id, testOpportunity.Id);

         testQuote.ApprovalStatus__c = approvalStatus;
        testQuote.BillTo_Site__c = billToSite.Id;
        
        if(createValidQuoteData){
            testQuote.ShipTo_Site__c = shipToSite.Id;     
        } else {
            testQuote.ShipTo_Site__c = invalidShipToSite.Id;
        }
        testQuote.Operating_Unit__c = 'HOLX_US_OU';   
        
        testQuote.SBQQ__SalesRep__c = testUser.Id;
        insert testQuote;
        
        System.debug('INSERTED TEST QUOTE');
        
        // Create Quote Lines
        if(createQuoteLines){
            System.debug('INSIDE CREATE QUOTE LINES');
            // Create Quote Lines
            List<SBQQ__QuoteLine__c> testQuoteLines = new List<SBQQ__QuoteLine__c>();
            SBQQ__QuoteLine__c ql = TestUtility.newQuoteLine(testQuote.Id, testProduct.Id, 95.5, 45.5);
            ql.SBQQ__Product__c = testProduct.Id;
            ql.SBQQ__NetPrice__c = 40.5;
            
            if(createValidQuoteLineData){
                ql.ShipTo_Site__c = shipToSite.Id;
            } else {
                ql.ShipTo_Site__c = invalidShipToSite.Id;
            }
            
            ql.SBQQ__Quantity__c = 10;
            ql.BillTo_Site__c = billToSite.Id;
            
            
            testQuoteLines.add(ql);
            insert testQuoteLines;
            System.debug('INSERTED TEST QUOTE LINES');          
        }
        
        return testQuote;
    }   
    
    @isTest 
    static void testMockService(){
        // Request
        System.RunAs(testUser) {
            String request = '{ "header" : { "headerId" : "Q-00077", "orgCode" : "HOLX_US_OU", "orderType" : "BEDFORD SYSTEM ORDER", "fob" : "DESTINATION", "currCode" : "USD", "trxDate" : "2016-06-21" }, "lines" : [ { "lineId" : "QL-0002294", "itemId" : 1554641, "itemNumber" : "1554641", "qty" : 1.0, "price" : 484500.0, "shipToId" : 1407535, "invoiceToId" : 1407535, "taxDate" : "2016-06-21" }, { "lineId" : "QL-0002301", "itemId" : 1705622, "itemNumber" : "1705622", "qty" : 1.0, "price" : 250.0, "shipToId" : 1407535, "invoiceToId" : 1407535, "taxDate" : "2016-06-21" }, { "lineId" : "QL-0002302", "itemId" : 1715663, "itemNumber" : "1715663", "qty" : 1.0, "price" : 2940.0, "shipToId" : 1407535, "invoiceToId" : 1407535, "taxDate" : "2016-06-21" } ] }';
            
            // Expected response
            String expectedResponse = '{"header": {"headerId":"Q-00077","status": "S","statusMsg": "Tax calculated successfully."},"lines": [{"lineId": "QL-0002294","taxRate": 5.5,"taxAmount": 7.0994225},{"lineId": "QL-0002301","taxRate": 6.5,"taxAmount": 8.0994225},{"lineId": "QL-0002302","taxRate": 7.5,"taxAmount": 9.0994225}]}';
            
            // Instantiate the controller
            ApexPages.StandardController standardController = new ApexPages.StandardController(createQuoteAndQuoteLines('HOLX_US_OU', 'Approved', true, true, true));
            GetTaxInformationController controller = new GetTaxInformationController(standardController);
            Continuation continuation = (Continuation)controller.invokeAsynchronousTaxService();
            system.debug('continuation: ' + continuation);

            // Create the mock response
            HttpResponse response = new HttpResponse();
            response.setBody(expectedResponse);
            
            // Set the mock response for the Continuation
            Test.setContinuationResponse(controller.taxInformationCalloutId ,response);
            
            // Invoke the callback method
            Object result = Test.invokeContinuationMethod(controller,continuation);
            
            System.debug('TEST CLASS :: '+controller.taxInformationStatus);
            // Verify the result of the callback
            System.assertEquals('Tax information updated successfully',controller.taxInformationStatus);
            }
    }
    
    @isTest 
    static void testMockServiceWithBadHttpResponseCode(){
          System.RunAs(testUser) {
       // Request
        String request = '{ "header" : { "headerId" : "Q-00077", "orgCode" : "HOLX_US_OU", "orderType" : "BEDFORD SYSTEM ORDER", "fob" : "DESTINATION", "currCode" : "USD", "trxDate" : "2016-06-21" }, "lines" : [ { "lineId" : "QL-0002294", "itemId" : 1554641, "itemNumber" : "1554641", "qty" : 1.0, "price" : 484500.0, "shipToId" : 1407535, "invoiceToId" : 1407535, "taxDate" : "2016-06-21" }, { "lineId" : "QL-0002301", "itemId" : 1705622, "itemNumber" : "1705622", "qty" : 1.0, "price" : 250.0, "shipToId" : 1407535, "invoiceToId" : 1407535, "taxDate" : "2016-06-21" }, { "lineId" : "QL-0002302", "itemId" : 1715663, "itemNumber" : "1715663", "qty" : 1.0, "price" : 2940.0, "shipToId" : 1407535, "invoiceToId" : 1407535, "taxDate" : "2016-06-21" } ] }';
        
        // Expected response
        String expectedResponse = '{"header": {"headerId":"Q-00077","status": "S","statusMsg": "Tax calculated successfully."},"lines": [{"lineId": "QL-0002294","taxRate": 5.5,"taxAmount": 7.0994225},{"lineId": "QL-0002301","taxRate": 6.5,"taxAmount": 8.0994225},{"lineId": "QL-0002302","taxRate": 7.5,"taxAmount": 9.0994225}]}';
        
        // Instantiate the controller
        ApexPages.StandardController standardController = new ApexPages.StandardController(createQuoteAndQuoteLines('HOLX_US_OU', 'Approved', true, true, true));
        GetTaxInformationController controller = new GetTaxInformationController(standardController);
        Continuation continuation = (Continuation)controller.invokeAsynchronousTaxService();
        
        // Create the mock response
        HttpResponse response = new HttpResponse();
        response.setStatusCode(500);
        response.setBody(expectedResponse);
        
        // Set the mock response for the Continuation
        Test.setContinuationResponse(controller.taxInformationCalloutId,response);
        
        // Invoke the callback method
        Object result = Test.invokeContinuationMethod(controller,continuation);
        
        System.debug('TEST CLASS :: '+controller.taxInformationStatus);
        // Verify the result of the callback

        System.assertEquals('HTTP response does not contain success status. Status received is - 500. Please check with \'calculate-tax\' service provider.',controller.taxInformationStatus);
    }
    }
    
    @isTest 
    static void testQuoteLineWithoutBillToAndShipTo(){
         System.RunAs(testUser) {
       // Request
        String request = '{ "header" : { "headerId" : "Q-00077", "orgCode" : "HOLX_US_OU", "orderType" : "BEDFORD SYSTEM ORDER", "fob" : "DESTINATION", "currCode" : "USD", "trxDate" : "2016-06-21" }, "lines" : [ { "lineId" : "QL-0002294", "itemId" : 1554641, "itemNumber" : "1554641", "qty" : 1.0, "price" : 484500.0, "shipToId" : 1407535, "invoiceToId" : 1407535, "taxDate" : "2016-06-21" }, { "lineId" : "QL-0002301", "itemId" : 1705622, "itemNumber" : "1705622", "qty" : 1.0, "price" : 250.0, "shipToId" : 1407535, "invoiceToId" : 1407535, "taxDate" : "2016-06-21" }, { "lineId" : "QL-0002302", "itemId" : 1715663, "itemNumber" : "1715663", "qty" : 1.0, "price" : 2940.0, "shipToId" : 1407535, "invoiceToId" : 1407535, "taxDate" : "2016-06-21" } ] }';
        
        // Expected response
        String expectedResponse = '{"header": {"headerId":"Q-00077","status": "S","statusMsg": "Tax calculated successfully."},"lines": [{"lineId": "QL-0002294","taxRate": 5.5,"taxAmount": 7.0994225},{"lineId": "QL-0002301","taxRate": 6.5,"taxAmount": 8.0994225},{"lineId": "QL-0002302","taxRate": 7.5,"taxAmount": 9.0994225}]}';
        
        // Instantiate the controller
        ApexPages.StandardController standardController = new ApexPages.StandardController(createQuoteAndQuoteLines('HOLX_US_OU', 'Approved', true, true, false));
        GetTaxInformationController controller = new GetTaxInformationController(standardController);
        Continuation continuation = (Continuation)controller.invokeAsynchronousTaxService();
        
        // Create the mock response
        HttpResponse response = new HttpResponse();
        response.setBody(expectedResponse);
        
        // Set the mock response for the Continuation
        Test.setContinuationResponse(controller.taxInformationCalloutID,response);
        
        // Invoke the callback method
        Object result = Test.invokeContinuationMethod(controller,continuation);
        
        System.debug('TEST CLASS :: '+controller.taxInformationStatus);
        // Verify the result of the callback
        System.assertEquals('Tax information updated successfully',controller.taxInformationStatus);
    }
    }

    @isTest 
    static void testMockServiceWithErrorStatus(){
        System.RunAs(testUser) {
        // Request
        String request = '{ "header" : { "headerId" : "Q-00077", "orgCode" : "HOLX_US_OU", "orderType" : "BEDFORD SYSTEM ORDER", "fob" : "DESTINATION", "currCode" : "USD", "trxDate" : "2016-06-21" }, "lines" : [ { "lineId" : "QL-0002294", "itemId" : 1554641, "itemNumber" : "1554641", "qty" : 1.0, "price" : 484500.0, "shipToId" : 1407535, "invoiceToId" : 1407535, "taxDate" : "2016-06-21" }, { "lineId" : "QL-0002301", "itemId" : 1705622, "itemNumber" : "1705622", "qty" : 1.0, "price" : 250.0, "shipToId" : 1407535, "invoiceToId" : 1407535, "taxDate" : "2016-06-21" }, { "lineId" : "QL-0002302", "itemId" : 1715663, "itemNumber" : "1715663", "qty" : 1.0, "price" : 2940.0, "shipToId" : 1407535, "invoiceToId" : 1407535, "taxDate" : "2016-06-21" } ] }';
        
        // Expected response
        String expectedResponse = '{"header": {"headerId":"Q-00077","status": "E","statusMsg": "Error while fetching tax informationTax calculated successfully."},"lines": [{"lineId": "QL-0002294","taxRate": 5.5,"taxAmount": 7.0994225},{"lineId": "QL-0002301","taxRate": 6.5,"taxAmount": 8.0994225},{"lineId": "QL-0002302","taxRate": 7.5,"taxAmount": 9.0994225}]}';
        
        // Instantiate the controller
        ApexPages.StandardController standardController = new ApexPages.StandardController(createQuoteAndQuoteLines('HOLX_US_OU', 'Approved', true, true, true));
        GetTaxInformationController controller = new GetTaxInformationController(standardController);
        Continuation continuation = (Continuation)controller.invokeAsynchronousTaxService();
        
        // Create the mock response
        HttpResponse response = new HttpResponse();
        response.setBody(expectedResponse);
        
        // Set the mock response for the Continuation
        Test.setContinuationResponse(controller.taxInformationCalloutID,response);
        
        // Invoke the callback method
        Object result = Test.invokeContinuationMethod(controller,continuation);
        
        System.debug('TEST CLASS :: '+controller.taxInformationStatus);
        // Verify the result of the callback
    }
    }

    @isTest 
    static void testMockServiceWithBadJSONResponse(){
        System.RunAs(testUser) {
       // Request
        String request = '{ "header" : { "headerId" : "Q-00077", "orgCode" : "HOLX_US_OU", "orderType" : "BEDFORD SYSTEM ORDER", "fob" : "DESTINATION", "currCode" : "USD", "trxDate" : "2016-06-21" }, "lines" : [ { "lineId" : "QL-0002294", "itemId" : 1554641, "itemNumber" : "1554641", "qty" : 1.0, "price" : 484500.0, "shipToId" : 1407535, "invoiceToId" : 1407535, "taxDate" : "2016-06-21" }, { "lineId" : "QL-0002301", "itemId" : 1705622, "itemNumber" : "1705622", "qty" : 1.0, "price" : 250.0, "shipToId" : 1407535, "invoiceToId" : 1407535, "taxDate" : "2016-06-21" }, { "lineId" : "QL-0002302", "itemId" : 1715663, "itemNumber" : "1715663", "qty" : 1.0, "price" : 2940.0, "shipToId" : 1407535, "invoiceToId" : 1407535, "taxDate" : "2016-06-21" } ] }';
        
        // Expected response
        String expectedResponse = 'Bad JSON Response';
    
        // Instantiate the controller
        ApexPages.StandardController standardController = new ApexPages.StandardController(createQuoteAndQuoteLines('HOLX_US_OU', 'Approved', true, true, true));
        GetTaxInformationController controller = new GetTaxInformationController(standardController);
        Continuation continuation = (Continuation)controller.invokeAsynchronousTaxService();
        
        // Create the mock response
        HttpResponse response = new HttpResponse();
        response.setBody(expectedResponse);
        
        // Set the mock response for the Continuation
        Test.setContinuationResponse(controller.taxInformationCalloutID,response);
        
        // Invoke the callback method
        Object result = Test.invokeContinuationMethod(controller,continuation);
        
        System.debug('TEST CLASS :: '+controller.taxInformationStatus);
        // Verify the result of the callback
        System.assert(controller.taxInformationStatus.contains('Unexpected character'));
    }    
    }
    
    @isTest 
    static void testMissingQuoteLines(){
         System.RunAs(testUser) {
       
        // Expected response
        String expectedResponse = '{"header": {"headerId":"Q-00077","status": "S","statusMsg": "Tax calculated successfully."},"lines": [{"lineId": "QL-0002294","taxRate": 5.5,"taxAmount": 7.0994225},{"lineId": "QL-0002301","taxRate": 6.5,"taxAmount": 8.0994225},{"lineId": "QL-0002302","taxRate": 7.5,"taxAmount": 9.0994225}]}';
        
        SBQQ__Quote__c testQuote = createQuoteAndQuoteLines('HOLX_US_OU', 'Approved', true, false, true);
        
        // Instantiate the controller
        ApexPages.StandardController standardController = new ApexPages.StandardController(testQuote);
        GetTaxInformationController controller = new GetTaxInformationController(standardController);
        Continuation continuation = (Continuation)controller.invokeAsynchronousTaxService();
        
        // Create the mock response
        HttpResponse response = new HttpResponse();
        response.setBody(expectedResponse);
        
        System.debug('TEST CLASS :: '+controller.taxInformationStatus);
        // Verify the result of the callback
        System.assertEquals('ERROR - No data returned for quote id - '+testQuote.Id+'. Please check',controller.taxInformationStatus);
    } 
    }    
    
    /*@isTest 
    static void testQuoteMissingMandatoryFields(){        
        // Instantiate the controller
        ApexPages.StandardController standardController = new ApexPages.StandardController(createQuoteAndQuoteLines(null, 'Approved', true, true, true));
        GetTaxInformationController controller = new GetTaxInformationController(standardController);
        
        // Invoke the service
        controller.invokeSynchronousTaxService();
        System.debug('TEST CLASS :: '+controller.taxInformationStatus);
        // Verify the result of the callback
        System.assert(controller.taxInformationStatus.contains('Quote - VALIDATION ERROR'));
    }*/
    
    @isTest 
    static void testQuoteLinesMissingMandatoryFields(){
         System.RunAs(testUser) {
       // Instantiate the controller
        ApexPages.StandardController standardController = new ApexPages.StandardController(createQuoteAndQuoteLines('HOLX_US_OU', 'Approved', false, true, false));
        GetTaxInformationController controller = new GetTaxInformationController(standardController);
        
        // Invoke the service
        controller.invokeSynchronousTaxService();
        System.debug('TEST CLASS :: '+controller.taxInformationStatus);
        // Verify the result of the callback
        System.assert(controller.taxInformationStatus.contains('ERROR'));
    }
    }
    
    @isTest 
    static void testQuoteNotApproved(){        
         System.RunAs(testUser) {
       // Instantiate the controller
        ApexPages.StandardController standardController = new ApexPages.StandardController(createQuoteAndQuoteLines('HOLX_US_OU', 'Draft', true, true, true));
        GetTaxInformationController controller = new GetTaxInformationController(standardController);
        
        // Invoke the service
        controller.invokeSynchronousTaxService();
        System.debug('TEST CLASS :: '+controller.taxInformationStatus);
        // Verify the result of the callback
        System.assertEquals('VALIDATION ERROR :: Quote is not approved. Tax can be calculated only for APPROVED quotes. Please submit the quote for approval prior to initiating tax generation. Approval status of the quote is - Draft',controller.taxInformationStatus);
        
        // Test the back to quote button    
        controller.backToQuote();
    }
    }
       
    @isTest 
    static void testSyncService(){
        // Insert test Quote
        /*testQuote = TestUtility.newQuote(testAccount.Id, testOpportunity.Id);
        testQuote.Operating_Unit__c = 'HOLX_US_OU';
        testQuote.ApprovalStatus__c = 'Approved';
        insert testQuote;
        
        // Insert test Quote Lines
        testQuoteLines = new List<SBQQ__QuoteLine__c>();
        SBQQ__QuoteLine__c ql = TestUtility.newQuoteLine(testQuote.Id, testProduct.Id, 95.5, 45.5);
        ql.SBQQ__Product__c = testProduct.Id;
        ql.SBQQ__Quantity__c = 10;
        ql.SBQQ__NetPrice__c = 25.4;
        ql.BillTo_Site__c = billToSite.Id;
        ql.ShipTo_Site__c = shipToSite.Id;

        testQuoteLines.add(ql);
        insert testQuoteLines;*/


        
        // Instantiate the controller
        ApexPages.StandardController standardController = new ApexPages.StandardController(createQuoteAndQuoteLines('HOLX_US_OU', 'Approved', true, true, true));
        GetTaxInformationController controller = new GetTaxInformationController(standardController);

        Test.startTest();

        // Set HTTP mock callout class 
        Test.setMock(HttpCalloutMock.class, new GetTaxInformationHTTPMockTest());
        
        // Invoke the service
        controller.invokeSynchronousTaxService();
        
        Test.stopTest();
        
        System.debug('TEST CLASS :: '+controller.taxInformationStatus);
        // Verify the result of the callback
        //System.assertEquals('Tax information updated successfully',controller.taxInformationStatus);
    }        
}