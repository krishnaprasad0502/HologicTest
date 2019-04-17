/*------------------------------------------------------------
Author          Dave Mansell
Company:        Salesforce.com
Description:    Trigger framework for the WorkOrderLineItem object

History:
<Date           <Authors Name>      <Brief Description of Change>
03/19/2018      Dave Mansell        Initial Creation (US-0004035)
12/20/2018      Kasmoor Reddy       To make unit price as zero based on contions
------------------------------------------------------------*/
trigger WorkOrderLineItemTrigger on WorkOrderLineItem (after delete,
                                                       after insert,
                                                       after undelete,
                                                       after update,
                                                       before delete,
                                                       before insert,
                                                       before update) {
    											 	
	private static Boolean isActive = GlobalUtility.isTriggerActive('WorkOrderLineItemTrigger');
	if(isActive){
		if (Trigger.isBefore) {
	        if (Trigger.isInsert) {
	            WorkOrderLineItemTriggerActions.performCustomValidations(trigger.new);
	            WorkOrderLineItemTriggerActions.setQuantity(trigger.new);
	            WorkOrderLineItemTriggerActions.setPriceBookEntryAndListPrice(trigger.new);
	            WorkOrderLineItemTriggerActions.linkEntitlementsAndSetUnitPricing(trigger.new);
                 //12/20/2018      Kasmoor Reddy       To make unit price as zero based on contions
                 WorkOrderLineItemTriggerActions.changeUnitPrice(trigger.new);
	        }
	        if (Trigger.isUpdate) {
	            WorkOrderLineItemTriggerActions.performCustomValidations(trigger.new);
	            WorkOrderLineItemTriggerActions.checkForNewAsset(trigger.new, trigger.oldMap);
	        }
	        if (Trigger.isDelete) {}
	    }
	
	    if (Trigger.isAfter) {
	        if (Trigger.isInsert) {}
	        if (Trigger.isUpdate) {
	            WorkOrderLineItemTriggerActions.checkForCancelledStatus(trigger.new);
	        }
	        if (Trigger.isDelete) {}
	        if (Trigger.isUndelete) {}
	    }
	}
}