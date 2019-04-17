/*------------------------------------------------------------
Author			Dave Mansell
Company:		Salesforce.com
Description:	Trigger framework for the ProductRequest object

History:
<Date			<Authors Name>		<Brief Description of Change>
04/26/2018		Dave Mansell		Initial Creation (US-0004070)
02/07/2019      Kasmoor Reddy       Update Service Resource field in Product Request (US-0006381)
------------------------------------------------------------*/
trigger ProductRequestTrigger on ProductRequest (before insert,
												 before update,
												 before delete,
												 after insert,
												 after update,
												 after delete,
												 after undelete) {
											 	
	private static Boolean isActive = GlobalUtility.isTriggerActive('ProductRequestTrigger');
	
	if(isActive){
		if (Trigger.isBefore) {
			if (Trigger.isInsert) {
				ProductRequestTriggerActions.setFieldValues(trigger.new);
                //Updated to assign Service Resource field if not null in Product Request (US-0006381) by Kasmoor Reddy on 02/07/2019
                ProductRequestTriggerActions.UpdateServiceResourceField(trigger.new,null);
                
			}
			if (Trigger.isUpdate) {
				ProductRequestTriggerActions.setFieldValues(trigger.new);
				ProductRequestTriggerActions.checkToClearDestinationAddress(trigger.new, trigger.oldMap);
                //Updated to assign Service Resource field if not null in Product Request (US-0006381) by Kasmoor Reddy on 02/07/2019
                 ProductRequestTriggerActions.UpdateServiceResourceField(trigger.new, trigger.oldMap);
			}
			if (Trigger.isDelete) {}
		}
	
		if (Trigger.isAfter) {
			if (Trigger.isInsert) {
				ProductRequestTriggerActions.createNewAddress(trigger.new);
			}
			if (Trigger.isUpdate) {}
			if (Trigger.isDelete) {}
			if (Trigger.isUndelete) {}
		}
	}
}