/*------------------------------------------------------------
Author:         Denise Bacher
Company:        Salesforce.com
Description:    Trigger framework for the Case object
Test Class:     CaseTrigger_Test

History:
<Date>          <Authors Name>      <Brief Description of Change>
06/24/2016      Denise Bacher       Initial Creation (US1311)
05/01/2017      Raj Sharan          Update for Logic for Diagnostic and Surigical (US 2505)
12/06/2017      Mani Sundaresan     Validation to prevent cases from being dispatched without Case Efforts (US 3657) 
12/18/2017      Mani Sundaresan     Introduce CalculateBusinessHours logic within the Case Trigger   
------------------------------------------------------------*/
trigger CaseTrigger on Case (after delete, after insert, after undelete, after update, before delete, before insert, before update) {
    
    // 05-01-2017      Raj Sharan          Update for Logic for Diagnostic and Surigical (US 2505)
    //private static Trigger_Switch__c caseTriggerSwitch = Trigger_Switch__c.getValues('CaseTrigger');
    //private static Boolean runCaseFeature = caseTriggerSwitch.Active__c;
    private static Boolean runCaseFeature = GlobalUtility.isTriggerActive('CaseTrigger');
    
    if (Trigger.isBefore && runCaseFeature) {
        if (Trigger.isInsert) {
            // 05-01-2017      Raj Sharan          Update for Logic for Diagnostic and Surigical (US 2505)
            CaseTriggerActions.reviewCases(Trigger.new, null);
            
            //12-18-2017       Mani Sundaresan     Introduced the CaseBusinessHours logic within the Case Trigger
            CaseTriggerActions.calculateBusinessHoursAges_insert(Trigger.new, null);
            
            CaseTriggerActions.checkToAssignServiceTerritory(trigger.new);
        }
        if (Trigger.isUpdate) {
            // 05-01-2017      Raj Sharan          Update for Logic for Diagnostic and Surigical (US 2505)
            CaseTriggerActions.reviewCases(Trigger.new, Trigger.oldMap);
            
            //12-18-2017       Mani Sundaresan     Introduced the CaseBusinessHours logic within the Case Trigger
            CaseTriggerActions.calculateBusinessHoursAges_update(Trigger.new, Trigger.oldMap);
            
            /**12/06/2017 - Validation to prevent cases from being dispatched without case efforts (US 3657) - [Mani Sundaresan]***/
            CaseTriggerActions.validateDispatchedCases(Trigger.new, Trigger.oldMap);
            
            CaseTriggerActions.checkToAssignServiceTerritory(trigger.new);
        }
        if (Trigger.isDelete) {}
        if (Trigger.isUndelete) {}
    }
    
    if (Trigger.isAfter && runCaseFeature) {
        if (Trigger.isInsert) {}
        if (Trigger.isUpdate) {}
        if (Trigger.isDelete) {}
        if (Trigger.isUndelete) {}
    }
}