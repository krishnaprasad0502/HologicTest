/*------------------------------------------------------------
Author:         Denise Bacher
Company:        Salesforce.com
Description:    Test class to validate WorkOrderTrigger
                Tests Excecuted:
                
                closeRelatedCase_insertWorkOrderAllComplete - verify that on insert of closed work orders, the Case closes
                
                closeRelatedCase_insertWorkOrderAllCompleteNoAutoClose - verify that on insert of closed work orders, the Case completes
                
                closeRelatedCase_insertWorkOrderSomeComplete - verify that on insert of some closed and open work orders, the Case status does not change
                
                closeRelatedCase_updateWorkOrderAllComplete - verify that on update of closed work orders, the Case closes
                
                closeRelatedCase_updateWorkOrderAllCompleteNoAutoClose - verify that on update of closed work orders, the Case completes
                
                closeRelatedCase_updateWorkOrderSomeComplete - verify that on update of some closed and open work orders, the Case status does not change
                
                updateInstalledAssets_update - verify assets have their statuses changed to install, and install dates set when install Wo are closed
                
                setContact_insert - verify work orders with Applications or Connectivity record type have their contact lookup set
                
                setContact_update - verify work orders with Applications or Connectivity record type have their contact lookup set
                
                entitlementEscalationTest - tests the following escalation functions: setOwnerToDSM, sendPushNotification, createExcludedResource, createChatterPost
                
                setRecordType_insert - verify that on insert of a WO, the correct RecordType is set from the Service.ServiceType
                
                setRecordType_update - verify that on update of a WO, the correct RecordType is set from the Service.ServiceType
                
History:
<Date>          <Authors Name>      <Brief Description of Change>
04/19/2016      Denise Bacher       Initial Creation
06/30/2016      Denise Bacher       Added tests for setWorkOrderEntitlement - sets entitlement on WO (US1311)
07/21/2016      Denise Bacher       Update to auto close of cases on work order close - removed closeRelatedCase_bypassBillableCases (US1371)
07/26/2016      Sumit Gupta         Added tests for createOrderAndOrderItems method in WorkOrderTriggerActions class
07/29/2016      Sumit Gupta         Added tests for createOrUpdateStandingOrders method in WorkOrderTriggerActions class
08/17/2016      Denise Bacher       Added tests for setDefaultPricebook_insert
09/01/2016      Denise Bacher       Added tests for updateInstalledAssets_update (REQ165)
09/02/2016      Denise Bacher       Added tests for setContact (REQ125)
10/27/2016      Denise Bacher       Added tests for setOwnerToDSM, sendPushNotification, createExcludedResource, createChatterPost (HD-1666)
10/28/2016      Denise Bacher       Added tests for setRecordType (HD-1666)

06/20/2018   Ryan Lambert    Remove all code / reference to FSLIS - -- apparently can be deleted, code replaced by WorkOrderTriggerActions_Test
------------------------------------------------------------*/
@isTest
private class WorkOrderTrigger_Test {
   
}