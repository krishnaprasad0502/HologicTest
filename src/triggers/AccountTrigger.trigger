/*------------------------------------------------------------
  Author:         Denise Bacher
  Company:        Salesforce.com
  Description:    Trigger framework for the Account object
  Test Class:     AccountTrigger_Test
  <EOF>
  History:
  <Date>          <Authors Name>      <Brief Description of Change>
  04/08/2016      Denise Bacher       Initial Creation (US538)
  03/06/2019      Mani Sundaresan     International Territory Management (US6875)
  ------------------------------------------------------------*/
trigger AccountTrigger on Account(after delete, after insert, after undelete, after update, before delete, before insert, before update) {
    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            AccountTriggerActions.splitStreetFields((List<Account>) Trigger.new);
        }
        if (Trigger.isUpdate) {
            AccountTriggerActions.splitStreetFields((List<Account>) Trigger.new);
        }
        if (Trigger.isDelete) { }
        if (Trigger.isUndelete) { }
    }

    if (Trigger.isAfter) {
        if (Trigger.isInsert) { 
            AccountTriggerActions.internationalTerritoryAssignments(Trigger.new, null);
        }
        if (Trigger.isUpdate) { 
            AccountTriggerActions.checkToCreateInitiatingTasks(Trigger.new, Trigger.oldMap);
            AccountTriggerActions.internationalTerritoryAssignments(Trigger.new, Trigger.oldMap);
        }
        if (Trigger.isDelete) { }
        if (Trigger.isUndelete) { }
    }
}