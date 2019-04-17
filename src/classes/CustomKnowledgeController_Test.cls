/***************************************************************************************
    Author : Niraj
    Company : Hexaware Technologies
    Description : Test Class for CustomKnowledgeController 

    History:
    <Date>         <Author Name>            <Brief Description of Change>     <Copa.do US#>
    13/09/2018      Niraj                   Initial Creation                   US-0005699
    11/02/2018      Nomita Walke            updated coverage        US-0006075
    10/01/2019        Nomita Walke            Updated Profile with custom label US-0006524
*******************************************************************************************/
@isTest 
public class CustomKnowledgeController_Test {
  
    static testMethod void TestCustomKnowledge() {
        
        TestUtility.setupConfigurationSettings();
        
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        Id RecordTypeIdKB = Schema.SObjectType.Knowledge__kav.getRecordTypeInfosByName().get('FAQ').getRecordTypeId();
    
        Account testAccount ;
        
        testAccount = TestUtility.newAccount('Account0', 'Account0');
        database.insert(testAccount) ;
        
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
            (Title='test article ' + i, Summary='This is hologic a test article' + i, UrlName='testarticleurl' + i, Language='en_US', ValidationStatus ='External' , RecordTypeId= RecordTypeIdKB, IsVisibleInCsp=isCustVisible );
            // Insert Article
            database.insert(newArticle) ;
            articleId = newArticle.Id;
            knowledge__kav kArticle  = [SELECT Id,Title,KnowledgeArticleId FROM knowledge__kav WHERE id =: newArticle.Id];
            
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
               //Test for make sure article is returned
               CustomKnowledgeController.Master result; 
               //string searchVar,  string CategoryString, string ParentCategory, string SelArticleTypes,
               // string RecordType, string StrPageNumber ,string StrRecordToDisply, String ArticleSummaryChars, String LimitNumOfRecords
               result = CustomKnowledgeController.FetchArticles('','','','','FAQ','1','2','100','100','' );
               System.assertEquals(2,result.Results.Size());
               // Test to confirm search operation worked 
               Id [] fixedSearchResults= new Id[2];
               fixedSearchResults[0] = articleId1;
               fixedSearchResults[1] = articleId2;
               Test.setFixedSearchResults(fixedSearchResults);
               result = CustomKnowledgeController.FetchArticles('hologic','','','','FAQ','1','2','100','100','' );
               System.assertEquals(2,result.Results.Size());
               // Test to confirm search operation with All Record Type works
               result = CustomKnowledgeController.FetchArticles('hologic','','','','All','1','2','100','100','' );
               System.assertEquals(2,result.Results.Size());
               // Test to confirm search operation with All Record Type Along with sepcific article type works
               result = CustomKnowledgeController.FetchArticles('hologic','','','FAQ','All','1','2','100','100','' );
               System.assertEquals(2,result.Results.Size()); 
               // Test to confirm search operation with All Record Type Along with sepcific article type works & record to display on page 1
               result = CustomKnowledgeController.FetchArticles('hologic','','','FAQ','All','1','1','100','100','' );
               System.assertEquals(1,result.Results.Size());
               // Test to confirm search operation with All Record Type Along with sepcific article type works & record to display on page 2
               result = CustomKnowledgeController.FetchArticles('','','','FAQ','All','2','1','100','100' ,'');
               System.assertEquals(1,result.Results.Size());
               //Test Call to getDataCategoryTree Method  
               List <CustomKnowledgeController.item> dataCategoryItems; 
               dataCategoryItems = CustomKnowledgeController.getDataCategoryTree();
                for (CustomKnowledgeController.item I: dataCategoryItems){
                    if (I.label == 'Product Classification')
                    {
                        System.assertEquals('Product Classification',I.label);
                        break;
                    }
                }
               // Test Call to method - getFilters
               CustomKnowledgeController.Filters testFilters; 
               testFilters = CustomKnowledgeController.getFilters();
               for (String strArtType : testFilters.ArTyps){
                    if (strArtType == 'FAQ')
                    {
                        System.debug(strArtType);
                        System.assertEquals('FAQ',strArtType);
                        break;
                    }
                }
           CustomKnowledgeController.fetchConfigData(); 
           test.stopTest();

       }
    }
    
    static testMethod void TestArticleTypeList() {
        
       GetArticleTypeList artTypeList = new GetArticleTypeList() ;
       test.startTest();
       
           VisualEditor.DataRow  dr = artTypeList.getDefaultValue();
           VisualEditor.DynamicPickListRows dPr = artTypeList.getValues();
           
           System.assertEquals('All',dr.getValue());  
        
       test.stopTest();
        
    }

    
}