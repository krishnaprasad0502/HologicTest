public class ContractLineItemTriggerActions {
    
    public static void setServiceType(List<ContractLineItem> clis){
        //Find CLIs missing service type
        Map<Id, PricebookEntry> pbesById = new Map<Id, PricebookEntry>();
        for(ContractLineItem cli : clis){
            if(cli.Service_Type__c == null && cli.PricebookEntryId != null){
                pbesById.put(cli.PricebookEntryId, null);
            }
        }
        
        //Query for related PBE records
        if(pbesById.size() > 0){
            pbesById = new Map<Id, PricebookEntry>([
                SELECT Id
                      ,Product2Id
                      ,Product2.Service_Type__c
                  FROM PricebookEntry
                 WHERE Id IN :pbesById.keySet()
            ]);
            
            for(ContractLineItem cli : clis){
                if(cli.Service_Type__c == null && cli.PricebookEntryId != null){
                    PricebookEntry pbe = pbesById.get(cli.PricebookEntryId);
                    if(pbe != null && pbe.Product2Id != null && pbe.Product2.Service_Type__c != null){
                        cli.Service_Type__c = pbe.Product2.Service_Type__c;
                    }
                }
            }
        }
    }
    
    public static void updateAsset(List<ContractLineItem> clis){
        //Update asset to covered asset
        for(ContractLineItem cli : clis){
            if(cli.Covered_Asset__c != null){
                cli.AssetId = cli.Covered_Asset__c;
            }
        }
    }
    
    public static void checkToUpdateParentAssets(List<ContractLineItem> clis){
        Set<Id> assetIds = new Set<Id>();
        for(ContractLineItem cli : clis){
            if(cli.AssetId != null && cli.Status == 'Active' && cli.EndDate > Date.today()){
                assetIds.add(cli.assetId);
            }
        }
        
        if(assetIds.size() > 0){
            updateParentAssets(assetIds);
        }
    }
    
    public static void checkToUpdateParentAssets(List<ContractLineItem> clis, Map<Id, ContractLineItem> oldMap){
        Set<Id> assetIds = new Set<Id>();
        for(ContractLineItem cli : clis){
            ContractLineItem old = oldMap.get(cli.Id);
            if(cli.AssetId != null && cli.Status != old.Status && cli.EndDate > Date.today()){
                assetIds.add(cli.assetId);
            }
        }
        
        if(assetIds.size() > 0){
            updateParentAssets(assetIds);
        }
    }
    
    public static void updateParentAssets(Set<Id> assetIds){
        List<Asset> assets = [
            SELECT Id
                  ,(SELECT Id
                      FROM ContractLineItems
                     WHERE Status = 'Active'
                       AND EndDate > :Date.today()
                     ORDER BY EndDate DESC
                     LIMIT 1
                   )
              FROM Asset
             WHERE Id IN :assetIds
        ];
        for(Asset asst : assets){
            if(asst.ContractLineItems.size() > 0){
                asst.SBQQSC__CurrentContractLineItem__c = asst.ContractLineItems[0].Id;
            } else {
                asst.SBQQSC__CurrentContractLineItem__c = null;
            }
            asst.Contract_Line_Processing_Completed__c = true;
        }
        update assets;
    }
    
    public static void createEntitlements(List<ContractLineItem> clis){
        //Query for greater details
        Map<Id, ContractLineItem> clisById = new Map<Id, ContractLineItem>([
            SELECT Id
                  ,AssetId
                  ,Asset.AccountId
                  ,Asset.SerialNumber
                  ,EndDate
                  ,PricebookEntry.Product2Id
                  ,ServiceContractId
                  ,Service_Type__c
                  ,StartDate
                  ,ServiceContract.AccountId
              FROM ContractLineItem
             WHERE Id IN :clis
               AND PricebookEntry.Product2Id != null
        ]);
        
        if(clisById.isEmpty()){
            return;
        }
        
        //Gather product Ids
        Map<Id, List<Coverage_Template__c>> templateListsByProductId = new Map<Id, List<Coverage_Template__c>>();
        for(ContractLineItem cli : clisById.values()){
            if(cli.PricebookEntryId != null && cli.PricebookEntry.Product2Id != null){
                templateListsByProductId.put(cli.PricebookEntry.Product2Id, null);
            }
        }
        
        //Map coverage templates by product Id
        for(Coverage_Template__c template : [
            SELECT Id
                  ,Business_Hours__c
                  ,Case_Entitlement_Process_Name__c
                  ,Coverage_Group__c
                  ,Discount__c
                  ,Max_Covered_Amount__c
                  ,Name
                  ,RecordType.DeveloperName
                  ,Service_Contract_Product__c
                  ,Work_Order_Entitlement_Process_Name__c
              FROM Coverage_Template__c
             WHERE Service_Contract_Product__c IN :templateListsByProductId.keySet()
        ]){
            List<Coverage_Template__c> templates = templateListsByProductId.get(template.Service_Contract_Product__c);
            if(templates == null){
                templates = new List<Coverage_Template__c>();
            }
            templates.add(template);
            templateListsByProductId.put(template.Service_Contract_Product__c, templates);
        }
        
        //Map SLAs by key: object type | name
        Map<String, SlaProcess> slasByKey = new Map<String, SlaProcess>();
        for(SlaProcess sla : [
            SELECT Id
                  ,Name
                  ,SObjectType
              FROM SlaProcess
             WHERE SObjectType = 'Case'
                OR SObjectType = 'WorkOrder'
        ]){
            String key = sla.SObjectType + '|' + sla.Name;
            slasByKey.put(key, sla);
        }
        
        //Create entitlements
        List<Entitlement> ents = new List<Entitlement>();
        for(ContractLineItem cli : clisById.values()){
            if(templateListsByProductId.get(cli.PricebookEntry.Product2Id) != null){
                for(Coverage_Template__c template : templateListsByProductId.get(cli.PricebookEntry.Product2Id)){
                    //Create entitlement
                    Entitlement ent = new Entitlement();
                    ent.Name                    = template.Name + ' for SN: ' + cli.Asset.SerialNumber;
                    
                     if(cli.AssetId != null){
                ent.AccountId               = cli.Asset.AccountId;
                ent.AssetId                 = cli.AssetId;
            } else {
                ent.AccountId               = cli.ServiceContract.AccountId;
            }
                    
                           
                    ent.BusinessHoursId         = template.Business_Hours__c;
                    ent.ServiceContractId       = cli.ServiceContractId;
                    ent.ContractLineItemId      = cli.Id;
                    ent.RecordTypeId            = GlobalUtility.getRecordTypeId('Entitlement', template.RecordType.DeveloperName);
                    ent.StartDate               = cli.StartDate;
                    ent.EndDate                 = cli.EndDate;
                    ent.Type                    = cli.Service_Type__c;
                    ent.Coverage_Group__c       = template.Coverage_Group__c;
                    ent.Coverage_Template__c    = template.Id;
                    ents.add(ent);
                    
                    if(template.RecordType.DeveloperName == 'B_SH_Discount'){
                        //If needed, add discount info
                        ent.Discount__c             = template.Discount__c;
                        ent.Max_Covered_Amount__c   = template.Max_Covered_Amount__c;
                    } else if(template.RecordType.DeveloperName == 'B_SH_SLA'){
                        //If needed, set SLA process to case SLA
                        SlaProcess caseSLA = slasByKey.get('Case|' + template.Case_Entitlement_Process_Name__c);
                        if(caseSLA != null){
                            ent.SlaProcessId = caseSLA.Id;
                        }
                        
                        //If needed, create additional entitlement for work order SLA
                        SlaProcess workOrderSLA = slasByKey.get('WorkOrder|' + template.Work_Order_Entitlement_Process_Name__c);
                        if(workOrderSLA != null){
                            Entitlement woSlaEnt = ent.clone();
                            woSlaEnt.SlaProcessId = workOrderSLA.Id;
                            ents.add(woSlaEnt);
                        }
                    }
                }
            }
        }
        
        insert ents;
    }
    
    public static void setServiceContractApprovalStatus(List<ContractLineItem> clis){
        //Gather service contract Ids
        Set<Id> sconIds = new Set<Id>();
        for(ContractLineItem cli : clis){
            if(cli.Asset_Created__c == false && cli.ServiceContractId != null){
                sconIds.add(cli.ServiceContractId);
            }
        }
        
        //Update service contracts
        List<ServiceContract> scons = [
            SELECT Id
              FROM ServiceContract
             WHERE Id IN :sconIds
        ];
        for(ServiceContract scon : scons){
            scon.ApprovalStatus = 'Draft';
        }
        update scons;
    }
    
    public static void terminateEntitlementAndPMPlans(List<ContractLineItem> clis, Map<Id, ContractLineItem> oldMap){
        //Filter for incoming CLIs with a new terminated date
        Map<Id, ContractLineItem> validCLIsById = new Map<Id, ContractLineItem>();
        for(ContractLineItem cli : clis){
            ContractLineItem old = oldMap.get(cli.Id);
            if(cli.SBQQSC__TerminatedDate__c != old.SBQQSC__TerminatedDate__c){
                validCLIsById.put(cli.Id, cli);
            }
        }
        
        if(validCLIsById.isEmpty()){
            return;
        }
        
        //Query for and update related entitlements
        List<Entitlement> ents = [
            SELECT Id
                  ,ContractLineItemId
                  ,EndDate
              FROM Entitlement
             WHERE ContractLineItemId IN :validCLIsById.keySet()
        ];
        for(Entitlement ent : ents){
            ContractLineItem cli = validCLIsById.get(ent.ContractLineItemId);
            ent.Original_End_Date__c    = ent.EndDate;
            ent.Terminated_Date__c      = cli.SBQQSC__TerminatedDate__c;
            ent.EndDate                 = cli.EndDate;
        }
        update ents;
    }

}





/*------------------------------------------------------------
Author:      Denise Bacher
Company:    Salesforce.com
Description:  ContractLineItem Trigger functions
Test Class:    ContractLineItemTrigger_Test

History:
<Date>      <Authors Name>    <Brief Description of Change>
07/25/2016    Denise Bacher    Initial Creation (US54)
07/29/2016    Denise Bacher    Add createEntitlements (US164)
08/03/2016    Matt Yogi      Added Method updateAsset
08/08/2016    Denise Bacher    Added setServiceContractApprovalStatus (US1444)
10/28/2016    Denise Bacher    Added setServiceType (US-0001108)
04/11/2017    Ronald Mendoza   Commented out FSO Related Fields due to Managed Package Removal (US-0003947)

06/20/2018   Ryan Lambert    Remove all code / reference to FSLIS
------------------------------------------------------------*/
/*
public with sharing class ContractLineItemTriggerActions {

        public static void checkToUpdateParentAssets(List<ContractLineItem> clis){
        Set<Id> assetIds = new Set<Id>();
        for(ContractLineItem cli : clis){
            if(cli.AssetId != null && cli.Status == 'Active' && cli.EndDate > Date.today()){
                assetIds.add(cli.assetId);
            }
        }
        
        if(assetIds.size() > 0){
            updateParentAssets(assetIds);
        }
    }
    
    public static void checkToUpdateParentAssets(List<ContractLineItem> clis, Map<Id, ContractLineItem> oldMap){
        Set<Id> assetIds = new Set<Id>();
        for(ContractLineItem cli : clis){
            ContractLineItem old = oldMap.get(cli.Id);
            if(cli.AssetId != null && cli.Status != old.Status && cli.EndDate > Date.today()){
                assetIds.add(cli.assetId);
            }
        }
        
        if(assetIds.size() > 0){
            updateParentAssets(assetIds);
        }
    }
    
    public static void updateParentAssets(Set<Id> assetIds){
        List<Asset> assets = [
            SELECT Id
                  ,(SELECT Id
                      FROM ContractLineItems
                     WHERE Status = 'Active'
                       AND EndDate > :Date.today()
                     ORDER BY EndDate DESC
                     LIMIT 1
                   )
              FROM Asset
             WHERE Id IN :assetIds
        ];
        for(Asset asst : assets){
            if(asst.ContractLineItems.size() > 0){
                asst.SBQQSC__CurrentContractLineItem__c = asst.ContractLineItems[0].Id;
            } else {
                asst.SBQQSC__CurrentContractLineItem__c = null;
            }
            asst.Contract_Line_Processing_Completed__c = true;
        }
        update assets;
    }

    /*------------------------------------------------------------
        Author:         Dave Mansell
        Company:        Salesforce.com
        Description:    On insert of a ContractLineItem, create the related Renewal Opportunity
        Inputs:         contractLineItems - The list of ContractLineItem inserted
        Returns:        N/A
  
        History:
        <Date>          <Authors Name>      <Brief Description of Change>
        06/14/2018      Dave Mansell        Initial Creation (US4448)
    ------------------------------------------------------------*/
    /*public static void createRenewalOpportunity(List<ContractLineItem> contractLineItems){
        Id rortId = GlobalUtility.getRecordTypeId('Opportunity', 'Medical_Aesthetics_Svc_Contract_Opportunity');
        
        List<ServiceContract> servCons = [
            SELECT Id
              FROM ServiceContract
             WHERE Id IN (SELECT ServiceContractId FROM ContractLineItem
                           WHERE Id IN :contractLineItems
                             AND PricebookEntry.Product2.Product_Source_Division__r.Source_Division__c = 'MEDICAL AESTHETICS'
                             AND Service_Type__c = 'Warranty'
                         )
        ];
        
        for(ServiceContract servCon : servCons){
            servCon.SBQQSC__PreserveBundleStructureUponRenewals__c  = false;
            servCon.SBQQSC__RenewalForecast__c                      = true;
            servCon.SBQQSC__RenewalOpportunityRecordTypeId__c       = rortId;
        }
        update servCons;
    }*/
  
  /*------------------------------------------------------------
  Author:      Denise Bacher
  Company:    Salesforce.com
  Description:  On insert of a ContractLineItem, create the related Entitlements 
          Runs after insert
  Inputs:      contractLineItems - The list of ContractLineItem inserted
  Returns:    N/A
  
  History:
  <Date>      <Authors Name>    <Brief Description of Change>
  07/29/2016    Denise Bacher    Initial Creation (US164)
  ------------------------------------------------------------
  public static void createEntitlements(List<ContractLineItem> contractLineItems){
    Set<Id> productIds = new Set<Id>();
    Map<Id, ContractLineItem> cliOtherValues = new Map<Id, ContractLineItem>([Select Id, PricebookEntry.Product2Id, Asset.AccountId, Asset.SerialNumber 
      From ContractLineItem 
      Where Id IN: contractLineItems]);
    
    for(ContractLineItem cli : cliOtherValues.values()){
      productIds.add(cli.PricebookEntry.Product2Id);
    }
    
    // query coverage templates
    Set<String> caseSlaProcessNames = new Set<String>();
    Set<String> woSlaProcessNames = new Set<String>();
    Map<Id, List<Coverage_Template__c>> productIdToCoverageTemplate = new Map<Id, List<Coverage_Template__c>>();
    for(Coverage_Template__c ct : [Select Id, Name, Business_Hours__c, Coverage_Group__c, Service_Contract_Product__c, RecordTypeId, RecordType.DeveloperName 
      , Case_Entitlement_Process_Name__c, Work_Order_Entitlement_Process_Name__c, Discount__c, Max_Covered_Amount__c
      From Coverage_Template__c 
      Where Service_Contract_Product__c IN: productIds])
    {
      if(String.isNotBlank(ct.Case_Entitlement_Process_Name__c)){
        caseSlaProcessNames.add(ct.Case_Entitlement_Process_Name__c);
      }
      
      if(String.isNotBlank(ct.Work_Order_Entitlement_Process_Name__c)){
        woSlaProcessNames.add(ct.Work_Order_Entitlement_Process_Name__c);
      }
      
      if(!productIdToCoverageTemplate.containsKey(ct.Service_Contract_Product__c)){
        productIdToCoverageTemplate.put(ct.Service_Contract_Product__c, new List<Coverage_Template__c>());
      }
      productIdToCoverageTemplate.get(ct.Service_Contract_Product__c).add(ct);
    }
    //System.debug('productIdToCoverageTemplate '+Json.serialize(productIdToCoverageTemplate));
    //System.debug('caseSlaProcessNames '+Json.serialize(caseSlaProcessNames));
    //System.debug('woSlaProcessNames '+Json.serialize(woSlaProcessNames));
    
    // query SLA Process
    Map<String, SlaProcess> caseSLAs = new Map<String, SlaProcess>();
    Map<String, SlaProcess> workorderSLAs = new Map<String, SlaProcess>();
    for(SlaProcess sla : [Select Id, Name, SObjectType From SlaProcess Where (Name IN: caseSlaProcessNames OR Name IN: woSlaProcessNames)]){
      if(sla.SObjectType == 'Case'){
        caseSLAs.put(sla.Name, sla);
      }
      else if(sla.SObjectType == 'WorkOrder'){
        workorderSLAs.put(sla.Name, sla);
      }
    }
    //System.debug('caseSLAs '+Json.serialize(caseSLAs));
    //System.debug('workorderSLAs '+Json.serialize(workorderSLAs));
    
    // create Entitlements
    List<Entitlement> entitlements = new List<Entitlement>();
    for(ContractLineItem cli : contractLineItems){
      ContractLineItem cliOtherVals = cliOtherValues.get(cli.Id);
      
      List<Coverage_Template__c> coverageTemplates = productIdToCoverageTemplate.containsKey(cliOtherVals.PricebookEntry.Product2Id) ? productIdToCoverageTemplate.get(cliOtherVals.PricebookEntry.Product2Id) : new List<Coverage_Template__c>();
      
      for(Coverage_Template__c ct : coverageTemplates){
        // create workorder entitlement
        SlaProcess workOrderProcess = workorderSLAs.get(ct.Work_Order_Entitlement_Process_Name__c);
        
        if(workOrderProcess != null && ct.RecordTypeId == GlobalUtility.getRecordTypeId('Coverage_Template__c', 'B_SH_SLA')){
          Entitlement workOrderEnt = new Entitlement(
            Name = ct.Name + ' for SN: ' + cliOtherVals.Asset.SerialNumber
            , AccountId = cliOtherVals.Asset.AccountId
            , AssetId = cli.AssetId
            , SlaProcessId = workOrderProcess.Id
            , BusinessHoursId = ct.Business_Hours__c
            , ServiceContractId = cli.ServiceContractId
            , ContractLineItemId = cli.Id
            , RecordTypeId = GlobalUtility.getRecordTypeId('Entitlement', ct.RecordType.DeveloperName)
            , StartDate = cli.StartDate
            , EndDate = cli.EndDate
            , Type = cli.Service_Type__c
            , Coverage_Group__c = ct.Coverage_Group__c
            , Coverage_Template__c = ct.Id
          );
          
          entitlements.add(workOrderEnt);
        }
        
        // create entitlement
        Entitlement entitlement = new Entitlement(
          Name = ct.Name + ' for SN: ' + cliOtherVals.Asset.SerialNumber
          , AccountId = cliOtherVals.Asset.AccountId
          , AssetId = cli.AssetId
          , BusinessHoursId = ct.Business_Hours__c
          , ServiceContractId = cli.ServiceContractId
          , ContractLineItemId = cli.Id
          , RecordTypeId = GlobalUtility.getRecordTypeId('Entitlement', ct.RecordType.DeveloperName)
          , StartDate = cli.StartDate
          , EndDate = cli.EndDate
          , Type = cli.Service_Type__c
          , Coverage_Group__c = ct.Coverage_Group__c
          , Coverage_Template__c = ct.Id
        );
        
        // if the coverage template is a SLA, set the sla process
        SlaProcess caseProcess = caseSLAs.get(ct.Case_Entitlement_Process_Name__c);
        if(caseProcess != null && ct.RecordTypeId == GlobalUtility.getRecordTypeId('Coverage_Template__c', 'B_SH_SLA')){
          entitlement.SlaProcessId = caseProcess.Id;
        }
        
        // if the coverage template is a discount, set the discount adn max covered amount
        if(ct.RecordTypeId == GlobalUtility.getRecordTypeId('Coverage_Template__c', 'B_SH_Discount')){
          entitlement.Discount__c = ct.Discount__c;
          entitlement.Max_Covered_Amount__c = ct.Max_Covered_Amount__c;
        }
        
        entitlements.add(entitlement);
      }
    }
    insert entitlements;
    //System.debug('entitlements '+Json.serialize(entitlements));
  }
  
  /*------------------------------------------------------------
  Author:      Denise Bacher
  Company:    Salesforce.com
  Description:  On termination of a ContractLineItem, update the termination dates on related Entitlements and PM Plans 
          Runs after update
  Inputs:      contractLineItems - The list of ContractLineItem updated
          oldCLIs - Map of ContractLineItem containing old values
  Returns:    N/A
  
  History:
  <Date>      <Authors Name>    <Brief Description of Change>
  07/25/2016    Denise Bacher    Initial Creation (US54)
  ------------------------------------------------------------
  public static void terminateEntitlementAndPMPlans(List<ContractLineItem> contractLineItems, Map<Id, ContractLineItem> oldCLIs){
    Map<Id, ContractLineItem> terminatedContractLines = new Map<Id, ContractLineItem>();
    
    // compile a list of ContractLineItem records that are newly terminated, or have had their termination date changed
    for(ContractLineItem cli : contractLineItems){
      ContractLineItem oldCLI = oldCLIs != null ? oldCLIs.get(cli.Id) : null;
      
      if(oldCLI != null && cli.SBQQSC__TerminatedDate__c != oldCLI.SBQQSC__TerminatedDate__c){
        terminatedContractLines.put(cli.Id, cli);
      }
    }
    
    // query reltaed entitlements
    List<Entitlement> entitlements = [Select Id, ContractLineItemId, Terminated_Date__c, Original_End_Date__c, EndDate 
      From Entitlement 
      Where ContractLineItemId IN: terminatedContractLines.keySet()];
    
    // update the dates on the entitlement
    for(Entitlement e : entitlements){
      e.Original_End_Date__c = e.EndDate;
      e.Terminated_Date__c = terminatedContractLines.get(e.ContractLineItemId).SBQQSC__TerminatedDate__c;
      e.EndDate = terminatedContractLines.get(e.ContractLineItemId).EndDate;
    }
        
    update entitlements;
    //update pmPlans;
  }
  
  /*------------------------------------------------------------
  Author:      Mathanan Yogaratnam
  Company:    Salesforce.com
  Description:  On insert of a ContractLineItem, copy the Asset value from Covered_Asset__c (set by Steelbrick) to the Standard Asset field
          Runs before insert
  Inputs:      contractLineItems - The list of ContractLineItem inserted
  Returns:    N/A
  
  History:
  <Date>      <Authors Name>      <Brief Description of Change>
  08/03/2016    Mathanan Yogaratnam    Initial Creation (US164)
  ------------------------------------------------------------
  public static void updateAsset(List<ContractLineItem> contractLineItems){
    for(ContractLineItem cli : contractLineItems){
      if (cli.Covered_Asset__c != null){
        cli.AssetId = cli.Covered_Asset__c;
      }
    }
  }
  
  /*------------------------------------------------------------
  Author:      Denise Bacher
  Company:    Salesforce.com
  Description:  On insert of a ContractLineItem, update the ServiceContract.ApprovalStatus 
          Runs after insert
  Inputs:      contractLineItems - The list of ContractLineItem inserted
  Returns:    N/A
  
  History:
  <Date>      <Authors Name>    <Brief Description of Change>
  08/08/2016    Denise Bacher    Initial Creation (US1444)
  ------------------------------------------------------------
  public static void setServiceContractApprovalStatus(List<ContractLineItem> contractLineItems){
    Set<Id> serviceContractIds = new Set<Id>();
    for(ContractLineItem cli : contractLineItems){
      // if this contract line wasn't created as part of the asset insertion process, set the service contract approval status to draft
      if(cli.Asset_Created__c == false){
        serviceContractIds.add(cli.ServiceContractId);
      }
    }
    
    List<ServiceContract> serviceContracts = new List<ServiceContract>();
    for(Id scId : serviceContractIds){
      serviceContracts.add(new ServiceContract(Id = scId, ApprovalStatus = 'Draft'));
    }
    
    update serviceContracts; 
  }
  
  /*------------------------------------------------------------
  Author:      Denise Bacher
  Company:    Salesforce.com
  Description:  On insert of a ContractLineItem set the Service_Type__c 
          Runs before insert
  Inputs:      contractLineItems - The list of ContractLineItem inserted
  Returns:    N/A
  
  History:
  <Date>      <Authors Name>    <Brief Description of Change>
  10/28/2016    Denise Bacher    Initial Creation (US-0001108)
  ------------------------------------------------------------
  public static void setServiceType(List<ContractLineItem> contractLineItems){
    Set<Id> pbeIds = new Set<Id>();
    List<ContractLineItem> cliNeedsType = new List<ContractLineItem>();
    
    for(ContractLineItem cli : contractLineItems){
      if(String.isBlank(cli.Service_Type__c) && cli.PricebookEntryId != null){
        pbeIds.add(cli.PricebookEntryId);
        cliNeedsType.add(cli);
      }
    }
    
    if(cliNeedsType.size() > 0){
      Map<Id, PricebookEntry> pricebookEntries = new Map<Id, PricebookEntry>([Select Id, Product2Id, Product2.Service_Type__c From PricebookEntry Where Id IN: pbeIds]);
      
      for(ContractLineItem cli : cliNeedsType){
        cli.Service_Type__c = pricebookEntries.get(cli.PricebookEntryId).Product2.Service_Type__c;
      }
    }
  }
}
*/