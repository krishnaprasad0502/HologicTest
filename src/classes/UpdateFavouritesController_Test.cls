/**************************************************************************************
    Author       : Nikhil Mutyam
    Company      : Hexaware Technologies
    Created Date : 9/13/2018 11:50 AM
    Description  : Test Class for UpdateFavouritesController
    
    History:
    <Date>          <Author Name>           <Brief Description of Change>   		<Copa.do US#>
    9/13/2018       Nikhil Mutyam           Initial Creation                		US-0005700
    11/13/2018      Nomita Walke        	Updated user auto number field 			US-0006075
	1/4/2019		Yogitha Malireddy		Added method testFetchMetadataRecords()	US-0006454
**************************************************************************************/

@isTest
public class UpdateFavouritesController_Test {
    
    @testSetup static void setupTestData() {
        TestUtility.setupConfigurationSettings();
        //Create test Account record
        Account acc = TestUtility.newAccount('Test Account',null);
        database.insert(acc);
        
        //Create test Product records
        List<Product2> list_TestProducts = new List<Product2>();
        Product2 testProduct1 = new Product2(Name='Test Product1', Community_Family_Name__c='Mammography_Systems',
                                             Community_Product_Description__c='Test Product1', Community_Visible__c =true);
        Product2 testProduct2 = new Product2(Name='Test Product2', Community_Family_Name__c='Mammography_Systems', 
                                             Community_Product_Description__c='Test Product2', Community_Visible__c =true);
        product2 testProduct3 = new Product2(Name='Test Product3', Community_Family_Name__c='Mammography_Systems',
                                             Community_Product_Description__c='Test Product3', Community_Visible__c =true);
        list_TestProducts.add(testProduct1);
        list_TestProducts.add(testProduct2);
        list_TestProducts.add(testProduct3);
        database.insert(list_TestProducts);
        
        //Create Asset test data
        list<Asset> list_TestAssets = new list<Asset>();
        Asset testAssetRec1 = new Asset(Name ='Test Asset',Accountid =acc.Id,Product2Id= testProduct1.Id);
        Asset testAssetRec2 = new Asset(Name ='Test Asset',Accountid =acc.Id,Product2Id= testProduct1.Id);
        list_TestAssets.add(testAssetRec1);
        list_TestAssets.add(testAssetRec2);
        database.insert(list_TestAssets);
        
        Knowledge__kav newArticle = new Knowledge__kav
            (Title='test article', UrlName='testarticleurl', Language='en_US'  
            );
        
        // Insert Article
        insert newArticle; 

        //Create custom setting data for test class
        Service_Community_Config__c configSetting = new Service_Community_Config__c(Documentation__c ='test URL', Privacy_Policy__c='test Url');
        insert configSetting; 
    }
    
    /*Test Method created to unit test UpdateFavourite, CheckFavourite and RemoveFromFavourites methods in UpdateFavouritesController class*/
    static testmethod void main(){
        list<Asset> list_TestAssets = new list<Asset>([SELECT Id FROM Asset]);
        User Usr = new User();
        Usr = [SELECT Id, Community_User_Number__c from User Where Id =: Userinfo.getuserid()];
        test.startTest();
            UpdateFavouritesController.CheckFavourite(list_TestAssets[0].Id);
            UpdateFavouritesController.RemoveFromFavourites(list_TestAssets[0].Id);
            UpdateFavouritesController.UpdateFavourite(list_TestAssets[0].Id);
            system.assertEquals(Usr.Community_User_Number__c+'#', 
                                [SELECT Id, Community_Favorite_Users__c 
                                 FROM Asset 
                                 WHERE Id =: list_TestAssets[0].Id].Community_Favorite_Users__c,
                                 'Something went wrong, please contact your administrator');
            UpdateFavouritesController.UpdateFavourite(list_TestAssets[0].Id);
            UpdateFavouritesController.CheckFavourite(list_TestAssets[0].Id);
            UpdateFavouritesController.RemoveFromFavourites(list_TestAssets[0].Id);
            UpdateFavouritesController.saveAsset('Test',list_TestAssets[0].Id);
            UpdateFavouritesController.fetchAsset(Userinfo.getuserid());
            UpdateFavouritesController.fetchAsset(list_TestAssets[0].Id);
            UpdateFavouritesController.fetchConfigData();
        	
        test.stopTest();
    }  
    static testmethod void testUpdateFavouriteArticle(){
        Knowledge__kav newArticle = new Knowledge__kav
            (Title='test article', UrlName='knowledgearticleurl1', Language='en_US'  
            );
        
        // Insert Article
        insert newArticle; 
        
        Community_Favorite_Articles__c nwFavArticle = new Community_Favorite_Articles__c(Community_Article_Name__c = newArticle.Id,Community_User__c =userinfo.getuserid());
        insert nwFavArticle ;
        
        UpdateFavouritesController.UpdateFavouriteArticle(newArticle.Id);
    }
    static testmethod void testUpdateFavouriteArticle1(){
        Knowledge__kav newArticle = new Knowledge__kav
            (Title='test article', UrlName='knowledgearticleurl2', Language='en_US'  
            );
        
        // Insert Article
        insert newArticle; 
        
        UpdateFavouritesController.UpdateFavouriteArticle(newArticle.Id);
    }
    static testmethod void testRemoveFavouriteArticle(){
        Knowledge__kav newArticle = new Knowledge__kav
            (Title='test article', UrlName='knowledgearticleurl3', Language='en_US'  
            );
        
        // Insert Article
        insert newArticle; 
        
        Community_Favorite_Articles__c nwFavArticle = new Community_Favorite_Articles__c(Community_Article_Name__c = newArticle.Id,Community_User__c =userinfo.getuserid());
        insert nwFavArticle ;
        
        UpdateFavouritesController.removeFavouriteArticle(newArticle.Id);
    }
    static testmethod void testCheckFavouriteArticle(){
        Knowledge__kav newArticle = new Knowledge__kav
            (Title='test article', UrlName='knowledgearticleurl3', Language='en_US'  
            );
        
        // Insert Article
        insert newArticle; 
        
        Community_Favorite_Articles__c nwFavArticle = new Community_Favorite_Articles__c(Community_Article_Name__c = newArticle.Id,Community_User__c =userinfo.getuserid(),Community_Favourite__c= True);
        insert nwFavArticle ;
        
        UpdateFavouritesController.checkFavouriteArticle(newArticle.Id);
    }
    static testmethod void testCheckFavouriteArticleReturnFalse(){
        Knowledge__kav newArticle = new Knowledge__kav
            (Title='test article', UrlName='knowledgearticleurl3', Language='en_US'  
            );
        
        // Insert Article
        insert newArticle; 
        
        Community_Favorite_Articles__c nwFavArticle = new Community_Favorite_Articles__c(Community_Article_Name__c = newArticle.Id,Community_User__c =userinfo.getuserid(),Community_Favourite__c= false);
        insert nwFavArticle ;
        
        UpdateFavouritesController.checkFavouriteArticle(newArticle.Id);
    }
    static testmethod void testFetchRecords(){
        list<Service_Community_Menu__mdt> serviceCommunityMenuList = UpdateFavouritesController.fetchRecords();
        system.assertEquals(2, serviceCommunityMenuList.size(), 'The number of records returned for reports type is incorrect.');
    }
    static testmethod void testFetchMetadataRecords(){
        list<Service_Community_Menu__mdt> serviceCommunitySubmitanIssue = UpdateFavouritesController.FetchMetadataRecords();
        system.assertEquals(1, serviceCommunitySubmitanIssue.size(), 'The number of records returned for submit an issue button is incorrect.');
    }
}