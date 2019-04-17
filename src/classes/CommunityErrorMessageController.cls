/***************************************************************************
Author:Vrushabh Kataria
Company:Hexaware Technologies
Description: This controller class is used to create new case.

TestClass: CommunityErrorMessageControllerTest
Code Coverage: 100%

History:
<Date>              <Author Name>        <Brief description of change >     <Copa.do US#>
31/10/2018          Vrushabh Kataria     Initial Creation                    US-0006062           
****************************************************************************/
public with sharing class CommunityErrorMessageController {
    
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