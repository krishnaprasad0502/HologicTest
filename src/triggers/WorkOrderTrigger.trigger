/*------------------------------------------------------------
Author          Dave Mansell
Company:        Salesforce.com
Description:    Trigger framework for the WorkOrder object

History:
<Date           <Authors Name       <Brief Description of Change>
04/09/2018      Dave Mansell        Initial Creation (US-0004278)
------------------------------------------------------------*/
trigger WorkOrderTrigger on WorkOrder (after delete,
                                       after insert,
                                       after undelete,
                                       after update,
                                       before delete,
                                       before insert,
                                       before update) {
                                                    
    private static Boolean isActive = GlobalUtility.isTriggerActive('WorkOrderTrigger');
    
    if(isActive){
        if (Trigger.isBefore) {
            if (Trigger.isInsert) {
                WorkOrderTriggerActions.setAddress(trigger.new);
                WorkOrderTriggerActions.checkForWSTCapitalWorkOrder(trigger.new);
                WorkOrderTriggerActions.linkEntitlements(trigger.new);
                WorkOrderTriggerActions.checkForPricingAgreement(trigger.new);
                WorkOrderTriggerActions.setServiceContract(trigger.new);
            }
            if (Trigger.isUpdate) {
                WorkOrderTriggerActions.checkForWSTCapitalWorkOrder(trigger.new, trigger.oldMap);
                WorkOrderTriggerActions.updateDelegates(trigger.new, trigger.oldMap);
                WorkOrderTriggerActions.checkToSetServiceContract(trigger.new, trigger.oldMap);
            }
            if (Trigger.isDelete) {}
        }
    
        if (Trigger.isAfter) {
            if (Trigger.isInsert) {
                WorkOrderTriggerActions.setOwnership(trigger.new);
                WorkOrderTriggerActions.createResourcePreferences(trigger.new);
                WorkOrderTriggerActions.checkToAssignServiceTerritory(trigger.new);
                WorkOrderTriggerActions.checkToUpdateParentCases(trigger.new);
                WorkOrderTriggerActions.checkToUpdateParentCaseSummaries(trigger.new);
            }
            if (Trigger.isUpdate) {
                WorkOrderTriggerActions.checkToSetOwnership(trigger.new, trigger.oldMap);
                WorkOrderTriggerActions.checkToAssignServiceTerritory(trigger.new, trigger.oldMap);
                WorkOrderTriggerActions.checkForClosedStatus(trigger.new, trigger.oldMap);
                WorkOrderTriggerActions.checkToUpdateSAStatus(trigger.new, trigger.oldMap);
                WorkOrderTriggerActions.checkToUpdateAssets(trigger.new, trigger.oldMap);
                WorkOrderTriggerActions.checkToUpdateParentCaseSummaries(trigger.new, trigger.oldMap);
                //
                  if (GlobalUtility.runOnce()) {
                    WorkOrderTriggerActionsExtension.UpdateWorkOrderDetails(trigger.new,trigger.oldMap);
                }
            }
            if (Trigger.isDelete) {}
            if (Trigger.isUndelete) {}
        }
    }
}