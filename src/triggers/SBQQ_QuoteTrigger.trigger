/*------------------------------------------------------------
Author:     Kasmoor Reddy
Description:  Trigger framework for SBQQ__Quote__c object
Test Class:    SBQQ_QuoteTrigger_Test

History:
<Date>      <Authors Name>    <Brief Description of Change>
09/28/2017   Kasmoor Reddy      Initial Creation(US3470)
------------------------------------------------------------*/
trigger SBQQ_QuoteTrigger on SBQQ__Quote__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) {

    if (Trigger.isBefore) {
        if (Trigger.isInsert) {}
        if (Trigger.isUpdate) {}
        if (Trigger.isDelete) {}
        if (Trigger.isUndelete) {}
    }

    if (Trigger.isAfter) {
        if (Trigger.isInsert) {}    
        if(Trigger.isUpdate){
            //if (GlobalUtility.runOnceOnAfter()) {
            SBQQ_QuoteTriggerActions.updatePrimaryQuote((List<SBQQ__Quote__c>) Trigger.New,Trigger.oldMap);
           // }      
        }
        if (Trigger.isDelete) {}
        if (Trigger.isUndelete) {}
    }
}