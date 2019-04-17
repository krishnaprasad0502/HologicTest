/*------------------------------------------------------------
  Author:       John Christy
  Company:      Apps Associates  
  Description:  Trigger framework for Agreed_Price__c object
  History:
  <Date>      <Authors Name>    <Brief Description of Change>
  09/13/2018  John Christy       Initial Creation
  ------------------------------------------------------------*/
trigger AgreedPriceTrigger on Agreed_Price__c(before insert, before update, before delete, after insert, after update) {

    if (Trigger.isBefore && GlobalUtility.isTriggerActive('AgreedPriceTrigger')) {
        if (Trigger.isInsert) { }
        if (Trigger.isUpdate) { }
        if (Trigger.isDelete) {
            ContractAgreedPriceTriggerActions.updateContractAgreedPrice(Trigger.newMap, Trigger.oldMap);
        }
    }
    if (Trigger.isAfter && GlobalUtility.isTriggerActive('AgreedPriceTrigger')) {
        if (Trigger.isInsert || Trigger.isUpdate) {
            if (GlobalUtility.runOnce()) {
                ContractAgreedPriceTriggerActions.updateContractAgreedPrice(Trigger.newMap, Trigger.oldMap);
            }
        }
        if (Trigger.isDelete) { }
    }
}