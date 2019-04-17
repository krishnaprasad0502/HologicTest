/*------------------------------------------------------------
Author:         Denise Bacher
Company:        Salesforce.com
Description:    Test class to validate WorkOrderLineItemTrigger
                Tests Excecuted:
                
                setPriceBookEntryAndListPrice_insert - verify that on insert of a workOrderLineItem, the pricebookEntry and list price are set
                
                setPriceBookEntryAndListPrice_update - verify that on update of a workOrderLineItem, the pricebookEntry and list price are set
                
                setPriceBookEntryAndListPrice_insertLaborTravel - verify that on insert of a Labor/Travel workOrderLineItem, the product, pricebookEntry and list price are set
                
                setEntitlementAndUnitPrice_insertAddPart - verify that on insert of a workOrderLineItem, the entitlement and unit price are set
                
                setEntitlementAndUnitPrice_updateAddPart - verify that on update of a workOrderLineItem, the entitlement and unit price are set
                
                setEntitlementAndUnitPrice_insertAddLaborTravel - verify that on insert of a workOrderLineItem, the entitlement and unit price are set
                
                setEntitlementAndUnitPrice_updateAddLaborTravel - verify that on update of a workOrderLineItem, the entitlement and unit price are set
                
                createUpdateTask - verify that a task was created/updated with a WorkOrderLineItem gets created/Updated.
History:
<Date>          <Authors Name>      <Brief Description of Change>
07/20/2016      Denise Bacher       Initial Creation (US158)
08/15/2016      Marc Goldstein      setPriceBookEntryAndListPriceLabor_insert to verify labor pricing
10/15/2016      Denise Bacher       Added unit tests to cover insert/update for setting entitlement on Add Labor/Travel WOLI (part of Winter 17 patch)
11/06/2017      Mani Sundaresan     Added unit test method to cover createUpdateTask method in WorkOrderLineItemTrigger class 
03/01/2017      Mani Sundaresan     Added unit tests to cover update for Unit Price on Add Labor and Travel WOLI 
06/21/2017      Raj Sharan          Updated for Custom Settings

06/20/2018   Ryan Lambert    Remove all code / reference to FSLIS -- apparently can be deleted, code replaced by WorkOrderLineItemTriggerActions_Test
------------------------------------------------------------*/
@isTest
private class WorkOrderLineItemTrigger_Test {
   
}