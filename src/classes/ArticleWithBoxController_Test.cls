/************************************************************************************
    Author : Niraj
    Company : Hexaware Technologies
    Description : Test Class for 'TestArticleDetailsWithBoxController'

    History:
    <Date>         <Author Name>            <Brief Description of Change>   <Copa.do US#>
    13/09/2018      Niraj                   Initial Creation                US-0005634 
    10/01/2019        Nomita Walke            Updated Profile with custom label US-0006524
*************************************************************************************/
@isTest 
public class ArticleWithBoxController_Test {
    static testMethod void TestArticleDetailsWithBoxController() {
        TestUtility.setupConfigurationSettings();
        
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        Id RecordTypeIdKB = Schema.SObjectType.Knowledge__kav.getRecordTypeInfosByName().get('FAQ').getRecordTypeId();
    
        Account testAccount ;
        testAccount = TestUtility.newAccount('Account0', 'Account0');
        database.insert(testAccount);
        
        Contact cont = new Contact();
        cont.FirstName='Test';
        cont.LastName='Test';
        cont.Accountid= testAccount.id;
        database.insert(cont);
        
        boolean isCustVisible = true;
        String articleId;
        String articleId1;
        String articleId2;
        for (Integer i = 0; i <= 2; i++) {
            Knowledge__kav newArticle = new Knowledge__kav
            (Title='test article ' + i, Summary='This is hologic a test article' + i, UrlName='testarticleurl' + i, Language='en_US', RecordTypeId= RecordTypeIdKB, IsVisibleInCsp=isCustVisible );
            // Insert Article
            insert newArticle;
            articleId = newArticle.Id;
            knowledge__kav kArticle  = [SELECT Id,Title,KnowledgeArticleId FROM knowledge__kav WHERE id =: newArticle.Id];
            //system.debug(newArticle);
            if (i==0) 
                articleId1 = articleId; 
            else 
                articleId2 = articleId;
            KbManagement.PublishingService.publishArticle(kArticle.KnowledgeArticleId , true);
        }
        //Create User 
        Profile p = [SELECT Id FROM Profile WHERE Name=: Label.Community_Profile_Name]; 
        
        User u = new User(Alias = 'hotest', Email='hotest@test.com', 
        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
        LocaleSidKey='en_US', ProfileId = p.Id, 
        TimeZoneSidKey='America/Los_Angeles', UserName='hotest@test.com', ContactId=cont.Id);
        database.insert(u);
        
        System.runAs (u) 
        { 
           test.startTest();
               ArticleWithBoxController.Result res;
               res = ArticleWithBoxController.FetchKnowledge(articleId1);
               System.debug('Article:' + res.UrlName);
               System.assertEquals('testarticleurl0',res.UrlName);     
           test.stopTest();
       }
    }

    
}