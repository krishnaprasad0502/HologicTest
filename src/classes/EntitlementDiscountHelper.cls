/*------------------------------------------------------------
Author:         Denise Bacher
Company:        Salesforce.com
Description:    Helper class used to fetch and calculate the Entitlement Discount
Test Class:     OrderItemTrigger_Test
                WorkOrderLineItemTrigger_Test

History:
<Date>          <Authors Name>      <Brief Description of Change>
07/22/2016      Denise Bacher       Initial Creation (US158/US1387)
31/01/2018      Krishna prasad      fetch Entitlement  after expiry US-0003852
------------------------------------------------------------*/
public with sharing class EntitlementDiscountHelper {
    
    /*------------------------------------------------------------
    Author:         Denise Bacher
    Company:        Salesforce.com
    Description:    Determine the Entitlement with the largest discount (lowest unit cost)
    Inputs:         productIds - The set of product IDs
                    coverageGroupIds -  Set of coverageGroupIds - this will be used to return results
                    productIdToCoverageGroupId - Map productIds to coverage groups - this will be used to return results
    Returns:        N/A
    
    History:
    <Date>          <Authors Name>      <Brief Description of Change>
    07/19/2016      Denise Bacher       Initial Creation
    ------------------------------------------------------------*/
    public static void queryCoverageGroupProduct(Set<Id> productIds, Set<Id> coverageGroupIds, Map<Id, Set<Id>> productIdToCoverageGroupId){
        List<Coverage_Group_Product__c> coverageGroupProducts = [Select Id, Coverage_Group_Name__c, Product__c From Coverage_Group_Product__c Where Product__r.Id IN :productIds];
        
        for(Coverage_Group_Product__c cgp : coverageGroupProducts){
            coverageGroupIds.add(cgp.Coverage_Group_Name__c);
            
            if(!productIdToCoverageGroupId.containsKey(cgp.Product__c)){
                productIdToCoverageGroupId.put(cgp.Product__c, new Set<Id>());
            }
            productIdToCoverageGroupId.get(cgp.Product__c).add(cgp.Coverage_Group_Name__c);
        }
        //System.debug('coverageGroupIds '+Json.serialize(coverageGroupIds));
        //System.debug('productIdToCoverageGroupId '+Json.serialize(productIdToCoverageGroupId));
    }
    
    /*------------------------------------------------------------
    Author:         Denise Bacher
    Company:        Salesforce.com
    Description:    Determine the Entitlement with the largest discount (lowest unit cost)
    Inputs:         coverageGroupIds - Set of Coverage Group Ids to query against
                    rootAssetIds -  Set of Root Asset Ids to query against
                    minDate -  Minimum start date for entitlements to query
                    maxDate -  Maximum end date for entitlements to query
                    coverageGroupIdToRootAssetIdToEntitlements - Map coverage group to asset to entitlements - this will be used to return results
    Returns:        N/A
    
    History:
    <Date>          <Authors Name>      <Brief Description of Change>
    07/19/2016      Denise Bacher       Initial Creation
    31/01/2018      Krishna prasad      fetch Entitlement  after expiry US-0003852
    ------------------------------------------------------------*/
    public static void queryDiscountEntitlements(Set<Id> coverageGroupIds, Set<Id> rootAssetIds, Date minDate, Date maxDate, Map<Id, Map<Id, List<Entitlement>>> coverageGroupIdToRootAssetIdToEntitlements){
        List<Entitlement> entitlements = [Select Id, AssetId, Asset.RootAssetId, Coverage_Group__c
            , Discount__c, Max_Covered_Amount__c, StartDate, EndDate
            From Entitlement 
            Where Coverage_Group__c IN: coverageGroupIds
            And Asset.RootAssetId IN: rootAssetIds
            And RecordTypeId =: GlobalUtility.getRecordTypeId('Entitlement', 'B_SH_Discount')
            And StartDate <=: minDate
            //Commented by Krishna prasad as part of user story US-0003852
            And EndDate >=: maxDate
            ];
            
        for(Entitlement e : entitlements){
            if(!coverageGroupIdToRootAssetIdToEntitlements.containsKey(e.Coverage_Group__c)){
                coverageGroupIdToRootAssetIdToEntitlements.put(e.Coverage_Group__c, new Map<Id, List<Entitlement>>());
            }
            
            if(!coverageGroupIdToRootAssetIdToEntitlements.get(e.Coverage_Group__c).containsKey(e.Asset.RootAssetId)){
                coverageGroupIdToRootAssetIdToEntitlements.get(e.Coverage_Group__c).put(e.Asset.RootAssetId, new List<Entitlement>());
            }
            
            coverageGroupIdToRootAssetIdToEntitlements.get(e.Coverage_Group__c).get(e.Asset.RootAssetId).add(e);
        }
        System.debug('entitlements '+Json.serialize(entitlements));// 
        System.debug('coverageGroupIdToRootAssetIdToEntitlements '+Json.serialize(coverageGroupIdToRootAssetIdToEntitlements));
    }
    
    /*------------------------------------------------------------
    Author:         Denise Bacher
    Company:        Salesforce.com
    Description:    Determine the Entitlement with the largest discount (lowest unit cost)
    Inputs:         entitlements - The list of Entitlements to loop through
                    listPrice -  list price of the item we're discounting
                    createdDate - created date from the item, to ensure the entitlemnt applies
    Returns:        Entitlement
    
    History:
    <Date>          <Authors Name>      <Brief Description of Change>
    07/19/2016      Denise Bacher       Initial Creation
    ------------------------------------------------------------*/
    public static Entitlement determineDiscountEntitlement(List<Entitlement> entitlements, Decimal listPrice, Date createdDate){
        Entitlement entitlement = new Entitlement();
        Double lowestPrice;
        
        if(entitlements.size() == 1)
            entitlement = entitlements[0];
        else{
            for(Entitlement e : entitlements){
                if(e.StartDate <= createdDate && e.EndDate >= createdDate){
                    Double currentPrice = 0;
                    if(e.Discount__c > 0){
                        currentPrice = listPrice * (1 - (e.Discount__c/100));
                    } 
                    else if(e.Max_Covered_Amount__c > 0){
                        currentPrice = listPrice - e.Max_Covered_Amount__c;
                    }
                    
                    if(lowestPrice == null || currentPrice < lowestPrice){
                        entitlement = e;
                        lowestPrice = currentPrice;
                    }
                }
            }
        }
        
        //System.debug('new entitlement '+Json.serialize(entitlement));
        //System.debug('lowest price '+lowestPrice+' list price '+listPrice);
        return entitlement;
    }
}