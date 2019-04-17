/*------------------------------------------------------------
Author: Yogi    
Company:  Salesforce
Description:  Trigger framework for the SBQQ__QuoteLine__c object
Test Class:   QuoteLineTriggerActions_Test

History:
<Date>      <Authors Name>    <Brief Description of Change>
05/11/2017      Yogi           Initial Creation (HD-4290)
------------------------------------------------------------*/
trigger QuoteLineTrigger on SBQQ__QuoteLine__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) {

    if (Trigger.isBefore && GlobalUtility.isTriggerActive('QuoteLineTrigger')) {
        if (Trigger.isInsert) {}
        if (Trigger.isUpdate) {
            //Method to prevent Pricing batch job from getting trigger when certain fields on QL object is updated
            QuoteLineTriggerActions.checkFieldsAndDisableTrigger ((List<SBQQ__QuoteLine__c>)Trigger.old, (List<SBQQ__QuoteLine__c>)Trigger.new);
        }
        if (Trigger.isDelete) {}
        if (Trigger.isUndelete) {}
    }

    if(Trigger.isAfter && GlobalUtility.isTriggerActive('QuoteLineTrigger')) {
        if (Trigger.isInsert) {}
        if (Trigger.isUpdate) {}
        if (Trigger.isDelete) {}
        if (Trigger.isUndelete) {}
    }

}