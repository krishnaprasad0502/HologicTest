/**************************************************************************************
    Author       : Sunil Kumar Sharma
    Company      : Hexaware Technologies
    Created Date : 10/12/2018 
    Description  : Test Class for ListController for feedItem fetch
    
    History:
    <Date>              <Author Name>         <Brief Description of Change>     <Copa.do US#>
    10/12/2018          Sunil Kumar Sharma     Initial Creation                 US-0006008
    11/13/2018        Sunil Sharma            Updated testfetchBreadCrumbDatafor Discussion forums    US-0006076
	27/12/2018		Sunil Sharma			DF-388 fix 						US-0006345
***************************************************************************************/
@isTest(SeeAllData=True)
public class ListControllerFeedItem_Test {
    /*Test Method created to unit test Fetch Records methods in ListController class*/
    static testmethod void testFetchRecords(){  
        Test.startTest();    
            
            ListController.Master masterInstance =  ListController.FetchRecords( 'FeedItem','Title','','','',
                                                      'Title','5','','',
                                                      '','','',False,
                                                      '','','' );
        Test.stopTest();
    }
    
    /*Test Method created to unit test fetchBreadCrumbData method in BreadcrumbContainerController class*/
    static testmethod void testfetchBreadCrumbData(){ 
        Network communityName = [SELECT id, name FROM Network WHERE Name = 'Hologic Support Portal'];
        Id communityId = communityName.Id ;
        ConnectApi.TopicPage topicPage = ConnectApi.Topics.getTopics(communityId);
        Id topicId ;
        for(ConnectApi.Topic topicSelect : topicPage.topics){
            if(topicSelect.name == 'DXA'){
                topicId = topicSelect.Id ;
            }
        }
        Test.startTest();               
            List<BreadcrumbContainerController.BreadcrumbsItem> masterInstance =  BreadcrumbContainerController.fetchBreadCrumbData(topicId);
        Test.stopTest();
    }
    
    static testMethod void getForumId() {
        
        Account testAccount = TestUtility.newAccount('Account0', 'Account0');
        database.insert(testAccount) ;
        
        list<Product2> Products = new list<Product2>();
        Products = TestUtility.getProducts(1);
        Products[0].Data_Category__c = 'DXA__c';
        Products[0].Community_Family_Name__c = 'DXA';
        database.insert(Products);
        
        List<Asset> AssetList=new List<Asset>();
        AssetList.add(new Asset(
            name='test',
            AccountID=testAccount.id,
            Product2Id = Products[0].Id
        ));
        database.insert(AssetList);
        
        //List<Asset> ast = new List<Asset>([SELECT Id FROM Asset ]);
        CommunityNavigationController.getForumId(AssetList[0].Id);                   
    }
    
    static testMethod void getForumId1() {
        
        Account testAccount = TestUtility.newAccount('Account0', 'Account0');
        database.insert(testAccount) ;
        
        list<Product2> Products = new list<Product2>();
        Products = TestUtility.getProducts(1);
        Products[0].Data_Category__c = 'DXA__c';
        Products[0].Community_Family_Name__c = 'Breast Biopsy';
        database.insert(Products);
        
        List<Asset> AssetList=new List<Asset>();
        AssetList.add(new Asset(
            name='test',
            AccountID=testAccount.id,
            Product2Id = Products[0].Id
        ));
        database.insert(AssetList);
        
        //List<Asset> ast = new List<Asset>([SELECT Id FROM Asset ]);
        CommunityNavigationController.getForumId(AssetList[0].Id);                   
    }
    
}