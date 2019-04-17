/*------------------------------------------------------------
Author:          Mani Sundaresan
Company:         Hologic 
Description:     Pipeline Product Trigger
Class Name:      PipelineProductTriggerActions
Trigger:         PipelineProductTrigger
Test Class:      PipelineProductTriggerActions_Test
History:
<Date>           <Authors Name>      <Brief Description of Change>
01/24/2019       Mani Sundaresan      Initial Creation ()
------------------------------------------------------------*/
trigger PipelineProductTrigger on Pipeline_Products__c (before insert, before update, before delete, after insert, after update, after delete) {

    private static Boolean PipelineProductTrigger = GlobalUtility.isTriggerActive('PipelineProductTrigger');
    
    if(trigger.isbefore && PipelineProductTrigger){
        if(trigger.isinsert){}
        if(trigger.isupdate){}
        if(trigger.isDelete){}
    }
    if(trigger.isafter && PipelineProductTrigger){
        if(trigger.isInsert){
            PipelineProductTriggerActions.calcAmount(trigger.new, null);
        }
        if(trigger.isUpdate){
            PipelineProductTriggerActions.calcAmount(trigger.new, Trigger.oldMap);
        }
        if(trigger.isDelete){
            PipelineProductTriggerActions.calcAmount(null, Trigger.oldMap);
        }
    }
      
}