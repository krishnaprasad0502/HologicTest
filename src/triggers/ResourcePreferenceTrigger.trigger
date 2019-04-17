/*------------------------------------------------------------
Author			Dave Mansell
Company:		Salesforce.com
Description:	Trigger framework for the ResourcePreference object

History:
<Date			<Authors Name		<Brief Description of Change>
10/26/2018		Dave Mansell		Initial Creation (US-0005940)
------------------------------------------------------------*/
trigger ResourcePreferenceTrigger on ResourcePreference (after delete,
													     after insert,
													     after undelete,
													     after update,
													     before insert,
													     before update,
													     before delete) {
												 	
	private static Boolean isActive = GlobalUtility.isTriggerActive('ResourcePreferenceTrigger');
	
	if(isActive){
		if (Trigger.isBefore) {
			if (Trigger.isInsert) {
				ResourcePreferenceTriggerActions.checkToPreventAction(trigger.new);
			}
			if (Trigger.isUpdate) {
				ResourcePreferenceTriggerActions.checkToPreventAction(trigger.new);
			}
			if (Trigger.isDelete) {
				ResourcePreferenceTriggerActions.checkToPreventAction(trigger.old);
			}
		}
	
		if (Trigger.isAfter) {
			if (Trigger.isInsert) {}
			if (Trigger.isUpdate) {}
			if (Trigger.isDelete) {}
			if (Trigger.isUndelete) {}
		}
	}
}