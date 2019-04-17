/*------------------------------------------------------------
Author:         Tayo Chestnut
Description:    Trigger framework for ServiceContract object
Test Class:     ServiceContractTrigger_Test

History:
<Date>      <Authors Name>    <Brief Description of Change>
02/17/2018   Tayo Chesnut      Initial Creation(US-0003737)
05/23/2018   Ronald Mendoza    Updated Trigger to only run once to avoid duplicate records
07/18/2018   Mani Sundaresan   Updated Trigger to update payment records when Serivce contracts are created from Quote.
10/03/2018   Dave Mansell      Rework of previous code
------------------------------------------------------------*/
trigger ServiceContractTrigger on ServiceContract (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    
    private static Boolean isActive = GlobalUtility.isTriggerActive('ServiceContractTrigger');
    
    if(isActive){
        if(Trigger.isBefore) {
            if(Trigger.isInsert){}
            if(Trigger.isUpdate){}
            if(Trigger.isDelete){}
        }
        if(Trigger.isAfter){ 
             if(Trigger.isInsert){
                 ServiceContractTriggerHandler.updatePayments(Trigger.new);
             }
             if(Trigger.isUpdate){
                //if (GlobalUtility.runOnceOnAfter()) {
                    ServiceContractTriggerHandler.checkToCreateContracts(Trigger.new, Trigger.oldMap);
                //}
             }
             if(Trigger.isdelete){}
         }
    }
}