/*------------------------------------------------------------
Author:         Krishna Prasad
Company:        Apps Associates
Description:   Trigger framework for the Email Communication object
Test Class:    Emailcommunication_Test

History:
<Date>        <Authors Name>    <Brief Description of Change>
20/1/2018       KRISHNA PRASAD          Initial Creation(US-0003622)

------------------------------------------------------------*/
trigger EmailCommunicationTrigger on Email_Communication__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) {
    
    
    private static Trigger_Switch__c EmailCommunicationTriggerSwitch = Trigger_Switch__c.getValues('EmailCommunicationTrigger');
    private static Boolean runCaseFeature = EmailCommunicationTriggerSwitch.Active__c;
    
    
    if (Trigger.isBefore && runCaseFeature) {
        if (Trigger.isInsert) {
            
           
        }
        if (Trigger.isUpdate) {
           
            EmailCommunicationTriggerActions.deleteActivity(Trigger.new, Trigger.oldMap);
            EmailCommunicationTriggerActions.createTaskEm(Trigger.new, Trigger.oldMap);
            EmailCommunicationTriggerActions.insertAttacments(Trigger.new, Trigger.oldMap);
            
            
            
           
        }
        if (Trigger.isDelete) {}
        if (Trigger.isUndelete) {}
    }
    
    if (Trigger.isAfter && runCaseFeature) {
        if (Trigger.isInsert) {}
        if (Trigger.isUpdate) {}
        if (Trigger.isDelete) {}
        if (Trigger.isUndelete) {}
    }
}