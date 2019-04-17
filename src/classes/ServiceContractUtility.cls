/*------------------------------------------------------------
Author:         John Christy
Company:        Apps Associates
Description:    Pulic class to process Service Contract requests
Test Class:     AssetTrigger_Test 

History:
<Date>          <Authors Name>      <Brief Description of Change>
08/25/2017      John Christy        Update for Advance Exchange Warranty Creation US-0002764
08/25/2017      Raj Sharan          Update for Advance Exchange Warranty Creation US-0002764
------------------------------------------------------------*/

public with sharing class ServiceContractUtility {
    
    // transfer service contract information from RMA to new asset

/*------------------------------------------------------------
Author:         John Christy
Company:        Apps Associates
Description:    Pulic class to process Service Contract requests
Test Class:     AssetTrigger_Test 
Inputs:         Map of Contract Lines to Clone, Map of Corresponding Assets (Return and Replacement Asset), Map of Asset Inserted or Updated with Order Line
Returns:        Inserted Contract Lines 

History:
<Date>          <Authors Name>      <Brief Description of Change>
08/25/2017      John Christy        Update for Advance Exchange Warranty Creation US-0002764
08/25/2017      Raj Sharan          Update for Advance Exchange Warranty Creation US-0002764
------------------------------------------------------------*/

    public static List<ContractLineItem> copyContractLines(Map<Id, ContractLineItem> contractLinesToCloneMap, Map<Id, Id> correspondingAssetExchangeMap, 
                                                Map<Id, Asset> assetAdvanceExchangeMap){

        List<ContractLineItem> insertContractLinesList = new List<ContractLineItem>();

        ID returnAssetId; 
        ID newAssetId; 
        Date startDate; 
        String descriptionContractLine;

        for(ID contractLineId : contractLinesToCloneMap.keySet()){
     
          returnAssetId = contractLinesToCloneMap.get(contractLineId).AssetId;
          newAssetId = correspondingAssetExchangeMap.get(returnAssetId);
          startDate = assetAdvanceExchangeMap.get(newAssetId).Shipped_on_Date__c;
          descriptionContractLine = contractLinesToCloneMap.get(contractLineId).Description;

          ContractLineItem contractLineRecord = new ContractLineItem();

            contractLineRecord.Asset_Created__c = TRUE; 
            contractLineRecord.AssetId = newAssetId;
            contractLineRecord.Contract_Activated__c = TRUE; 
            contractLineRecord.Covered_Asset__c = newAssetId;
            contractLineRecord.Description = descriptionContractLine; 
            contractLineRecord.Discount = contractLinesToCloneMap.get(contractLineId).Discount;
            contractLineRecord.EndDate = contractLinesToCloneMap.get(contractLineId).EndDate;
            contractLineRecord.PricebookEntryId = contractLinesToCloneMap.get(contractLineId).PricebookEntryId;
            contractLineRecord.Quantity = contractLinesToCloneMap.get(contractLineId).Quantity;
            contractLineRecord.SBQQSC__Bundle__c = contractLinesToCloneMap.get(contractLineId).SBQQSC__Bundle__c;
            contractLineRecord.SBQQSC__Bundled__c = contractLinesToCloneMap.get(contractLineId).SBQQSC__Bundled__c;
            contractLineRecord.SBQQSC__ProrateMultiplier__c = contractLinesToCloneMap.get(contractLineId).SBQQSC__ProrateMultiplier__c;
            contractLineRecord.SBQQSC__Quantity__c = contractLinesToCloneMap.get(contractLineId).SBQQSC__Quantity__c;
            contractLineRecord.SBQQSC__QuoteLine__c = contractLinesToCloneMap.get(contractLineId).SBQQSC__QuoteLine__c;
            contractLineRecord.Service_Type__c = contractLinesToCloneMap.get(contractLineId).Service_Type__c;
            contractLineRecord.ServiceContractId = contractLinesToCloneMap.get(contractLineId).ServiceContractId;
            contractLineRecord.StartDate = startDate;
            contractLineRecord.Suppress_Credit__c = contractLinesToCloneMap.get(contractLineId).Suppress_Credit__c;
            contractLineRecord.Type__c = contractLinesToCloneMap.get(contractLineId).Type__c;
            contractLineRecord.UnitPrice = contractLinesToCloneMap.get(contractLineId).UnitPrice;
           
        insertContractLinesList.add(contractLineRecord);

        }

        if(insertContractLinesList.size() > 0) Database.SaveResult[] contractLineSaveList = Database.insert(insertContractLinesList, false);
      
        if(insertContractLinesList.size() > 0){
 
        return insertContractLinesList;

        }else{

        return null;

        } 

    }

/*------------------------------------------------------------
Author:         John Christy
Company:        Apps Associates
Description:    Pulic class to process Service Contract requests
Test Class:     AssetTrigger_Test 
Inputs:         Map of Billing Schedule to Clone, Lines of New Contract Lines, 
                Map of Corresponding Assets (Return and Replacement Asset), Map of Asset Inserted or Updated with Order Line, Map of Replacement Asset, 
                Map of Contract Lines to clone.
Returns:        NA 

History:
<Date>          <Authors Name>      <Brief Description of Change>
08/25/2017      John Christy        Update for Advance Exchange Warranty Creation US-0002764
08/25/2017      Raj Sharan          Update for Advance Exchange Warranty Creation US-0002764

------------------------------------------------------------*/
    
    // create billing schedule for new service contract line item

    public static void createBillingSchedule(Map<Id,Service_Billing_Schedule__c> billingScheduleToCloneMap, 
             List<ContractLineItem> newContractLines, Map<Id, Id> correspondingAssetExchangeMap,  Map<Id, Asset> assetAdvanceExchangeMap, 
             Map<Id, ContractLineItem> contractLinesToCloneMap){  
                                             
        List<Service_Billing_Schedule__c> insertBillingSchedules = new List<Service_Billing_Schedule__c>();
        Map<Id, Id> correspondingContractLineMap = new Map<Id, Id>();
  
        ID   returnAsset; 
        ID   newAssetId; 
        ID   oldAssetId; 
        Date startDate; 
        ID   oldContractLineId;
        ID   newContractLineId;

        // Create map of Old Contract Line to New Contract Line

        system.debug('newContractLines = ' + newContractLines);

        for(ContractLineItem newLine:newContractLines){

          system.debug('newLine = ' + newLine);

          for(ID contractLineId : contractLinesToCloneMap.keySet()){

          system.debug('contractLineId = ' + contractLineId);
          returnAsset = contractLinesToCloneMap.get(contractLineId).AssetId;

            if(newLine.ServiceContractId == contractLinesToCloneMap.get(contractLineId).ServiceContractId && 
            correspondingAssetExchangeMap.get(returnAsset) == newLine.AssetId) { 
            correspondingContractLineMap.put(contractLinesToCloneMap.get(contractLineId).Id, newLine.Id);

            }

          }
        }

        system.debug('correspondingContractLineMap = ' + correspondingContractLineMap);

 
        for(ID billingScheduleId : billingScheduleToCloneMap.keySet()){

        returnAsset = billingScheduleToCloneMap.get(billingScheduleId).Contract_Line_Item__r.AssetId;
        newAssetId =  correspondingAssetExchangeMap.get(returnAsset);
        startDate =  assetAdvanceExchangeMap.get(newAssetId).Shipped_on_Date__c;
        oldContractLineId = billingScheduleToCloneMap.get(billingScheduleId).Contract_Line_Item__c;
        newContractLineId = correspondingContractLineMap.get(oldContractLineId);

        Service_Billing_Schedule__c billingScheduleRecord = new Service_Billing_Schedule__c();


            billingScheduleRecord.Contract_Line_Item__c = newContractLineId;
            billingScheduleRecord.Name = billingScheduleToCloneMap.get(billingScheduleId).Name;
            billingScheduleRecord.Sequence__c = billingScheduleToCloneMap.get(billingScheduleId).Sequence__c;
            billingScheduleRecord.Number_of_Periods__c = billingScheduleToCloneMap.get(billingScheduleId).Number_of_Periods__c;
            billingScheduleRecord.Period__c = billingScheduleToCloneMap.get(billingScheduleId).Period__c;
            billingScheduleRecord.Amount__c = billingScheduleToCloneMap.get(billingScheduleId).Amount__c;
            billingScheduleRecord.Start_Date__c = startDate;
            billingScheduleRecord.End_Date__c = billingScheduleToCloneMap.get(billingScheduleId).End_Date__c;
       
            insertBillingSchedules.add(billingScheduleRecord); 

        }

    
     if(insertBillingSchedules.size() > 0) Database.SaveResult[] billingScheduleSaveList = Database.insert(insertBillingSchedules, false);


    }

/*------------------------------------------------------------
Author:         John Christy
Company:        Apps Associates
Description:    Pulic class to process Service Contract requests
Test Class:     AssetTrigger_Test 
Inputs:         Map of Contract Lines to Clone, Map of Corresponding Assets (Return and Replacement Asset), Map of Asset Inserted or Updated with Order Line
Returns:        Inserted Contract Lines 

History:
<Date>          <Authors Name>      <Brief Description of Change>
08/25/2017      John Christy        Update for Advance Exchange Warranty Creation US-0002764
08/25/2017      Raj Sharan          Update for Advance Exchange Warranty Creation US-0002764
------------------------------------------------------------*/

    public static void cancelContractLines(Map<Id, ContractLineItem> contractLinesToCloneMap, Map<Id, Id> correspondingAssetExchangeMap, 
                                                Map<Id, Asset> assetAdvanceExchangeMap){

        ID   returnAssetId; 
        ID   newAssetId; 
        Date expiryDate; 
        Date Today = System.Today(); 

        List<ContractLineItem> updateCancelContractLines = new List<ContractLineItem>(); 
      
          for(ID contractLineId : contractLinesToCloneMap.keySet()){
      
          returnAssetId = contractLinesToCloneMap.get(contractLineId).AssetId;
          newAssetId = correspondingAssetExchangeMap.get(returnAssetId);
          If(assetAdvanceExchangeMap.get(newAssetId).Shipped_on_Date__c < contractLinesToCloneMap.get(contractLineId).StartDate){
          expiryDate = Today;
          }else{
          expiryDate = assetAdvanceExchangeMap.get(newAssetId).Shipped_on_Date__c; 
          }
           
          ContractLineItem cancelContractLineRecord = new ContractLineItem();

          cancelContractLineRecord.Id = contractLineId; 
          cancelContractLineRecord.EndDate = expiryDate;
          updateCancelContractLines.add(cancelContractLineRecord);

          }

          if(updateCancelContractLines.size() > 0) update updateCancelContractLines;

          Database.SaveResult[] contractLineSaveList = Database.update(updateCancelContractLines, false);


    }

/*------------------------------------------------------------
Author:         John Christy
Company:        Apps Associates
Description:    Pulic class to process Service Contract requests
Test Class:     AssetTrigger_Test 
Inputs:         List of Returned Asset Ids, Map of Corresponding Assets (Return and Replacement Asset), Map of Asset Inserted or Updated with Order Line
Returns:        NA 

History:
<Date>          <Authors Name>      <Brief Description of Change>
08/25/2017      John Christy        Update for Advance Exchange Warranty Creation US-0002764
08/25/2017      Raj Sharan          Update for Advance Exchange Warranty Creation US-0002764
------------------------------------------------------------*/
 
    public static void cancelEntitlements(List<Id> returnAssetIds, Map<Id, Id> correspondingAssetExchangeMap, 
                                                Map<Id, Asset> assetAdvanceExchangeMap, Set<Id> returnedAssetIdSet, Set<Id> returnedAssetAccountSet){

        ID   returnAssetId; 
        ID   newAssetId; 
        Date expiryDate; 
        Date Today = System.Today();
        List<Entitlement> entitlementUpdateRecords = new List<Entitlement>(); 
      
        Map<Id, Entitlement> entitlementUpdateMap = new Map<Id, Entitlement>([SELECT Id, StartDate, EndDate, AssetId FROM Entitlement WHERE AssetId IN :returnedAssetIdSet and AccountId IN :returnedAssetAccountSet]); 

        if(!entitlementUpdateMap.isEmpty()){
     
          for(ID entitlementId : entitlementUpdateMap.keySet()){
    
          returnAssetId = entitlementUpdateMap.get(entitlementId).AssetId;
          newAssetId = correspondingAssetExchangeMap.get(returnAssetId);
          expiryDate = assetAdvanceExchangeMap.get(newAssetId).Shipped_on_Date__c;

          If(assetAdvanceExchangeMap.get(newAssetId).Shipped_on_Date__c < entitlementUpdateMap.get(entitlementId).StartDate){
          expiryDate = Today;
          }else{
          expiryDate = assetAdvanceExchangeMap.get(newAssetId).Shipped_on_Date__c; 
          }


          Entitlement cancelEntitlementRecord = new Entitlement();

          cancelEntitlementRecord.Id = entitlementId; 
          cancelEntitlementRecord.EndDate = expiryDate;
          entitlementUpdateRecords.add(cancelEntitlementRecord);
        

        }

        if(entitlementUpdateRecords.size() > 0) Database.SaveResult[] entitlementSaveList = Database.update(entitlementUpdateRecords, false);

      }

    }

/*------------------------------------------------------------
Author:         John Christy
Company:        Apps Associates
Description:    Pulic class to process Service Contract requests
Test Class:     AssetTrigger_Test 
Inputs:         List of Returned Asset Ids, Map of Corresponding Assets (Return and Replacement Asset), Map of Asset Inserted or Updated with Order Line
Returns:        NA 

History:
<Date>          <Authors Name>      <Brief Description of Change>
08/25/2017      John Christy        Update for Advance Exchange Warranty Creation US-0002764
08/25/2017      Raj Sharan          Update for Advance Exchange Warranty Creation US-0002764
------------------------------------------------------------*/

    public static void cancelPreventiveMaintenancePlans(List<Id> returnAssetIds, Map<Id, Id> correspondingAssetExchangeMap, 
                                                Map<Id, Asset> assetAdvanceExchangeMap){

      ID   returnAssetId; 
      ID   newAssetId; 
      Date expiryDate;
      Date Today = System.Today(); 
      List<FSO__PreventiveMaintenancePlan__c> pmPlansUpdateRecords = new List<FSO__PreventiveMaintenancePlan__c>(); 
      
      Map<Id, FSO__PreventiveMaintenancePlan__c> pmPlansUpdateMap = new Map<Id, FSO__PreventiveMaintenancePlan__c>([
      SELECT Id, FSO__Start_Date__c, FSO__End_Date__c, Asset__c FROM FSO__PreventiveMaintenancePlan__c WHERE Asset__c IN :returnAssetIds]); 

      if(!pmPlansUpdateMap.isEmpty()){
     
        for(ID pmPlanId : pmPlansUpdateMap.keySet()){
    
        returnAssetId = pmPlansUpdateMap.get(pmPlanId).Asset__c;
        newAssetId = correspondingAssetExchangeMap.get(returnAssetId);
        expiryDate = assetAdvanceExchangeMap.get(newAssetId).Shipped_on_Date__c;

        If(assetAdvanceExchangeMap.get(newAssetId).Shipped_on_Date__c < pmPlansUpdateMap.get(pmPlanId).FSO__Start_Date__c){
        expiryDate = Today;
        }else{
        expiryDate = assetAdvanceExchangeMap.get(newAssetId).Shipped_on_Date__c; 
        }


        FSO__PreventiveMaintenancePlan__c cancelPMPlandRecord = new FSO__PreventiveMaintenancePlan__c();

        cancelPMPlandRecord.Id = pmPlanId; 
        cancelPMPlandRecord.FSO__End_Date__c = expiryDate;
        pmPlansUpdateRecords.add(cancelPMPlandRecord);
        

        }

        if(pmPlansUpdateRecords.size() > 0) Database.SaveResult[] pmPlanSaveList = Database.update(pmPlansUpdateRecords, false);

      }

    }

/*------------------------------------------------------------
Author:         John Christy
Company:        Apps Associates
Description:    Pulic class to process Service Contract requests
Test Class:     AssetTrigger_Test 
Inputs:         Map of Billing Schedule to update End Date, Map of Corresponding Assets (Return and Replacement Asset), Map of Asset Inserted or Updated with Order Line
Returns:        Inserted Contract Lines 

History:
<Date>          <Authors Name>      <Brief Description of Change>
08/25/2017      John Christy        Update for Advance Exchange Warranty Creation US-0002764
08/25/2017      Raj Sharan          Update for Advance Exchange Warranty Creation US-0002764
------------------------------------------------------------*/

    public static void cancelBillingSchedules(Map<Id,Service_Billing_Schedule__c> billingScheduleToCloneMap, Map<Id, Id> correspondingAssetExchangeMap, 
                                                Map<Id, Asset> assetAdvanceExchangeMap){

      ID   returnAssetId; 
      ID   newAssetId; 
      Date expiryDate;
      Date Today = System.Today(); 
      List<Service_Billing_Schedule__c> billingScheduleUpdateRecords = new List<Service_Billing_Schedule__c>(); 
      
      if(!billingScheduleToCloneMap.isEmpty()){
     
        for(ID billingScheduleId : billingScheduleToCloneMap.keySet()){
    
        returnAssetId = billingScheduleToCloneMap.get(billingScheduleId).Contract_Line_Item__r.AssetId;
        newAssetId = correspondingAssetExchangeMap.get(returnAssetId);
        expiryDate = assetAdvanceExchangeMap.get(newAssetId).Shipped_on_Date__c;

        If(assetAdvanceExchangeMap.get(newAssetId).Shipped_on_Date__c < billingScheduleToCloneMap.get(billingScheduleId).Start_Date__c){
        expiryDate = Today;
        }else{
        expiryDate = assetAdvanceExchangeMap.get(newAssetId).Shipped_on_Date__c; 
        }


        Service_Billing_Schedule__c billingScheduleRecord = new Service_Billing_Schedule__c();

        billingScheduleRecord.Id = billingScheduleId; 
        billingScheduleRecord.End_Date__c = expiryDate;
        billingScheduleUpdateRecords.add(billingScheduleRecord);
        

        }

        if(billingScheduleUpdateRecords.size() > 0) Database.SaveResult[] billingScheduleSaveList = Database.update(billingScheduleUpdateRecords, false);

      }

    }

}