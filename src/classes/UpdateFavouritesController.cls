/**************************************************************************************
    Author       : Nikhil Mutyam
    Company      : Hexaware Technologies
    Created Date : 8/28/2018 10:13 AM
    Description  : Fetch, Update and delete favourite
    Test Class   : UpdateFavouritesController_Test    
    Coverage     : 92%  

    History:
    <Date>          <Author Name>           <Brief Description of Change>   	<Copa.do US#>
    8/28/2018       Nikhil Mutyam           Initial Creation                	US-0005700
    11/05/2018      Nomita Walke            Added method fetchConfigData()  	US-0006075
	1/2/2019		Yogitha Malireddy		Added method FetchMetadataRecords()	\US-0006454
	01/09/2019		Sunil Kumar Sharma		Added func to mark articles favorite 
**************************************************************************************/

public without sharing class UpdateFavouritesController {
	/*
    * Method Name: UpdateFavourite()
    * Input Param: Current Record Id 
    * Return: string 
    * Description: Update the Asset Record as Favourite for the loggedin user.
    */
    @AuraEnabled
    public static string UpdateFavourite(string RecId){
        Asset act = new Asset();
        User Usr = new User();
        
        act = [SELECT Id, Community_Favorite_Users__c FROM Asset WHERE Id =: RecId];
        Usr = [SELECT Id, Community_User_Number__c from User Where Id =: Userinfo.getuserid()];
        
        if(act.Community_Favorite_Users__c == null || act.Community_Favorite_Users__c == ''){
            act.Community_Favorite_Users__c = Usr.Community_User_Number__c + '#';
        }else{
            act.Community_Favorite_Users__c += Usr.Community_User_Number__c + '#';
        }

        try{
            update act;
            return 'Success';
        }catch(exception e){
            return label.Support_Favorite_Error;
        } 
    }
    
    /*
    * Method Name: UpdateFavouriteArticle()
    * Input Param: Current Record Id 
    * Return: string 
    * Description: Update the Article Record as Favourite for the loggedin user.
    */
    @AuraEnabled
    public static string UpdateFavouriteArticle(string articleId){
        try{
            system.debug('Current User is'+ userinfo.getuserid());
            List<Community_Favorite_Articles__c> articleRecList = new List<Community_Favorite_Articles__c>([SELECT id,Community_Favourite__c 
                                                                                        FROM Community_Favorite_Articles__c 
                                                                                        WHERE Community_Article_Name__c =: articleId AND Community_User__c =: userinfo.getuserid()]); 
            system.debug('List size is '+ articleRecList.size() +  'Rec id'+ articleId);
            if(articleRecList.size()>0){
                Community_Favorite_Articles__c favArticleRec = new Community_Favorite_Articles__c();
                favArticleRec.id = articleRecList[0].id ;
                favArticleRec.Community_Favourite__c = true ;
                update favArticleRec;
                return 'Success';
            }else{
                Community_Favorite_Articles__c favArticleRec = new Community_Favorite_Articles__c();
                favArticleRec.Community_Article_Name__c = articleId ;
                favArticleRec.Community_User__c = userinfo.getuserid() ;
                favArticleRec.Community_Favourite__c = true ;
                insert favArticleRec;
                return 'Success';
            }
        }catch(exception e){
            return label.Support_Favorite_Error;
        } 
    }
    
    /*
    * Method Name: removeFavouriteArticle()
    * Input Param: Current Record Id 
    * Return: string 
    * Description: Update the Article Record as Favourite for the loggedin user.
    */
    @AuraEnabled
    public static string removeFavouriteArticle(string articleId){
        try{
            system.debug('Current User is'+ userinfo.getuserid());
            List<Community_Favorite_Articles__c> articleRecList = new List<Community_Favorite_Articles__c>([SELECT id,Community_Favourite__c 
                                                                                        FROM Community_Favorite_Articles__c 
                                                                                        WHERE Community_Article_Name__c=: articleId AND Community_User__c =: userinfo.getuserid()]); 
            if(articleRecList.size()>0){
                Community_Favorite_Articles__c favArticleRec = new Community_Favorite_Articles__c();
                favArticleRec.id = articleRecList[0].id ;
                favArticleRec.Community_Favourite__c = false ;
                update favArticleRec;
            }
            return 'Success';
        }catch(exception e){
            return label.Support_Favorite_Error;
        } 
    }
    
    /*
    * Method Name: checkFavouriteArticle()
    * Input Param: Current Record Id 
    * Return: string 
    * Description: Returns true if the record is favourite to the loggedIn user else false.
    */
    @AuraEnabled
    public static Boolean checkFavouriteArticle(string articleId){
        List<Community_Favorite_Articles__c> articleRecList = new List<Community_Favorite_Articles__c>([SELECT id,Community_Favourite__c 
                                                                                    FROM Community_Favorite_Articles__c 
                                                                                    WHERE Community_Article_Name__c=: articleId AND Community_User__c =: userinfo.getuserid() AND Community_Favourite__c= True]); 
        if(articleRecList.size()> 0 ){
            return true;
        }else{
            return false;
        }
    }
    
    /*
    * Method Name: CheckFavourite()
    * Input Param: Current Record Id 
    * Return: string 
    * Description: Returns true if the record is favourite to the loggedIn user else false.
    */
    @AuraEnabled
    public static string CheckFavourite(string RecId){
        list<Asset> Assets = new list<Asset>();
        User Usr = new User();
        
        Usr = [SELECT Id, Community_User_Number__c from User Where Id =: Userinfo.getuserid()];
        string wipid = '%'+Usr.Community_User_Number__c+'#'+'%';
        Assets = [SELECT Id FROM Asset WHERE Community_Favorite_Users__c LIKE : wipid AND Id =: RecId];
        system.debug('The assets are'+Assets);
        if(Assets != Null && Assets.size() > 0){
            return 'True';
        }
        return 'False';   
    }
    
    /*
    * Method Name: RemoveFromFavourites()
    * Input Param: Current Record Id 
    * Return: string 
    * Description: Removes the Asset record as a favourite for Logged in user
    */
    @AuraEnabled
    public static string RemoveFromFavourites(string RecId){
        list<Asset> Assets = new list<Asset>();
        User Usr = new User();
        
        Usr = [SELECT Id, Community_User_Number__c from User Where Id =: Userinfo.getuserid()];
        string wipid = '%'+Usr.Community_User_Number__c+'#'+'%';
        Assets = [SELECT Id,Community_Favorite_Users__c FROM Asset WHERE Community_Favorite_Users__c LIKE : wipid AND Id =: RecId];
        if(Assets != Null && Assets.size() > 0){
            string FavStr = Assets[0].Community_Favorite_Users__c;
            FavStr = FavStr.replace(Usr.Community_User_Number__c + '#','');
            Assets[0].Community_Favorite_Users__c = FavStr;
            try{
                update Assets[0];
                return 'Success';
            }catch(exception e){
                return label.Support_Favorite_Error;
            }    
        } 
        return null;
    }
    
    /*
    * Method Name: fetchRecords()
    * Input Param: No input required
    * Return: list<Service_Community_Menu__mdt> 
    * Description: Fetch Service Community Menu items from Service_Community_Menu__mdt metadata.
    */
    @AuraEnabled
    public static list<Service_Community_Menu__mdt> fetchRecords(){
        
        list<Service_Community_Menu__mdt> serviceCommunityMenuList = new list<Service_Community_Menu__mdt>();
        serviceCommunityMenuList = [SELECT id,MasterLabel,Redirect_URL__c 
                                    FROM Service_Community_Menu__mdt
                                    WHERE Type__c ='REPORTS' 
                                    ORDER BY Sort_Order__c];
        return serviceCommunityMenuList ;
    }
    
    /*
    * Method Name: FetchMetadataRecords()
    * Input Param: No input required
    * Return: list<Service_Community_Menu__mdt> 
    * Description: Fetch records from custom meta data.
    */
    @AuraEnabled
    public static list<Service_Community_Menu__mdt> FetchMetadataRecords(){
        //Fetching the records from custom meta data
        List<Service_Community_Menu__mdt> metadata = [SELECT Id, MasterLabel,Show_As_Hero_Menu__c,Is_Email__c, DeveloperName, Redirect_URL__c, 
                                                    Sort_Order__c,Is_Not_Hyperlink__c,IsCorporateSiteUrl__c, Type__c,Quick_Link_Menu_Name__c, Invoke_Component__c, Component_Name__c, Value2__c, Value1__c,Value3__c,
                                                    Subject__c
                                                    FROM Service_Community_Menu__mdt 
                                                    WHERE MasterLabel =: 'Submit an Issue'];
        return metadata;
    }
    @AuraEnabled
    public static Asset fetchAsset(string RecId){
        system.debug('The record Id is: '+RecId);
        list<Asset> Assets = new list<Asset>();
        Assets = [SELECT Id, Name, Community_Custom_Asset_Name__c, Community_Asset_Display_Name__c FROM Asset WHERE Id=: RecId];
        system.debug('The Assets are: '+Assets);
        if(Assets != Null && Assets.size() > 0){
            return Assets[0];   
        }else{
            return null;
        }
    }
    
    /*
    * Method Name: saveAsset()
    * Input Param: Asset Name
    * Return: string 
    * Description: Update custom name to asset record.
    */
    @AuraEnabled
    public static string saveAsset(string customAssetName, string RecId){
        Asset ast = new Asset();
        ast.Id = RecId;
        ast.Community_Custom_Asset_Name__c = customAssetName;
        Update ast;
        return 'Success';
    }
    
    /*
    * Method Name: fetchConfigData()
    * Input Param: No inputs required
    * Return: Service_Community_Config__c 
    * Description: fetch Global Menu from Custom Setting
    */
    @AuraEnabled
    public static Service_Community_Config__c fetchConfigData(){
       Service_Community_Config__c config = Service_Community_Config__c.getOrgDefaults();
       return config;
    } 
}