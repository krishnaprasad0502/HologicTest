/*------------------------------------------------------------
Author:         Ryan Lambert
Company:        Salesforce.com
Description:    ProductTransfer Trigger
Test Class:     ProductTransferTriggerActions_Test

History:
<Date>          <Authors Name>      <Brief Description of Change>
05/09/2018      Ryan Lambert        Initial Creation (FSL OOTB Workaround)
------------------------------------------------------------*/
trigger ProductTransferTrigger on ProductTransfer (after delete, after insert, after undelete, after update, before delete, before insert, before update) {

    private static Boolean runSerializedProductTransferLogic = GlobalUtility.isTriggerActive('ProductTransfer');
    
    if (Trigger.isBefore && runSerializedProductTransferLogic) {
        if (Trigger.isInsert || Trigger.isUpdate) {
            ProductTransferTriggerActions.preserveSerialAndLotNumbers(Trigger.new);
        }
    }

    if (Trigger.isAfter && runSerializedProductTransferLogic) {
        if (Trigger.isInsert || Trigger.isUpdate) {
            ProductTransferTriggerActions.restoreSerialAndLotNumbersRefactored(Trigger.new);                        
        }
    }
}