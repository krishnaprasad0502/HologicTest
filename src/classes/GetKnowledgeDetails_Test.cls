/***************************************************************************
Author:Yogitha Malireddy
Company:Hexaware Technologies
Description: Test Class for getKnowledgeDetails class
Controller Class: getKnowledgeDetails
 
History:
<Date>              <Author Name>        <Brief description of change>      <Copa.do US#>
23/01/2019          Yogitha Malireddy     Initial creation                   US-0006553
28/01/2019          Yogitha Malireddy     to submit feedback via customer    US-0006553
****************************************************************************/
@isTest
public class GetKnowledgeDetails_Test { 
     @testsetup
     static void testSetup(){
        
        TestUtility.setupConfigurationSettings();
        Account testAccount = TestUtility.newAccount('TestAccount', 'TestAccount1');
        database.insert(testAccount) ;
        
        Contact cont = new Contact();
        cont.FirstName='testContact';
        cont.LastName='ContactLastName';
        cont.Accountid= testAccount.id;
        cont.Phone= '+1-9009191923';
        database.insert(cont);
        
        Profile p = [SELECT Id FROM Profile WHERE Name=: Label.Community_Profile_Name]; 
        User u = new User(Alias = 'testUser', Email='currentuser@test.com', 
                          EmailEncodingKey='UTF-8', FirstName='FirstName',LastName='LastName', LanguageLocaleKey='en_US', 
                          LocaleSidKey='en_US', ProfileId = p.Id, 
                          TimeZoneSidKey='America/Los_Angeles', UserName='currentuser@test.com', ContactId=cont.Id);
        database.insert(u);
    }
    @isTest
     public static void testKnowledgeDetails(){       
        User u =  [Select Id,Name from User where firstname ='FirstName'];
        Knowledge__kav A1 = new Knowledge__kav();
        A1.Title='test article';
        A1.UrlName='testarticleurl';
        A1.Language='en_US';
        database.insert(A1);
        //System.runAs(u) { 
            test.startTest();
            Community_Article_Feedback__c artFed = new Community_Article_Feedback__c();
            artFed.Community_Knowledge__c = A1.id;
            artFed.Community_Feedback__c = 'test feedback insert';
            database.insert(artFed);
            system.debug('artFed::' +artFed.Id);
            GetKnowledgeDetails controller = new GetKnowledgeDetails() ;
            controller.getArtFedId();
            controller.setArtFedId(artFed.Id);
            test.stopTest();
        //}
    }
}