/**********************************************************************************************************************
    Author 		 : Nikhil Mutyam
    Company 	 : Hexaware Technologies
	Created Date : 8/13/2018 7:30 AM
    Description  : Apex class acts as helper for Box_EmbedRecordDetail.vfp, helps access folders and files on box
				   for the specific knowledge article.
	Test Class   : Box_EmbedRecordDetailController_Test    
	Coverage 	 : 90%	

    History:
    <Date>         	<Author Name>       	<Brief Description of Change> 	<Copa.do US#>
	10/9/2018 	    Nikhil Mutyam			Initial Creation				US-0005861
**********************************************************************************************************************/
public without sharing class Box_EmbedRecordDetailController {
    
    public string AToken{get;set;}
    public string FolderId{get;set;}
    public string userType{get;set;}
    public boolean displayError{get;set;}
    
    /*
     * Method Name: FetchBoxDetails()
     * Input Param: NA
     * Return: PageReference 
     * Description: Fetches Box Folder Id from Box_Mapper__c based on article id. Fetches Access Token from Box_Auth__c. If the folder is not 
					created already in box for the Article, it the invokes Create Folder method.
     */
    public pageReference FetchBoxDetails(){  
        //Initialization
        displayError = false;
        
        //Fetch Access Token
        list<Box_Auth__c> boxMeta = new list<Box_Auth__c>();
        Box_Auth__c boxMetaData = new Box_Auth__c();
        userType = userInfo.getUserType();
        
        if(userInfo.getUserType() == 'Standard'){
        	boxMeta = [Select Id, Access_Token__c, Article_ID__c, User_Type__c from Box_Auth__c Where User_Type__c = 'Standard'];
        }else{
            boxMeta = [Select Id, Access_Token__c, Article_ID__c, User_Type__c from Box_Auth__c Where User_Type__c != 'Standard'];
        }
        if(boxMeta != Null && boxMeta.size() > 0){
            boxMetaData = boxMeta[0];
            AToken = boxMetaData.Access_Token__c;
            system.debug('The Access Token is: '+AToken);
            
            //Display Box specific to Knowledge Article
            string knowledgeArticleId = apexpages.currentPage().getParameters().get('Id');
            system.debug('The knowledge article id is: '+knowledgeArticleId);
			if(knowledgeArticleId != Null && knowledgeArticleId != ''){
				list<Knowledge__kav> kArticles = new list<Knowledge__kav>();
	            kArticles = [Select Id, ArticleNumber from Knowledge__kav Where Id =: knowledgeArticleId];
	            list<Box_Mapper__c> Articles = new list<Box_Mapper__c>();
	            if(kArticles != Null && kArticles.size() > 0){
		            Articles = [Select Id, Article_ID__c, Folder_ID__c from Box_Mapper__c Where Article_ID__c =: kArticles[0].ArticleNumber];
		            system.debug('You are here'+Articles);
	            
		            if(Articles != Null && Articles.size() > 0){
		                if(Articles[0].Folder_ID__c != Null && Articles[0].Folder_ID__c != ''){
		                    FolderId = Articles[0].Folder_ID__c;
		                    system.debug('The Folder Id is: '+FolderId);
		                }else{
		                    CreateFolder(kArticles[0].ArticleNumber, boxMetaData);
		                }
		            }else{
		                CreateFolder(kArticles[0].ArticleNumber, boxMetaData);
		            }
	            }
			}
        }
        return null;
    }
    
    /*
     * Method Name: CreateFolder()
     * Input Param: Knowledge Article Id and Box Credentials
     * Return: void 
     * Description: Creates folder in Box, then returns the Box folder unique Id and the updates the same back into Box Mapper object.
     */
    public void CreateFolder(string ArticleId, Box_Auth__c boxMeta){
        if(userInfo.getUserType() != 'Standard'){
            displayError = true;
            if(displayError == true){
            	return;
            }
        }else{    
            displayError = false;
            //Create New Folder in Box
            list<Box_Auth__c> boxMeta2 = new list<Box_Auth__c>();
            boxMeta2 = [Select Id, Access_Token__c, Article_ID__c, User_Type__c, Access_Token_URL__c, Folder_URL__c from Box_Auth__c 
                        Where User_Type__c = 'Standard'];
        
            if(boxMeta2 != Null && boxMeta2.size() > 0){
                String endpoint = boxMeta2[0].Folder_URL__c;
                Http http = new Http();
                HttpRequest request = new HttpRequest();
                request.setMethod('POST');
                request.setEndpoint(endpoint);
                request.setBody('{"name":"'+ArticleId+'", "parent": {"id": "'+boxMeta.Article_ID__c+'"}}');
                request.setHeader('Authorization', 'Bearer '+boxMeta2[0].Access_Token__c);
                HttpResponse response = new HttpResponse();
                if(!Test.isRunningTest()){
                    response = http.send(request);
                    if(response.getStatusCode() != 200 && response.getStatusCode() != 201){
                        sendException(response.getStatusCode(),response.getBody());
                        return;
                    }
                }    
                system.debug('The response contains: '+response.getBody());
            
                //Serialize response
                RootObject FolderInfo;
                string Folder_id;
                if(!Test.isRunningTest()){
                    FolderInfo = (RootObject)JSON.deserialize(response.getBody(), RootObject.class);
                    Folder_id = FolderInfo.Id;
                }else{
                    Folder_id = 'TestId';
                }    
                system.debug('The serialized class contains: '+Folder_id);
                
                //Insert Mapper Record
                if(Folder_id != Null && Folder_id != ''){
                    Box_Mapper__c BM = new Box_Mapper__c();
                    BM.Article_ID__c = ArticleId;
                    BM.Folder_ID__c = Folder_id;    
                    insert BM;
                    FolderId = BM.Folder_ID__c;
                }
            }
    	}
    }

    public static void sendException(integer erorCode, string errorMessage){
    	list<string> toAddressesTest = new list<string>();
		//for(User u : [select Id, email from User Where Profile.Name='System Administrator' and isActive = true]){
		string usernamestr = Label.Community_Box_Exception_Email_Address;
		usernamestr += '%';
		system.debug('The username str is: '+usernamestr);
		for(User u : [SELECT Id, email FROM User WHERE Username LIKE: usernamestr AND isActive = true]){
		    toAddressesTest.add(u.Email);
		}
		Messaging.SingleEmailMessage mailTest = new Messaging.SingleEmailMessage();
		mailTest.setToAddresses(toAddressesTest); 
		mailTest.setSubject('Unexpected Error occured while making a callout to Box. Error Code: '+erorCode);
		mailTest.setHtmlBody(errorMessage);
		Messaging.SendEmail(new Messaging.SingleEmailMessage[] {mailTest});
    }
    
    /*Helper classes to parse the incoming response on folder creation*/
    public class Entry{
        public string type;
        public string id;
        public string sequence_id;
        public string etag;
        public string name;
    }
    
    public class PathCollection{
        public integer total_count;
        public List<Entry> entries;
    }
    
    public class CreatedBy{
        public string type;
        public string id;
        public string name;
        public string login;
    }
    
    public class ModifiedBy{
        public string type;
        public string id;
        public string name;
        public string login;
    }
    
    public class OwnedBy{
        public string type;
        public string id;
        public string name;
        public string login;
    }
    
    public class Parent{
        public string type;
        public string id;
        public string sequence_id;
        public string etag;
        public string name;
    }
    
    public class Order{
        public string x_by;
        public string direction;
    }
    
    public class ItemCollection{
        public integer total_count;
        public List<object> entries;
        public integer offset;
        public integer line_limit;
        public List<Order> order;
    }
    
    public class RootObject{
        public string type;
        public string id;
        public string sequence_id;
        public string etag;
        public string name;
        public DateTime created_at;
        public DateTime modified_at;
        public string description;
        public integer size;
        public PathCollection path_collection;
        public CreatedBy created_by;
        public ModifiedBy modified_by;
        public object trashed_at;
        public object purged_at;
        public DateTime content_created_at;
        public DateTime content_modified_at;
        public OwnedBy owned_by;
        public object shared_link;
        public object folder_upload_email;
        public Parent parent;
        public string item_status;
        public ItemCollection item_collection;
    }
}