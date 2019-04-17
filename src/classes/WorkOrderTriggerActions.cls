/*------------------------------------------------------------
Author          Dave Mansell
Company:        Salesforce.com
Description:    Functions related to WorkOrder records

History:
<Date           <Authors Name       <Brief Description of Change>
04/09/2018      Dave Mansell        Initial Creation (US-0004278)/
04/02/2019      krishna             Auto Close Case when Work Order Estimate is rejected,
                                    and there are no other open work orders related to the Case(US-0007008)
04/16/2019        Krishna            (US--0006815)Implement status mapping via metadata                                      
------------------------------------------------------------*/

public class WorkOrderTriggerActions {
    
    /*------------------------------------------------------------
    Author:             Dave Mansell, Salesforce
    Description:        Checks to see if incoming records need to be assigned to a queue
    Inputs:             List of records, Map of old records
    Returns:            N/A
    Test Class(es):     WorkOrderTriggerActions_Test.testCheckToSetOwnership
    ------------------------------------------------------------*/
    public static void checkToSetOwnership(List<WorkOrder> wos, Map<Id, WorkOrder> oldMap){
        //Find valid WO records
        Set<Id> woIds = new Set<Id>();
        for(WorkOrder wo : wos){
            WorkOrder old = oldMap.get(wo.Id);
            if(wo.Product__c != old.Product__c && wo.Product__c != null){
                woIds.add(wo.Id);
            }
        }
        
        if(woIds.size() > 0){
            setOwnership(woIds);
        }
    }
    
    public static void setOwnership(List<WorkOrder> wos){
        Set<Id> woIds = new Set<Id>();
        for(WorkOrder wo : wos){
            if(wo.Product__c != null){
                woIds.add(wo.Id);
            }
        }
        if(woIds.size() > 0){
            setOwnership(woIds);
        }
    }
    
    @future
    public static void setOwnership(Set<Id> woIds){
        //Requery WOs
        List<WorkOrder> wos = [
            SELECT Id
                  ,RecordTypeId
                  ,Product__r.Product_Source_Division__r.Division__c
              FROM WorkOrder
             WHERE Id IN :woIds
               AND Product__r.Product_Source_Division__r.Division__c != null
        ];
        
        Map<String, Group> queusByDevName = new Map<String, Group>();
        for(Group grp : [
            SELECT Id
                  ,DeveloperName
              FROM Group
             WHERE Type='Queue'
               AND (DeveloperName = 'B_SH_Install_Upgrade_Case_Queue'
                OR  DeveloperName = 'Diagnostic_Install_Coordinator'
                OR  DeveloperName = 'Installation_MA'
                OR  DeveloperName = 'Clinical_Installs_MA')
        ]){
            queusByDevName.put(grp.DeveloperName, grp);
        }
        
        //Assign WOs based on division
        for(WorkOrder wo : wos){
            if(wo.RecordTypeId == GlobalUtility.getRecordTypeId('WorkOrder', 'B_SH_FE_Install_Upgrade_Move') ||
               wo.RecordTypeId == GlobalUtility.getRecordTypeId('WorkOrder', 'B_SH_Applications')
            ){
                String div = wo.Product__r.Product_Source_Division__r.Division__c;
                if(div == 'BSH'){
                    wo.OwnerId = queusByDevName.get('B_SH_Install_Upgrade_Case_Queue').Id;
                } else if(div == 'Diagnostics'){
                    wo.OwnerId = queusByDevName.get('Diagnostic_Install_Coordinator').Id;
                } else if(div == 'Medical Aesthetics'){
                    if(wo.RecordTypeId == GlobalUtility.getRecordTypeId('WorkOrder', 'B_SH_FE_Install_Upgrade_Move')){
                        wo.OwnerId = queusByDevName.get('Installation_MA').Id;
                    } else if(wo.RecordTypeId == GlobalUtility.getRecordTypeId('WorkOrder', 'B_SH_Applications')){
                        wo.OwnerId = queusByDevName.get('Clinical_Installs_MA').Id;
                    }
                }
            }
        }
        
        update wos;
    }
    
    /*------------------------------------------------------------
    Author:             Dave Mansell, Salesforce
    Description:        Set address fields on incoming records
    Inputs:             List of records
    Returns:            N/A
    Test Class(es):     WorkOrderTriggerActions_Test.testSetAddress
    ------------------------------------------------------------*/
    public static void setAddress(List<WorkOrder> wos){
        Map<Id, Case> casesById = new Map<Id, Case>();
        Map<Id, Account> accsById = new Map<Id, Account>();
        Map<Id, Asset> assetsById = new Map<Id, Asset>();
        for(WorkOrder wo : wos){
            if(wo.CaseId != null){
                casesById.put(wo.CaseId, null);
            }
            if(wo.AccountId != null){
                accsById.put(wo.AccountId, null);
            }
            if(wo.AssetId != null){
                assetsById.put(wo.AssetId, null);
            }
        }
        
        if(casesById.size() > 0){
            casesById = new Map<Id, Case>([
                SELECT Id
                      ,Case_Summary__c
                      ,Case_Summary__r.Note_to_FE__c
                      ,Case_Summary__r.Problem_Description__c
// US-0005530 {08242018} - EDIT BY RYAN - DAVE TO CHECK
                      ,ContactId
                      ,Priority
                  FROM Case
                 WHERE Id IN :casesById.keySet()
            ]);
        }
        
        if(accsById.size() > 0){
            accsById = new Map<Id, Account>([
                SELECT Id
                      ,BillingStreet
                      ,BillingCity
                      ,BillingStateCode
                      ,BillingCountryCode
                      ,BillingPostalCode
                  FROM Account
                 WHERE Id IN :accsById.keySet()
            ]);
        }
        
        if(assetsById.size() > 0){
            assetsById = new Map<Id, Asset>([
                SELECT Id
                      ,Install_Location__c
                      ,Install_Location__r.Address_Line_1__c
                      ,Install_Location__r.Address_Line_2__c
                      ,Install_Location__r.Address_Line_3__c
                      ,Install_Location__r.Address_Line_4__c
                      ,Install_Location__r.State__c
                      ,Install_Location__r.City__c
                      ,Install_Location__r.Zip_Code__c
                      ,Install_Location__r.Country__c
                  FROM Asset
                 WHERE Id IN :assetsById.keySet()
            ]);
        }
        
        Id canPBId = Configuration_Settings__c.getInstance().Service_Pricebook_CAD__c;
        Id usPBId = Configuration_Settings__c.getInstance().Service_Pricebook_USD__c;
        
        for(WorkOrder wo : wos){
            Case cas = casesById.get(wo.CaseId);
            Account acc = accsById.get(wo.AccountId);
            Asset asst = assetsById.get(wo.AssetId);
            
            //Set case summary fields
            if(cas != null && cas.Case_Summary__c != null){
                wo.Case_Summary__c              = cas.Case_Summary__c;
                wo.Case_Problem_Description__c  = cas.Case_Summary__r.Problem_Description__c;
                wo.Note_to_FE__c                = cas.Case_Summary__r.Note_to_FE__c;
            }

            if(cas != null) {
                wo.Priority = cas.Priority;
                wo.ContactId = cas.ContactId;
            }
            
            if(wo.Pricebook2Id == null){
                if(acc.BillingCountryCode == 'CA'){
                    wo.CurrencyIsoCode          = 'CAD';
                    wo.Pricebook2Id             = canPBId;
                } else {
                    wo.CurrencyIsoCode          = 'USD';
                    wo.Pricebook2Id             = usPBId;
                }
            }
            
            //Set address fields
            if(asst != null && asst.Install_Location__c != null){
                wo.Street           = asst.Install_Location__r.Address_Line_1__c;
                if(asst.Install_Location__r.Address_Line_2__c != null){
                    wo.Street       += ' ' + asst.Install_Location__r.Address_Line_2__c;
                }
                if(asst.Install_Location__r.Address_Line_3__c != null){
                    wo.Street       += ' ' + asst.Install_Location__r.Address_Line_3__c;
                }
                if(asst.Install_Location__r.Address_Line_4__c != null){
                    wo.Street       += ' ' + asst.Install_Location__r.Address_Line_4__c;
                }
                if(wo.Street.length() > 35){
                    wo.Street = wo.Street.substring(0, 35);
                }
                wo.City             = asst.Install_Location__r.City__c;
                wo.StateCode        = asst.Install_Location__r.State__c;
                wo.CountryCode      = asst.Install_Location__r.Country__c;
                wo.PostalCode       = asst.Install_Location__r.Zip_Code__c;
            } else if(acc != null){
                if(acc.BillingStreet != null){
                    wo.Street       = acc.BillingStreet;
                }
                if(acc.BillingCity != null){
                    wo.City         = acc.BillingCity;
                }
                if(acc.BillingStateCode != null){
                    wo.StateCode    = acc.BillingStateCode;
                }
                if(acc.BillingCountryCode != null){
                    wo.CountryCode  = acc.BillingCountryCode;
                }
                if(acc.BillingPostalCode != null){
                    wo.PostalCode   = acc.BillingPostalCode;
                }
            }
        }
    }
    
    /*------------------------------------------------------------
    Author:             Dave Mansell, Salesforce
    Description:        Checks to see if incoming records need to be assigned to a service contract
    Inputs:             List of records, Map of old records
    Returns:            N/A
    Test Class(es):     WorkOrderTriggerActions_Test.testLinkEntitlements
    ------------------------------------------------------------*/
    public static void checkToSetServiceContract(List<WorkOrder> wos, Map<Id, WorkOrder> oldMap){
        //Filter
        List<WorkOrder> validWOs = new List<WorkOrder>();
        for(WorkOrder wo : wos){
            WorkOrder old = oldMap.get(wo.Id);
            if(wo.EntitlementId != old.EntitlementId && wo.EntitlementId != null){
                validWOs.add(wo);
            }
        }
        if(validWOs.size() > 0){
            setServiceContract(validWOs);
        }
    }
    
    /*------------------------------------------------------------
    Author:             Dave Mansell, Salesforce
    Description:        Checks to see if incoming records need to be assigned to a service contract
    Inputs:             List of records
    Returns:            N/A
    Test Class(es):     WorkOrderTriggerActions_Test.testLinkEntitlements
    ------------------------------------------------------------*/
    public static void setServiceContract(List<WorkOrder> wos){
        //Gather parent entitlements and map them
        Map<Id, Entitlement> entsById = new Map<Id, Entitlement>();
        for(WorkOrder wo : wos){
            entsById.put(wo.EntitlementId, null);
        }
        
        if(entsById.size() > 0){
            entsById = new Map<Id, Entitlement>([
                SELECT Id
                      ,ServiceContractId
                  FROM Entitlement
                 WHERE Id IN :entsById.keySet()
            ]);
        }
        
        for(WorkOrder wo : wos){
            if(wo.EntitlementId != null){
                wo.ServiceContractId = entsById.get(wo.EntitlementId).ServiceContractId;
            }
        }
    }
    
    /*------------------------------------------------------------
    Author:             Dave Mansell, Salesforce
    Description:        Checks to see if incoming records need are WST Capital
    Inputs:             List of records, Map of old records
    Returns:            N/A
    Test Class(es):     WorkOrderTriggerActions_Test.testCheckForWSTCapitalWorkOrder
    ------------------------------------------------------------*/
    public static void checkForWSTCapitalWorkOrder(List<WorkOrder> wos, Map<Id, WorkOrder> oldMap){
        //Find valid WO records
        List<WorkOrder> validWOs = new List<WorkOrder>();
        for(WorkOrder wo : wos){
            WorkOrder old = oldMap.get(wo.Id);
            if(wo.Type__c == 'New Install' && (old.Type__c != 'New Install' || wo.Order__c != old.Order__c)){
                validWOs.add(wo);
            }
        }
        
        if(!validWOs.isEmpty()){
            checkForWSTCapitalWorkOrder(validWOs);
        }
    }
    
    /*------------------------------------------------------------
    Author:             Dave Mansell, Salesforce
    Description:        Checks to see if incoming records are WST Capital
    Inputs:             List of records
    Returns:            N/A
    Test Class(es):     WorkOrderTriggerActions_Test.testCheckForWSTCapitalWorkOrder
    ------------------------------------------------------------*/
    public static void checkForWSTCapitalWorkOrder(List<WorkOrder> wos){
        //Gather parent Order Ids
        Map<Id, Order> ordersById = new Map<Id, Order>();
        for(WorkOrder wo : wos){
            if(wo.Type__c == 'New Install' && wo.Order__c != null){
                ordersById.put(wo.Order__c, null);
            }
        }
        
        if(ordersById.size() > 0){
            Id queueId = [SELECT Id FROM Group WHERE Type = 'Queue' AND Name = 'Medical Aesthetics Installation'].Id;
            ordersById = new Map<Id, Order>([
                SELECT Id
                  FROM Order
                 WHERE Id IN :ordersById.keySet()
                   AND Oracle_Order_Type__c = 'WST CAPITAL'
            ]);
            
            for(WorkOrder wo : wos){
                if(wo.Type__c == 'New Install' && wo.Order__c != null){
                    if(ordersById.get(wo.Order__c) != null){
                        wo.OwnerId = queueId;
                    }
                }
            }
        
            updateWOParentageBasedOnWorkType(ordersById.keySet());
        }
    }
    
    @future
    private static void updateWOParentageBasedOnWorkType(Set<Id> orderIds){
        //Map WOs by OrderId|WorkTypeId
        Map<String, WorkOrder> wosByKey = new Map<String, WorkOrder>();
        for(WorkOrder wo : [
            SELECT Id
                  ,Order__c
                  ,WorkTypeId
                  ,WorkType.Parent_Work_Type__c
              FROM WorkOrder
             WHERE Order__c IN :orderIds
               AND WorkTypeId != null
        ]){
            String key = wo.Order__c + '|' + wo.WorkTypeId;
            wosByKey.put(key, wo);
        }
        
        //Loop through WOs and assign parents
        for(WorkOrder wo : wosByKey.values()){
            String key = wo.Order__c + '|' + wo.WorkType.Parent_Work_Type__c;
            WorkOrder parentWO = wosByKey.get(key);
            if(parentWO != null && parentWO.Id != wo.Id){
                wo.ParentWorkOrderId = parentWO.Id;
            }
        }
        update wosByKey.values();
    }
    
    /*------------------------------------------------------------
    Author:             Dave Mansell, Salesforce
    Description:        Finds and links entitlements for incoming WO records
    Inputs:             List of records
    Returns:            N/A
    Test Class(es):     WorkOrderTriggerActions_Test.testAssignServiceTerritoryWithWOInsert
    ------------------------------------------------------------*/
    public static void linkEntitlements(List<WorkOrder> wos){
        //Filter WOs and Gather parent Asset Ids
        Id billableEventRTId = GlobalUtility.getRecordTypeId('WorkOrder', 'Billable_Event');
        List<WorkOrder> validWOs = new List<WorkOrder>();
        Map<Id, Asset> assetsById = new Map<Id, Asset>();
        for(WorkOrder wo : wos){
            if(wo.RecordTypeId != billableEventRTId){
                validWOs.add(wo);
                assetsById.put(wo.AssetId, null);
            }
        }
        
        //Query parent Assets and map by Id
        assetsById = new Map<Id, Asset>([
            SELECT Id
                  ,Product2Id
                  ,RootAssetId
              FROM Asset
             WHERE Id IN :assetsById.keySet()
        ]);
        
        Map<Integer, Id> prodIdsByListIndex = new Map<Integer, Id>();
        Map<Id, Id> rootAssetIdsByAssetId = new Map<Id, Id>();
        for(Integer i = 0; i < validWOs.size(); i++){
            WorkOrder wo = validWOs[i];
            Asset asst = assetsById.get(wo.AssetId);
            if(asst != null){
                prodIdsByListIndex.put(i, asst.Product2Id);
                rootAssetIdsByAssetId.put(asst.Id, asst.RootAssetId);
            }
        }
        
        //Call helper function to create entitlements
        EntitlementLinkingHelper.linkEntitlementsForRecords(validWOs, EntitlementLinkingHelper.TYPE_WO, prodIdsByListIndex, rootAssetIdsByAssetId);
    }
    
    /*------------------------------------------------------------
    Author:             Dave Mansell, Salesforce
    Description:        Finds and links entitlements for incoming WO records
    Inputs:             List of records
    Returns:            N/A
    Test Class(es):     WorkOrderTriggerActions_Test.testAssignServiceTerritoryWithWOInsert
    ------------------------------------------------------------*/
    public static void checkForPricingAgreement(List<WorkOrder> wos){
        //Map incoming WOs by AssetId
        Map<Id, Asset> validAssetsById = new Map<Id, Asset>();
        for(WorkOrder wo : wos){
            if(wo.AssetId != null){
                validAssetsById.put(wo.AssetId, null);
            }
        }
        validAssetsById = new Map<Id, Asset>([
            SELECT Id
                  ,Product2Id
              FROM Asset
             WHERE Id IN :validAssetsById.keySet()
               AND Product2.Product_Source_Division__r.Division__c = 'Medical Aesthetics'
        ]);
        
        //Filter for valid WOs
        List<WorkOrder> validWOs = new List<WorkOrder>();
        for(WorkOrder wo : wos){
            if(validAssetsById.get(wo.AssetId) != null){
                validWOs.add(wo);
            }
        }
        
        if(validWOs.isEmpty()){
            return;
        } else {
            wos = validWOs;
        }
        
        //Map work orders by their account Id
        Map<Id, List<WorkOrder>> woListsByAccountId = new Map<Id, List<WorkOrder>>();
        for(WorkOrder wo : wos){
            List<WorkOrder> woList = woListsByAccountId.get(wo.AccountId);
            if(woList == null){
                woList = new List<WorkOrder>();
            }
            woList.add(wo);
            woListsByAccountId.put(wo.AccountId, woList);
        }
        
        //Map work orders by their account's parent account Id
        Map<Id, List<WorkOrder>> woListsByParentAccountId = new Map<Id, List<WorkOrder>>();
        for(Account acc : [
            SELECT Id
                  ,ParentId
              FROM Account
             WHERE Id IN :woListsByAccountId.keySet()
        ]){
            List<WorkOrder> parentList = woListsByParentAccountId.get(acc.ParentId);
            if(parentList == null){
                parentList = new List<WorkOrder>();
            }
            parentList.addAll(woListsByAccountId.get(acc.Id));
            woListsByParentAccountId.put(acc.ParentId, parentList);
        }
        
        for(Contract con : [
            SELECT Id
                  ,(SELECT Id
                          ,Customer_Account__c
                      FROM Customer_Eligible_Contracts__r
                   )
                  ,(SELECT Id
                      FROM Agreed_Price__r
                     WHERE Product__r.Name = 'MEDA-LUMINARY (Category)'
                     LIMIT 1
                   )
              FROM Contract
             WHERE Id IN
                (SELECT Contract__c
                   FROM Customer_Eligible_Contract__c
                  WHERE Agreement_Active__c = true
                    AND Marketing_Program__c = 'MEDA-Luminary Discounts'
                )
        ]){
            for(Customer_Eligible_Contract__c cec : con.Customer_Eligible_Contracts__r){
                if(woListsByParentAccountId.get(cec.Customer_Account__c) != null){
                    for(WorkOrder wo : woListsByParentAccountId.get(cec.Customer_Account__c)){
                        if(con.Agreed_Price__r.size() > 0){
                            wo.Luminary_Discount_Agreed_Price__c = con.Agreed_Price__r[0].Id;
                        }
                    }
                }
            }
        }
    }
    
    /*------------------------------------------------------------
    Author:             Dave Mansell, Salesforce
    Description:        Checks to see if incoming records need a service territory assignment
    Inputs:             List of records
    Returns:            N/A
    Test Class(es):     WorkOrderTriggerActions_Test.testAssignServiceTerritoryWithWOInsert
    ------------------------------------------------------------*/
    public static void checkToAssignServiceTerritory(List<WorkOrder> wos){
        //Find valid WO records
        Set<Id> validWOIds = new Set<Id>();
        for(WorkOrder wo : wos){
            if(wo.ServiceTerritoryId == null){
                validWOIds.add(wo.Id);
            }
        }
        
        if(!validWOIds.isEmpty()){
            batchAssignServiceTerritory(validWOIds);
        }
    }
    
    /*------------------------------------------------------------
    Author:             Dave Mansell, Salesforce
    Description:        Checks to see if incoming records need a service territory assignment
    Inputs:             List of records, Map of old records
    Returns:            N/A
    Test Class(es):     WorkOrderTriggerActions_Test.testAssignServiceTerritoryWithWOUpdate
    ------------------------------------------------------------*/
    public static void checkToAssignServiceTerritory(List<WorkOrder> wos, Map<Id, WorkOrder> oldMap){
        //Find valid WO records
        Set<Id> validWOIds = new Set<Id>();
        for(WorkOrder wo : wos){
            WorkOrder old = oldMap.get(wo.Id);
            if(wo.AssetId               != old.AssetId ||
                wo.PostalCode           != old.PostalCode ||
                wo.StateCode            != old.StateCode ||
                wo.CountryCode          != old.CountryCode ||
                wo.WorkTypeId           != old.WorkTypeId ||
                (wo.ServiceTerritoryId  != old.ServiceTerritoryId && wo.ServiceTerritoryId == null)
            ){
                validWOIds.add(wo.Id);
            }
        }
        
        if(!validWOIds.isEmpty()){
            batchAssignServiceTerritory(validWOIds);
        }
    }
    
    private static void batchAssignServiceTerritory(Set<Id> woIds){
        Integer batchSize = 10;
        Set<Id> batchIds = new Set<Id>();
        for(Id woId : woIds){
            batchIds.add(woId);
            if(batchIds.size() == batchSize){
                if(System.isFuture()){
                    assignServiceTerritory(batchIds);
                } else {
                    assignServiceTerritory_Future(batchIds);
                }
                batchIds = new Set<Id>();
            }
        }
        if(batchIds.size() > 0){
            if(System.isFuture()){
                assignServiceTerritory(batchIds);
            } else {
                assignServiceTerritory_Future(batchIds);
            }
        }
    }
    
    @future
    public static void assignServiceTerritory_Future(Set<Id> woIds){
        assignServiceTerritory(woIds);
    }
    
    /*------------------------------------------------------------
    Author:             Dave Mansell, Salesforce
    Description:        Assigns service territory to incoming Work Order records
    Inputs:             List of records, Map of old records
    Returns:            N/A
    Test Class(es):     WorkOrderTriggerActions_Test.testAssignServiceTerritoryWithWOInsert,
                        WorkOrderTriggerActions_Test.testAssignServiceTerritoryWithWOUpdate
    ------------------------------------------------------------*/
    public static void assignServiceTerritory(Set<Id> woIds){
        List<WorkOrder> wos = [
            SELECT Id
                  ,AssetId
                  ,Product__c
                  ,WorkTypeId
                  ,PostalCode
                  ,StateCode
                  ,CountryCode
                  ,(SELECT Id
                      FROM ServiceAppointments
                   )
              FROM WorkOrder
             WHERE Id IN :woIds
        ];
        
        Map<Id, Asset> assetsById = new Map<Id, Asset>();
        Map<Id, Product2> prodsById = new Map<Id, Product2>();
        Map<Id, WorkType> workTypesById = new Map<Id, WorkType>();
        for(WorkOrder wo : wos){
            assetsById.put(wo.AssetId, null);
            prodsById.put(wo.Product__c, null);
            workTypesById.put(wo.WorkTypeId, null);
        }
        
        //Query for extended field values on valid WO records
        assetsById = new Map<Id, Asset>([
            SELECT Id
                  ,Product2.Product_Source_Division__r.Service_Territory__r.TopLevelTerritory.Name
             FROM Asset
            WHERE Id IN :assetsById.keySet()
              AND Product2.Product_Source_Division__r.Service_Territory__r.TopLevelTerritory.Name != null
        ]);
        prodsById = new Map<Id, Product2>([
            SELECT Id
                  ,Product_Source_Division__r.Service_Territory__r.TopLevelTerritory.Name
             FROM Product2
            WHERE Id IN :prodsById.keySet()
              AND Product_Source_Division__r.Service_Territory__r.TopLevelTerritory.Name != null
        ]);
        workTypesById = new Map<Id, WorkType>([
            SELECT Id
                  ,Service_Territory_Type__c
             FROM WorkType
            WHERE Id IN :workTypesById.keySet()
              AND Service_Territory_Type__c != null
        ]);
        
        List<ServiceAppointment> sasToUpdate = new List<ServiceAppointment>();
        for(WorkOrder wo : wos){
            String divName;
            if(wo.AssetId != null && assetsById.get(wo.AssetId) != null){
                divName = assetsById.get(wo.AssetId).Product2.Product_Source_Division__r.Service_Territory__r.TopLevelTerritory.Name;
            } else if(wo.Product__c != null && prodsById.get(wo.Product__c) != null){
                divName = prodsById.get(wo.Product__c).Product_Source_Division__r.Service_Territory__r.TopLevelTerritory.Name;
            }
            WorkType wType = workTypesById.get(wo.WorkTypeId);
            if(divName != null && wType != null){
                wo.ServiceTerritoryId = ServiceTerritoryHelper.findServiceTerritoryId(
                    divName,
                    wo.PostalCode,
                    wo.StateCode,
                    wo.CountryCode,
                    wType.Service_Territory_Type__c
                );
                for(ServiceAppointment sa : wo.ServiceAppointments){
                    sa.ServiceTerritoryId = wo.ServiceTerritoryId;
                    sasToUpdate.add(sa);
                }
            }
        }
        
        update wos;
        update sasToUpdate;
    }
    
    /*------------------------------------------------------------
    Author:             Dave Mansell, Salesforce
    Description:        Checks to see if WO records are closed
    Inputs:             List of records, Map of old records
    Returns:            N/A
    Test Class(es):     WorkOrderTriggerActions_Test.testCreateOrdersAndOrderLines,
                        WorkOrderTriggerActions_Test.testCreateOrdersAndOrderLinesWithCase
    History:
    <Date           <Authors Name       <Brief Description of Change>                   
    04/02/2019      krishna             Auto Close Case when Work Order Estimate is rejected,
                                    and there are no other open work orders related to the Case(US-0007008)                 
    ------------------------------------------------------------*/
    public static void checkForClosedStatus(List<WorkOrder> wos, Map<Id, WorkOrder> oldMap){
        //Find valid WO records
        List<WorkOrder> validWOs = new List<WorkOrder>();
        List<WorkOrder> validWOsCancelled = new List<WorkOrder>();
        for(WorkOrder wo : wos){
            WorkOrder old = oldMap.get(wo.Id);
            
            if((wo.Status == 'Closed' && old.Status != 'Closed')){
                validWOs.add(wo);
            }           
            else if( wo.Status == 'Cancelled' && old.Status != 'Cancelled'
                 && wo.Division__c =='Medical Aesthetics' &&  wo.Estimate_status__c =='Rejected'
                ){
                validWOsCancelled.add(wo);
            }
        }
        
        if(!validWOs.isEmpty()){
            createOrdersAndOrderLines(validWOs);
            checkToCloseParentCases(validWOs);
            checkToCreateTasks(validWOs);
            closeParentATBs(validWOs);
        }
        if(!validWOsCancelled.isEmpty()){
            CloseParentCasesWhenMedicalAesthetics(validWOsCancelled);
        }
         
    }
    /*------------------------------------------------------------
    Author:             Dave Mansell, Salesforce
    Description:        Creates orders and order lines for closed work order records
    Inputs:             List of records
    Returns:            N/A
    Test Class(es):     WorkOrderTriggerActions_Test.testCreateOrdersAndOrderLines,
                        WorkOrderTriggerActions_Test.testCreateOrdersAndOrderLinesWithCase
                        
    US-0006017 - Mani   Updated the logic to update Products Consumed to trigger the outbound message instead of Platform Events                  
    ------------------------------------------------------------*/
    public static void createOrdersAndOrderLines(List<WorkOrder> wos){
        //Query for extended field values on WO records
        wos = [
            SELECT Id
                  ,AccountId
                  ,Account.ParentId
                  ,Account.Parent.Oracle_Customer_Number__c
                  ,Account.Parent.Oracle_Party_Id__c
                  ,CurrencyIsoCode
                  ,Description
                  ,OwnerId
                  ,Pricebook2Id
                  ,StartDate
                  ,WorkOrderNumber
                  ,Division__c
                  ,Payment__c
                  ,AssetId
                  ,Asset.Bill_To_Location__c
                  ,Asset.Bill_To_Location__r.Account__r.ParentId
                  ,Asset.Bill_To_Location__r.Account__r.Parent.AccountNumber
                  ,Asset.Ship_To_Location__c
                  ,Asset.Ship_To_Location__r.Account__r.ParentId
                  ,Asset.Product2Id
                  ,Asset.Product2.Product_Source_Division__c
                  ,Asset.Product2.Product_Source_Division__r.Division__c
                  ,Product__c
                  ,Product__r.Product_Source_Division__c
                  ,Product__r.Product_Source_Division__r.Division__c
                  ,CaseId
                  ,Case.Bill_to_Customer__c
                  ,Case.Bill_to_Customer__r.AccountNumber
                  ,Case.Bill_To_Site_Location__c
                  ,Case.Ship_To_Customer__c
                  ,Case.Ship_To_Site_Location__c
                  ,Case.Sub_Type__c
                  ,Order__c
                  ,Order__r.Status
                  ,(SELECT Id
                          ,Case__c
                          ,Category_Code__c
                          ,Description
                          ,Entitlement__c
                          ,Exclude_from_Invoice__c
                          ,PricebookEntryId
                          ,Quantity
                          ,RecordType.DeveloperName
                          ,Return_Reason_Code__c
                          ,Returned_Asset__c
                          ,Serial_Number__c
                          ,Ship_to_Site_Location__c
                          ,TotalPrice
                          ,UnitPrice
                      FROM WorkOrderLineItems
                   )
                  ,(SELECT Id
                          ,Case__c
                          ,Description
                          ,Entitlement__c
                          ,PricebookEntryId
                          ,QuantityConsumed
                          ,QuantityUnitOfMeasure
                          ,Return_Lot_Number__c
                          ,Return_Reason_Code__c
                          ,Return_Product__c
                          ,Return_Serial_Number__c
                          ,Return_Asset__c
                          ,Total_Price__c
                          ,UnitPrice
                          ,ProductItem.Lot_Number__c
                          ,ProductItem.SerialNumber
                          ,Work_Order_Approved__c
                      FROM ProductsConsumed
                   )
              FROM WorkOrder
             WHERE Id IN :wos
        ];
        
        //Map to hold Ids of WO & payment record.
        Map<Id, Id>woPaymentMap = new Map<Id, Id>();
        
        List<Payment__c> payments = [
            SELECT Id
                  ,Work_Order__c
              FROM Payment__c
             WHERE Work_Order__c IN :wos
        ];
        
        for(Payment__c pay :  payments)
            woPaymentMap.put(pay.Work_Order__c, pay.Id);
            
        System.debug('woPaymentMap:'+woPaymentMap);
        
        List<ProductConsumed> pcIdsToSend = new List<ProductConsumed>();
        for(WorkOrder wo : wos){
            for(ProductConsumed pc : wo.ProductsConsumed){
                System.debug('pc:'+pc.Id);
                if(pc.Work_Order_Approved__c == false){
                    pc.Work_Order_Approved__c = True;
                    
                    pcIdsToSend.add(pc);
                }
            }
        }
        //EBSCalloutHelper.sendProductConsumedIDs(pcIdsToSend);
        System.debug('pcIdsToSend:'+pcIdsToSend);
        if(pcIdsToSend.size() > 0)
            update pcIdsToSend;
        
        //Filter out WOs without $ WOLIs or PCs
        Map<Id, Boolean> shouldCreateByWOId = new Map<Id, Boolean>();
        for(WorkOrder wo : wos){
            shouldCreateByWOId.put(wo.Id, false);
            for(WorkOrderLineItem woli : wo.WorkOrderLineItems){
                if(woli.TotalPrice > 0 || woli.RecordType.DeveloperName == 'B_SH_RMA'){
                    shouldCreateByWOId.put(wo.Id, true);
                }
            }
            for(ProductConsumed pc : wo.ProductsConsumed){
                if(pc.Total_Price__c > 0 || pc.Return_Product__c != null){
                    shouldCreateByWOId.put(wo.Id, true);
                }
            }
        }
        
        //Map orders by WO Id and insert needed orders
        Map<Id, Order> ordersByWOId = new Map<Id, Order>();
        List<Order> ordersToInsert = new List<Order>();
        Id newOrderRecordTypeId = GlobalUtility.getRecordTypeId('Order', 'B_SH_Service_Order');
        Map<Id, List<ContentNote>> notesToCreateByCaseId = new Map<Id, List<ContentNote>>();
        Set<Id> caseIdsWithServiceOrders = new Set<Id>();
        List<Order> ordersToSetToBooked = new List<Order>();
        for(WorkOrder wo : wos){
            Order ord = wo.Order__r;
            if(ord == null && shouldCreateByWOId.get(wo.Id) == true){
                ord = new Order();
                ord.Work_Order__c                   = wo.Id;
                ord.Name                            = 'Generated from Work Order: ' + wo.WorkOrderNumber;
                ord.OwnerId                         = wo.OwnerId;
                ord.RecordTypeId                    = newOrderRecordTypeId;
                ord.AccountId                       = wo.Account.ParentId;
                ord.Owner_Oracle_Customer_Number__c = wo.Account.Parent.Oracle_Customer_Number__c;
                ord.Oracle_Party_Id__c              = wo.Account.Parent.Oracle_Party_Id__c;
                ord.EffectiveDate                   = Date.today();
                ord.Pricebook2Id                    = wo.Pricebook2Id;
                ord.CurrencyIsoCode                 = wo.CurrencyIsoCode;
                ord.Description                     = wo.Description;
                ord.Type                            = 'Field Service';
                ord.Status                          = 'DRAFT';
                if(wo.Payment__c != null){
                    ord.Payment__c                  = wo.Payment__c;
                } else if(woPaymentMap.size() > 0 && woPaymentMap.get(wo.Id) != null){
                    ord.Payment__c                  = woPaymentMap.get(wo.Id);
                }
                
                String div;
                if(wo.AssetId != null){
                    div = wo.Asset.Product2.Product_Source_Division__r.Division__c;
                } else if(wo.Product__c != null){
                    div = wo.Product__r.Product_Source_Division__r.Division__c;
                }
                //Set to BOOKED for Med Aesthetic, unless case.subtype = Customer Owned Repair
                if(div == 'Medical Aesthetics' && (wo.CaseId == null || wo.Case.Sub_Type__c == null || wo.Case.Sub_Type__c != 'Customer Owned Repair')){
                    ordersToSetToBooked.add(ord);
                }
                
                if(wo.CaseId == null){
                    ord.Bill_To_Account__c = wo.Asset.Bill_To_Location__r.Account__r.ParentId;
                    ord.Bill_To_Site_Location__c = wo.Asset.Bill_To_Location__c;
                    ord.Ship_To_Account__c = wo.Asset.Ship_To_Location__r.Account__r.ParentId;
                    ord.Ship_To_Site_Location__c = wo.Asset.Ship_To_Location__c;
                } else {
                    ord.Case__c = wo.CaseId;
                    ord.Bill_To_Account__c = wo.Case.Bill_to_Customer__c;
                    ord.Bill_To_Site_Location__c = wo.Case.Bill_To_Site_Location__c;
                    ord.Ship_To_Account__c = wo.Case.Ship_To_Customer__c;
                    ord.Ship_To_Site_Location__c = wo.Case.Ship_To_Site_Location__c;
                    
                    caseIdsWithServiceOrders.add(ord.Case__c);
                    List<ContentNote> notes = notesToCreateByCaseId.get(ord.Case__c);
                    if(notes == null){
                        notes = new List<ContentNote>();
                    }
                    ContentNote nte = new ContentNote();
                    nte.Title = 'Service Order Created';
                    nte.Content = Blob.valueOf(wo.Id);
                    notes.add(nte);
                    notesToCreateByCaseId.put(ord.Case__c, notes);
                }
                
                ordersToInsert.add(ord);
                system.debug('ordersToInsert---'+ordersToInsert);
            }
            ordersByWOId.put(wo.Id, ord);
        }
        insert ordersToInsert;
        
        Set<Id> caseIdsWithWorkOrders = new Set<Id>();
        for(WorkOrder wo : wos){
            if(wo.CaseId != null){
                caseIdsWithWorkOrders.add(wo.CaseId);
                List<ContentNote> notes = notesToCreateByCaseId.get(wo.CaseId);
                if(notes == null){
                    notes = new List<ContentNote>();
                }
                ContentNote nte = new ContentNote();
                nte.Title = 'Work Order Closed';
                nte.Content = Blob.valueOf(wo.Id);
                notes.add(nte);
                notesToCreateByCaseId.put(wo.CaseId, notes);
            }
        }
        
        Map<Id, Order> ordersWithNumberById = new Map<Id, Order>([SELECT Id, OrderNumber FROM Order WHERE Id IN :ordersToInsert]);
        Map<Id, WorkOrder> wosWithNumberById = new Map<Id, WorkOrder>([SELECT Id, WorkOrderNumber, Completed_Date__c FROM WorkOrder WHERE Id IN :wos]);
        List<ContentNote> notesToInsert = new List<ContentNote>();
        for(Id caseId : notesToCreateByCaseId.keySet()){
            for(ContentNote nte : notesToCreateByCaseId.get(caseId)){
                Id woId = nte.Content.toString();
                String newContent;
                if(nte.Title == 'Service Order Created'){
                    newContent = 'Order ' + ordersWithNumberById.get(ordersByWOId.get(woId).Id).OrderNumber;
                } else if(nte.Title == 'Work Order Closed'){
                    newContent = 'Work Order ' + wosWithNumberById.get(woId).WorkOrderNumber + '\n' +
                                  'Completed Date: ' + wosWithNumberById.get(woId).Completed_Date__c;
                }
                nte.Content = Blob.valueOf(newContent);
                notesToInsert.add(nte);
            }
        }
        if(notesToInsert.size() > 0){
            insert notesToInsert;
            
            List<ContentDocumentLink> links = new List<ContentDocumentLink>();
            for(Id caseId : notesToCreateByCaseId.keySet()){
                for(ContentNote nte : notesToCreateByCaseId.get(caseId)){
                    ContentDocumentLink link = new ContentDocumentLink();
                    link.ContentDocumentId = nte.Id;
                    link.LinkedEntityId = caseId;
                    link.ShareType = 'I';
                    links.add(link);
                }
            }
            insert links;
            
            //Update case summaries
            List<Case_Summary__c> summaries = [
                SELECT Id
                      ,Case__c
                  FROM Case_Summary__c
                 WHERE Case__c IN :caseIdsWithServiceOrders
                    OR Case__c IN :caseIdsWithWorkOrders
            ];
            for(Case_Summary__c summary : summaries){
                if(caseIdsWithServiceOrders.contains(summary.Case__c)){
                    summary.Has_Service_Orders__c = true;
                }
                if(caseIdsWithWorkOrders.contains(summary.Case__c)){
                    summary.Has_Work_Orders__c = true;
                }
            }
            update summaries;
        }
        
        //Reverse that mapping, so that WOs are mapped by their Order Id
        Map<Id, WorkOrder> wosByOrderId = new Map<Id, WorkOrder>();
        List<WorkOrder> wosToUpdateWithNewOrderIds = new List<WorkOrder>();
        for(WorkOrder wo : wos){
            Order ord = ordersByWOId.get(wo.Id);
            if(ord != null){
                if(wo.Order__c == null){
                    //no existing order
                    wo.Order__c = ord.Id;
                    if(wo.Payment__c == null && woPaymentMap.size() > 0 && woPaymentMap.get(wo.Id) != null)
                        wo.Payment__c = woPaymentMap.get(wo.Id);
                    wosToUpdateWithNewOrderIds.add(wo);
                }
                wosByOrderId.put(ord.Id, wo);
            }
        }
        
        //Update WorkOrders with new parent Order__c value
        update wosToUpdateWithNewOrderIds;
        
        //Update child payment records
        /*List<Payment__c> payments = [
            SELECT Id
                  ,Work_Order__c
              FROM Payment__c
             WHERE Work_Order__c IN :wos
        ];*/
        for(Payment__c payment : payments){
            Order ord = ordersByWOId.get(payment.Work_Order__c);
            if(ord != null){
                payment.Order__c = ord.Id;
                
            }
        }
        update payments;

        //Get existing order items, if they exist, and map by WOLI/PC Id, to prevent dupes
        Map<Id, OrderItem> existingOIsByWOLIPCId = new Map<Id, OrderItem>();
        for(OrderItem oi : [
                SELECT Id
                      ,Work_Order_Line_Item__c
                      ,Product_Consumed__c
                  FROM OrderItem
                 WHERE OrderId IN :wosByOrderId.keySet()
            ]){
            if(oi.Work_Order_Line_Item__c != null){
                existingOIsByWOLIPCId.put(oi.Work_Order_Line_Item__c, oi);
            }
            if(oi.Product_Consumed__c != null){
                existingOIsByWOLIPCId.put(oi.Product_Consumed__c, oi);
            }
        }
        
        //Create OrderItems
        List<OrderItem> oisToInsert = new List<OrderItem>();
        for(Id ordId : wosByOrderId.keySet()){
            WorkOrder wo = wosByOrderId.get(ordId);
            if(shouldCreateByWOId.get(wo.Id) == true){
                for(WorkOrderLineItem woli : wo.WorkOrderLineItems){
                    if((woli.TotalPrice > 0 || woli.RecordType.DeveloperName == 'B_SH_RMA') && existingOIsByWOLIPCId.get(woli.Id) == null){
                        OrderItem oi = new OrderItem();
                        oi.OrderId = ordId;
                        
                        oi.Work_Order_Line_Item__c = woli.Id;
                        oi.PricebookEntryId = woli.PricebookEntryId;
                        oi.Description = woli.Description;
                        oi.Quantity = woli.Quantity;
                        oi.Case__c = woli.Case__c;
                        oi.Entitlement__c = woli.Entitlement__c;
                        oi.Exclude_from_Invoice__c = woli.Exclude_from_Invoice__c;
                        oi.Ship_To_Site_Location__c = woli.Ship_to_Site_Location__c;
                        oi.Returned_Asset__c = woli.Returned_Asset__c;
                        oi.Serial_Number__c = woli.Serial_Number__c; 
                        oi.Return_Reason_Code__c = woli.Return_Reason_Code__c;
                        oi.Category_Code__c = woli.Category_Code__c;
                        
                        oi.UnitPrice = 0;
                        if(woli.UnitPrice != null){
                            oi.UnitPrice = woli.UnitPrice;
                        }
                        if (wo.StartDate != null) {
                            oi.Request_Date__c = date.newinstance(wo.StartDate.year(), wo.StartDate.month(), wo.StartDate.day());
                        }
                        if(woli.RecordType.DeveloperName == 'Labor' ||
                           woli.RecordType.DeveloperName == 'Travel' ||
                           woli.RecordType.DeveloperName == 'Fixed_Fee' ||
                           woli.RecordType.DeveloperName == 'Billable_Event' ||
                           woli.RecordType.DeveloperName == 'Part_Billing'){
                            oi.Line_Type__c = 'Add Labor / Travel';
                        } else if(woli.RecordType.DeveloperName == 'B_SH_RMA'){
                            oi.Line_Type__c = 'RMA';
                            oi.RMA_Serial_Number__c = woli.Serial_Number__c;
                        }
                        
                        oisToInsert.add(oi);
                    }
                }
                for(ProductConsumed pc : wo.ProductsConsumed){
                    if(existingOIsByWOLIPCId.get(pc.Id) == null){
                        //Create "Add Part" OI
                        if(pc.Total_Price__c > 0){
                            oisToInsert.add(createOrderItemFromPC(pc, ordId, wo.StartDate, false));
                        }
                        
                        //Create "RMA" OI
                        if(pc.Return_Product__c != null){
                            oisToInsert.add(createOrderItemFromPC(pc, ordId, wo.StartDate, true));
                        }
                    }
                }
            }
        }
        insert oisToInsert;
        
        Set<Id> ordersToDefinitelyBook = new Set<Id>();
        Set<Id> ordersToPossiblyBook = new Set<Id>();
        system.debug('ordersToSetToBooked---'+ordersToSetToBooked);
        system.debug('ordersToInsert---'+ordersToInsert);
        for(Order ord : ordersToSetToBooked){
            ordersToDefinitelyBook.add(ord.Id);
        }
        for(Order ord : ordersToInsert){
            ordersToPossiblyBook.add(ord.Id);
        }
        system.debug('ordersToDefinitelyBook---'+ordersToDefinitelyBook);
        system.debug('ordersToPossiblyBook---'+ordersToPossiblyBook);
        setOrdersToBooked(ordersToDefinitelyBook, ordersToPossiblyBook);
    }
    
    @future
    private static void setOrdersToBooked(Set<Id> ordersToDefinitelyBook, Set<Id> ordersToPossiblyBook){
        List<Order> orders = [
            SELECT Id
              FROM Order
             WHERE Status != 'BOOKED'
               AND (Id IN :ordersToDefinitelyBook
                    OR (Id IN :ordersToPossiblyBook AND TotalAmount = 0)
                   )
        ];
        system.debug('orders---'+orders);
        for(Order ord : orders){
            ord.Status = 'BOOKED';
        }
        update orders;
    }
    
    /*------------------------------------------------------------
    Author:             Dave Mansell, Salesforce
    Description:        Creates orders and order lines for closed work order records
    Inputs:             pc:         the relative ProductConsumed record
                        ordId:      the related Order record Id
                        startDate:  the date to use for Request Date
                        isRMA:      Boolean declaring whether or not this is an RMA
    Returns:            A new OrderItem record
    Test Class(es):     WorkOrderTriggerActions_Test.testCreateOrdersAndOrderLines,
                        WorkOrderTriggerActions_Test.testCreateOrdersAndOrderLinesWithCase
                        
    US-0005969 - PW     Change mapping for Order Line Type from 'Add Part' to 'Bill Only'          
    ------------------------------------------------------------*/
    private static OrderItem createOrderItemFromPC(ProductConsumed pc, Id ordId, DateTime startDate, Boolean isRMA){
        OrderItem oi = new OrderItem();
        oi.OrderId = ordId;
        
        oi.Case__c = pc.Case__c;
        oi.Description = pc.Description;
        oi.Entitlement__c = pc.Entitlement__c;
        oi.PricebookEntryId = pc.PricebookEntryId;
        oi.Product_Consumed__c = pc.Id;
        oi.Unit_of_Measure__c = pc.QuantityUnitOfMeasure;
        
        oi.UnitPrice = 0;
        if(pc.UnitPrice != null){
            oi.UnitPrice = pc.UnitPrice;
        }
        if (startDate != null) {
            oi.Request_Date__c = date.newinstance(startDate.year(), startDate.month(), startDate.day());
        }
        
        if(isRMA){
            oi.Line_Type__c = 'RMA';
            oi.UnitPrice = 0;
            oi.Quantity = -1 * pc.QuantityConsumed;
            oi.RMA_Lot_Number__c = pc.Return_Lot_Number__c;
            oi.RMA_Serial_Number__c = pc.Return_Serial_Number__c;
            oi.Return_Reason_Code__c = pc.Return_Reason_Code__c;
            oi.Returned_Asset__c = pc.Return_Asset__c;
        } else {
            oi.Line_Type__c = 'Bill Only';
            oi.Lot_Number__c = pc.ProductItem.Lot_Number__c;
            oi.Quantity = pc.QuantityConsumed;
            oi.Serial_Number__c = pc.ProductItem.SerialNumber;
        }
        
        return oi;
    }
    
    /*------------------------------------------------------------
    Author:             Dave Mansell, Salesforce
    Description:        Creates ResourcePreference records for new work order records
    Inputs:             List of records
    Returns:            N/A
    Test Class(es):     WorkOrderTriggerActions_Test.testCreateResourcePreferences
    ------------------------------------------------------------*/
    public static void createResourcePreferences(List<WorkOrder> wos){
        //Collect Asset Ids
        Map<Id, Asset> assetsById = new Map<Id, Asset>();
        for(WorkOrder wo : wos){
            if(wo.AssetId != null){
                assetsById.put(wo.AssetId, null);
            }
        }
        
        //Query for Asset details
        assetsById = new Map<Id, Asset>([
            SELECT Id
                  ,(SELECT Id
                          ,Relationship__c
                          ,User__c
                      FROM Asset_Teams__r
                     WHERE Relationship__c LIKE '% Field Engineer'
                   )
              FROM Asset
             WHERE Id IN :assetsById.keySet()
        ]);
        
        //Collect team member user Ids
        Map<Id, User> usersById = new Map<Id, User>();
        for(Asset asst : assetsById.values()){
            for(Asset_Team__c teamMember : asst.Asset_Teams__r){
                usersById.put(teamMember.User__c, null);
            }
        }
        
        //Query for User details
        usersById = new Map<Id, User>([
            SELECT Id
                  ,(SELECT Id
                      FROM ServiceResources
                     LIMIT 1
                   )
              FROM User
             WHERE Id IN :usersById.keySet()
        ]);
        
        //Create and insert ResourcePreference records
        List<ResourcePreference> prefs = new List<ResourcePreference>();
        for(WorkOrder wo : wos){
            Asset asst = assetsById.get(wo.AssetId);
            if(asst != null){
                for(Asset_Team__c teamMember : asst.Asset_Teams__r){
                    User use = usersById.get(teamMember.User__c);
                    if(use.ServiceResources.size() > 0){
                        ResourcePreference pref = new ResourcePreference();
                        
                        pref.ServiceResourceId = use.ServiceResources[0].Id;
                        pref.RelatedRecordId = wo.Id;
                        pref.PreferenceType = 'Preferred';
                        pref.Rank__c = teamMember.Relationship__c.split(' ')[0];
                        
                        prefs.add(pref);
                    }
                }
            }
        }
        insert prefs;
    }
    
    /*------------------------------------------------------------
    Author:             Dave Mansell, Salesforce
    Description:        Queries all WOs for some Cases and sets those cases to closed sometimes
    Inputs:             List of WorkOrder records that have just closed
    Returns:            N/A
    Test Class(es):     WorkOrderTriggerActions_Test.testCheckForClosedStatus
    ------------------------------------------------------------*/
    public static void checkToCloseParentCases(List<WorkOrder> wos){
        //Collect Case Ids
        Map<Id, Case> casesById = new Map<Id, Case>();
        for(WorkOrder wo : wos){
            if(wo.CaseId != null){
                casesById.put(wo.CaseId, null);
            }
        }
        
        //Query for Case details
        casesById = new Map<Id, Case>([
            SELECT Id
                  ,(SELECT Id
                          ,Status
                      FROM WorkOrders
                   )
              FROM Case
             WHERE Id IN :casesById.keySet()
        ]);
        
        //Update cases where needed
        List<Case> casesToUpdate = new List<Case>();
        for(Case cas : casesById.values()){
            Boolean allWOsAreClosed = true;
            for(WorkOrder wo : cas.WorkOrders){
                if(wo.Status != 'Closed'){
                    allWOsAreClosed = false;
                }
            }
            if(allWOsAreClosed == true){
                cas.Status = 'Closed';
                casesToUpdate.add(cas);
            }
        }
        update casesToUpdate;
    }
    
    /*------------------------------------------------------------
    Author:             Dave Mansell, Salesforce
    Description:        Creates tasks on certain newly-closed WorkOrders
    Inputs:             List of WorkOrder records that have just closed
    Returns:            N/A
    Test Class(es):     WorkOrderTriggerActions_Test.testCreateTasks
    ------------------------------------------------------------*/
    public static void checkToCreateTasks(List<WorkOrder> wos){
        //Filter WOs
        List<WorkOrder> validWOs = new List<WorkOrder>();
        Id rtId = GlobalUtility.getRecordTypeId('WorkOrder', 'B_SH_FE_Install_Upgrade_Move');
        for(WorkOrder wo : wos){
            if(
                wo.RecordTypeId == rtId &&
                wo.Type__c == 'De-Install' &&
                wo.AssetId != null &&
                wo.Division__c == 'Breast & Skeletal Health'
            ){
                validWOs.add(wo);
            }
        }
        
        if(validWOs.isEmpty()){
            return;
        }
        
        //Create tasks
        List<User> usersToCreateTasksFor = [
            SELECT Id
              FROM User
             WHERE Id IN (SELECT UserOrGroupId
                            FROM GroupMember
                           WHERE Group.Name = 'Service Contract Admin'
                         )
        ];
        
        List<Task> tasksToInsert = new List<Task>();
        for(WorkOrder wo : [
            SELECT Id
                  ,Asset.SBQQSC__CurrentContractLineItem__c
                  ,Asset.SBQQSC__CurrentContractLineItem__r.Description
              FROM WorkOrder
             WHERE Id IN :validWOs
               AND Asset.SBQQSC__CurrentContractLineItem__c != null
        ]){
            for(User use : usersToCreateTasksFor){
                Task tsk = new Task();
                tsk.OwnerId         = use.Id;
                tsk.WhatId          = wo.Asset.SBQQSC__CurrentContractLineItem__c;
                tsk.Subject         = 'De-Installation';
                tsk.Description     = wo.Asset.SBQQSC__CurrentContractLineItem__r.Description;
                tsk.ActivityDate    = Date.today();
                tasksToInsert.add(tsk);
            }
        }
        
        insert tasksToInsert;
        
    }
    
    /*------------------------------------------------------------
    Author:             Dave Mansell, Salesforce
    Description:        Queries all WOs for some ATBs and sets those ATBs to closed
    Inputs:             List of WorkOrder records that have just closed
    Returns:            N/A
    Test Class(es):     WorkOrderTriggerActions_Test.testCheckForClosedStatus
    ------------------------------------------------------------*/
    public static void closeParentATBs(List<WorkOrder> wos){
        //Collect ATB Ids
        Map<Id, Asset_Tech_Bulletin__c> atbsById = new Map<Id, Asset_Tech_Bulletin__c>();
        for(WorkOrder wo : wos){
            if(wo.Asset_Tech_Bulletin__c != null){
                atbsById.put(wo.Asset_Tech_Bulletin__c, null);
            }
        }
        
        //Query for ATB details
        atbsById = new Map<Id, Asset_Tech_Bulletin__c>([
            SELECT Id
              FROM Asset_Tech_Bulletin__c
             WHERE Id IN :atbsById.keySet()
        ]);
        
        //Update ATBs
        for(Asset_Tech_Bulletin__c atb : atbsById.values()){
            atb.Status__c = 'Closed';
        }
        update atbsById.values();
    }
    
    /*----------------------------------------------------------------------------------------
      Author:         Mani Sundaresan
      Description:    Method to update DSM Delegate and Zone Director Delegate fields when WO is created or WO Owner is updated
      Runs before update
      Inputs:         workOrders - The list of Work Orders
      oldWorkOrders - Map of pervious Work Order values
      Returns:        N/A
     
      History:
      <Date>          <Authors Name>      <Brief Description of Change>
      02/11/2017       Mani Sundaresan      Initial Creation
      07/31/2017      Mani Sundaresan     Static variable introduced to prevent recursion (HD-5255)
      11/28/2017      Mani Sundaresan     Static variable to prevent recursion has been removed(HD-6453)
      -------------------------------------------------------------------------------------------*/
    public static void updateDelegates(List<WorkOrder> workOrders, Map<Id, WorkOrder> oldWorkOrders) {

        //Variable Declaration
        Set<Id> ownerSet = new Set<Id> ();
        List<User> userList = new List<User> ();
        List<WorkOrder> updateWO = new List<WorkOrder> ();

        for (WorkOrder wo : workOrders) {
            if (wo.OwnerId != oldWorkOrders.get(wo.Id).OwnerId || (wo.Status != oldWorkOrders.get(wo.Id).Status && (wo.DSM_Delegate__c == null || wo.Zone_Director_Delegate__c == null))) {
                ownerSet.add(wo.OwnerId);
            }
        }

        if (ownerSet.size()> 0)
            userList = [SELECT ManagerId, Manager.DelegatedApproverId, Manager.ManagerId, Manager.Manager.DelegatedApproverId from User where Id IN :ownerSet];

        if (userList.size() > 0) {
            for (WorkOrder wo : workOrders) {
                for (User u : userList) {
                    if (wo.OwnerId == u.Id) {
                        if (u.Manager.DelegatedApproverId != null)
                            wo.DSM_Delegate__c = u.Manager.DelegatedApproverId;
                        else
                            wo.DSM_Delegate__c = u.ManagerId;

                        if (u.Manager.Manager.DelegatedApproverId != null)
                            wo.Zone_Director_Delegate__c = u.Manager.Manager.DelegatedApproverId;
                        else
                            wo.Zone_Director_Delegate__c = u.Manager.ManagerId;
                     }
                }
            }
                
       }
        
    }
    
    /*------------------------------------------------------------
    Author:             Dave Mansell, Salesforce
    Description:        Updates status of parent SAs
    Inputs:             List of WorkOrder records, map of old WorkOrder records
    Returns:            N/A
    Test Class(es):     WorkOrderTriggerActions_Test.testCheckToUpdateSAStatus
     History:
    <Date>           <Authors Name>       <Brief Description of Change>
    04/16/2019        Krishna             (US-0006815)Implement status mapping via metadata 
    
    ------------------------------------------------------------*/
    public static void checkToUpdateSAStatus(List<WorkOrder> wos, Map<Id, WorkOrder> oldMap){
        List<WorkOrder> validWOs = new List<WorkOrder>();
        for(WorkOrder wo : wos){
            WorkOrder old = oldMap.get(wo.Id);
            if(wo.Status != old.Status){
                validWOs.add(wo);
            }
        }
        
        if(validWOs.size() > 0){
            Map<Id, ServiceAppointment> sasByWOId = new Map<Id, ServiceAppointment>();
            for(ServiceAppointment sa : [
                SELECT Id
                      ,ParentRecordId
                  FROM ServiceAppointment
                 WHERE ParentRecordId IN : validWOs
            ]){
                sasByWOId.put(sa.ParentRecordId, sa);
            }
            
            Boolean shouldModifySAStatus = true;//Configuration_Settings__c.getInstance().WO_Status_should_affect_SA_Status__c;
            
            /*for(WorkOrder wo : validWOs){
                ServiceAppointment sa = sasByWOId.get(wo.Id);
                if(sa != null && shouldModifySAStatus == true){
                    if(wo.Status == 'Rejected'){
                        sa.Status = 'Rejected';
                    } else if(wo.Status == 'Cancelled'){
                        sa.Status = 'Canceled';
                    } else if(wo.Status == 'Re-opened'){
                        sa.Status = 'Re-opened';
                    } else if(wo.Status == 'Completed'){
                        sa.Status = 'Completed';
                    }
                }
            }*/
            //04/16/2019        Krishna             (US-0006815)Implement status mapping via metadata 
            Map<string,string> woStatusMap = new Map<string,string>();
            list<WoSa_Status__mdt> woStatusListDteails = new list<WoSa_Status__mdt>([SELECT ID, Object_id__c, SA_Status__c,WO_Status__c FROM WoSa_Status__mdt where Object_id__c='0WO' ]);
                system.debug('woStatusListDteails::::'+ woStatusListDteails);
                if(woStatusListDteails.size()>0)
                for(WoSa_Status__mdt woStatusDetail :woStatusListDteails){
                    system.debug('woStatusDetail::::'+ woStatusDetail);
                    woStatusMap.put(woStatusDetail.WO_Status__c,woStatusDetail.SA_Status__c);
                }
            for(WorkOrder wo : validWOs){
             system.debug('woStatusMap::::'+ woStatusMap);
             system.debug('wo.status::::'+ wo.status);
                if(woStatusMap.containsKey(wo.status)){
                ServiceAppointment sa = sasByWOId.get(wo.Id);
                    if(sa != null && shouldModifySAStatus == true){
                        sa.Status=woStatusMap.get(wo.Status);                    
                    }
                }
            }
            
            //Temporarily turn off the SA trigger to prevent infinite loop
            Trigger_Switch__c saSwitch = Trigger_Switch__c.getValues('ServiceAppointmentTrigger');
            Boolean switchWasOn = saSwitch.Active__c;
            if(switchWasOn){
                saSwitch.Active__c = false;
                update saSwitch;
            }
            update sasByWOId.values();
            if(switchWasOn){
                saSwitch.Active__c = true;
                update saSwitch;
            }
        }
    }
    
    /*------------------------------------------------------------
    Author:             Dave Mansell, Salesforce
    Description:        Updates status of parent Assets
    Inputs:             List of WorkOrder records, map of old WorkOrder records
    Returns:            N/A
    Test Class(es):     WorkOrderTriggerActions_Test.testCheckToUpdateAssets
    ------------------------------------------------------------*/
    public static void checkToUpdateAssets(List<WorkOrder> wos, Map<Id, WorkOrder> oldMap){
        Id rtId = GlobalUtility.getRecordTypeId('WorkOrder', 'B_SH_FE_Install_Upgrade_Move');
        
        List<WorkOrder> validWOs = new List<WorkOrder>();
        for(WorkOrder wo : wos){
            WorkOrder old = oldMap.get(wo.Id);
            if(wo.AssetId != null && wo.Status == 'Closed' && old.Status != 'Closed' && wo.RecordTypeId == rtId && (wo.Type__c == 'New Install' || wo.Type__c == 'De-Install')){
                validWOs.add(wo);
            }
        }
        
        if(validWOs.isEmpty()){
            return;
        }
        
        Map<Id, Asset> assetsToUpdateById = new Map<Id, Asset>();
        for(WorkOrder wo : [
            SELECT Id
                  ,Type__c
                  ,Completed_Date__c
                  ,Asset.Id
          FROM WorkOrder
         WHERE Id IN :wos
        ]){
            Asset asst = wo.Asset;
            
            if(wo.Type__c == 'New Install'){
                asst.Status = 'Installed';
                asst.InstallDate = Date.valueOf(wo.Completed_Date__c);
            } else if(wo.Type__c == 'De-Install'){
                asst.Status = 'Uninstalled';
                asst.Uninstall_Date__c = Date.valueOf(wo.Completed_Date__c);
            }
            
            assetsToUpdateById.put(asst.Id, asst);
        }
        
        update assetsToUpdateById.values();
    }
    
    /*------------------------------------------------------------
    Author:             Dave Mansell, Salesforce
    Description:        Updates field values on parent Cases
    Inputs:             List of WorkOrder records
    Returns:            N/A
    Test Class(es):     WorkOrderTriggerActions_Test.testCheckToUpdateParentCases
    ------------------------------------------------------------*/
    public static void checkToUpdateParentCases(List<WorkOrder> wos){
        Map<Id, Case> casesById = new Map<Id, Case>();
        for(WorkOrder wo : wos){
            if(wo.CaseId != null){
                casesById.put(wo.CaseId, null);
            }
        }
        
        if(casesById.size() > 0){
            casesById = new Map<Id, Case>([
                SELECT Id
                      ,(SELECT Id
                          FROM WorkOrders
                       )
                  FROM Case
                 WHERE Id IN :casesById.keySet()
            ]);
            
            for(Case cas : casesById.values()){
                cas.Work_Order_Associated__c = true;
                cas.Number_of_Related_Work_Orders__c = cas.WorkOrders.size();
            }
            
            update casesById.values();
        }
    }
    
    /*------------------------------------------------------------
    Author:             Dave Mansell, Salesforce
    Description:        Updates field values on parent Case Summaries
    Inputs:             List of WorkOrder records
    Returns:            N/A
    Test Class(es):     WorkOrderTriggerActions_Test.testCheckToUpdateParentCaseSummaries
    ------------------------------------------------------------*/
    public static void checkToUpdateParentCaseSummaries(List<WorkOrder> wos){
        Set<Id> summaryIds = new Set<Id>();
        for(WorkOrder wo : wos){
            if(wo.Case_Summary__c != null &&
                (wo.FE_Resolution__c != null ||
                 wo.FE_Update__c != null ||
                 wo.FE_RCC__c != null
                )
            ){
                summaryIds.add(wo.Case_Summary__c);
            }
        }
        
        if(summaryIds.size() > 0){
            updateParentCaseSummaries(summaryIds);
        }
    }
    
    /*------------------------------------------------------------
    Author:             Dave Mansell, Salesforce
    Description:        Updates field values on parent Case Summaries
    Inputs:             List of WorkOrder records, Map of old records
    Returns:            N/A
    Test Class(es):     WorkOrderTriggerActions_Test.testCheckToUpdateParentCaseSummaries
    ------------------------------------------------------------*/
    public static void checkToUpdateParentCaseSummaries(List<WorkOrder> wos, Map<Id, WorkOrder> oldMap){
        Set<Id> summaryIds = new Set<Id>();
        for(WorkOrder wo : wos){
            WorkOrder old = oldMap.get(wo.Id);
            if(wo.Case_Summary__c != null &&
                (wo.FE_Resolution__c != old.FE_Resolution__c ||
                 wo.FE_Update__c != old.FE_Update__c ||
                 wo.FE_RCC__c != old.FE_RCC__c
                )
            ){
                summaryIds.add(wo.Case_Summary__c);
            }
        }
        
        if(summaryIds.size() > 0){
            updateParentCaseSummaries(summaryIds);
        }
    }
    
    private static void updateParentCaseSummaries(Set<Id> summaryIds){
        List<Case_Summary__c> summaries = [
            SELECT Id
                  ,(SELECT Id
                          ,WorkOrderNumber
                          ,Owner.Name
                          ,FE_Resolution__c
                          ,FE_Update__c
                          ,FE_RCC__c
                      FROM Work_Orders__r
                     ORDER BY CreatedDate ASC
                   )
              FROM Case_Summary__c
             WHERE Id IN :summaryIds
        ];
        
        for(Case_Summary__c summary : summaries){
            List<String> resStrings = new List<String>();
            List<String> updStrings = new List<String>();
            List<String> rccStrings = new List<String>();
            
            for(WorkOrder wo : summary.Work_Orders__r){
                String introString = '[' + wo.Owner.Name + ' - WO# ' + wo.WorkOrderNumber + '] ';
                if(wo.FE_Resolution__c != null){
                    resStrings.add(introString + wo.FE_Resolution__c);
                }
                if(wo.FE_Update__c != null){
                    updStrings.add(introString + wo.FE_Update__c);
                }
                if(wo.FE_RCC__c != null){
                    rccStrings.add(introString + wo.FE_RCC__c);
                }
                summary.FE_Resolution__c    = String.join(resStrings, '\n');
                summary.FE_Update__c        = String.join(updStrings, '\n');
                summary.FE_RCC__c           = String.join(rccStrings, '\n');
              
            }
        }   
        update summaries;
    }
    
      /*------------------------------------------------------------
    Author:             KRISHNA, APPS ASSOCIATES
    Description:        Queries all WOs for some Cases and sets those cases to closed sometimes
    Inputs:             List of WorkOrder records that have just closed(US-0007008)
    Returns:            N/A
    Test Class(es):     WorkOrderTriggerActions_Test.testCheckForClosedStatus
    ------------------------------------------------------------*/
    public static void CloseParentCasesWhenMedicalAesthetics(List<WorkOrder> wos){
        //Collect Case Ids
        Map<Id, Case> casesById = new Map<Id, Case>();
        for(WorkOrder wo : wos){
            if(wo.CaseId != null){
                casesById.put(wo.CaseId, null);
            }
        }
        System.debug('casesById::::out'+casesById);
        //Query for Case details
        casesById = new Map<Id, Case>([
            SELECT Id
                  ,(SELECT Id,Division__c,Estimate_status__c
                          ,Status
                      FROM WorkOrders
                   )
              FROM Case
             WHERE Id IN :casesById.keySet()
        ]);
        
        //Update cases where needed
        List<Case> casesToUpdate = new List<Case>();
        for(Case cas : casesById.values()){
            Boolean allWOsAreClosed = true;
            for(WorkOrder wo : cas.WorkOrders){
                if(wo.Status != 'Closed' && wo.Status != 'Cancelled'){
                    allWOsAreClosed = false;
                }
            }
            System.debug('allWOsAreClosed::::'+allWOsAreClosed);
            if(allWOsAreClosed == true){
                cas.Status = 'Closed';
                casesToUpdate.add(cas);
            }
            System.debug('allWOsAreClosed::::out'+allWOsAreClosed);
        }
        
        System.debug('casesToUpdate::::out'+casesToUpdate);
        if(casesToUpdate.size()>0){
            update casesToUpdate;
        }
    }
}