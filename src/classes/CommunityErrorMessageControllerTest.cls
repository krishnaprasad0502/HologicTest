/**************************************************************************************
    Author       : Vrushabh Katariya
    Company      : Hexaware Technologies
    Created Date : 10/31/2018 11:30 AM
    Description  : Test Class for CommunityNavigationController    

    History:
    <Date>          <Author Name>           <Brief Description of Change>   <Copa.do US#>
    10/31/2018      Vrushabh Katariya           Initial Creation          US-0006062  
    10/01/2019        Nomita Walke            Updated Profile with custom label US-0006524     
**************************************************************************************/
@isTest
public class CommunityErrorMessageControllerTest {

    /*Test Method created to unit test methods of CommunityErrorMessageController*/
    public static testMethod void testfetchRecords(){
        CommunityErrorMessageController.fetchConfigData();
        Service_Community_Config__c config = new Service_Community_Config__c();
        config.Community_Profile_Name__c = Label.Community_Profile_Name;
        database.insert(config);
        system.assertEquals(config.Community_Profile_Name__c,Label.Community_Profile_Name);
    }
}