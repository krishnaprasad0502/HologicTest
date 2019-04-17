/*------------------------------------------------------------
Author:   Mani Sundaresan
Description:  Trigger framework for the CollaborationGroupMember object
Test Class:  CollaborationGroupMemberTriggerActions_Test

History:
<Date>      <Authors Name>    <Brief Description of Change>
08/28/2017  Mani Sundaresan    Initial Creation (US3322)
------------------------------------------------------------*/
trigger preventUserRemoval on CollaborationGroupMember (before insert, before update, before delete, after insert, after update, after delete) {

    private static Boolean isActive = GlobalUtility.isTriggerActive('CollaborationGroupMemberTrigger');

    if(Trigger.isBefore && isActive){
        if(Trigger.isDelete){
            CollaborationGroupMemberTriggerActions.preventUserRemoval(Trigger.old, null);
        }
    }
    if(Trigger.isAfter && isActive){}

}