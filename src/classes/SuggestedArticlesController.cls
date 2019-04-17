/**************************************************************************************
    Author       : Nikhil Mutyam
    Company      : Hexaware Technologies
    Created Date : 09/25/2018
    Description  : Returns Suggested Articles 
    Test Class   : SuggestedArticlesController_Test    
    Coverage     : 100% 

    History:
    <Date>          <Author Name>           <Brief Description of Change>   <Copa.do US#>
    09/25/2018      Nikhil Mutyam           Initial Creation          
	01/11/2019      Nomita Walke           Handled code for scenario where user doesnt have access to Articles. US-0006454    
**************************************************************************************/
public class SuggestedArticlesController {
    
    /*Searches knowledge articles depending upon the valu entered in subject field of case creation 
    and returns the list of knowledge articles*/
    @AuraEnabled
    public static list<KnowledgeArticleVersion> searchArticles(string searchString){
        system.debug('The search string is: '+searchString);
        list<KnowledgeArticleVersion> KArticles = new list<KnowledgeArticleVersion>();
        if(searchString != null && searchString != ''){
            List<List<sObject>> searchList = new List<List<sObject>>();
            searchList = [FIND :searchString RETURNING KnowledgeArticleVersion(Id, Title, Summary, UrlName 
                                              WHERE PublishStatus='online' AND Language='en_US' and ValidationStatus='External')];
            
            if(searchList.size() > 0){
            	KArticles = searchList[0];    
            }
            
            system.debug('The articles are: '+KArticles);
        }  
        return KArticles;
    }    
}