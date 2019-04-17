/*------------------------------------------------------------
Author          Dave Mansell
Company:        Salesforce.com
Description:    Trigger framework for the ContentDocumentLink object

History:
<Date           <Authors Name       <Brief Description of Change>
05/8/2018       Dave Mansell        Initial Creation (US-0004058)
------------------------------------------------------------*/
trigger ContentDocumentLinkTrigger on ContentDocumentLink (after delete,
                                                           after insert,
                                                           after undelete,
                                                           after update,
                                                           before delete,
                                                           before insert,
                                                           before update) {
                                                            
    private static Boolean isActive = GlobalUtility.isTriggerActive('ContentDocumentLinkTrigger');
    
    if(isActive){
        if (Trigger.isBefore) {
            if (Trigger.isInsert) {}
            if (Trigger.isUpdate) {}
            if (Trigger.isDelete) {}
        }
    
        if (Trigger.isAfter) {
            if (Trigger.isInsert) {
                ContentDocumentLinkTriggerActions.updateParentIfCase(Trigger.new);
                ContentDocumentLinkTriggerActions.checkToSendFSREmails(Trigger.new);
            }
            if (Trigger.isUpdate) {}
            if (Trigger.isDelete) {}
            if (Trigger.isUndelete) {}
        }
    }
}