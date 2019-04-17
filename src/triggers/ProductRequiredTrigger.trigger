/*------------------------------------------------------------
Author			Dave Mansell
Company:		Salesforce.com
Description:	Trigger framework for the ProductRequired object

History:
<Date			<Authors Name		<Brief Description of Change>
04/03/2018		Dave Mansell		Initial Creation (US-0004059)
------------------------------------------------------------*/
trigger ProductRequiredTrigger on ProductRequired (after delete,
												   after insert,
												   after undelete,
												   after update,
												   before delete,
												   before insert,
												   before update) {
											 	
	private static Boolean isActive = GlobalUtility.isTriggerActive('ProductRequiredTrigger');
	
	if(isActive){
		if (Trigger.isBefore) {
			if (Trigger.isInsert) {
				ProductRequiredTriggerActions.setPriceBookEntryAndListPrice(trigger.new);
				ProductRequiredTriggerActions.linkEntitlementsAndSetUnitPricing(trigger.new);
			}
			if (Trigger.isUpdate) {}
			if (Trigger.isDelete) {}
		}
	
		if (Trigger.isAfter) {
			if (Trigger.isInsert) {
				ProductRequiredTriggerActions.updateParentWorkOrders(trigger.new);
			}
			if (Trigger.isUpdate) {
				ProductRequiredTriggerActions.checkToUpdateParentWorkOrders(trigger.new, trigger.oldMap);
				ProductRequiredTriggerActions.checkForDelete(trigger.new);
			}
			if (Trigger.isDelete) {
				ProductRequiredTriggerActions.updateParentWorkOrders(trigger.old);
			}
			if (Trigger.isUndelete) {}
		}
	}
}