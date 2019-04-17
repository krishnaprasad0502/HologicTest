/*------------------------------------------------------------
Author:         Marc Goldstein
Company:        Salesforce.com
Description:    Trigger framework for the Order object
Test Class:     OrderTrigger_Test

History:
<Date>          <Authors Name>      <Brief Description of Change>
08/09/2016      Marc Goldstein      Initial Creation (INT21)
11/08/2016      Denise Bacher       Added updateRelatedCase (US-0001169)
10/19/2018		Dave Mansell		Refactored code
------------------------------------------------------------*/
trigger OrderTrigger on Order (after delete, after insert, after undelete, after update, before delete, before insert, before update) {
                                                    
    private static Boolean isActive = GlobalUtility.isTriggerActive('OrderTrigger');
    
    if(isActive){
        if(Trigger.isBefore){
            if(Trigger.isInsert){}
            if(Trigger.isUpdate){}
            if(Trigger.isDelete){}
            if(Trigger.isUndelete){}
        }
    
        if(Trigger.isAfter){
            if(Trigger.isInsert){
                OrderTriggerActions.updateRelatedCases(trigger.new);
                OrderTriggerActions.createQuoteServiceOrderLineItems(trigger.new);
                OrderTriggerActions.setSunshineCompliantOnAccount(trigger.new);
            }
            if(Trigger.isUpdate){
                OrderTriggerActions.checkToUpdateRelatedCases(trigger.new, trigger.oldMap);
                OrderTriggerActions.updateRelatedAssets(trigger.new, trigger.oldMap);
                OrderTriggerActions.createWorkOrders(trigger.new, trigger.oldMap);
                OrderTriggerActions.checkToSetSunshineCompliantOnAccount(trigger.new, trigger.oldMap);
            }
            if(Trigger.isDelete){}
            if(Trigger.isUndelete){}
        }
    }
}





/*------------------------------------------------------------
Author:         Marc Goldstein
Company:        Salesforce.com
Description:    Trigger framework for the Order object
Test Class:     OrderTrigger_Test

History:
<Date>          <Authors Name>      <Brief Description of Change>
08/09/2016      Marc Goldstein      Initial Creation (INT21)
11/08/2016      Denise Bacher       Added updateRelatedCase (US-0001169)
------------------------------------------------------------*/
/*trigger OrderTrigger on Order (after delete, after insert, after undelete, after update, before delete, before insert, before update) {
                                                    
    private static Boolean isActive = GlobalUtility.isTriggerActive('OrderTrigger');
    
    if(isActive){
        if (Trigger.isBefore) {
            if (Trigger.isInsert) {}
            if (Trigger.isUpdate) {}
            if (Trigger.isDelete) {}
            if (Trigger.isUndelete) {}
        }
    
        if (Trigger.isAfter) {
            if (Trigger.isInsert) {
                OrderTriggerActions.updateRelatedCase((List<Order>)Trigger.new, null);
                OrderTriggerActions.createQuoteServiceOrderLineItems((List<Order>)Trigger.new);
            }
            if (Trigger.isUpdate) {
                OrderTriggerActions.updateRelatedCase((List<Order>)Trigger.new, Trigger.oldMap);
                OrderTriggerActions.updateRelatedAssets(trigger.new, trigger.oldMap);
                OrderTriggerActions.createWorkOrders(trigger.new, trigger.oldMap);
                OrderTriggerActions.setSunshineCompliantOnAccount((List<Order>)Trigger.new, Trigger.oldMap);
            }
            if (Trigger.isDelete) {}
            if (Trigger.isUndelete) {}
        }
    }
}*/