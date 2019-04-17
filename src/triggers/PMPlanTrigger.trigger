/*------------------------------------------------------------
Author:         Raj Sharan
Company:        AppsAssociates
Description:    Trigger framework for the PM Plan object
Test Class:     PMPlanTrigger_Test

History:
<Date>          <Authors Name>      <Brief Description of Change>
02/06/2017      Raj Sharan            Initial Creation ()
------------------------------------------------------------*/
trigger PMPlanTrigger on FSO__PreventiveMaintenancePlan__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) {

//private static Trigger_Switch__c pmpSwitch = Trigger_Switch__c.getValues('PMPlans');
//private static Boolean runFeature = pmpSwitch.Active__c;
  private static Boolean runFeature = GlobalUtility.isTriggerActive('PMPlans');

    if (Trigger.isBefore) {

        if (Trigger.isUpdate) {

        if (runFeature) PMPlanTriggerActions.assessPMPlan(Trigger.new, Trigger.oldMap);
           
        }

    }
 
}