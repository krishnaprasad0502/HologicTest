/***************************************************************************
Author:Yogitha Malireddy
Company:Hexaware Technologies
Description: This controller class is used to get the values from Article Feedback object to show in visualforce email template.

TestClass: getKnowledgeDetails_Test
Code Coverage: 100%

History:
<Date>              <Author Name>           <Brief description of change >         <Copa.do US#>
23/01/2019          Yogitha Malireddy       Initial Creation                        US-0006553
****************************************************************************/
public without sharing class GetKnowledgeDetails{
    public Id artFedId ;
    public Community_Article_Feedback__c artFedList{get;set;}
    public Knowledge__kav articleDetails{get;set;}
    public Id artFedIdtemp{get;set;}
    public void getKnowledgeDetails() {
        artFedIdtemp =artFedId;
        artFedList = new Community_Article_Feedback__c();
        List<Community_Article_Feedback__c> artFedList1 = new List<Community_Article_Feedback__c>([Select Id,CreatedDate,Community_Knowledge__c,Community_Feedback__c,CreatedBy.Name FROM Community_Article_Feedback__c where Id =:artFedIdtemp ]);
        artFedList = artFedList1[0]; 
        
        articleDetails = new Knowledge__kav();
        articleDetails = [Select ArticleNumber,Title,Product_Name__c,AssignedTo.Name,UrlName FROM Knowledge__kav WHERE Id=:artFedList.Community_Knowledge__c LIMIT 1];
        system.debug('articleDetails::' +articleDetails);     
    }
    public void setArtFedId (Id s){
        artFedId = s;
        getKnowledgeDetails();
    }
    
    public String getArtFedId() {
        return artFedId;
    } 
}