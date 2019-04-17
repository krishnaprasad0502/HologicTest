/*------------------------------------------------------------
Author          Dave Mansell
Company:        Salesforce.com
Description:    Trigger framework for the DemoRequest object

History:
<Date           <Authors Name>      <Brief Description of Change>
05/22/2018      Dave Mansell        Initial Creation (US-0004234)
------------------------------------------------------------*/
trigger DemoRequestTrigger on Demo_Request__c (after delete,
                                               after insert,
                                               after undelete,
                                               after update,
                                               before delete,
                                               before insert,
                                               before update) {
    											 	
	private static Boolean isActive = GlobalUtility.isTriggerActive('DemoRequestTrigger');
	
	if(isActive){
		if (Trigger.isBefore) {
	        if (Trigger.isInsert) {
	            DemoRequestTriggerActions.setDestinationAddress(trigger.new);
	        }
	        if (Trigger.isUpdate) {}
	        if (Trigger.isDelete) {}
	    }
	
	    if (Trigger.isAfter) {
	        if (Trigger.isInsert) {}
	        if (Trigger.isUpdate) {
	            DemoRequestTriggerActions.checkForApproval(trigger.newMap, trigger.oldMap);
	        }
	        if (Trigger.isDelete) {}
	        if (Trigger.isUndelete) {}
	    }
	}
}