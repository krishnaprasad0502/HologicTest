/*------------------------------------------------------------
Author          Dave Mansell
Company:        Salesforce.com
Description:    Trigger framework for the EmailMessage object

History:
<Date           <Authors Name       <Brief Description of Change>
05/03/2018      Dave Mansell        Initial Creation (US-0004058)
16/12/2018      Yogitha Malireddy   Added code to call the method to display customer emails in community(US-0006345) 
------------------------------------------------------------*/
trigger EmailMessageTrigger on EmailMessage (after delete,
                                             after insert,
                                             after undelete,
                                             after update,
                                             before delete,
                                             before insert,
                                             before update) {
                                                
    private static Boolean isActive = GlobalUtility.isTriggerActive('EmailMessageTrigger');
    
    if(isActive){
        if (Trigger.isBefore) {
            if (Trigger.isInsert) {}
            if (Trigger.isUpdate) {}
            if (Trigger.isDelete) {}
        }
    
        if (Trigger.isAfter) {
            if (Trigger.isInsert) {
                EmailMessageTriggerActions.createNotesForCaseEmails(Trigger.new);
                EmailMessageTriggerActions.trackCaseEmails(Trigger.new);
            }
            if (Trigger.isUpdate) {}
            if (Trigger.isDelete) {}
            if (Trigger.isUndelete) {}
        }
    }
}