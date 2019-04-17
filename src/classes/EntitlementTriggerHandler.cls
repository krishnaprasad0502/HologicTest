/*------------------------------------------------------------
Author          Rob Strickler
Company:        Salesforce
Description:    Entitlement trigger actions:
                On Entitlement creation, auto create related Maintenance Plans per Contract Line Items (ie. per Asset)
Related:        EntitlementTriggerHandler.cls
                EntitlementTriggerHandler_Test.cls

History:
<Date           <Authors Name       <Brief Description of Change>
05/30/2018      Rob Strickler       Initial Creation
2/5/2019        krishna             US-0006365(o set the Suggested Maintenance Date of the first WO to be Start Date + Frequency - 1 day)
------------------------------------------------------------*/

public with sharing class EntitlementTriggerHandler {

    public static void createMaintenancePlans(List<Entitlement> ents) {
        //Requery entitlements to get more data
        Map<Id, Entitlement> entsById = new Map<Id, Entitlement>([
            SELECT Id
                  ,Status
                  ,RecordTypeId
                  ,RecordType.Name
                  ,AssetId
                  ,Asset.Product2.PM_Work_Type__c
                  ,ServiceContractId
                  ,ServiceContract.ContactId
                  ,Coverage_Group__c
                  ,Coverage_Group__r.Maintenance_Frequency__c
                  ,Coverage_Group__r.Maintenance_Frequency_Type__c
                  ,ContractLineItemId
                  ,ContractLineItem.EndDate
                  ,ContractLineItem.ServiceContractId
                  ,ContractLineItem.StartDate
                  ,ContractLineItem.Ship_To_Site_Location__c
                  ,ContractLineItem.SBQQSC__Product__r.PM_Work_Type__c
                  ,ContractLineItem.AssetId
                  ,ContractLineItem.Asset.Product2Id
                  ,ContractLineItem.Asset.AccountId
                  ,ContractLineItem.Asset.Name
                  ,ContractLineItem.Asset.SerialNumber
                  ,ContractLineItem.ServiceContract.ContactId
                  ,ContractLineItem.ServiceContract.AccountId
                  ,ContractLineItem.ServiceContract.Account.ShippingStreet
                  ,ContractLineItem.ServiceContract.Account.ShippingCity
                  ,ContractLineItem.ServiceContract.Account.ShippingStateCode
                  ,ContractLineItem.ServiceContract.Account.ShippingPostalCode
                  ,ContractLineItem.ServiceContract.Account.ShippingCountryCode
              FROM Entitlement 
             WHERE Id IN :ents
               AND RecordType.DeveloperName = 'B_SH_PM'
               AND ContractLineItem.StartDate != null
               AND Coverage_Group__r.Maintenance_Frequency__c != null
               AND Coverage_Group__r.Maintenance_Frequency_Type__c != null
               AND Asset.Product2.PM_Work_Type__c != null
        ]);
        
        if(entsById.isEmpty()){
            return;
        }
        
        List<MaintenancePlan> maintPlans = new List<MaintenancePlan>();
        for(Entitlement ent : entsById.values()){
            MaintenancePlan maintPlan = new MaintenancePlan();
    
            maintPlan.AccountId                     = ent.ContractLineItem.ServiceContract.AccountId;
            maintPlan.ContactId                     = ent.ServiceContract.ContactId;
            maintPlan.Description                   = 'Maintenance Plan - ' + ent.ContractLineItem.Asset.Name;
            maintPlan.DoesAutoGenerateWorkOrders    = false;
            maintPlan.EndDate                       = ent.ContractLineItem.EndDate;
            maintPlan.Entitlement__c                = ent.Id;
            maintPlan.Frequency                     = (Integer)ent.Coverage_Group__r.Maintenance_Frequency__c;
            maintPlan.FrequencyType                 = ent.Coverage_Group__r.Maintenance_Frequency_Type__c;
            maintPlan.GenerationTimeframe           = 10;
            maintPlan.GenerationTimeframeType       = 'Years';
            maintPlan.MaintenancePlanTitle          = ent.ContractLineItem.Asset.SerialNumber;
            maintPlan.NextSuggestedMaintenanceDate  = addFrequency(ent.ContractLineItem.StartDate, maintPlan.Frequency, maintPlan.FrequencyType);
            maintPlan.OwnerId                       = UserInfo.getuserId();
            maintPlan.ServiceContractId             = ent.ContractLineItem.ServiceContractId;
            maintPlan.StartDate                     = ent.ContractLineItem.StartDate;
            maintPlan.Status__c                     = 'Scheduled';
            
            maintPlan.MaintenanceWindowStartDays    = 30;
            maintPlan.MaintenanceWindowEndDays      = 0;
            
            if(ent.AssetId != null){
                maintPlan.WorkTypeId                = ent.Asset.Product2.PM_Work_Type__c;
            }
            
            maintPlans.add(maintPlan);
        }
        //Insert maintenance plans
        insert maintPlans;
        
        //Create related Maintenance Assets for each new Maintenance Plan
        List<MaintenanceAsset> maintAssets = new List<MaintenanceAsset>();
        for(MaintenancePlan maintPlan : maintPlans){
            Entitlement ent = entsById.get(maintPlan.Entitlement__c);
            MaintenanceAsset maintAsset = new MaintenanceAsset();
            
            maintAsset.AssetId              = ent.ContractLineItem.AssetId;
            maintAsset.ContractLineItemId   = ent.ContractLineItemId;
            maintAsset.MaintenancePlanId    = maintPlan.Id;
            maintAsset.WorkTypeId           = maintPlan.WorkTypeId;
            
            maintAssets.add(maintAsset);
        }
        //Insert maintenance assets
        insert maintAssets;
        

        //Create Work Orders
        List<WorkOrder> wos = new List<WorkOrder>();
        Id woRTId = GlobalUtility.getRecordTypeId('WorkOrder', 'B_SH_PM');
        for(MaintenancePlan maintPlan : maintPlans){
            Entitlement ent = entsById.get(maintPlan.Entitlement__c);
            //krishna 2/5/2019  as part of US-0006365(o set the Suggested Maintenance Date of the first WO to be Start Date + Frequency - 1 day)
            //for(Date tempDate = maintPlan.NextSuggestedMaintenanceDate.addMonths(-2); tempDate <= maintPlan.EndDate; tempDate = addFrequency(tempDate, maintPlan.Frequency, maintPlan.FrequencyType)){
                for(Date tempDate = maintPlan.NextSuggestedMaintenanceDate.addDays(-1); tempDate <= maintPlan.EndDate; tempDate = addFrequency(tempDate, maintPlan.Frequency, maintPlan.FrequencyType)){
                
                if(tempDate <= Date.today() && GlobalUtility.isTriggerActive('EntitlementTriggerFirstTime')){
                    //Skip during first load
                    continue;
                }
                
                WorkOrder wo = new WorkOrder();
                wo.AccountId                = ent.ContractLineItem.Asset.AccountId;
                wo.AssetId                  = ent.ContractLineItem.AssetId;
                wo.ContactId                = maintPlan.ContactId;
                wo.Description              = 'PM ' + ent.ContractLineItem.Asset.Name;
                wo.EntitlementId            = ent.Id;
                wo.LocationId               = maintPlan.LocationId;
                wo.MaintenancePlanId        = maintPlan.Id;
                wo.StartDate                = tempDate;
                wo.SuggestedMaintenanceDate = tempDate;
                wo.RecordTypeId             = woRTId;
                wo.WorkTypeId               = maintPlan.WorkTypeId;
                wo.Street                   = ent.ContractLineItem.ServiceContract.Account.ShippingStreet;
                wo.City                     = ent.ContractLineItem.ServiceContract.Account.ShippingCity;
                wo.StateCode                = ent.ContractLineItem.ServiceContract.Account.ShippingStateCode;
                wo.PostalCode               = ent.ContractLineItem.ServiceContract.Account.ShippingPostalCode;
                wo.CountryCode              = ent.ContractLineItem.ServiceContract.Account.ShippingCountryCode;
                
                wos.add(wo);
            }
        }
        insert wos;
    }
    
    public static Date addFrequency(Date dat, Integer freq, String freqType){
        if(freqType == 'Days'){
            return dat.addDays(freq);
        } else if(freqType == 'Weeks'){
            return dat.addDays(7 * freq);
        } else if(freqType == 'Months'){
            return dat.addMonths(freq);
        } else if(freqType == 'Years'){
            return dat.addYears(freq);
        }
        return null;
    }
}