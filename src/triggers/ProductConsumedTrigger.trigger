/*------------------------------------------------------------
Author			Dave Mansell
Company:		Salesforce.com
Description:	Trigger framework for the ProductConsumed object

History:
<Date			<Authors Name		<Brief Description of Change>
03/20/201		Dave Mansell		Initial Creation (US-0004035)
12/20/2018      Kasmoor Reddy       To make unit price as zero based on contions
------------------------------------------------------------*/
trigger ProductConsumedTrigger on ProductConsumed (after delete,
													   after insert,
													   after undelete,
													   after update,
													   before delete,
													   before insert,
													   before update) {
											 	
	private static Boolean isActive = GlobalUtility.isTriggerActive('ProductConsumedTrigger');
	
	if(isActive){
		if (Trigger.isBefore) {
			if (Trigger.isInsert) {
	            ProductConsumedTriggerActions.performCustomValidations(trigger.new);
				ProductConsumedTriggerActions.updateReturnFields(trigger.new);
				ProductConsumedTriggerActions.linkEntitlements(trigger.new);
                //12/20/2018      Kasmoor Reddy       To make unit price as zero based on contions
                ProductConsumedTriggerActions.changeUnitPrice(trigger.new);
                
			}
			if (Trigger.isUpdate) {
	            ProductConsumedTriggerActions.performCustomValidations(trigger.new);
	            ProductConsumedTriggerActions.checkForUnitPriceChange(trigger.new, trigger.oldMap);
			}
			if (Trigger.isDelete) {}
		}
	
		if (Trigger.isAfter) {
			if (Trigger.isInsert) {
				ProductConsumedTriggerActions.updateAssetFields(trigger.new);
			}
			if (Trigger.isUpdate) {
				ProductConsumedTriggerActions.checkForDelete(trigger.new);
			}
			if (Trigger.isDelete) {}
			if (Trigger.isUndelete) {}
		}
	}
}