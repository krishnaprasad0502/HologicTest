/**************************************************************************************
Author:Sunil Kumar Sharma
Company:Hexaware Technologies
Description: Test Class for BreadcrumbContainerController class
Controller Class: BreadcrumbContainerController

History:
<Date>              <Author Name>        <Brief description of change >     <Copa.do US#>           
29-10-2018          Sunil Kumar Sharma   Initial Creation                   US-0006008
11/13/2018        Sunil Sharma            Updated for Discussion forums    US-0006076
**************************************************************************************/
@isTest
public class BreadcrumbContainerController_Test {

    @testSetup static void setupTestData() {
        //Create custom setting data for test class
        Service_Community_Config__c configSetting = new Service_Community_Config__c(Documentation__c ='test URL',
                                                                                    Privacy_Policy__c='test Url');
        database.insert(configSetting); 
    }
    
    /*Test method to test functionality of controller method -"fetchConfigData()"*/
    @isTest static void testFetchConfigDataReturnsSuccess(){
        Test.startTest();
            Service_Community_Config__c configSetting = BreadcrumbContainerController.fetchConfigData();
            system.assertEquals('test URL', configSetting.Documentation__c, 'Actual documentation link is not matched with expected link.');
        Test.stopTest();
    }    
}