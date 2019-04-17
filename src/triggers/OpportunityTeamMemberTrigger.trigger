/*-----------------------------------------------------------
Author:     Dinesh Mummidi
Description:  Trigger framework for Automatic update of OpportunitySplit after adding OpportunityTeammember 
TriggerHandler: OpportunityTeamMemberTriggerHandler
Test Class: OpportunityTeamMemeberTriggerHandler_Test

History:
<Date>      <Authors Name>    <Brief Description of Change>
06/16/2018  Dinesh Mummidi   Initial Creation (US-4457)
------------------------------------------------------------*/

trigger OpportunityTeamMemberTrigger on OpportunityTeamMember (before insert, before update, before delete, after insert, after update, after undelete) {
    
    private static Boolean isActive = GlobalUtility.isTriggerActive('OpportunityTeamMemberTrigger');
    if(Trigger.isBefore && isActive){
        if(Trigger.isInsert){}
        if(Trigger.isUpdate){}
        if(Trigger.isDelete){}
    }
    if(Trigger.isAfter && isActive){
        if(Trigger.isInsert){
            OpportunityTeamMemberTriggerHandler.createOpportunitySplit(Trigger.New, Trigger.oldMap);
        }
        if(Trigger.isUpdate){}
        if(Trigger.isUndelete){}
    }
    
}