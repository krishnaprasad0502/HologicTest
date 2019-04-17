/*------------------------------------------------------------
Author:         Yael Perez
Company:        Salesforce.com
Description:    Trigger framework for the Task object
Test Class:     TaskTrigger_Test

History:
<Date>          <Authors Name>      <Brief Description of Change>
08/04/2016      Yael Perez          Initial Creation <US1443>
10/26/2017      Kasmoor Reddy       Method to create procedure from activities <US3490>
01/16/2018      Mani Sundaresan     Method to update Task Description field on Case when Task is created/updated (HD-8082)
03/14/2018      Raviraj Reddy       AMPS Marketing process (US3819)
10/22/2018      Dave Mansell        Refactored all code
------------------------------------------------------------*/
trigger TaskTrigger on Task (before insert, before update, before delete, after insert, after update, after delete) {
    
    private static Boolean isActive = GlobalUtility.isTriggerActive('TaskTrigger');
    system.debug('TaskTriggerStatus'+isActive);
    if(isActive){
        system.debug('TaskTriggerStatus'+isActive);

        if(Trigger.isBefore){
            if(Trigger.isInsert){
                TaskTriggerActions.checkForComplaintTasks(trigger.new);
            }
            if(Trigger.isUpdate){
                TaskTriggerActions.preventEditOfComplaintTasks(trigger.new, trigger.oldMap);
            }
            if(Trigger.isDelete){
                 TaskTriggerActions.preventDeletionOfComplaintTasks(trigger.old);   
            }
            if(Trigger.isUndelete){}
            
        }
        if(Trigger.isAfter){
            if(Trigger.isInsert){
                ActivityHelper.createProcedureFromActivity(trigger.new);
                TaskTriggerActions.updateTaskDescriptionOnCase(Trigger.new);
            }
            
            //Added by Raviraj To trigger Tasks through AMPS_Activity_Flow_Helper 
            if(Trigger.isUpdate){
                AMPS_Activity_Flow_Helper flowHelper = new AMPS_Activity_Flow_Helper(Trigger.oldMap,Trigger.newMap); 
                flowHelper.createActivities();
            }
        }
    }
}






/*------------------------------------------------------------
Author:         Yael Perez
Company:        Salesforce.com
Description:    Trigger framework for the Task object
Test Class:     TaskTrigger_Test

History:
<Date>          <Authors Name>      <Brief Description of Change>
08/04/2016      Yael Perez          Initial Creation <US1443>
10/26/2017      Kasmoor Reddy       Method to create procedure from activities <US3490>
01/16/2018      Mani Sundaresan     Method to update Task Description field on Case when Task is created/updated (HD-8082)
03/14/2018      Raviraj Reddy       AMPS Marketing process (US3819)
------------------------------------------------------------*/
/*trigger TaskTrigger on Task (before insert, before update, before delete, after insert, after update) {
    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            TaskTriggerActions.checkForComplaintTasks(Trigger.new, null);
            TaskTriggerActions.checkForUncompletedComplaintTasks(Trigger.new);
            TaskTriggerActions.preventAddingNotetoClosedCase(Trigger.new);
           
        }
        if (Trigger.isUpdate) {
            TaskTriggerActions.preventEditOfComplaintTasks(Trigger.new, Trigger.oldMap);
            
        }
        if (Trigger.isDelete) {
             TaskTriggerActions.preventDeletionOfComplaintTasks(Trigger.old);   
        }
        if (Trigger.isUndelete) {}
        
    }
    if(Trigger.isAfter){
            if (Trigger.isInsert) {
                if (GlobalUtility.runOnceOnAfter()) {
                  ActivityTriggerActions.createProcedureFromActivity(Trigger.new);
                  
                }
                TaskTriggerActions.updateTaskDescriptionOnCase(Trigger.new);
            }
            
            //Added by Raviraj To trigger Tasks through AMPS_Activity_Flow_Helper 
            if(Trigger.isUpdate){
                AMPS_Activity_Flow_Helper flowHelper = new AMPS_Activity_Flow_Helper(Trigger.oldMap,Trigger.newMap); 
                flowHelper.createActivities();
            }
        }
}*/