/***************************************************************************************************
Author       : Niraj Wani
Company      : Hexaware Technologies
Created Date : 10/09/2018 2:39 AM
Description  : Test class - CommunitySelfRegistrationReqTrigger_Test    

History:
<Date>          <Author Name>                   <Brief Description of Change>   <Copa.do US#>
8/13/2018       Community Enablement            Initial Creation                US-0005630
10/15/2018      Niraj Wani                      Approval Process                US-0005861
10/30/2018      Vrushabh Katariya               Moved code to handler class     US-0006062, US-0006075 
***************************************************************************************************/
trigger CommunitySelfRegistrationRequestTrigger on Community_Self_Registration_Request__c (before update) {
    
    if ( trigger.isBefore ) {
        if ( trigger.isUpdate ) {
            CommunitySelfRegistrationTriggerHandler.onBeforeUpdate(trigger.new, trigger.oldMap);
        }
    }
}