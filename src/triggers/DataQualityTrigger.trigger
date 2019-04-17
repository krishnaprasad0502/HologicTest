/*------------------------------------------------------------
Author:			Denise Bacher
Company:		Salesforce.com
Description:	Trigger framework for the Data_Quality__c object
Test Class:		DataQualityTrigger_Test

History:
<Date>			<Authors Name>		<Brief Description of Change>
05/25/2016		Denise Bacher		Initial Creation (US1070)
------------------------------------------------------------*/
trigger DataQualityTrigger on Data_Quality__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) {
	if (Trigger.isBefore) {
		if (Trigger.isInsert) {}
		if (Trigger.isUpdate) {
			DataQualityTriggerActions.autoGenerateNewSiteLocation((List<Data_Quality__c>)Trigger.new, Trigger.oldMap);
		}
		if (Trigger.isDelete) {}
		if (Trigger.isUndelete) {}
	}

	if (Trigger.isAfter) {
		if (Trigger.isInsert) {}
		if (Trigger.isUpdate) {}
		if (Trigger.isDelete) {}
		if (Trigger.isUndelete) {}
	}
}