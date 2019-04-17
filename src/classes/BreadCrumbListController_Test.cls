/**************************************************************************************
    Author       : Sunil Kumar Sharma
    Company      : Hexaware Technologies
    Created Date : 12/19/2018
    Description  : Test class for BreadCrumbsListController
    Coverage     : 100%  

    History:
    <Date>          <Author Name>           <Brief Description of Change>   <Copa.do US#>
    12/20/2018       Sunil Sharma           Initial Creation                US-0006345
**************************************************************************************/
@isTest
public class BreadCrumbListController_Test {
    @testSetup static void setupTestData() {
    	//Create custom setting data for test class
        Service_Community_Config__c configSetting = new Service_Community_Config__c(Documentation__c ='test URL',
            Privacy_Policy__c='test Url');
        database.insert(configSetting); 
        
        list<Case> casesList = new list<Case>();
        casesList = TestUtility.getCases(10);
        database.insert(casesList);
    }
    
    
	/*Test Method created to unit test fetchRecordName methods in BreadCrumbListController class*/
    static testmethod void testFetchRecordName(){   
        list<Case> casesList = new list<Case>([SELECT Id FROM Case]);
        system.debug('The Cases are: '+casesList);
        Test.startTest();
            BreadCrumbListController.fetchRecordName(casesList[0].Id,'CaseNumber','Case'); 
        Test.stopTest();
        system.assertEquals(10, casesList.size(), 'Actual size of list does not match with expected results');
    }
    
    /*Test method to test fucntionality of controller method -"fetchConfigData()"*/
    @isTest static void testFetchConfigDataReturnsSuccess(){
        Test.startTest();
            Service_Community_Config__c configSetting = BreadCrumbListController.fetchConfigData();
            system.assertEquals('test URL', configSetting.Documentation__c, 'Actual documentation link is not matched with expected link.');
        Test.stopTest();
    }
}