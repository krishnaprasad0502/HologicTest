/*------------------------------------------------------------
Author:         Denise Bacher
Company:        Salesforce.com
Description:    Trigger framework for the ContractLineItem object
Test Class:     ContractLineItemTrigger_Test

History:
<Date>          <Authors Name>      <Brief Description of Change>
07/25/2016      Denise Bacher       Initial Creation (US54)
07/29/2016      Denise Bacher       Add createEntitlements (US164)
08/03/2016      Matt Yogi           Updated code to invoke updateAsset on before insert
08/08/2016      Denise Bacher       Added setServiceContractApprovalStatus (US1444)
10/28/2016      Denise Bacher       Added setServiceType (US-0001108)
10/08/2018      Dave Mansell        Refactored all code
------------------------------------------------------------*/
trigger ContractLineItemTrigger on ContractLineItem (after delete, after insert, after undelete, after update, before delete, before insert, before update) {
    
    private static Boolean isActive = GlobalUtility.isTriggerActive('ContractLineItemTrigger');
    
    if(isActive){
        if (Trigger.isBefore) {
            if (Trigger.isInsert) {
                ContractLineItemTriggerActions.setServiceType(trigger.new);
                ContractLineItemTriggerActions.updateAsset(trigger.new);
            }
            if (Trigger.isUpdate) {}
            if (Trigger.isDelete) {}
            if (Trigger.isUndelete) {}
        }
    
        if (Trigger.isAfter) {
            if (Trigger.isInsert) {
                ContractLineItemTriggerActions.checkToUpdateParentAssets(trigger.new);
                ContractLineItemTriggerActions.createEntitlements(trigger.new);
                ContractLineItemTriggerActions.setServiceContractApprovalStatus(trigger.new);
            }
            if (Trigger.isUpdate) {
                ContractLineItemTriggerActions.checkToUpdateParentAssets(trigger.new, trigger.oldMap);
                ContractLineItemTriggerActions.terminateEntitlementAndPMPlans(trigger.new, trigger.oldMap);
            }
            if (Trigger.isDelete) {}
            if (Trigger.isUndelete) {}
        }
    }
}