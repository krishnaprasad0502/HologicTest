/*------------------------------------------------------------
Author			Dave Mansell
Company:		Salesforce.com
Description:	Trigger framework for the ProductRequestLineItem object

History:
<Date			<Authors Name>		<Brief Description of Change>
04/26/2018		Dave Mansell		Initial Creation (US-0004070)
------------------------------------------------------------*/
trigger ProductRequestLineItemTrigger on ProductRequestLineItem (before insert,
																 before update,
																 before delete,
																 after insert,
																 after update,
																 after delete,
																 after undelete) {
											 	
	private static Boolean isActive = GlobalUtility.isTriggerActive('ProductRequestLineItemTrigger');
	
	if(isActive){
		if (Trigger.isBefore) {
			if (Trigger.isInsert) {
				ProductRequestLineItemTriggerActions.copyFieldValuesFromParents(trigger.new);
			}
			if (Trigger.isUpdate) {}
			if (Trigger.isDelete) {}
		}
	
		if (Trigger.isAfter) {
			if (Trigger.isInsert) {}
			if (Trigger.isUpdate) {}
			if (Trigger.isDelete) {}
			if (Trigger.isUndelete) {}
		}
	}
}