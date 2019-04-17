@isTest
private class ContentDocumentLinkTriggerActions_Test {

    private static testMethod void testUpdateParentIfCase() {
        TestUtility.setupConfigurationSettings();
        
        //Create data
        Case cas = new Case();
        cas.Priority = 'High';
        insert cas;
        
        Case_Summary__c caseSummary = new Case_Summary__c();
        caseSummary.Case__c = cas.Id;
        caseSummary.Problem_Subject__c = 'Test Subject';
        insert caseSummary;
        
        caseSummary = [
            SELECT Id
                  ,Quality_Integration_String__c
              FROM Case_Summary__c
             WHERE Id = :caseSummary.Id
        ];
        
        Integer oldAgileStringLength = 0;
        
        if(caseSummary.Quality_Integration_String__c != null)
        oldAgileStringLength = caseSummary.Quality_Integration_String__c.length();
        
        ContentNote nte = new ContentNote();
        nte.Title = 'Test title';
        insert nte;
        
        ContentDocumentLink link = new ContentDocumentLink();
        link.ContentDocumentId = nte.Id;
        link.LinkedEntityId = cas.Id;
        link.ShareType = 'I';
        
        //Start test
        Test.startTest();
        
        //Insert link
        insert link;
        
        //Stop test
        Test.stopTest();
        
        //Validate data
        caseSummary = [
            SELECT Id
                  ,Quality_Integration_String__c
              FROM Case_Summary__c
             WHERE Id = :caseSummary.Id
        ];
        Integer newAgileStringLength = caseSummary.Quality_Integration_String__c.length();
        
        System.assertEquals(true, newAgileStringLength > oldAgileStringLength);
    }

    private static testMethod void testCheckToSendFSREmailsForWOs() {
        TestUtility.setupConfigurationSettings();
        
        User use = TestUtility.newUser(UserInfo.getProfileId(), 'testUser');
        use.Division = 'Medical Aesthetics';
        insert use;
        
        //Create data
        Account acc = TestUtility.newAccount('Test Account', null);
        insert acc;
        
        Account acc2 = TestUtility.newAccount('Test Account 2', null);
        insert acc2;
        
        Contact con = TestUtility.newContact('Test', 'Contact', acc2.Id);
        insert con;
        
        AccountContactRelation acr = new AccountContactRelation();
        acr.AccountId = acc.Id;
        acr.ContactId = con.Id;
        acr.Roles = 'FSR Recipient';
        insert acr;
        
        Pricebook2 pb = TestUtility.newPricebook('Test Pricebook');
        insert pb;
        
        Case cas = new Case();
        cas.Priority = 'High';
        cas.AccountId = acc.Id;
        insert cas;
        
        ContentNote nte = new ContentNote();
        nte.Title = '00191716_V2';
        insert nte;
        
        WorkOrder wo = TestUtility.newWorkOrder(acc.Id, null, null);
        wo.Pricebook2Id = pb.Id;
        wo.StartDate = Date.today();
        wo.CaseId = cas.Id;
        wo.ContactId = con.Id;
        //wo.OwnerId = use.Id;
        insert wo;
        
        ContentDocumentLink link = new ContentDocumentLink();
        link.ContentDocumentId = nte.Id;
        link.LinkedEntityId = wo.Id;
        link.ShareType = 'I';
        
        //Start test
        Test.startTest();
        
        //Insert link
        insert link;
        
        //Stop test
        Test.stopTest();
        
        //Validate data
    }

    private static testMethod void testCheckToSendFSREmailsForSAs() {
        TestUtility.setupConfigurationSettings();
        
        //Create data
        Account acc = TestUtility.newAccount('Test Account', null);
        insert acc;
        
        Account acc2 = TestUtility.newAccount('Test Account 2', null);
        insert acc2;
        
        Contact con = TestUtility.newContact('Test', 'Contact', acc2.Id);
        insert con;
        
        AccountContactRelation acr = new AccountContactRelation();
        acr.AccountId = acc.Id;
        acr.ContactId = con.Id;
        acr.Roles = 'FSR Recipient';
        insert acr;
        
        Pricebook2 pb = TestUtility.newPricebook('Test Pricebook');
        insert pb;
        
        Case cas = new Case();
        cas.Priority = 'High';
        cas.AccountId = acc.Id;
        insert cas;
        
        ContentNote nte = new ContentNote();
        nte.Title = 'SA-00191716_V2';
        insert nte;
        
        WorkOrder wo = TestUtility.newWorkOrder(acc.Id, null, null);
        wo.Pricebook2Id = pb.Id;
        wo.StartDate = Date.today();
        wo.CaseId = cas.Id;
        wo.ContactId = con.Id;
        System.assertNotEquals(null, wo.AccountId);
        insert wo;
        System.assertNotEquals(null, [SELECT Id, AccountId FROM WorkOrder WHERE Id = :wo.Id].AccountId);
        
        ServiceAppointment sa = TestUtility.newServiceAppointment(wo.Id, null, wo.Id, DateTime.now(), DateTime.now());
        insert sa;
        
        ContentDocumentLink link = new ContentDocumentLink();
        link.ContentDocumentId = nte.Id;
        link.LinkedEntityId = sa.Id;
        link.ShareType = 'I';
        
        //Start test
        Test.startTest();
        
        //Insert link
        insert link;
        
        //Stop test
        Test.stopTest();
        
        //Validate data
    }

}