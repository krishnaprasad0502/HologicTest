/*------------------------------------------------------------
Author			Dave Mansell
Company:		Salesforce.com
Description:	Trigger framework for the ContentVersion object

History:
<Date			<Authors Name		<Brief Description of Change>
05/8/2018		Dave Mansell		Initial Creation (US-0004058)
------------------------------------------------------------*/
trigger ContentVersionTrigger on ContentVersion (after delete,
												 after insert,
												 after undelete,
												 after update,
												 before delete,
												 before insert,
												 before update) {
														   	
	private static Boolean isActive = GlobalUtility.isTriggerActive('ContentVersionTrigger');
	
	if(isActive){
		if (Trigger.isBefore) {
			if (Trigger.isInsert) {}
			if (Trigger.isUpdate) {}
			if (Trigger.isDelete) {}
		}
	
		if (Trigger.isAfter) {
			if (Trigger.isInsert) {
				ContentVersionTriggerActions.updateParentIfCase(trigger.new);
			}
			if (Trigger.isUpdate) {
				ContentVersionTriggerActions.updateParentIfCase(trigger.new, trigger.oldMap);
			}
			if (Trigger.isDelete) {}
			if (Trigger.isUndelete) {}
		}
	}
}