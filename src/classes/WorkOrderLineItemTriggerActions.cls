/*------------------------------------------------------------
Author			Dave Mansell
Company:		Salesforce.com
Description:	Functions related to WorkOrderLineItem records

History:
<Date			<Authors Name		<Brief Description of Change>
03/19/2018		Dave Mansell		Initial Creation (US-0004035)
12/20/2018      Kasmoor Reddy       To make unit price as zero based on contions
------------------------------------------------------------*/

public class WorkOrderLineItemTriggerActions {
    
    public static Map<Integer, Id> newProdIdsByListIndex				{get;set;}
    public static Map<Integer, Decimal> newListPricesByListIndex		{get;set;}
    
    /*------------------------------------------------------------
Author:         	Dave Mansell, Salesforce
Description:    	Performs custom validation on the incoming WOLI records
Inputs:         	List of records
Returns:        	N/A
Test Class(es):		WorkOrderLineItemTriggerActions_Test.testCustomValidations
------------------------------------------------------------*/
    public static void performCustomValidations(List<WorkOrderLineItem> wolis){
        String userDivision = [SELECT Division FROM User WHERE Id = :UserInfo.getUserId()].Division;
        for(WorkOrderLineItem woli : wolis){
            if(woli.Override_Amount__c != null &&
               woli.Override_Explanation__c == null &&
               woli.Price_Override_Reason__c == null &&
               userDivision == 'Breast & Skeletal Health'
              ){
                  woli.addError('If Price has been modified, you must select a Price Override reason or provide an explanation.');
              }
        }
    }
    
    /*------------------------------------------------------------
Author:         	Dave Mansell, Salesforce
Description:    	Sets quantity on the incoming WOLI records
Inputs:         	List of records
Returns:        	N/A
Test Class(es):		WorkOrderLineItemTriggerActions_Test.testInsertWOLI1,
WorkOrderLineItemTriggerActions_Test.testInsertWOLI2,
WorkOrderLineItemTriggerActions_Test.testInsertWOLI3
------------------------------------------------------------*/
    public static void setQuantity(List<WorkOrderLineItem> wolis){
        Set<Id> woIds = new Set<Id>();
        for(WorkOrderLineItem woli : wolis){
            woIds.add(woli.WorkOrderId);
        }
        
        Map<Id, WorkOrder> wosById = new Map<Id, WorkOrder>([
            SELECT Id
            ,AssetId
            ,Asset.Product2Id
            ,Asset.Product2.Product_Source_Division__r.Source_Division__c
            ,Product__c
            ,Product__r.Product_Source_Division__c
            ,Product__r.Product_Source_Division__r.Source_Division__c
            FROM WorkOrder
            WHERE Id IN :woIds
        ]);
        
        Id billableEventRTId = GlobalUtility.getRecordTypeId('WorkOrderLineItem', 'Billable_Event');
        for(WorkOrderLineItem woli : wolis){
            WorkOrder wo = wosById.get(woli.WorkOrderId);
            String division;
            if(wo.AssetId != null
               && wo.Asset.Product2Id != null
               && wo.Asset.Product2.Product_Source_Division__c != null
               && wo.Asset.Product2.Product_Source_Division__r.Source_Division__c != null){
                   division = wo.Asset.Product2.Product_Source_Division__r.Source_Division__c;
               } else if(wo.Product__c != null
                         && wo.Product__r.Product_Source_Division__c != null
                         && wo.Product__r.Product_Source_Division__r.Source_Division__c != null){
                             division = wo.Product__r.Product_Source_Division__r.Source_Division__c;
                         }
            if(division != null){
                if(woli.RecordTypeId != billableEventRTId && (division == 'MOLECULAR' || division == 'CYTOLOGY')){
                    woli.Quantity = 1;
                } else {
                    woli.Quantity = woli.Labor_Qty__c;
                }
            }
            if(woli.Labor_Travel_Type__c == 'Depot Repair'){
                woli.Quantity = woli.Labor_Qty__c;
            }
        }
    }
    
    /*------------------------------------------------------------
Author:         	Dave Mansell, Salesforce
Description:    	Sets PricebookEntryId on the incoming WOLI records
Inputs:         	List of records
Returns:        	N/A
Test Class(es):		WorkOrderLineItemTriggerActions_Test.testInsertWOLI1,
WorkOrderLineItemTriggerActions_Test.testInsertWOLI2,
WorkOrderLineItemTriggerActions_Test.testInsertWOLI3
------------------------------------------------------------*/
    public static void setPriceBookEntryAndListPrice(List<WorkOrderLineItem> wolis){
        Map<Id, WorkOrder> wosById = new Map<Id, WorkOrder>();
        Set<Id> pricebookIds = new Set<Id>();
        Set<Id> psdIds = new Set<Id>();
        Set<String> servCats = new Set<String>();
        Set<String> types = new Set<String>();
        
        //Collect values from incoming WOLIs
        for(WorkOrderLineItem woli : wolis) {
            wosById.put(woli.WorkOrderId, null);
            if(woli.Labor_Travel_Type__c != null){
                types.add(woli.Labor_Travel_Type__c);
            }
        }
        
        //Map parent work order records by Id
        for(WorkOrder wo : [
            SELECT Id
            ,Pricebook2Id
            ,AssetId
            ,Asset.Product2.Product_Source_Division__c
            ,Asset.Product2.Product_Source_Division__r.Division__c
            ,Asset.Product2.Service_Category__c
            ,Product__c
            ,Product__r.Product_Source_Division__c
            ,Product__r.Product_Source_Division__r.Division__c
            ,Product__r.Service_Category__c
            FROM WorkOrder
            WHERE Id IN :wosById.keySet()
            AND Pricebook2Id != null
            AND (Asset.Product2.Product_Source_Division__c != null OR Product__r.Product_Source_Division__c != null)
        ]){
            if(wo.AssetId != null || wo.Product__c != null){
                wosById.put(wo.Id, wo);
                pricebookIds.add(wo.Pricebook2Id);
                if(wo.AssetId != null){
                    psdIds.add(wo.Asset.Product2.Product_Source_Division__c);
                    servCats.add(wo.Asset.Product2.Service_Category__c);
                } else if(wo.Product__c != null){
                    psdIds.add(wo.Product__r.Product_Source_Division__c);
                    servCats.add(wo.Product__r.Service_Category__c);
                }
            }
        }
        
        Id depotRepairProductId = Configuration_Settings__c.getInstance().Depot_Repair_Labor_Product_Diag__c;
        
        //Map pbes by key: Pricebook2Id | Product2.Product_Source_Division__c | Product2.Service_Category__c | Type
        Map<String, PricebookEntry> pbesByKey = new Map<String, PricebookEntry>();
        for(PricebookEntry pbe : [
            SELECT Id
            ,Product2Id
            ,Pricebook2Id
            ,Product2.Product_Source_Division__c
            ,Product2.Service_Category__c
            ,Product2.Labor_Travel_Type__c
            ,UnitPrice
            FROM PricebookEntry
            WHERE Pricebook2Id IN :pricebookIds
            AND IsActive = true
            AND (Product2Id = :depotRepairProductId OR
                 (Product2.Product_Source_Division__c IN :psdIds
                  AND (Product2.Service_Category__c IN :servCats OR Product2.Service_Category__c = null)
                  AND Product2.Labor_Travel_Type__c IN :types
                 )
                )
        ]){
            String key;
            if(pbe.Product2Id == depotRepairProductId){
                //Special rules for Diagnostic Depot Repair
                key = pbe.Pricebook2Id;
            } else {
                //Regular process
                key = pbe.Pricebook2Id + '|' + pbe.Product2.Product_Source_Division__c + '|' + pbe.Product2.Service_Category__c + '|' + pbe.Product2.Labor_Travel_Type__c;
            }
            pbesByKey.put(key, pbe);
        }
        
        newProdIdsByListIndex = new Map<Integer, Id>();
        newListPricesByListIndex = new Map<Integer, Decimal>();
        
        //Loop through incoming WOLIs
        for(Integer i = 0; i < wolis.size(); i++){
            WorkOrderLineItem woli = wolis[i];
            
            WorkOrder wo = wosById.get(woli.WorkOrderId);
            if(wo != null){
                PricebookEntry pbe;
                
                Id psdId;
                String division;
                String serviceCategory;
                if(wo.AssetId != null){
                    psdId = wo.Asset.Product2.Product_Source_Division__c;
                    division = wo.Asset.Product2.Product_Source_Division__r.Division__c;
                    serviceCategory = wo.Asset.Product2.Service_Category__c;
                } else if(wo.Product__c != null){
                    psdId = wo.Product__r.Product_Source_Division__c;
                    division = wo.Product__r.Product_Source_Division__r.Division__c;
                    serviceCategory = wo.Product__r.Service_Category__c;
                }
                
                //Give each one the correct PBE
                if(woli.Labor_Travel_Type__c == 'Depot Repair' && division == 'Diagnostics'){
                    //Special rules for Diagnostic Depot Repair
                    String key = wo.Pricebook2Id;
                    pbe = pbesByKey.get(key);
                } else {
                    //Regular process
                    String key = wo.Pricebook2Id + '|' + psdId + '|' + serviceCategory + '|' + woli.Labor_Travel_Type__c;
                    pbe = pbesByKey.get(key);
                    if(pbe == null){
                        key = wo.Pricebook2Id + '|' + psdId + '|null|' + woli.Labor_Travel_Type__c;
                        pbe = pbesByKey.get(key);
                    }
                }
                
                if(pbe == null){
                    if(!Test.isRunningTest()){
                        //woli.addError('No matching PriceBookEntry record was found.');
                    }
                } else {
                    woli.PricebookEntryId = pbe.Id;
                    
                    //Index the new values for use in linkEntitlementsAndSetUnitPricing()
                    newProdIdsByListIndex.put(i, pbe.Product2Id);
                    newListPricesByListIndex.put(i, pbe.UnitPrice);
                }
            }
        }
    }
    
    /*------------------------------------------------------------
Author:         	Dave Mansell, Salesforce
Description:    	Finds and links entitlements for incoming WOLI records
Inputs:         	List of records
Returns:        	N/A
Test Class(es):		WorkOrderLineItemTriggerActions_Test.testInsertWOLI1,
WorkOrderLineItemTriggerActions_Test.testInsertWOLI2,
WorkOrderLineItemTriggerActions_Test.testInsertWOLI3
------------------------------------------------------------*/
    public static void linkEntitlementsAndSetUnitPricing(List<WorkOrderLineItem> wolis){
        System.debug('***[a]');
        List<WorkOrderLineItem> wolisToUpdate = new List<WorkOrderLineItem>();
        List<WorkOrderLineItem> wolisToZeroOut = new List<WorkOrderLineItem>();
        
        Set<Id> validRecTypeIds = new Set<Id>{
            GlobalUtility.getRecordTypeId('WorkOrderLineItem', 'Labor')
                ,GlobalUtility.getRecordTypeId('WorkOrderLineItem', 'Travel')
                ,GlobalUtility.getRecordTypeId('WorkOrderLineItem', 'Billable_Event')
                ,GlobalUtility.getRecordTypeId('WorkOrderLineItem', 'Part_Billing')
                ,GlobalUtility.getRecordTypeId('WorkOrderLineItem', 'Fixed_Fee')
                };
                    
                    Map<Id, WorkOrder> parentWOsById = new Map<Id, WorkOrder>();
        for(WorkOrderLineItem woli : wolis) {
            if(woli.WorkOrderId != null){
                parentWOsById.put(woli.WorkOrderId, null);
            }
        }
        parentWOsById = new Map<Id, WorkOrder>([
            SELECT Id
            ,AssetId
            FROM WorkOrder
            WHERE Id IN :parentWOsById.keySet()
        ]);
        
        //Loop through WOLIs and filter by those that need entitlements
        for(WorkOrderLineItem woli : wolis) {
            WorkOrder wo = parentWOsById.get(woli.WorkOrderId);
            if(validRecTypeIds.contains(woli.RecordTypeId) && wo != null && wo.AssetId != null){
                wolisToUpdate.add(woli);
            }
            if(woli.RecordTypeId == GlobalUtility.getRecordTypeId('WorkOrderLineItem', 'Labor') ||
               woli.RecordTypeId == GlobalUtility.getRecordTypeId('WorkOrderLineItem', 'Travel')){
                   wolisToZeroOut.add(woli);
               }
        }
        
        if(wolisToUpdate.size() > 0){
            //Call helper function to create entitlements
            EntitlementLinkingHelper.linkEntitlementsForRecords(wolisToUpdate, EntitlementLinkingHelper.TYPE_WOLI, newProdIdsByListIndex, null);
        }
        
        if(wolisToZeroOut.size() > 0){
            //Gather parent WorkOrder Ids
            Map<Id, WorkOrder> wosById = new Map<Id, WorkOrder>();
            for(WorkOrderLineItem woli : wolisToZeroOut){
                System.assertNotEquals(null, woli.WorkOrderId);
                wosById.put(woli.WorkOrderId, null);
            }
            
            wosById = new Map<Id, WorkOrder>([
                SELECT Id, RecordType.DeveloperName
                FROM WorkOrder
                WHERE Id IN :wosById.keySet()
                AND (RecordType.DeveloperName = 'B_SH_Applications' OR
                     RecordType.DeveloperName = 'B_SH_FE_Install_Upgrade_Move')
            ]);
            
            for(WorkOrderLineItem woli : wolisToZeroOut){
                WorkOrder wo = wosById.get(woli.WorkOrderId);
                if(wo != null){
                    woli.UnitPrice = 0;
                }
            }
        }
    }
    
    /*------------------------------------------------------------
Author:         	Dave Mansell, Salesforce
Description:    	Checks for new Asset value on WOLI
Inputs:         	List of new records, Map of old records
Returns:        	N/A
Test Class(es):		WorkOrderLineItemTriggerActions_Test.testUpdateWOLI
------------------------------------------------------------*/
    public static void checkForNewAsset(List<WorkOrderLineItem> wolis, Map<Id, WorkOrderLineItem> oldMap){
        List<WorkOrderLineItem> validWOLIs = new List<WorkOrderLineItem>();
        for(WorkOrderLineItem woli : wolis){
            WorkOrderLineItem old = oldMap.get(woli.Id);
            if(old.AssetId != woli.AssetId && woli.PricebookEntryId == null){
                validWOLIs.add(woli);
            }
        }
        if(validWOLIs.size() > 0){
            setQuantity(validWOLIs);
            setPriceBookEntryAndListPrice(validWOLIs);
            linkEntitlementsAndSetUnitPricing(validWOLIs);
            for(WorkOrderLineItem woli : validWOLIs){
                if(woli.PricebookEntryId != null){
                    woli.UnitPrice = 0;
                }
            }
        }
    }
    
    /*------------------------------------------------------------
Author:         	Dave Mansell, Salesforce
Description:    	Checks for Cancelled status on WOLI
Inputs:         	List of new records
Returns:        	N/A
Test Class(es):		WorkOrderLineItemTriggerActions_Test.testCheckForCancelledStatus
------------------------------------------------------------*/
    public static void checkForCancelledStatus(List<WorkOrderLineItem> wolis){
        Set<Id> woliIds = new Set<Id>();
        for(WorkOrderLineItem woli : [
            SELECT Id, Status
            FROM WorkOrderLineItem
            WHERE Id IN :wolis
            AND Status = 'Cancelled'
            AND Order.Status != 'Closed'
            AND Order.Status != 'Completed'
        ]){
            woliIds.add(woli.Id);
        }
        if(woliIds.size() > 0){
            deleteWOLIs(woliIds);
        }
    }
    
    @future
    private static void deleteWOLIs(Set<Id> woliIds){
        delete [SELECT Id FROM WorkOrderLineItem WHERE Id IN :woliIds];
    }
    
 /*------------------------------------------------------------
Author:         	Kasmoor Reddy, Apps Associates
Description:    	To make unit price as zero based on contions
Inputs:         	List of new records
Returns:        	N/A
Test Class(es):		WorkOrderLineItemTriggerActions_Test
12/20/2018          AS part of user story US-0006204
------------------------------------------------------------*/
    public static void changeUnitPrice(List<WorkOrderLineItem> WorkOrderLineItemList)
    {
        List<Id> WorkOrderIds=new List<Id>();
        RecordType rt = [SELECT Id,Name FROM RecordType WHERE Name='PM'  AND SobjectType ='WorkOrder' LIMIT 1];
        system.debug(rt);
        for(WorkOrderLineItem woli: WorkOrderLineItemList)
        {
            if(woli.WorkOrderId!=null)
                WorkOrderIds.add(woli.WorkOrderId); 
        }
        
        Map<Id,WorkOrder> WorkOrderMap=new Map<Id,WorkOrder>([select id,RecordTypeId,MaintenancePlanId,Division__c from WorkOrder where id in: WorkOrderIds]);
        for(WorkOrderLineItem woli: WorkOrderLineItemList)
        {
            
     	       system.debug(woli.WorkOrderId); 
            system.debug(WorkOrderMap.get(woli.WorkOrderId).RecordTypeId);
            system.debug(WorkOrderMap.get(woli.WorkOrderId).Division__c);
            system.debug(WorkOrderMap.get(woli.WorkOrderId).MaintenancePlanId);
            if(woli.WorkOrderId!=null && WorkOrderMap.containsKey(woli.WorkOrderId))
                if(WorkOrderMap.get(woli.WorkOrderId).RecordTypeId==rt.id && WorkOrderMap.get(woli.WorkOrderId).MaintenancePlanId!=null && WorkOrderMap.get(woli.WorkOrderId).Division__c=='Diagnostics')
            {
                system.debug('in if');
                woli.UnitPrice=0;
                system.debug(woli.UnitPrice);
            }
        }
    }
    
}