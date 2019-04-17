/**************************************************************************************
    Author       : Nikhil Mutyam
    Company      : Hexaware Technologies
    Created Date : 8/23/2018 4:08 AM
    Description  : Test Class for ListController
    
    History:
    <Date>              <Author Name>         <Brief Description of Change> 
    8/23/2018           Nikhil Mutyamn         Initial Creation
    11/13/2018        Sunil Sharma            Updated for Discussion forums    US-0006076
***************************************************************************************/

@isTest
public class ListController_Test {
    @testSetup static void setupTestData() {
        list<Case> casesList = new list<Case>();
        casesList = TestUtility.getCases(10);
        database.insert(casesList);
        system.debug('The Cases are: '+casesList);
        
        list<Product2> Products = new list<Product2>();
        Products = TestUtility.getProducts(1);
        Products[0].Data_Category__c = 'DXA__c';
        database.insert(Products);
        system.debug('The Cases are: '+Products);
        
        Knowledge__kav newArticle = new Knowledge__kav
            (Title='test article', UrlName='knowledgearticleurl8', Language='en_US'  
            );
        
        // Insert Article
        insert newArticle; 
        
        Community_Favorite_Articles__c nwFavArticle = new Community_Favorite_Articles__c(Community_Article_Name__c = newArticle.Id,Community_Favourite__c=true,Community_User__c =userinfo.getuserid());
        insert nwFavArticle ;
    }   
    
    /*Test Method created to unit test Fetch Records methods in ListController class*/
    static testmethod void testFetchRecords(){  
        Test.startTest();    
            list<product2> Products = new list<Product2>();
            Products = [select Id, Name, Data_Category__c from Product2];
            ListController.Master masterInstance = ListController.FetchRecords( 'Case','Subject','Description','Origin','System_Status__c',
                                                                                    'Subject','5','','',
                                                                                    '','','',False,
                                                                                    '','','' );
            masterInstance =  ListController.FetchRecords( 'Case','Subject','Description','Origin','System_Status__c',
                                                      'Subject','5','','Priority',
                                                      '=','Low','',False,
                                                      '','','' );
            masterInstance =  ListController.FetchRecords( 'Knowledge__kav','Community_LastPublishedDate__c','Title','Summary','',
                                                      'Community_Article_View_Count__c','5','','',
                                                      '=','','',True,
                                                      'Data_Category__c',Products[0].Id,'Product2' );
            masterInstance =  ListController.FetchRecords( 'Community_Favorite_Articles__c','Community_Article_Name__r.Community_LastPublishedDate__c','Community_Article_Name__r.Title','Community_Article_Name__r.Summary','',
                                                      '','5','','',
                                                      'Community_User__c','=','currentuser',True,
                                                      '','','' );                                              
        Test.stopTest();
    }
    /*Test Method created to unit test Fetch Records methods in ListController class*/
    static testmethod void testFetchRecords1(){  
        Test.startTest();  
            ListController.Master masterInstance =  ListController.FetchRecords( 'Community_Favorite_Articles__c','Community_Article_Name__r.Community_LastPublishedDate__c','Community_Article_Name__r.Title','Community_Article_Name__r.Summary','',
                                                      '','5','','',
                                                      'Community_User__c','=','currentuser',True,
                                                      '','','' );                                              
        Test.stopTest();
    }
    /*Test Method created to unit test fetchDataCategory methods in ListController class*/
    static testmethod void testFetchDataCategories(){   
        list<Case> casesList = new list<Case>([SELECT Id FROM Case]);
        system.debug('The Cases are: '+casesList);
        Test.startTest();
            ListController.fetchDataCategory(casesList[0].Id,'Case','Subject'); 
        Test.stopTest();
        system.assertEquals(10, casesList.size(), 'Actual size of list does not match with expected results');
    }
}