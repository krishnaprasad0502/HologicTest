trigger EntitlementTrigger on Entitlement (
    before insert, 
    before update, 
    before delete, 
    after insert, 
    after update, 
    after delete, 
    after undelete) {

    private static Boolean isActive = GlobalUtility.isTriggerActive('EntitlementTrigger');
    private static Boolean isFirstTime = GlobalUtility.isTriggerActive('EntitlementTriggerFirstTime');
    
    if(isActive){
        if (Trigger.isBefore) {
            //call handler.before method
            if (Trigger.isInsert) {
                
            }
            if (Trigger.isUpdate) {
                
            }

        } else if (Trigger.isAfter) {
            //call handler.after method
            if (Trigger.isInsert) {
                EntitlementTriggerHandler.createMaintenancePlans(trigger.new);
            }
            if (Trigger.isUpdate) {
                if(isFirstTime) {
                    EntitlementTriggerHandler.createMaintenancePlans(trigger.new);    
                }
            }
        }
    }
}