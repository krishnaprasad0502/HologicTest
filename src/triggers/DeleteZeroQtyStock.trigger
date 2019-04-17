/*------------------------------------------------------------
Author:     Mani Sundaresan
Description:  Trigger to delete Location Stock records when Quantity=0
Test Class:   Test_DeleteZeroQtyStock

History:
<Date>      <Authors Name>    <Brief Description of Change>
11/02/2016   Mani Sundaresan    Initial Creation
------------------------------------------------------------*/
trigger DeleteZeroQtyStock on FSO__LocationStock__c (before insert, before update, after insert, after update) {

    Boolean isActive=false;
    isActive=[SELECT Name, Active__c FROM Trigger_Switch__C WHERE Name = 'DeleteZeroQtyStock'].Active__c; 
    
        if(Trigger.isBefore && isActive){
            if(Trigger.isInsert){
            }
            if(Trigger.isUpdate){
            }
        }
        if(Trigger.isAfter && isActive){
            if(Trigger.isInsert){
                LocationStockTriggerActions.deleteLocationStock((List<FSO__LocationStock__c>) Trigger.new);
            }
            if(Trigger.isUpdate){
                LocationStockTriggerActions.deleteLocationStock((List<FSO__LocationStock__c>) Trigger.new);
            }
        } 
 }