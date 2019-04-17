/***************************************************************************
Author:
Company:
Description: Test Class for EmailMessageTriggerActions class
Controller Class: EmailMessageTriggerActions

History:
<Date>              <Author Name>        <Brief description of change>      <Copa.do US#>
18/12/2018          Yogitha Malireddy     Added testtrackCaseEmails()       US-0006345
****************************************************************************/
@isTest
private class EmailMessageTriggerActions_Test {
    @testsetup
     static void testSetup(){
         TestUtility.insertAllTriggerCustSettings();    
         TestUtility.setupConfigurationSettings();
        //Create data
        Account testAccount = TestUtility.newAccount('TestAccount', 'TestAccount1');
        database.insert(testAccount) ;
         
         /*Contact Con = TestUtility.newContact('Firstname ','Lastname ', testAccount.id);
         con.Phone = '+(999) 999-9999';
         insert con;*/
        Contact con = new Contact();
        con.Email = 'abc@gmail.com';
        con.FirstName = 'firstname';
        con.AccountId = testAccount.Id;
        con.Lastname = 'test';
        con.GDPR__c =False;
       
        con.Phone = '123456';
        database.insert(con);
          //con.GDPR__c =True;
         //Update con;
        Contact cont = new Contact();
        cont.Email = 'def@gmail.com';
        cont.FirstName = 'firstname1';
        cont.AccountId = testAccount.Id;
        cont.Lastname = 'test1';
        cont.Phone = '1234563';
        database.insert(cont);
        Case cs = new Case();
        cs.Priority = 'Low';
        cs.AccountId = testAccount.Id;
         //cs.ContactEmail = 'def@gmail.com';
        cs.ContactId = con.Id;
        database.insert(cs);
        Case cas = new Case();
        cas.Priority = 'Medium';
        cas.AccountId = testAccount.Id;
         //cas.ContactEmail = 'abc@gmail.com';
        cas.ContactId = cont.Id;
        database.insert(cas);
         
     }

    private static testMethod void testCreateNotesForCaseEmails() {
        TestUtility.insertAllTriggerCustSettings();
        
        //Create data
        Case cas = new Case();
        cas.Priority = 'Low';
        insert cas;
        
        Case_Summary__c summary = new Case_Summary__c();
        summary.Case__c = cas.Id;
        insert summary;
        
        EmailMessage email = new EmailMessage();
        email.ParentId = cas.Id;
        
        //Start test
        Test.startTest();
        
        //Insert email
        insert email;
        
        //Stop test
        Test.stopTest();
        
        //Validate data
        //Ensure email checkbox was checked
        summary = [
            SELECT Has_Emails__c
              FROM Case_Summary__c
             WHERE Id = :summary.Id
        ];
        System.assertEquals(true, summary.Has_Emails__c);
        
        //Ensure note was created
        List<ContentDocumentLink> links = [
            SELECT ContentDocumentId
              FROM ContentDocumentLink
             WHERE LinkedEntityId = :cas.Id
        ];
        System.assertEquals(1, links.size());
    }
    /*Test method to test fucntionality of controller method -"trackCaseEmails()"*/
    private static testMethod void testtrackCaseEmails(){
        Case cs = [Select id,ContactEmail,Casenumber from case where Priority ='Low'];
        Case cas = [Select id,ContactEmail,Casenumber from case where Priority ='Medium'];
        EmailMessage em = new EmailMessage();
        em.ParentId = cs.Id;
        em.Subject = 'test data subject';
        em.TextBody = 'test data body';
        em.ToAddress = 'abc@gmail.com';
        em.FromAddress = 'xyz@gmail.com';
        insert em;
        EmailMessage ema = new EmailMessage();
        ema.ParentId = cas.Id;
        ema.Subject = 'test data subject1';
        ema.TextBody = 'test data body1';
        ema.CcAddress = 'def@gmail.com';
        insert ema;
        //Validate data
        //Ensure Community Emails was created
        List<Community_Emails__c> comEmails = [Select Name FROM Community_Emails__c where Community_Case__c =:cs.Id];
        List<Community_Emails__c> comEmail = [Select Name FROM Community_Emails__c where Community_Case__c =:cas.Id];
        System.assertEquals(1,comEmail.size());        
        System.assertEquals(1,comEmails.size());
    }
}