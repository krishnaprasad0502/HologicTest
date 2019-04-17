/*------------------------------------------------------------
Author:         Kasmoor Reddy
Company:        Apps Associates
Description:    Trigger framework for the Contact object
Test Class:     ContactTrigger_Test

History:
<Date>          <Authors Name>      <Brief Description of Change>
12/05/2018       Kasmoor Reddy            Initial Creation <US6207>
------------------------------------------------------------*/
trigger ContactTrigger on Contact (before insert, before update) {
private static Boolean isActive = GlobalUtility.isTriggerActive('ContactTrigger');
    system.debug('ContactTriggerStatus'+isActive);
    if(isActive){
        system.debug('ContactTriggerStatus'+isActive);

        if(Trigger.isBefore){
            if(Trigger.isInsert){
                ContactTriggerActions.capitalizeContactName(trigger.new,null);
            }
            if(Trigger.isUpdate){
                ContactTriggerActions.capitalizeContactName(trigger.new, trigger.oldMap);
            }
            
            
            
        }

}
}