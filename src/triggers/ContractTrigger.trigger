/*------------------------------------------------------------
  Author:  Ronald Mendoza
  Company: Salesforce  
  Description:  Trigger framework for Contract object
  Test Class:   Test_GenerateRenewalContract 
  <EOF>
  History:
  <Date>      <Authors Name>    <Brief Description of Change>
  11/04/2016  Ronald Mendoza     Initial Creation
  02/27/2017  Sheetal Rathod     Moved the code from trigger into a class to resolve optimization issue
  08/20/2018  John Christy       Added updateContractAgreedPrice
  01/29/2019  John Christy       Wrapped all trigger calls around recursive check runOnce()
 
  ------------------------------------------------------------*/
trigger ContractTrigger on Contract(before insert, before update, before delete, after insert, after update) {

    if (Trigger.isBefore && GlobalUtility.isTriggerActive('ContractTrigger')) {
        if (Trigger.isInsert) { }

        if (Trigger.isUpdate) {
            ContractTriggerActions.validateTierValue((List<Contract>) Trigger.new, Trigger.oldMap);
            ContractTriggerActions.updateAmendedContract((List<Contract>) Trigger.new);
            if (GlobalUtility.runOnce()) {
                ContractTriggerActions.childRecUpdate((List<Contract>) Trigger.new, Trigger.oldMap);
                ContractAgreedPriceTriggerActions.updateContractAgreedPrice(Trigger.newMap, Trigger.oldMap);
            }
        }
        if (Trigger.isDelete) { }
    }
    if (Trigger.isAfter && GlobalUtility.isTriggerActive('ContractTrigger')) {
        if (Trigger.isInsert) { }
        if (Trigger.isUpdate) { }
        if (Trigger.isDelete) { }
    }
}