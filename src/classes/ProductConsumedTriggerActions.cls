public class ProductConsumedTriggerActions {
    
    /*------------------------------------------------------------
Author:         	Dave Mansell, Salesforce
Description:    	Performs custom validation on the incoming PC records
Inputs:         	List of records
Returns:        	N/A
Test Class(es):		ProductConsumedTriggerActions_Test.testCustomValidations
------------------------------------------------------------*/
    public static void performCustomValidations(List<ProductConsumed> pcs){
        String userDivision = [SELECT Division FROM User WHERE Id = :UserInfo.getUserId()].Division;
        for(ProductConsumed pc : pcs){
            if(pc.Override_Amount__c != null &&
               pc.Override_Explanation__c == null &&
               pc.Price_Override_Reason__c == null &&
               userDivision == 'Breast & Skeletal Health'
              ){
                  pc.addError('If Price has been modified, you must select a Price Override reason or provide an explanation.');
              }
        }
    }
    
    /*------------------------------------------------------------
Author:         	Dave Mansell, Salesforce
Description:    	Check for unit price change on the incoming PC records
Inputs:         	List of records, Map of old records
Returns:        	N/A
Test Class(es):		ProductConsumedTriggerActions_Test.testCheckForUnitPriceChange
------------------------------------------------------------*/
    public static void checkForUnitPriceChange(List<ProductConsumed> pcs, Map<Id, ProductConsumed> oldMap){
        for(ProductConsumed pc : pcs){
            ProductConsumed old = oldMap.get(pc.Id);
            if(pc.UnitPrice != old.UnitPrice && pc.UnitPrice != null && pc.QuantityConsumed != null){
                pc.Override_Amount__c = pc.UnitPrice * pc.QuantityConsumed;
            }
        }
    }
    
    /*------------------------------------------------------------
Author:         	Dave Mansell, Salesforce
Description:    	Updates a few ProductConsumed record fields based on parent asset field values
Inputs:         	List of records
Returns:        	N/A
Test Class(es):		ProductConsumedTriggerActions_Test.testUpdateReturnFields
------------------------------------------------------------*/
    public static void updateReturnFields(List<ProductConsumed> pcons){
        //Gather parent return Asset Ids
        Set<Id> assetIds = new Set<Id>();
        for(ProductConsumed pcon : pcons){
            if(pcon.Return_Asset__c != null){
                assetIds.add(pcon.Return_Asset__c);
            }
        }
        
        //Query parent Assets and map by Id
        Map<Id, Asset> assetsById = new Map<Id, Asset>([
            SELECT Id
            ,Product2Id
            ,SerialNumber
            FROM Asset
            WHERE Id IN :assetIds
        ]);
        
        //Loop through ProductConsumeds and copy field values
        for(ProductConsumed pcon : pcons){
            Asset asst = assetsById.get(pcon.Return_Asset__c);
            if(asst != null){
                pcon.Return_Product__c = asst.Product2Id;
                pcon.Return_Serial_Number__c = asst.SerialNumber;
            }
        }
    }
    
    /*------------------------------------------------------------
Author:         	Dave Mansell, Salesforce
Description:    	Finds entitlements and links them to incoming ProductConsumed records
Inputs:         	List of records
Returns:        	N/A
Test Class(es):		ProductConsumedTriggerActions_Test.testLinkEntitlements
------------------------------------------------------------*/
    public static void linkEntitlements(List<ProductConsumed> pcons){
        //Gather parent ProductItem Ids
        Map<Id, ProductItem> pritsById = new Map<Id, ProductItem>();
        for(ProductConsumed pcon : pcons){
            pritsById.put(pcon.ProductItemId, null);
        }
        
        //Query parent ProductItems and map by Id
        pritsById = new Map<Id, ProductItem>([
            SELECT Id
            ,Product2Id
            FROM ProductItem
            WHERE Id IN :pritsById.keySet()
        ]);
        
        Map<Integer, Id> prodIdsByListIndex = new Map<Integer, Id>();
        for(Integer i = 0; i < pcons.size(); i++){
            ProductConsumed pcon = pcons[i];
            ProductItem prit = pritsById.get(pcon.ProductItemId);
            if(prit != null){
                prodIdsByListIndex.put(i, prit.Product2Id);
            }
        }
        
        //Call helper function to create entitlements
        EntitlementLinkingHelper.linkEntitlementsForRecords(pcons, EntitlementLinkingHelper.TYPE_PRODUCT_CONSUMED, prodIdsByListIndex, null);
    }
    
    /*------------------------------------------------------------
Author:         	Dave Mansell, Salesforce
Description:    	Clears a field on Asset for ProductConsumeds with completed parent work orders
Inputs:         	List of records
Returns:        	N/A
Test Class(es):		ProductConsumedTriggerActions_Test.testUpdateAssetFields
------------------------------------------------------------*/
    public static void updateAssetFields(List<ProductConsumed> pcons){
        //Find assets related to [incoming ProductConsumeds with completed parent WOs]
        List<Asset> assets = [
            SELECT Id
            FROM Asset
            WHERE Id IN (
                SELECT Return_Asset__c
                FROM ProductConsumed
                WHERE Id IN :pcons
                AND (WorkOrder.Status = 'Completed' OR WorkOrder.Status = 'Closed')
            )
        ];
        
        for(Asset asst : assets){
            asst.Oracle_System_ID__c = null;
        }
        
        update assets;
    }
    
    /*------------------------------------------------------------
Author:         	Dave Mansell, Salesforce
Description:    	Checks for Delete checkbox value
Inputs:         	List of new records
Returns:        	N/A
Test Class(es):		ProductConsumedTriggerActions_Test.testCheckForDelete
------------------------------------------------------------*/
    public static void checkForDelete(List<ProductConsumed> pcs){
        Set<Id> pcIds = new Set<Id>();
        for(ProductConsumed pc : [
            SELECT Id
            FROM ProductConsumed
            WHERE Id IN :pcs
            AND Delete__c = true
        ]){
            pcIds.add(pc.Id);
        }
        if(pcIds.size() > 0){
            deletePCs(pcIds);
        }
    }
    
    @future
    private static void deletePCs(Set<Id> pcIds){
        delete [SELECT Id FROM ProductConsumed WHERE Id IN :pcIds];
    }
                
 /*------------------------------------------------------------
Author:         	Kasmoor Reddy, Apps Associates
Description:    	To make unit price as zero based on contions
Inputs:         	List of new records
Returns:        	N/A
Test Class(es):		ProductConsumedTriggerActions_Test
12/20/2018          AS part of user story US-0006204
------------------------------------------------------------*/
    public static void changeUnitPrice(List<ProductConsumed> ProductConsumedList)
    {
        List<Id> WorkOrderIds=new List<Id>();
        RecordType rt = [SELECT Id,Name FROM RecordType WHERE Name='PM'  AND SobjectType ='WorkOrder' LIMIT 1];
        system.debug(rt);
        for(ProductConsumed pc: ProductConsumedList)
        {
            if(pc.WorkOrderId!=null)
                WorkOrderIds.add(pc.WorkOrderId); 
        }
        
        Map<Id,WorkOrder> WorkOrderMap=new Map<Id,WorkOrder>([select id,RecordTypeId,MaintenancePlanId,Division__c from WorkOrder where id in: WorkOrderIds]);
        for(ProductConsumed pc: ProductConsumedList)
        {
            
            system.debug(pc.WorkOrderId); 
            system.debug(WorkOrderMap.get(pc.WorkOrderId).RecordTypeId);
            system.debug(WorkOrderMap.get(pc.WorkOrderId).Division__c);
            system.debug(WorkOrderMap.get(pc.WorkOrderId).MaintenancePlanId);
            if(pc.WorkOrderId!=null && WorkOrderMap.containsKey(pc.WorkOrderId))
                if(WorkOrderMap.get(pc.WorkOrderId).RecordTypeId==rt.id && WorkOrderMap.get(pc.WorkOrderId).MaintenancePlanId!=null && WorkOrderMap.get(pc.WorkOrderId).Division__c=='Diagnostics')
            {
                system.debug('in if');
                pc.UnitPrice=0;
                system.debug(pc.UnitPrice);
            }
        }
        
        
    }
}