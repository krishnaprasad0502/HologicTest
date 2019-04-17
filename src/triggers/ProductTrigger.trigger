/*------------------------------------------------------------
Author:			Marc Goldstein
Company:		Salesforce.com
Description:	Trigger framework for the Product2 object
Test Class:		ProductTrigger_Test

History:
<Date>			<Authors Name>		<Brief Description of Change>
06/14/2016		Marc Goldstein		Initial Creation (US1315)
08/09/2016		Marc Goldstein		Added default warranty coverage(US1445)
------------------------------------------------------------*/
trigger ProductTrigger on Product2 (after delete, after insert, after undelete, after update, before delete, before insert, before update) {
	if (Trigger.isBefore) {
		if (Trigger.isInsert) {
			ProductTriggerActions.setDefaultWarrantyCoverage((List<Product2>)Trigger.new);				
		}
		if (Trigger.isUpdate) {
			ProductTriggerActions.setDefaultWarrantyCoverage((List<Product2>)Trigger.new);
		}
		if (Trigger.isDelete) {}
		if (Trigger.isUndelete) {}
	}

	if (Trigger.isAfter) {
		if (Trigger.isInsert) {
			ProductTriggerActions.createStandardPriceBookEntries((List<Product2>)Trigger.new);
		}
		if (Trigger.isUpdate) {}
		if (Trigger.isDelete) {}
		if (Trigger.isUndelete) {}
	}
}