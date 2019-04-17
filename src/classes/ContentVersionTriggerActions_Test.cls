@isTest
private class ContentVersionTriggerActions_Test {

    private static testMethod void testUpdateParentIfCase() {
        TestUtility.insertAllTriggerCustSettings();
        
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

}