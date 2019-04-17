/*----------------------------------------------------------------------------------------------------------------------------------------------
Author:     Mani Sundaresan
Description:  Test class to validate paymentLightning page and paymentAuthorization controller
        Tests Excecuted:
        
        init - verifies that the test data gets created successfully
        
        verifyCard - Test the card tokenization
        
        AuthorizeCard - Test the card authorization

History:
<Date>      <Authors Name>    <Brief Description of Change>
07/17/2018   Mani Sundaresan   Initial Creation (US-0004314)
-------------------------------------------------------------------------------------------------------------------------------------------------*/
@isTest 
private class paymentAuthorization_Test {

    static Account customerAccount;
    static Account parentCustomerAccount;
    static Order servOrderUSD;
    static Order servOrderCAD;
    static ServiceContract servContUSD;
    static ServiceContract servContCAD;
    static WorkOrder workOrdUSD;
    static WorkOrder workOrdUSD1;
    static WorkOrder workOrdCAD;
    static Site_Location__c siteLoc;
    static User otherUser;
    static PageReference pageRef;
    static SBQQ__Quote__c testQuoteUSD;
    static SBQQ__Quote__c testQuoteCAD;
    private static Configuration_Settings__c orgDefaults;
    private static Product2 product;
    private static Pricebook2 pricebook;
    private static PricebookEntry pricebookEntry;
    static Payment_Card__c pc;
    static Payment__c pay;

     static{
        
        orgDefaults = TestUtility.setupConfigurationSettings();
        TestUtility.insertAllTriggerCustSettings();
        
        orgDefaults.Uplift_Percentage__c = 10;
        update orgDefaults;
               
        TestUtility.insertCustSetting('OrderTrigger');         
        TestUtility.insertCustSetting('WorkOrderTrigger');                 
        TestUtility.insertCustSetting('SBQQ_QuoteTrigger');
    }


    private static void init() {
    
        
        // insert an account
        
        
        parentCustomerAccount = TestUtility.newAccount('Parent Customer Account', 'testParentCust', 'ABC Street', null, GlobalUtility.getRecordTypeId('Account', 'Customer'));
        insert parentCustomerAccount;
        
        customerAccount = TestUtility.newAccount('Customer Account', 'testCust', 'ABC Street', null, GlobalUtility.getRecordTypeId('Account', 'Customer'));
        customerAccount.ParentId = parentCustomerAccount.Id;
        insert customerAccount;
        
        
        //insert site location
        siteLoc = TestUtility.newSiteLocation('Test Site', customerAccount.Id, 'Site 1 test address');
        siteLoc.Bill_To__c = true;
        insert siteLoc;
        
        Opportunity oppty = TestUtility.newOpportunity('Test Opportunity', customerAccount.Id, System.Today(), 'Target', 'Omitted');
        insert oppty;
        
        //insert an User
        otherUser = TestUtility.newUser(UserInfo.getProfileId(), 'other');
        insert otherUser;
        
        
        product = TestUtility.newProduct('Test Product');
        insert product;
        
        pricebook = TestUtility.newPricebook('Test Pricebook');
        insert pricebook;
        
        pricebookEntry = TestUtility.newPricebookEntry(pricebook.Id, product.Id, 100);
        insert pricebookEntry;
        
        servOrderUSD = TestUtility.newOrder(customerAccount.Id, pricebook.Id, null, GlobalUtility.getRecordTypeId('Order', 'B_SH_Service_Order'), 'DRAFT', 'Field Service', System.today());
        //servOrderUSD.Bill_To_Site_Location__c = siteLoc.Id;
        //servOrderUSD.AccountId = customerAccount.Id;
        //servOrderUSD.Bill_To_Account__c = parentCustomerAccount.Id;
        
        insert servOrderUSD;
        
        servOrderCAD = TestUtility.newOrder(customerAccount.Id, pricebook.Id, null, GlobalUtility.getRecordTypeId('Order', 'B_SH_Service_Order'), 'DRAFT', 'Field Service', System.today());
        servOrderCAD.currencyIsoCode = 'CAD';
        //servOrderCAD.Bill_To_Site_Location__c = siteLoc.Id;
        //servOrderCAD.AccountId = customerAccount.Id;
        //servOrderCAD.Bill_To_Account__c = parentCustomerAccount.Id;
        insert servOrderCAD;
        
        Asset parentAsset = TestUtility.newAsset('Parent Asset', customerAccount.Id, customerAccount.Id, product.Id);
        parentAsset.Bill_To_Location__c = siteLoc.Id;
        insert parentAsset;
         WorkType w = new WorkType(Name='estimate',EstimatedDuration=10);
        
        
        insert w;
        
        workOrdUSD = TestUtility.newWorkOrder(customerAccount.Id, null, null);
        workOrdUSD.Pricebook2Id = pricebook.Id;
        workOrdUSD.StartDate = Date.today();
        workOrdUSD.AssetId = parentAsset.Id;
        workOrdUSD.WorkTypeId=w.Id;
        insert workOrdUSD;
        WorkType w1 = new WorkType(Name='test',EstimatedDuration=10);
        
        
        insert w1;
        workOrdUSD1 = TestUtility.newWorkOrder(customerAccount.Id, null, null);
        workOrdUSD1.Pricebook2Id = pricebook.Id;
        workOrdUSD1.StartDate = Date.today();
        workOrdUSD1.AssetId = parentAsset.Id;
        workOrdUSD1.WorkTypeId=w1.Id;
        insert workOrdUSD1;
        
        workOrdCAD = TestUtility.newWorkOrder(customerAccount.Id, null, null);
        workOrdCAD.Pricebook2Id = pricebook.Id;
        workOrdCAD.StartDate = Date.today();
        workOrdCAD.AssetId = parentAsset.Id;
        workOrdCAD.currencyIsoCode = 'CAD';
        insert workOrdCAD;
        
        servContUSD = TestUtility.newServiceContract(customerAccount.Name + ' Purchase Order', customerAccount.Id, GlobalUtility.getRecordTypeId('ServiceContract', 'B_SH_Service_Contract'), pricebook.Id, System.today().addDays(-1), System.today().addMonths(12));
        servContUSD.Bill_To_Site_Location__c = siteLoc.Id;
        servContUSD.Bill_To_Account__c = parentCustomerAccount.Id;
        GlobalUtility.runAfter = true;
        insert servContUSD;
        
        servContCAD = TestUtility.newServiceContract(customerAccount.Name + ' Purchase Order', customerAccount.Id, GlobalUtility.getRecordTypeId('ServiceContract', 'B_SH_Service_Contract'), pricebook.Id, System.today().addDays(-1), System.today().addMonths(12));
        GlobalUtility.runAfter = true;
        servContCAD.currencyIsoCode = 'CAD';
        servContCAD.Bill_To_Site_Location__c = siteLoc.Id;
        servContCAD.Bill_To_Account__c = parentCustomerAccount.Id;
        insert servContCAD;
        
        //insert quote
        testQuoteUSD = TestUtility.newQuote(customerAccount.Id, oppty.Id);
        testQuoteUSD.RecordTypeId = GlobalUtility.getRecordTypeId('SBQQ__Quote__c', 'Diagnostic_Draft');
        //testQuoteUSD.SBQQ__Primary__c = true;
        testQuoteUSD.BillTo_Site__c = siteLoc.Id;
        insert testQuoteUSD;
        
        testQuoteCAD = TestUtility.newQuote(customerAccount.Id, oppty.Id);
        //testQuoteCAD.SBQQ__Primary__c = true;
        testQuoteCAD.RecordTypeId = GlobalUtility.getRecordTypeId('SBQQ__Quote__c', 'Diagnostic_Draft');
        testQuoteCAD.currencyIsoCode = 'CAD';
        testQuoteCAD.BillTo_Site__c = siteLoc.Id;
        insert testQuoteCAD;
        
        //insert paymentCard on account
        pc = TestUtility.newPaymentCard('Test Card', customerAccount.Id, null, '05', '2020', 'Test User Card', 'Test Token', 'Visa');        
        insert pc;
        
        pay = TestUtility.newPayment(customerAccount.Id, 10, siteLoc.Id, 'I100', servOrderCAD.Id, pc.Id, testQuoteUSD.id, servContCAD.Id, workOrdCAD.Id);
        insert pay;
    }

    private static testmethod void payment_Account(){
    
        init();
        
        Test.startTest();
        pageRef = Page.PaymentLightning;
        Test.setCurrentPage(pageRef);
        
        // This causes a fake response to be generated for displaying the iFrame
        Test.setMock(HttpCalloutMock.class, new paymetricsMockHttpResponseGenerator());
        
        ApexPages.currentPage().getParameters().put('Id', customerAccount.Id);
        paymentAuthorization payAuth = new paymentAuthorization();
        
        payAuth.getconfigSetting();
        payAuth.getXiInterceptURL();
        payAuth.getXiInterceptGUID();
        payAuth.getXiInterceptPSK();
        
        // This causes a fake response to be generated for Tokenization
        Test.setMock(HttpCalloutMock.class, new paymetricsTokenMockHttpResponseGenerator());
        ApexPages.currentPage().getParameters().put('accessToken', '46cfa13c-64f0-4b7d-b218-e56346a10e99');
        ApexPages.currentPage().getParameters().put('signedToken', 'JTZ80/3YX4BiPJSuVVLHD7vvTQWPP726B3VoIcftnZ0=');
        payAuth.getCreditCardToken();
        
        // This causes a fake response to be generated for Authorization
        Test.setMock(HttpCalloutMock.class, new paymetricsAuthMockHttpResponseGenerator());
        payAuth.amount = '10';
        payAuth.ccType = 'Visa';
        payAuth.ccExpMonth = '05';
        payAuth.ccExpYear = '2020';
        payAuth.ccName = 'Test CC';
        payAuth.billToAcct = customerAccount.Id;
        payAuth.billToSiteId = siteLoc.Id; 
        
        paymentAuthorization.existingCardsWrapper wrapClass = new paymentAuthorization.existingCardsWrapper(pc);
        wrapClass.selected = true;
        ApexPages.currentPage().getParameters().put('conid', pc.id);
        
        ApexPages.currentPage().getParameters().put('index', '0');
        payAuth.selectcon();
        payAuth.removeCard();
        
        payAuth.authorizePayment();
        
        Test.stopTest();
        
        
    }
 private static testmethod void payment_Account1(){
    
        init();
        
        Test.startTest();
        pageRef = Page.PaymentLightning;
        Test.setCurrentPage(pageRef);
        
        // This causes a fake response to be generated for displaying the iFrame
        Test.setMock(HttpCalloutMock.class, new paymetricsMockHttpResponseGenerator());
        
        ApexPages.currentPage().getParameters().put('Id', null);
     ApexPages.currentPage().getParameters().put('retURL', '0'+customerAccount.Id);
        paymentAuthorization payAuth = new paymentAuthorization();
        
        payAuth.getconfigSetting();
        payAuth.getXiInterceptURL();
        payAuth.getXiInterceptGUID();
        payAuth.getXiInterceptPSK();
        
        // This causes a fake response to be generated for Tokenization
        Test.setMock(HttpCalloutMock.class, new paymetricsTokenMockHttpResponseGenerator());
        ApexPages.currentPage().getParameters().put('accessToken', '46cfa13c-64f0-4b7d-b218-e56346a10e99');
        ApexPages.currentPage().getParameters().put('signedToken', 'JTZ80/3YX4BiPJSuVVLHD7vvTQWPP726B3VoIcftnZ0=');
        payAuth.getCreditCardToken();
        
        // This causes a fake response to be generated for Authorization
        Test.setMock(HttpCalloutMock.class, new paymetricsAuthMockHttpResponseGenerator());
        payAuth.amount = '10';
        payAuth.ccType = 'Visa';
        payAuth.ccExpMonth = '05';
        payAuth.ccExpYear = '2020';
        payAuth.ccName = 'Test CC';
        payAuth.billToAcct = customerAccount.Id;
        payAuth.billToSiteId = siteLoc.Id; 
        
        paymentAuthorization.existingCardsWrapper wrapClass = new paymentAuthorization.existingCardsWrapper(pc);
        wrapClass.selected = true;
        ApexPages.currentPage().getParameters().put('conid', pc.id);
        ApexPages.currentPage().getParameters().put('index', '1');
        payAuth.selectcon();
      payAuth.authorizePayment();
        payAuth.removeCard();
        
       
        
        Test.stopTest();
        
        
    }
    
    private static testmethod void payment_Order(){
        init();
        
        Test.startTest();
        pageRef = Page.PaymentLightning;
        Test.setCurrentPage(pageRef);
        
        // This causes a fake response to be generated
        Test.setMock(HttpCalloutMock.class, new paymetricsMockHttpResponseGenerator());
        
        ApexPages.currentPage().getParameters().put('Id', servOrderUSD.Id);
        paymentAuthorization payAuth = new paymentAuthorization();
        
        // This causes a fake response to be generated for Tokenization
        Test.setMock(HttpCalloutMock.class, new paymetricsTokenMockHttpResponseGenerator());
        ApexPages.currentPage().getParameters().put('accessToken', '46cfa13c-64f0-4b7d-b218-e56346a10e99');
        ApexPages.currentPage().getParameters().put('signedToken', 'JTZ80/3YX4BiPJSuVVLHD7vvTQWPP726B3VoIcftnZ0=');
        payAuth.getCreditCardToken();
        
        // This causes a fake response to be generated for Authorization
        Test.setMock(HttpCalloutMock.class, new paymetricsAuthMockHttpResponseGenerator());
        payAuth.amount = '10';
        payAuth.billToAcct = customerAccount.Id;
        payAuth.billToSiteId = siteLoc.Id; 
        payAuth.authorizePayment();
        
        Test.stopTest();
        
    }
    
    private static testmethod void payment_OrderCAD(){
    
        init();
        
        Test.startTest();
        pageRef = Page.PaymentLightning;
        Test.setCurrentPage(pageRef);
        
        // This causes a fake response to be generated
        Test.setMock(HttpCalloutMock.class, new paymetricsMockHttpResponseGenerator());
        
        ApexPages.currentPage().getParameters().put('Id', servOrderCAD.Id);
        paymentAuthorization payAuth1 = new paymentAuthorization();
        
        // This causes a fake response to be generated for Tokenization
        Test.setMock(HttpCalloutMock.class, new paymetricsTokenMockHttpResponseGenerator());
        ApexPages.currentPage().getParameters().put('accessToken', '46cfa13c-64f0-4b7d-b218-e56346a10e99');
        ApexPages.currentPage().getParameters().put('signedToken', 'JTZ80/3YX4BiPJSuVVLHD7vvTQWPP726B3VoIcftnZ0=');
        payAuth1.getCreditCardToken();
        
        // This causes a fake response to be generated for Authorization
        Test.setMock(HttpCalloutMock.class, new paymetricsAuthMockHttpResponseGenerator());
        payAuth1.amount = '10';
        payAuth1.billToAcct = customerAccount.Id;
        payAuth1.billToSiteId = siteLoc.Id; 
        payAuth1.authorizePayment();
        
        Test.stopTest();
        
    }
    
    private static testmethod void payment_ServiceContract(){
        init();
        
        Test.startTest();
        pageRef = Page.PaymentLightning;
        Test.setCurrentPage(pageRef);
        
        // This causes a fake response to be generated
        Test.setMock(HttpCalloutMock.class, new paymetricsMockHttpResponseGenerator());
        
        ApexPages.currentPage().getParameters().put('Id', servContUSD.Id);
        paymentAuthorization payAuth = new paymentAuthorization();
        
        // This causes a fake response to be generated for Tokenization
        Test.setMock(HttpCalloutMock.class, new paymetricsTokenMockHttpResponseGenerator());
        ApexPages.currentPage().getParameters().put('accessToken', '46cfa13c-64f0-4b7d-b218-e56346a10e99');
        ApexPages.currentPage().getParameters().put('signedToken', 'JTZ80/3YX4BiPJSuVVLHD7vvTQWPP726B3VoIcftnZ0=');
        payAuth.getCreditCardToken();
        
        // This causes a fake response to be generated for Authorization
        Test.setMock(HttpCalloutMock.class, new paymetricsAuthMockHttpResponseGenerator());
        payAuth.amount = '10';
        payAuth.authorizePayment();
        
        Test.stopTest();
    }
    
    private static testmethod void payment_ServiceContractCAD(){
        init();
        
        Test.startTest();
        pageRef = Page.PaymentLightning;
        Test.setCurrentPage(pageRef);
        
        // This causes a fake response to be generated
        Test.setMock(HttpCalloutMock.class, new paymetricsMockHttpResponseGenerator());
        
        ApexPages.currentPage().getParameters().put('Id', servContCAD.Id);
        paymentAuthorization payAuth1 = new paymentAuthorization();
        
        // This causes a fake response to be generated for Tokenization
        Test.setMock(HttpCalloutMock.class, new paymetricsTokenMockHttpResponseGenerator());
        ApexPages.currentPage().getParameters().put('accessToken', '46cfa13c-64f0-4b7d-b218-e56346a10e99');
        ApexPages.currentPage().getParameters().put('signedToken', 'JTZ80/3YX4BiPJSuVVLHD7vvTQWPP726B3VoIcftnZ0=');
        payAuth1.getCreditCardToken();
        
        // This causes a fake response to be generated for Authorization
        Test.setMock(HttpCalloutMock.class, new paymetricsAuthMockHttpResponseGenerator());
        payAuth1.amount = '10';
        payAuth1.authorizePayment();
        
        Test.stopTest();
    }
    
    private static testmethod void payment_WorkOrder(){
    
        init();
        
        Test.startTest();
        pageRef = Page.PaymentLightning;
        Test.setCurrentPage(pageRef);
        
        // This causes a fake response to be generated
        Test.setMock(HttpCalloutMock.class, new paymetricsMockHttpResponseGenerator());
        
        ApexPages.currentPage().getParameters().put('Id', workOrdUSD.Id);
        paymentAuthorization payAuth = new paymentAuthorization();
        
        // This causes a fake response to be generated for Tokenization
        Test.setMock(HttpCalloutMock.class, new paymetricsTokenMockHttpResponseGenerator());
        ApexPages.currentPage().getParameters().put('accessToken', '46cfa13c-64f0-4b7d-b218-e56346a10e99');
        ApexPages.currentPage().getParameters().put('signedToken', 'JTZ80/3YX4BiPJSuVVLHD7vvTQWPP726B3VoIcftnZ0=');
        payAuth.getCreditCardToken();
        
        // This causes a fake response to be generated for Authorization
        Test.setMock(HttpCalloutMock.class, new paymetricsAuthMockHttpResponseGenerator());
        payAuth.amount = '10';
        
        payAuth.getconfigSetting();
        payAuth.getXiInterceptURL();
        payAuth.getXiInterceptGUID();
        payAuth.getXiInterceptPSK();
        payAuth.authorizePayment();
        
        
        
        Test.stopTest();
        
    }
        
    private static testmethod void payment_WorkOrder1(){
    
        init();
        
        Test.startTest();
        pageRef = Page.PaymentLightning;
        Test.setCurrentPage(pageRef);
        
        // This causes a fake response to be generated
        Test.setMock(HttpCalloutMock.class, new paymetricsMockHttpResponseGenerator());
        
        ApexPages.currentPage().getParameters().put('Id', workOrdUSD1.Id);
        paymentAuthorization payAuth = new paymentAuthorization();
        
        // This causes a fake response to be generated for Tokenization
        Test.setMock(HttpCalloutMock.class, new paymetricsTokenMockHttpResponseGenerator());
        ApexPages.currentPage().getParameters().put('accessToken', '46cfa13c-64f0-4b7d-b218-e56346a10e99');
        ApexPages.currentPage().getParameters().put('signedToken', 'JTZ80/3YX4BiPJSuVVLHD7vvTQWPP726B3VoIcftnZ0=');
        payAuth.getCreditCardToken();
        
        // This causes a fake response to be generated for Authorization
        Test.setMock(HttpCalloutMock.class, new paymetricsAuthMockHttpResponseGenerator());
        payAuth.amount = '10';
        
        payAuth.getconfigSetting();
        payAuth.getXiInterceptURL();
        payAuth.getXiInterceptGUID();
        payAuth.getXiInterceptPSK();
        payAuth.authorizePayment();
        
        
        
        Test.stopTest();
        
    }
    
    private static testmethod void payment_WorkOrderCAD(){
    
        init();
        
        Test.startTest();
        pageRef = Page.PaymentLightning;
        Test.setCurrentPage(pageRef);
        
        // This causes a fake response to be generated
        Test.setMock(HttpCalloutMock.class, new paymetricsMockHttpResponseGenerator());
        
        ApexPages.currentPage().getParameters().put('Id', workOrdCAD.Id);
        paymentAuthorization payAuth1 = new paymentAuthorization();
        
        // This causes a fake response to be generated for Tokenization
        Test.setMock(HttpCalloutMock.class, new paymetricsTokenMockHttpResponseGenerator());
        ApexPages.currentPage().getParameters().put('accessToken', '46cfa13c-64f0-4b7d-b218-e56346a10e99');
        ApexPages.currentPage().getParameters().put('signedToken', 'JTZ80/3YX4BiPJSuVVLHD7vvTQWPP726B3VoIcftnZ0=');
        payAuth1.getCreditCardToken();
        
        // This causes a fake response to be generated for Authorization
        Test.setMock(HttpCalloutMock.class, new paymetricsAuthMockHttpResponseGenerator());
        payAuth1.amount = '10';
        
        payAuth1.getconfigSetting();
        payAuth1.getXiInterceptURL();
        payAuth1.getXiInterceptGUID();
        payAuth1.getXiInterceptPSK();
        payAuth1.authorizePayment();
       
        Test.stopTest();
        
    }
    
    private static testmethod void payment_Quote(){
    
        init();
        
        Test.startTest();
        
        pageRef = Page.PaymentLightning;
        Test.setCurrentPage(pageRef);
        
        // This causes a fake response to be generated
        Test.setMock(HttpCalloutMock.class, new paymetricsMockHttpResponseGenerator());
        
        ApexPages.currentPage().getParameters().put('Id', testQuoteUSD.Id);
        paymentAuthorization payAuth = new paymentAuthorization();
        
        // This causes a fake response to be generated for Tokenization
        Test.setMock(HttpCalloutMock.class, new paymetricsTokenMockHttpResponseGenerator());
        ApexPages.currentPage().getParameters().put('accessToken', '46cfa13c-64f0-4b7d-b218-e56346a10e99');
        ApexPages.currentPage().getParameters().put('signedToken', 'JTZ80/3YX4BiPJSuVVLHD7vvTQWPP726B3VoIcftnZ0=');
        payAuth.getCreditCardToken();
        
        // This causes a fake response to be generated for Authorization
        Test.setMock(HttpCalloutMock.class, new paymetricsAuthMockHttpResponseGenerator());
        payAuth.amount = '10';
        
        payAuth.getconfigSetting();
        payAuth.getXiInterceptURL();
        payAuth.getXiInterceptGUID();
        payAuth.getXiInterceptPSK();
        
        payAuth.authorizePayment();
        
        payAuth.cancel();
        payAuth.getItems();
        payAuth.showNewCardSection();
        payAuth.BillToAcctChanged();
        
        
        
        Test.stopTest();
        
    }
    
    private static testmethod void payment_QuoteCAD(){
    
        init();
        
        Test.startTest();
        
        pageRef = Page.PaymentLightning;
        Test.setCurrentPage(pageRef);
        
        // This causes a fake response to be generated
        Test.setMock(HttpCalloutMock.class, new paymetricsMockHttpResponseGenerator());
        
        ApexPages.currentPage().getParameters().put('Id', testQuoteCAD.Id);
        paymentAuthorization payAuth1 = new paymentAuthorization();
        
        // This causes a fake response to be generated for Tokenization
        Test.setMock(HttpCalloutMock.class, new paymetricsTokenMockHttpResponseGenerator());
        ApexPages.currentPage().getParameters().put('accessToken', '46cfa13c-64f0-4b7d-b218-e56346a10e99');
        ApexPages.currentPage().getParameters().put('signedToken', 'JTZ80/3YX4BiPJSuVVLHD7vvTQWPP726B3VoIcftnZ0=');
        payAuth1.getCreditCardToken();
        
        // This causes a fake response to be generated for Authorization
        Test.setMock(HttpCalloutMock.class, new paymetricsAuthMockHttpResponseGenerator());
        payAuth1.amount = '10';
        
        payAuth1.authorizePayment();
        
        Test.stopTest();
        
    }
    
}