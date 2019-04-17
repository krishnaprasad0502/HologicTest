/*------------------------------------------------------------
Author          Ken Taylor
Company:        Salesforce.com
Description:    Trigger framework for the Case_Summary__c object

History:
<Date           <Authors Name       <Brief Description of Change>
01/15/2019      Ken Taylor        Initial Creation International Lab Landscape (US-0006881)
------------------------------------------------------------*/
trigger ProfileDataTrigger on Profile_Data__c (after delete,
                                               after insert,
                                               after undelete,
                                               after update,
                                               before delete,
                                               before insert,
                                               before update) {

private static Boolean isActive = GlobalUtility.isTriggerActive('ProfileDataTrigger');

     if(isActive){
        if (Trigger.isBefore) {
            if (Trigger.isInsert) {
                ProfileDataTriggerActions.setProfileASP (trigger.new);
            }
            if (Trigger.isUpdate) {
                ProfileDataTriggerActions.setProfileASP (trigger.new);
            }
            if (Trigger.isDelete) {}
        }
    
        if (Trigger.isAfter) {
            if (Trigger.isInsert) {
            }
            if (Trigger.isUpdate) {
                ProfileDataTriggerActions.setProfileTotalVolume (trigger.new, Trigger.oldMap);
            }
            if (Trigger.isDelete) {}
            if (Trigger.isUndelete) {}
        }
    }
}