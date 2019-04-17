/*------------------------------------------------------------
Author          Dave Mansell
Company:        Salesforce.com
Description:    Trigger framework for the Case_Summary__c object

History:
<Date           <Authors Name       <Brief Description of Change>
04/19/2018      Dave Mansell        Initial Creation (US-0004058)
------------------------------------------------------------*/
trigger CaseSummaryTrigger on Case_Summary__c (after delete,
                                               after insert,
                                               after undelete,
                                               after update,
                                               before delete,
                                               before insert,
                                               before update) {

    private static Boolean isActive = GlobalUtility.isTriggerActive('CaseSummaryTrigger');
    
    if(isActive){
        if (Trigger.isBefore) {
            if (Trigger.isInsert) {
                CaseSummaryTriggerActions.updateAgileIntegrationString(Trigger.new);
            }
            if (Trigger.isUpdate) {
                CaseSummaryTriggerActions.createNotesOnCases(Trigger.new, Trigger.oldMap);
                CaseSummaryTriggerActions.updateAgileIntegrationString(Trigger.new);
            }
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