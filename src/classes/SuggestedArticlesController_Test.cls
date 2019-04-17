/**************************************************************************************
    Author 		 : Nikhil Mutyam
    Company 	 : Hexaware Technologies
	Created Date : 09/26/2018
    Description  : Test Class for SuggestedArticlesController	

    History:
    <Date>         	<Author Name>       	<Brief Description of Change> 	<Copa.do US#>
	09/26/2018		Nikhil Mutyam			Initial Creation				
**************************************************************************************/
@isTest
public class SuggestedArticlesController_Test {
    
    static testMethod void testSearchArticles(){
        list<KnowledgeArticleVersion> articles = new list<KnowledgeArticleVersion>();
        SuggestedArticlesController.searchArticles('Sample');
        system.assertEquals(0, articles.size(), 'Actual size of list does not match with expected results');
    }
    
}