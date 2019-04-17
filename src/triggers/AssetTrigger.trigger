/*------------------------------------------------------------
Author:         Denise Bacher
Company:        Salesforce.com
Description:    Trigger framework for the Asset object
Test Class:     AssetTrigger_Test

History:
<Date>          <Authors Name>      <Brief Description of Change>
04/27/2016      Denise Bacher       Initial Creation (US762)
06/21/2016      Marc Goldstein      Added new function setQuoteLineLookups (US1316)
07/13/2016      Denise Bacher       Added new functions updateCaseWorkOrderAssetLookups, createServiceContracts (US1072 & US142)
08/25/2017      John Christy        Update for Advance Exchange Warranty Creation US-0003094. 
03/22/2018      Raviraj Reddy       Added a new function to call AMPS Merchant Track Method (US3819)
04/02/2018      Chris Jongbloed     Update for Account Product Family Method, (US3843)
10/04/2018      Dave Mansell        Cleaned up all code
11/06/2018      Mani Sundaresan     Added trigger switch to control the Account Product Family functionality(US-6095)
2/13/2019       Kasmoor Reddy       Update Location based on Selected to Bill To Address (US-6149)
25/02/2019      Alex Powning        Removed AMPS Tasks -> moved to account
------------------------------------------------------------*/

trigger AssetTrigger on Asset (after delete, after insert, after undelete, after update, before delete, before insert, before update) {
    
    private static Boolean isActive = GlobalUtility.isTriggerActive('AssetTrigger');
    
    private static Boolean isActiveAPF = GlobalUtility.isTriggerActive('AssetProductFamilyTrigger');
    
    if(isActive){
        if (Trigger.isBefore) {
            if (Trigger.isInsert) {
                AssetTriggerActions.setAccountLookups(Trigger.new);
                AssetTriggerActions.setQuoteLineLookups(Trigger.new);
                //Updates Location based on Selected to Bill To Address (US-6149) by Kasmoor Reddy on 2/13/2019
                AssetTriggerActions_Ext.UpdateAssetLocation(Trigger.new,null);
                
            }
            if (Trigger.isUpdate) {
                AssetTriggerActions.checkToSetAccountLookups(Trigger.new, Trigger.oldMap);
                AssetTriggerActions.checkToSetQuoteLineLookups(Trigger.new, Trigger.oldMap);
                //Updates Location based on Selected to Bill To Address (US-6149) by Kasmoor Reddy on 2/13/2019
                AssetTriggerActions_Ext.UpdateAssetLocation(Trigger.new,Trigger.oldMap);
            }
            if (Trigger.isDelete) {}
            if (Trigger.isUndelete) {}
        }
        
        if (Trigger.isAfter) {
            if (Trigger.isInsert) {
                AssetTriggerActions.createServiceContracts(Trigger.new);
                AssetTriggerActions.updateMultipleAssetLookups(Trigger.new);
                AssetTriggerActions.setAdvancedExchange(Trigger.new);
                if(isActiveAPF)
                    AssetTriggerActions.updateAccountProductFamily(Trigger.new);
                AssetTriggerActions.updateRelatedWorkOrders(Trigger.new);
            }
            if (Trigger.isUpdate) {
                AssetTriggerActions.checkToCreateServiceContracts(Trigger.new,Trigger.oldMap);
                AssetTriggerActions.checkToUpdateMultipleAssetLookups(Trigger.new, Trigger.oldMap);
                AssetTriggerActions.checkToSetAdvancedExchange(Trigger.new, Trigger.oldMap);
                //AssetTriggerActions.checkToCreateInitiatingTasks(Trigger.new, Trigger.oldMap);
                AssetTriggerActions.updateRelatedWorkOrders(Trigger.new, Trigger.oldMap);
                if(isActiveAPF)
                    AssetTriggerActions.updateAccountProductFamily(Trigger.new);
            }
            if (Trigger.isDelete) {
                if(isActiveAPF)
                    AssetTriggerActions.updateAccountProductFamily(Trigger.old);
            }
    
        }
    }
}

/*
trigger AssetTrigger on Asset (after delete, after insert, after undelete, after update, before delete, before insert, before update) {
    
    private static Boolean isActive = GlobalUtility.isTriggerActive('AssetTrigger');
    
    if(isActive){
        if (Trigger.isBefore) {
            if (Trigger.isInsert) {
                AssetTriggerActions.setAccountLookups((List<Asset>)Trigger.new, null);
                AssetTriggerActions.setQuoteLineLookups((List<Asset>)Trigger.new, null);
                
            }
            if (Trigger.isUpdate) {
                AssetTriggerActions.setAccountLookups((List<Asset>)Trigger.new, Trigger.oldMap);
                AssetTriggerActions.setQuoteLineLookups((List<Asset>)Trigger.new, Trigger.oldMap);
                
            }
            if (Trigger.isDelete) {}
            if (Trigger.isUndelete) {}
        }
        
        if (Trigger.isAfter) {
            if (Trigger.isInsert) {
                AssetTriggerActions.createServiceContracts((List<Asset>)Trigger.new, null);
                AssetTriggerActions.updateCaseWorkOrderAssetLookups((List<Asset>)Trigger.new, null);
                AssetTriggerActions.setAdvancedExchange((List<Asset>)Trigger.new, null);
                AssetTriggerActions.updateAccountProductFamily((List<Asset>)Trigger.new, null);
            }
            if (Trigger.isUpdate) {
                AssetTriggerActions.createServiceContracts((List<Asset>)Trigger.new,Trigger.oldMap);
                AssetTriggerActions.updateCaseWorkOrderAssetLookups((List<Asset>)Trigger.new, Trigger.oldMap);
                
                //if (GlobalUtility.runOnceOnAfter())
                AssetTriggerActions.setAdvancedExchange((List<Asset>)Trigger.new, Trigger.oldMap);
                
                AssetTriggerActions.createInitiatingTasks(Trigger.newMap,Trigger.oldMap);//calls AMPS Merchant Track method. Added by RaviRaj
                AssetTriggerActions.updateAccountProductFamily((List<Asset>)Trigger.new, Trigger.oldMap);
                
                AssetTriggerActions.updateRelatedWorkOrders(trigger.new, trigger.oldMap);
            }
            if (Trigger.isDelete) {
                AssetTriggerActions.updateAccountProductFamily((List<Asset>)Trigger.old, null);
            }
    
        }
    }
}
*/