/*------------------------------------------------------------
Author:         Amarendra Nagireddy
Company:        Apps Associates
Description:    Test class to validate WorkOrderTriggerActions_PM_Test
                Tests Excecuted:
                setPMWorkOrders_Test1 - verify that on insert of work orders, If Work Orders is an Auto PM Record Type then it 
                                        should update the fields on Work Order with related case field values. and update the
                                         related Service with work order id.
              
                setPMWorkOrders_Test2 - verify that on update of Order work orders,if the work order record type is set to closed
                                        or completed update the no of work orders completed and work order closed date on related
                                        PreventiveMaintenancePlan.
History:
<Date>          <Authors Name>          <Brief Description of Change>
02/20/2017       Amarendra Nagireddy     Initial Creation

06/20/2018   Ryan Lambert    Remove all code / reference to FSLIS
------------------------------------------------------------*/

@isTest
public class WorkOrderTriggerActions_PM_Test {
        
}