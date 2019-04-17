@isTest
private class WorkOrderServiceReportController_Test {

	private static testMethod void testWorkOrderServiceReportController() {
        //Create test data
        TestUtility.setupConfigurationSettings();
        
        Configuration_Settings__c orgDefaults = Configuration_Settings__c.getInstance();
        orgDefaults.Service_Report_Generation_URL__c = 'http://testurl.com';
        insert orgDefaults;
        
        Account acc = TestUtility.newAccount('Test Account', null);
        insert acc;
        
        Contact con = TestUtility.newContact('Test', 'Contact', acc.Id);
        insert con;
        
        Pricebook2 pb = TestUtility.newPricebook('Test Pricebook');
        insert pb;
        
        Product2 prod = TestUtility.newProduct('Test Product');
        insert prod;
        
        PricebookEntry pbe = TestUtility.newPricebookEntry(pb.Id, prod.Id, 12);
        insert pbe;
        
        Asset asst = TestUtility.newAsset('Parent Asset', acc.Id, acc.Id, prod.Id);
        insert asst;
        
        Case cas = new Case();
        cas.AccountId = acc.Id;
        cas.Priority = 'High';
        insert cas;
        
        CaseContactRole ccr = new CaseContactRole();
        ccr.ContactId = con.Id;
        ccr.CasesId = cas.Id;
        ccr.Role = 'FSR Recipient';
        insert ccr;
        
        WorkOrder wo = TestUtility.newWorkOrder(acc.Id, null, null);
        wo.Pricebook2Id = pb.Id;
        wo.StartDate = Date.today();
        wo.CaseId = cas.Id;
        wo.ContactId = con.Id;
        insert wo;
        
		//Set mock callout class
        Test.setmock(HttpCalloutMock.class, new ServiceReportCalloutHelperMockGenerator(wo.Id));
        
        //Start test
        Test.startTest();
        
        //Open page and run default action
        WorkOrderServiceReportController cont = new WorkOrderServiceReportController(new ApexPages.StandardController(wo));
        cont.generateReport();
        
        //Stop test
        Test.stopTest();
	}

}