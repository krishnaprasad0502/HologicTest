/*------------------------------------------------------------
Author:         Denise Bacher
Company:        Salesforce.com
Description:    Trigger framework for the OrderItem object
Test Class:     OrderItemTrigger_Test

History:
<Date>          <Authors Name>      <Brief Description of Change>
07/22/2016      Denise Bacher       Initial Creation (US1387)
05/05/2017      Raj Sharan          Updated for Product Replacement based on Replacement Version (US-0002638)
07/12/2018      Mani Sundaresan     Flag the related account to be Sunshine compliant (US-0003812)
------------------------------------------------------------*/

trigger OrderItemTrigger on OrderItem (after delete, after insert, after undelete, after update, before delete, before insert, before update) {
            
    private static Boolean isActive = GlobalUtility.isTriggerActive('OrderItemTrigger');
    private static Boolean runReplacementFeature = GlobalUtility.isTriggerActive('OrderLineProductReplacement');
    
    if(isActive){
      if (Trigger.isBefore) {
        if (Trigger.isInsert) {
          //OrderItemTriggerActions.preventDML((List<OrderItem>)Trigger.new, null);
         // Modification for (US-0002638) 
         if(runReplacementFeature) OrderItemTriggerActions.reviewOrderItems((List<OrderItem>)Trigger.new,null);
         // End of Modification for (US-0002638) 
          OrderItemTriggerActions.setEntitlementAndUnitPrice((List<OrderItem>)Trigger.new);
          OrderItemTriggerActions.setSunshineCompliantOnAccount((List<OrderItem>)Trigger.new, null);
        }
        if (Trigger.isUpdate) {
         //OrderItemTriggerActions.preventDML((List<OrderItem>)Trigger.new, Trigger.oldMap);
         
        }
        if (Trigger.isDelete) {
         //OrderItemTriggerActions.preventDML((List<OrderItem>)Trigger.old, null);
        }
        if (Trigger.isUndelete) {}
      }
    
      if (Trigger.isAfter) {
        if (Trigger.isInsert) {
          OrderItemTriggerActions.checkToCreateWorkOrders(trigger.new);
          OrderItemTriggerActions.setSunshineCompliantOnAccount((List<OrderItem>)Trigger.new, null);
        }
        if (Trigger.isUpdate) {
            OrderItemTriggerActions.setSunshineCompliantOnAccount((List<OrderItem>)Trigger.new, Trigger.oldMap);
        }
        if (Trigger.isDelete) {}
        if (Trigger.isUndelete) {}
      }
    }
}