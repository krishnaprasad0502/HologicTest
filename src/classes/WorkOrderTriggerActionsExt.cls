/*------------------------------------------------------------
Author:     Mani Sundaresan
Description:  Trigger framework for WorkOrder object
Test Class:   Test_WorkOrderTriggerActionsExt

History:
<Date>      <Authors Name>    <Brief Description of Change>
02/11/2017  Mani Sundaresan    Initial Creation (HD-3226)
02/23/2017  Mani Sundaresan    setDeInstallationType
02/23/2017  Mani Sundaresan    deInstallationWOClosure
07/31/2017  Mani Sundaresan    Static variable introduced to prevent recursion (HD-5255) 
8/7/2017    John Christy       updated to for serial number (US-0002609) 
09/27/2017  Mani Sundaresan    sendOwnerNotification - Notification to WO Owner(US-0003385)  
27/09/2017  Krishna prasad     update case ststus to Resolved  US-0003409 
23/10/2017  Krishna Prasad     update case Region to Resolved  HD-5768   
27/10/2018  Raj Sharan         Update to retrieve record type IDs from Custom Settings (US-0003556)
11/27/2017  krishna Prasad     Updated the logic  when close WO whichcreate Service Order with corresponding order Line on Professional Service(US-0003670) 
11/28/2017  Mani Sundaresan    Removed the variable to prevent recursion from updateDelegates function (HD-6453)
11/29/2017  Mani Sundaresan    Update sendOwnerNotification method to trigger only when Push Notification & Escalation fields are enabled by the Entitlement process (US-0003385)
6/02/2018   krishna Prasad      Updated the logic--  Ability to generate new Orders from a Work Order that was re-opened (US-0003810)
------------------------------------------------------------*/
public with sharing class WorkOrderTriggerActionsExt{
    
    //Variable Declaration Section
    private static Set<String> closedStatuses = new Set<String>{'Closed', 'Apps Closed', 'Cares Closed', 'Connectivity Closed'};
    private static Configuration_Settings__c orgDefaults = Configuration_Settings__c.getOrgDefaults();
    private static Record_Type_IDs__c recordTypeIds = Record_Type_IDs__c.getOrgDefaults();
    private static Id integrationProfileId = [select Id, Name from Profile where Name LIKE 'Integration API%' limit 1].Id;
    
    
    //Static variable to prevent recursion in before update
    static Boolean wosetDeInstallationType = false;
    static Boolean wodeInstallationWOClosure = false;
    static Boolean wocreateOrderAndOrderItems = false;
    static Boolean woupdateInstalledAssets = false;
    static Boolean sendOwnerEmail = false;
    static Boolean woCaseUpdate = false;
    
    //27/09/2017(Krishna prasad)-Added Set-As part of US-0003409 
    private static Set<String> woStatus = new Set<String>{'Closed', 'Cancelled', 'Resolved','Completed'};
    private static Set<String> ResolvedStatuses = new Set<String> {'Resolved'};
    private static Set<String> CompletedStatuses = new Set<String> {'Completed'};
    private static Set<String> closedStatus = new Set<String> {'Closed'};
    private static Set<String> cancelledStatuses = new Set<String> {'Cancelled'};
    
    private static id woliProfessionalServicesRecordTypeId = recordTypeIds.WOL_Professional_Services_Reco__c;
    
    
    
    /*--------------------------------------------------------------
    Author:      Krishna Prasad
    Company:     Apps Associates
    Description: update case status to Resolved 
    Inputs:      string 
    Returns:    N/A
      
    History:
    <Date>         <Authors Name>       <Brief Description of Change>
    27/09/2017     Krishna Prasad      update case ststus to Resolved  US-0003409 
    23/10/2017     Krishna Prasad      update case Region to Resolved  HD-5768
    --------------------------------------------------------------*/

            
    public static void setWorkOrderCaseStatus(List<WorkOrder> workOrders, Map<Id, WorkOrder> oldWorkOrders){
        Set<ID> caseIds = new Set<ID> ();   
        List<Case> CaseStatusUpdatelist  = new List<Case> ();   
         system.debug('woCaseUpdate---'+woCaseUpdate);
        if(!woCaseUpdate){ 
        for(WorkOrder w : workOrders){
            system.debug('woStatus:'+w.Status);
            System.debug('H1:'+CompletedStatuses.contains(w.Status));
            System.debug('H2:'+ResolvedStatuses.contains(w.Status));
         //if(CompletedStatuses.contains(w.Status) || (ResolvedStatuses.contains(w.Status))){
         if(woStatus.contains(w.Status)){
            caseIds.add(w.CaseId);
         }
        }
             system.debug('caseIds---'+caseIds.size());
        if (caseIds.size() > 0) {
        
            // query cases realted to our closed workorder that are not billable
            for (Case c :[Select Id, Status, Reason, RecordTypeId, Billable__c, (Select Id, Status From WorkOrders) From Case Where Id IN :caseIds]) {
                //Count the number of Cancelled & Closed WO's per case
                Integer cancelledWOCount = 0;
                Integer closedWOCount = 0;
                Integer ResolvedWOCount = 0;
                Integer CompletedWOCount = 0;
                Integer OthersWOCount = 0;
                List<WorkOrder> woList = c.getSObjects('WorkOrders');
                system.debug('woList---'+woList.size());
                if(woList.size()>0)            
                for(WorkOrder wo : (List<WorkOrder>)c.getSObjects('WorkOrders')){
                    system.debug('woStatus2:'+wo.Status);    
                    if(woStatus.contains(wo.Status)){
                        system.debug('woStatus2:'+wo.Status);
                        System.debug('isClosed:'+closedStatus.contains(wo.Status));
                        if(cancelledStatuses.contains(wo.Status)){
                            cancelledWOCount++;
                        }
                        if(closedStatus.contains(wo.Status)){
                            closedWOCount++;
                        }
                        if(ResolvedStatuses.contains(wo.Status)){
                            ResolvedWOCount++;
                        }
                        if(CompletedStatuses.contains(wo.Status)){
                            CompletedWOCount++;
                        }
                    }
                }
                
                system.debug('CompletedWOCount --'+CompletedWOCount );
                system.debug('ResolvedWOCount--'+ResolvedWOCount);
                system.debug('closedWOCount--'+closedWOCount);
                system.debug('cancelledWOCount--'+cancelledWOCount);
               
                
                if((CompletedWOCount + ResolvedWOCount) > 0 && ((CompletedWOCount + ResolvedWOCount + cancelledWOCount+ closedWOCount) == c.WorkOrders.size())){
                    c.status = 'Resolved';
                    /*23/10/2017     Krishna Prasad      update case Region to Resolved  HD-5768                        
                    --------------------------------STARt NOTE ------------------------------
                    The Case History should reflect that the Case Staus was set to resolved by the OWrk Order.  update the Case Reason field with Resolved via Work Order value.
                    ----------------------------- END NOTE ---------------------------------*/
                    c.Reason = 'Resolved via work order';

                    CaseStatusUpdatelist.add(c);
                }
                
            }
           
        }   
        if(CaseStatusUpdatelist.size()>0){
            Database.SaveResult[] lsr = Database.update(CaseStatusUpdatelist, false);

            for (Integer index = 0; index<lsr.size(); index++) {
                if (!lsr[index].isSuccess()) {
                    workOrders[index].addError('Failed to update the related Case: ' + lsr[index].getErrors() [0].getMessage());
                }
            }
            woCaseUpdate = true;
        }
            
        
        }
    }
    
    /*----------------------------------------------------------------------------------------
    Author:         Mani Sundaresan
    Description:    Method to create B&SH Add a Part WOLI when a Billable PM WO is created
                    Runs after insert
    Inputs:         workOrders - The list of Work Orders
                    
    Returns:        N/A
    
    History:
    <Date>          <Authors Name>      <Brief Description of Change>
    02/11/2017       Mani Sundaresan      Initial Creation (HD-3226)
    -------------------------------------------------------------------------------------------*/
    public static void createPMWOLI(List<WorkOrder> woList){
        
        //Variable Declaration
        List<WorkOrderLineItem> woliList = new List<WorkOrderLineItem>();
        List<WorkOrder> workOrderList = new List<WorkOrder>();
        List<WorkOrder> finalWOList = new List<WorkOrder>();
        List<Id> woBillableList = new List<Id>();
        List<PriceBookEntry> pbeList = new List<PriceBookEntry>();
        system.debug('woList-----'+woList);
        for(WorkOrder wo : woList){
            system.debug('recordTypeIds.Work_Order_B_SH_Billable_PM__c----'+recordTypeIds.Work_Order_B_SH_Billable_PM__c);
            system.debug('wo.RecordTypeId----'+wo.RecordTypeId);
            if(String.valueOf(wo.RecordTypeId).contains(recordTypeIds.Work_Order_B_SH_Billable_PM__c))
                woBillableList.add(wo.Id);
        }
            
        if(woBillableList.size() > 0)
            workOrderList = [SELECT Id, Asset.Product2Id, Pricebook2Id, Case.Asset.Product2Id, Case.Asset.Product2.PM_Product__c from WorkOrder where Id IN :woBillableList AND Case.Asset.Product2.PM_Product__c != null]; 
            
        System.debug('workOrderList:'+workOrderList);
        
        woBillableList.clear();    
        if(workOrderList.size() > 0){
            for(WorkOrder wo : workOrderList)
                woBillableList.add(wo.Case.Asset.Product2.PM_Product__c);
                
            System.debug('productlist:'+woBillableList);
            
            if(woBillableList.size() > 0)
                pbeList = [SELECT Id, Pricebook2Id, Product2Id, Product2.PM_Product__c from PriceBookEntry where Product2Id IN :woBillableList];
        }
        
        if(workOrderList.size() > 0 && pbeList.size() > 0){
            for(WorkOrder wo : workOrderList){
                for(PriceBookEntry pbe : pbeList){
                    System.debug('wo Pricebook:'+wo.Pricebook2Id);
                    System.debug('pbe Pricebook:'+pbe.Pricebook2Id);
                    System.debug(wo.Pricebook2Id == pbe.Pricebook2Id);
                    if(wo.Pricebook2Id == pbe.Pricebook2Id){
                        WorkOrderLineItem woli = new WorkOrderLineItem(RecordTypeId = recordTypeIds.WOLI_Add_a_Part__c, Quantity = 1, StartDate=System.now(), WorkOrderId = wo.Id, PricebookEntryId = pbe.Id);
                        woliList.add(woli);
                    }
                }
            }
        }
        
        System.debug('WOLIList:'+woliList);
        
        if(woliList.size() > 0){
            Database.SaveResult[] lsr = Database.insert(woliList,false);
              
        
            for(Integer index = 0; index < lsr.size(); index++){
                if(!lsr[index].isSuccess()){
                    woList[index].addError('Failed to create WorkOrder Line Item: '+lsr[index].getErrors()[0].getMessage());
                }
            }
        }
      
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



    
    /*----------------------------------------------------------------------------------------
      Author:         Mani Sundaresan
      Description:    Method to assign the De-Installed Asset to the WO if the Case has De-Installed asset populated.
      Runs before update
      Inputs:         workOrders - The list of Work Orders
      oldWorkOrders - Map of pervious Work Order values
      Returns:        N/A
     
      History:
      <Date>          <Authors Name>      <Brief Description of Change>
      02/23/2017      Mani Sundaresan      Initial Creation
      07/31/2017      Mani Sundaresan     Static variable introduced to prevent recursion (HD-5255)
      -------------------------------------------------------------------------------------------*/
    public static void setDeInstallationType(List<WorkOrder> workOrders, Map<Id, WorkOrder> oldWorkOrders) {

        List<Id> serviceTypeIdList = new List<Id> ();
        List<CKSW_BASE__Service__c> serviceList = new List<CKSW_BASE__Service__c> ();
        List<Id> woIdList = new List<Id> ();
        Map<Id, WorkOrder> woMap;

        if (!wosetDeInstallationType) {
            for (WorkOrder wo : workOrders)
            if (String.valueOf(wo.RecordTypeId).contains(recordTypeIds.Work_Order_B_SH_FE_Install_Upgrade_Move__c) && wo.FSL_INTG__Service__c != null) {
                serviceTypeIdList.add(wo.FSL_INTG__Service__c);
                woIdList.add(wo.Id);
            }

            if (woIdList.size() > 0)
            woMap = new Map<Id, WorkOrder> ([SELECT Id, Case.De_Installed_Asset__c, Case.RecordTypeId from WorkOrder where Id IN :woIdList]);

            if (serviceTypeIdList.size() > 0)
            serviceList = [SELECT Id, CKSW_BASE__Service_Type__r.Name from CKSW_BASE__Service__c where Id IN :serviceTypeIdList AND CKSW_BASE__Service_Type__r.Name LIKE '%De-Installation%'];

            if (serviceList.size() > 0)
            for (WorkOrder wo : workOrders) {
                for (CKSW_BASE__Service__c serv : serviceList) {
                    if (wo.FSL_INTG__Service__c == serv.Id) {
                        wo.FSO__Type__c = 'De-Installation';
                        if (woMap.get(wo.Id) != null && woMap.get(wo.Id).Case.De_Installed_Asset__c != null)
                        wo.AssetId = woMap.get(wo.Id).Case.De_Installed_Asset__c;
                        else if (woMap.get(wo.Id) != null && woMap.get(wo.Id).Case.De_Installed_Asset__c == null && String.valueOf(woMap.get(wo.Id).Case.RecordTypeId).contains(recordTypeIds.Case_B_SH_Install__c) && String.valueOf(UserInfo.getProfileId()).substring(0, 15) != String.valueOf(integrationProfileId).substring(0, 15))
                        wo.addError('Kindly populate the De-Installed Asset on the Case.');

                        wosetDeInstallationType = true;
                    }
                }
            }
        }
    }
    
    /*----------------------------------------------------------------------------------------
      Author:         Mani Sundaresan
      Description:    Method to update the asset details on WO Closure.
      Runs before update
      Inputs:         workOrders - The list of Work Orders
      oldWorkOrders - Map of pervious Work Order values
      Returns:        N/A
     
      History:
      <Date>          <Authors Name>      <Brief Description of Change>
      02/23/2017      Mani Sundaresan      Initial Creation
      07/31/2017      Mani Sundaresan     Static variable introduced to prevent recursion (HD-5255)
      -------------------------------------------------------------------------------------------*/
    public static void deInstallationWOClosure(List<WorkOrder> workOrders, Map<Id, WorkOrder> oldWorkOrders) {

        //Variable Declaration Section
        Set<Id> woIdSet = new Set<Id> ();
        List<WorkOrder> woList = new List<WorkOrder> ();
        List<ContractLineItem> cliList = new List<ContractLineItem> ();
        List<Asset> assetList = new List<Asset> ();
        Set<Id> assetSet = new Set<Id> ();
        List<Task> taskList = new List<Task> ();
        Id grpId;
        List<GroupMember> serviceContractAdmin;


        if (!wodeInstallationWOClosure) {

            for (WorkOrder wo : workOrders) {

                System.debug('Yup:' + oldWorkOrders.get(wo.Id).Status != wo.Status);
                System.debug('wo status:' + wo.Status);
                System.debug('Status Check:' + closedStatuses.contains(wo.Status));
                System.debug(wo.FSO__Type__c == 'De-Installation');
                System.debug(String.valueOf(wo.RecordTypeId).contains(recordTypeIds.Work_Order_B_SH_FE_Install_Upgrade_Move__c));

                if (oldWorkOrders.get(wo.Id).Status != wo.Status && closedStatuses.contains(wo.Status) && wo.FSO__Type__c == 'De-Installation' && String.valueOf(wo.RecordTypeId).contains(recordTypeIds.Work_Order_B_SH_FE_Install_Upgrade_Move__c))
                {
                    woIdSet.add(wo.Id);
                }
            }

            if (woIdSet.size() > 0) {
                woList = [SELECT Id, Case.De_Installed_Asset__c, AssetId, Case.RecordTypeId, Case.Type from WorkOrder where Id IN :woIdSet];
                grpId = [SELECT Id from group where Name = 'Service Contract Admin' limit 1].Id;
                serviceContractAdmin = [SELECT Id, UserOrGroupId from GroupMember where GroupId = :grpId];
            }
            System.debug('wolist:' + woList);

            if (woList.size() > 0)
            for (WorkOrder wo1 : workOrders) {
                for (WorkOrder wo : woList) {
                    if (wo1.Id == wo.Id && wo.Case.De_Installed_Asset__c != null) {
                        wo1.AssetId = wo.Case.De_Installed_Asset__c;
                        assetSet.add(wo.Case.De_Installed_Asset__c);
                    }
                    else if (wo1.Id == wo.Id && String.valueOf(wo.Case.RecordTypeId).contains(recordTypeIds.Case_B_SH_Service__c) && wo.Case.Type == 'De-Installation') {
                        System.debug('HW:');
                        if (wo.AssetId != null)
                        assetSet.add(wo.AssetId);
                    }
                }
            }

            System.debug('AssetSet:' + assetSet);

            if (assetSet.size() > 0) {
                assetList = [SELECT Id, Status, Uninstall_Date__c from Asset where Id IN :assetSet OR ParentId IN :assetSet];
                cliList = [SELECT Id, AssetId, Description from ContractLineItem where AssetId IN :assetSet AND Status = 'Active'];
            }

            System.debug('assetList:' + assetList);

            if (assetList.size() > 0)
            for (Asset a : assetList) {
                a.Status = 'Uninstalled';
                a.Uninstall_Date__c = System.today();
            }

            if (cliList.size() > 0)
            for (ContractLineItem cli : cliList) {
                for (GroupMember gm : serviceContractAdmin) {
                    Task t = new Task(OwnerId = gm.UserOrGroupId, WhatId = cli.Id, Description = cli.Description, Subject = 'De-Installation');
                    taskList.add(t);
                }
            }

            if (assetList.size() > 0) {
                Database.SaveResult[] lsr = Database.update(assetList, false);
                //update assetList;

                for (Integer index = 0; index<lsr.size(); index++) {
                    if (!lsr[index].isSuccess()) {
                        workOrders[index].addError('Failed to update Asset: ' + lsr[index].getErrors() [0].getMessage());
                    }
                }

                wodeInstallationWOClosure = true;
            }

            if (taskList.size()> 0) {
                Database.SaveResult[] lsr = Database.insert(taskList, false);
                //insert taskList;

                for (Integer index = 0; index<lsr.size(); index++) {
                    if (!lsr[index].isSuccess()) {
                        workOrders[index].addError('Failed to create Task: ' + lsr[index].getErrors() [0].getMessage());
                    }
                }


            }

        }
    }
    
      /*------------------------------------------------------------
      Author:         Denise Bacher
      Company:        Salesforce.com
      Description:    If the WorkOrder is closed and was an Install, update the WorkOrder's Asset's Status and Install Date 
      Runs after update
      Inputs:         workOrders - The list of Work Orders
      oldWorkOrders - Map of pervious Work Order values
      Returns:        N/A
     
      History:
      <Date>          <Authors Name>      <Brief Description of Change>
      09/01/2016      Denise Bacher       Initial Creation (REQ165)
      05/04/2017      Mani Sundaresan     Moved the method from WorkOrderTriggerActions class (US-2573)
      07/31/2017      Mani Sundaresan     Static variable introduced to prevent recursion (HD-5255)
      ------------------------------------------------------------*/
    public static void updateInstalledAssets(List<WorkOrder> workOrders, Map<Id, WorkOrder> oldWorkOrders) {
        List<Asset> installedAssets = new List<Asset> ();
        Set<Asset> assetSets = new Set<Asset> ();
        List<Asset> assetList = new List<Asset> ();
        List<Id> assetIdList = new List<Id> ();

        if (!woupdateInstalledAssets) {

            for (WorkOrder wo : workOrders) {
                WorkOrder oldwo = oldWorkOrders != null ? oldWorkOrders.get(wo.Id) : null;
                System.debug('Status:' + wo.Status);
                System.debug(closedStatuses.contains(wo.Status));
                System.debug(wo.FSO__Type__c == 'New Install');
                System.debug(String.valueOf(wo.RecordTypeId).contains(recordTypeIds.Work_Order_B_SH_FE_Install_Upgrade_Move__c));
                System.debug(wo.AssetId != null);


                if ((oldwo == null || oldwo.Status != wo.Status) && closedStatuses.contains(wo.Status) && wo.FSO__Type__c == 'New Install' && String.valueOf(wo.RecordTypeId).contains(recordTypeIds.Work_Order_B_SH_FE_Install_Upgrade_Move__c) && wo.AssetId != null) {
                    assetIdList.add(wo.AssetId);
                    //assetList.add(wo.Asset);
                }
            }

            if (assetIdList.size()> 0)
            assetList = [SELECT Id, Status, InstallDate from Asset where Id IN :assetIdList];

            System.debug('assetList:' + assetList.size());

            if (assetList.size() > 0) {
                for (WorkOrder wo : workOrders) {
                    for (Asset updateAsset : assetList)
                    {
                        System.debug('update asset:' + updateasset);
                        System.debug('update asset:' + updateAsset.InstallDate);
                        System.debug('update asset:' + wo);
                        System.debug('update asset:' + wo.FSO__Completed_Date__c);
                        if (wo.AssetId == updateAsset.Id && updateAsset.InstallDate == null && wo.FSO__Completed_Date__c != null) {
                            updateAsset.InstallDate = date.valueof(wo.FSO__Completed_Date__c);

                            updateAsset.Status = 'Installed';
                            assetSets.add(updateAsset);
                        }
                    }
                }
            }

            System.debug('assetSet:' + assetSets);
            if (assetSets.size() > 0)
            installedAssets.addAll(assetSets);

            System.debug('installedAssets:' + installedAssets);


            if (installedAssets.size() > 0) {
                Database.SaveResult[] lsr = Database.update(installedAssets, false);
                //update installedAssets;

                for (Integer index = 0; index<lsr.size(); index++) {
                    if (!lsr[index].isSuccess()) {
                        workOrders[index].addError('Failed to update Asset: ' + lsr[index].getErrors() [0].getMessage());
                    }
                }

                woupdateInstalledAssets = true;
            }
        }


    }
    
     /*------------------------------------------------------------
      Author:         Sumit Gupta
      Company:        Salesforce.com
      Description:    When a Work Order is Closed an Order should be created that mirrors the Work Order that created it and sent to eBS 
      Inputs:         workOrders - The list of Work Orders
      oldWorkOrders - Map of pervious Work Order values
      Returns:        N/A
     
      History:
      <Date>          <Authors Name>      <Brief Description of Change>
      07/26/2016      Sumit Gupta         Initial Creation (US1330)
      08/11/2016      Marc Goldstein      Update to mappings (US1439)
      09/20/2016      Denise Bacher       remove setting Order.EndDate
      10/04/2016      Denise Bacher       Update to not reprocess this function if a WO has been reopened and closed again (HD-1322)
      07/31/2017      Mani Sundaresan     Static variable introduced to prevent recursion (HD-5255)
      11/27/2017     krishna Prasad       Updated the logic  when close WO whichcreate Service Order with corresponding order Line on Professional Service(US-0003670) 
      6/02/2018       krishna Prasad      Updated the logic--  Ability to generate new Orders from a Work Order that was re-opened (US-0003810)  
------------------------------------------------------------*/
    public static void createOrderAndOrderItems(List<WorkOrder> workOrders, Map<Id, WorkOrder> oldWorkOrders) {
        /*
          1) Filter Closed WorkOrders
          2) Query WorkOrderLineItems
          3) Create an Order for each WorkOrder that has atleast one WorkOrderlineItem
          4) Insert Orders
          5) Create an OrderItem for each WorkOrderLineItem
          6) Insert OrderItems
          7) Update WorkOrderLineItems with OrderItemId
          8) Update WorkOrders with OrderId
         */
        Id orderRecordTypeId = recordTypeIds.Order_B_SH_Service_Order__c;

        // Filter closed WorkOrders that require an order to be created
        Map<Id, WorkOrder> closedWorkOrders = new Map<Id, WorkOrder> ();
        //List to query closed WO details
        List<Id> closedWOList = new List<Id> ();

        if (!wocreateOrderAndOrderItems) {

            for (WorkOrder wo : workOrders) {
                System.debug('WO Status***:' + wo.Status);
                WorkOrder oldwo = oldWorkOrders != null ? oldWorkOrders.get(wo.Id) : null;
                //6/02/2018       krishna Prasad      Updated the logic--  Ability to generate new Orders from a Work Order that was re-opened (US-0003810)
                //if (!wo.SYS_Reopened__c && (oldwo == null || oldwo.Status != wo.Status) && closedStatuses.contains(wo.Status) && wo.Requires_Order__c && wo.Order__c == null) {
                if ((oldwo == null || oldwo.Status != wo.Status) && closedStatuses.contains(wo.Status) && wo.Requires_Order__c ) {
                    //closedWorkOrders.put(wo.Id, wo);
                    closedWOList.add(wo.Id);
                }
            }
             System.debug('WO closedWOList***:' + closedWOList);

            if (closedWOList.size()> 0)
            for (WorkOrder wo :[SELECT Id, RecordTypeId, StartDate, FSO__Completed_Date__c, AssetId, AccountId, Order__c, Requires_Order__c, Status, SYS_Reopened__c, CaseId, WorkOrderNumber, OwnerId, Pricebook2Id, CurrencyIsoCode, Description from WorkOrder where Id IN :closedWOList]) {
                closedWorkOrders.put(wo.Id, wo);
            }

            // If no newly closed WorkOrders, return
            if (closedWorkOrders.isEmpty()) {
                return;
            }

            // Query Custom Metadata Type to get applicable WorkOrderLineItem Record Types and FSO Types 
            Set<Id> recordTypeIdSet = new Set<Id> ();
            Set<Id> recordTypeIdWithFSOTypes = new Set<Id> ();
            Set<String> fsoTypes = new Set<String> ();
            List<Order_Sync_Criteria__mdt> orderSyncCriteria = [SELECT FSO_Types__c, Sync_All_FSO_Types__c, Work_Order_Line_Record_Type__c
                                                                FROM Order_Sync_Criteria__mdt
                                                               ];

            for (Order_Sync_Criteria__mdt syncCriteria : orderSyncCriteria) {
                Id recordTypeId = GlobalUtility.getRecordTypeId('WorkOrderLineItem', syncCriteria.Work_Order_Line_Record_Type__c);

                if (syncCriteria.Sync_All_FSO_Types__c) {
                    // No need to check FSO types in this case 
                    recordTypeIdSet.add(recordTypeId);
                }
                else {
                    recordTypeIdWithFSOTypes.add(recordTypeId);
                    if (String.isNotBlank(syncCriteria.FSO_Types__c)) {
                        fsoTypes.addAll(syncCriteria.FSO_Types__c.split(','));
                    }
                }
            }

            // Query Custom Metadata Type to get FSO Type and Line Type mappings 
            Map<String, String> woLineRTtoOILineTypes = new Map<String, String> ();
            List<Order_Sync_Map__mdt> orderSyncMap = [SELECT Line_Type__c, Work_Order_Line_RecordType__c
                                                      FROM Order_Sync_Map__mdt
                                                     ];

            for (Order_Sync_Map__mdt syncMap : orderSyncMap) {
                woLineRTtoOILineTypes.put(syncMap.Work_Order_Line_RecordType__c, syncMap.Line_Type__c);
            }
            
            
            system.debug('closedWorkOrders.keySet():::::::'+closedWorkOrders.keySet());
            system.debug('recordTypeIdWithFSOTypes:::::::'+recordTypeIdWithFSOTypes);
            system.debug('fsoTypes:::::::'+fsoTypes);
            system.debug('recordTypeIdSet:::::::'+recordTypeIdSet);
           //6/02/2018       krishna Prasad      Updated the query with field "Order_Line_Item__c"--  Ability to generate new Orders from a Work Order that was re-opened (US-0003810)
            // Query WorkOrderLineItems for the given WorkOrders where Reorder_Part__c is true
           Map<Id, WorkOrderLineItem> workOrderLineItems = new Map<Id, WorkOrderLineItem> ([
                                                                                            SELECT Id, WorkOrderId, RecordTypeId, RecordType.DeveloperName, Description, PricebookEntryId, Quantity, UnitPrice, Net_Price__c, Entitlement__c,
                                                                                            Exclude_From_Invoice__c,Order_Line_Item__c, Case__c, RMA_Work_Order_Line_Record_Id__c, Ship_to_Site_Location__c, Returned_Asset__c, Serial_Number__c, 
                                                                                            StartDate, EndDate, FSO__Location__c, FSO__Type__c, FSO__LocationStock__r.FSO__Asset__c, Return_Reason_Code__c, Category_Code__c
                                                                                            FROM WorkOrderLineItem
                                                                                            WHERE WorkOrderId IN :closedWorkOrders.keySet()
                                                                                            AND PricebookEntryId != null
                                                                                            AND((RecordTypeId IN :recordTypeIdWithFSOTypes AND FSO__Type__c IN :fsoTypes) OR RecordTypeId IN :recordTypeIdSet OR RecordTypeId =: woliProfessionalServicesRecordTypeId )
                                                                                            ]);

            
            // Query WorkOrderLineItems for the given WorkOrders where Reorder_Part__c is true
            /*Map<Id, WorkOrderLineItem> workOrderLineItems = new Map<Id, WorkOrderLineItem> ([
                                                                                            SELECT Id, WorkOrderId, RecordTypeId, RecordType.DeveloperName, Description, PricebookEntryId, Quantity, UnitPrice, Net_Price__c, Entitlement__c,
                                                                                            Exclude_From_Invoice__c, Case__c, RMA_Work_Order_Line_Record_Id__c, Ship_to_Site_Location__c, Returned_Asset__c, Serial_Number__c, 
                                                                                            StartDate, EndDate, FSO__Location__c, FSO__Type__c, FSO__LocationStock__r.FSO__Asset__c, Return_Reason_Code__c, Category_Code__c
                                                                                            FROM WorkOrderLineItem
                                                                                            WHERE WorkOrderId IN :closedWorkOrders.keySet()
                                                                                            AND PricebookEntryId != null
                                                                                            AND((RecordTypeId IN :recordTypeIdWithFSOTypes AND FSO__Type__c IN :fsoTypes) OR RecordTypeId IN :recordTypeIdSet)
                                                                                            ]);*/

            
            
            // If no WorkOrderLineItems, no need to create Order and OrderItem
            if (workOrderLineItems.isEmpty()) {
                return;
            }
            system.debug('workOrderLineItems::::::100011:'+workOrderLineItems);
            Set<Id> caseIds = new Set<Id> ();
            Map<Id, List<WorkOrderLineItem>> workOrderToWOLineItems = new Map<Id, List<WorkOrderLineItem>> ();
            integer counter=0;
            for (Id woliId : workOrderLineItems.keySet()) {
                WorkOrderLineItem woli = workOrderLineItems.get(woliId);

                WorkOrder wo = closedWorkOrders.get(woli.WorkOrderId);
                if (wo.CaseId != null) {
                    caseIds.add(wo.CaseId);
                }
                system.debug('woli::::::111:'+woli);
                //6/02/2018       krishna Prasad      Updated logic--  Ability to generate new Orders from a Work Order that was re-opened (US-0003810)
                /*if (!workOrderToWOLineItems.containsKey(woli.WorkOrderId)) {                 
                    workOrderToWOLineItems.put(woli.WorkOrderId, new List<WorkOrderLineItem> ());
                }
                workOrderToWOLineItems.get(woli.WorkOrderId).add(woli);
                */
                system.debug('woli.WorkOrderId::::::'+woli.WorkOrderId);
                system.debug('woli.Order_Line_Item__c::::::'+woli.Order_Line_Item__c);
                if ((woli.Order_Line_Item__c == null)) {
                   
                    if(counter ==0){
                    workOrderToWOLineItems.put(woli.WorkOrderId, new List<WorkOrderLineItem> ());
                    }
                    system.debug('woli.WorkOrderId:::::'+woli.WorkOrderId);
                    if(woli.WorkOrderId  != null && workOrderToWOLineItems.containsKey(woli.WorkOrderId)){
                    workOrderToWOLineItems.get(woli.WorkOrderId).add(woli);
                    }
                   
                    counter++;
                    
                }
                
                
            }
            
            // Query Case records
            Map<Id, Case> cases = new Map<Id, Case> ([
                                                     SELECT Id, Customer_Name__c, Bill_To_Customer__c, Bill_To_Site_Location__c, Ship_To_Customer__c, Ship_To_Site_Location__c
                                                     , Bill_to_Customer__r.BillingStreet, Bill_to_Customer__r.BillingCity, Bill_to_Customer__r.BillingStateCode
                                                     , Bill_to_Customer__r.BillingPostalCode, Bill_to_Customer__r.BillingCountryCode
                                                     , Ship_to_Site_Location__r.Address_Line_1__c, Ship_to_Site_Location__r.Address_Line_2__c, Ship_to_Site_Location__r.Address_Line_3__c, Ship_to_Site_Location__r.Address_Line_4__c
                                                     , Ship_to_Site_Location__r.City__c, Ship_to_Site_Location__r.State__c
                                                     , Ship_to_Site_Location__r.Zip_Code__c, Ship_to_Site_Location__r.Country__c
                                                     , Purchase_Order__c, Purchase_Order__r.StartDate
                                                     , AssetId, Asset.SBQQ__QuoteLine__c, Asset.SBQQ__QuoteLine__r.PO_Number__c
                                                     FROM Case
                                                     WHERE Id IN :caseIds
                                                     ]);

            // Create an Order for each WorkOrder that has WorkOrderLineItems
            Map<Id, Order> workOrderToOrder = new Map<Id, Order> ();
            for (Id woID : workOrderToWOLineItems.keySet()) {
                WorkOrder wo = closedWorkOrders.get(woID);
                Order newOrder = new Order();

                newOrder.Name = 'Generated from Work Order: ' + wo.WorkOrderNumber;
                newOrder.OwnerId = wo.OwnerId;
                newOrder.RecordTypeId = orderRecordTypeId;
                newOrder.Pricebook2Id = wo.Pricebook2Id;
                newOrder.CurrencyIsoCode = wo.CurrencyIsoCode;
                newOrder.Description = wo.Description;
                newOrder.Status = 'Draft';
                newOrder.EffectiveDate = date.today();
                newOrder.Type = 'Field Service';
                newOrder.Case__c = wo.CaseId;
                newOrder.FSO__WorkOrder__c = wo.Id;

                Case woCase = cases.get(wo.CaseId);
                if (woCase != null) {
                    newOrder.AccountId = woCase.Customer_Name__c;
                    newOrder.Bill_To_Account__c = woCase.Bill_To_Customer__c;
                    newOrder.Bill_To_Site_Location__c = woCase.Bill_To_Site_Location__c;
                    newOrder.Ship_To_Account__c = woCase.Ship_To_Customer__c;
                    newOrder.Ship_To_Site_Location__c = woCase.Ship_To_Site_Location__c;

                    if (woCase.Bill_to_Customer__c != null) {
                        newOrder.BillingStreet = woCase.Bill_to_Customer__r.BillingStreet;
                        newOrder.BillingCity = woCase.Bill_to_Customer__r.BillingCity;
                        newOrder.BillingStateCode = woCase.Bill_to_Customer__r.BillingStateCode;
                        newOrder.BillingPostalCode = woCase.Bill_to_Customer__r.BillingPostalCode;
                        newOrder.BillingCountryCode = woCase.Bill_to_Customer__r.BillingCountryCode;
                    }

                    if (woCase.Ship_to_Site_Location__c != null) {
                        //String shipAddress= woCase.Ship_to_Site_Location__r.Address_Line_1__c+'\r\n'+woCase.Ship_to_Site_Location__r.Address_Line_2__c+'\r\n'+woCase.Ship_to_Site_Location__r.Address_Line_3__c+'\r\n'+woCase.Ship_to_Site_Location__r.Address_Line_4__c; 
                        //newOrder.ShippingStreet = shipAddress;
                        newOrder.ShippingStreet_Line1__c = woCase.Ship_to_Site_Location__r.Address_Line_1__c;
                        newOrder.ShippingStreet_Line2__c = woCase.Ship_to_Site_Location__r.Address_Line_2__c;
                        newOrder.ShippingStreet_Line3__c = woCase.Ship_to_Site_Location__r.Address_Line_3__c;
                        newOrder.ShippingCity = woCase.Ship_to_Site_Location__r.City__c;
                        newOrder.ShippingStateCode = woCase.Ship_to_Site_Location__r.State__c;
                        newOrder.ShippingPostalCode = woCase.Ship_to_Site_Location__r.Zip_Code__c;
                        newOrder.ShippingCountryCode = woCase.Ship_to_Site_Location__r.Country__c;
                    }

                    if (woCase.Purchase_Order__c != null) {
                        newOrder.PoDate = woCase.Purchase_Order__r.StartDate;
                    }

                    if (woCase.AssetId != null && woCase.Asset.SBQQ__QuoteLine__c != null) {
                        newOrder.PoNumber = woCase.Asset.SBQQ__QuoteLine__r.PO_Number__c;
                    }
                }
                workOrderToOrder.put(wo.Id, newOrder);
            }

            // Insert new Orders and OrderItems;
            insertOrdersAndOrderItems(closedWorkOrders, workOrderToOrder, workOrderToWOLineItems, woLineRTtoOILineTypes, workOrders);
        }
    }
    
   /*------------------------------------------------------------
      Author:         Sumit Gupta
      Company:        Salesforce.com
      Description:    Internal method to create Order and Order Items
      Inputs:         closedWorkOrders - Map of Work Orders that have been closed
      workOrderToOrder - Map of new Orders by WorkOrder
      workOrderToWOLineItems - Map of WorkOrderLineItems by WorkOrder
      woLineRTtoOILineTypes - Map of WOLine Record types to Order Line Type
      Returns:        N/A
     
      History:
      <Date>          <Authors Name>      <Brief Description of Change>
      07/26/2016      Sumit Gupta         Initial Creation (US1330)
      08/11/2016      Marc Goldstein      Updated mappings (US1439)
      09/20/2016      Denise Bacher       remove setting OrderLine.EndDate
      10/24/2016      Denise Bacher       updated to not set all orders to 'ENTERED' automatically (HD-1712)
      ------------------------------------------------------------*/
    private static void insertOrdersAndOrderItems(Map<Id, WorkOrder> closedWorkOrders, Map<Id, Order> workOrderToOrder,
                                                  Map<Id, List<WorkOrderLineItem>> workOrderToWOLineItems, Map<String, String> woLineRTtoOILineTypes, List<WorkOrder> workOrders)
    {
        // Insert new Orders
        insert workOrderToOrder.values();

        // Create new OrderItems foreach WorkOrderLineItems corresponding to it's parent WorkOrder's Order
        Map<Id, List<OrderItem>> orderToOrderItems = new Map<Id, List<OrderItem>> ();
        Map<Id, Double> orderValue = new Map<Id, Double> (); // used to determine if we update the order to 'ENTERED'
        Map<Id, OrderItem> woliIdToOrderItem = new Map<Id, OrderItem> ();
        List<OrderItem> orderItems = new List<OrderItem> ();
        List<WorkOrder> woList = new List<WorkOrder> ();
        system.debug('workOrderToOrder.keySet():::::::'+workOrderToOrder.keySet());
        for (Id woId : workOrderToOrder.keySet()) {
            WorkOrder wo = closedWorkOrders.get(woId);
            Order currentOrder = workOrderToOrder.get(woId);
            List<WorkOrderLineItem> currentWOLIs = workOrderToWOLineItems.get(woId);
            List<OrderItem> newOrderItems = new List<OrderItem> ();
            Double oValue = 0;
            system.debug('currentWOLIs:::::::'+currentWOLIs);
            for (WorkOrderLineItem woli : currentWOLIs) {
                OrderItem oi = new OrderItem();
                oi.OrderId = currentOrder.Id;
                oi.PricebookEntryId = woli.PricebookEntryId;
                oi.Description = woli.Description;
                oi.Quantity = woli.Quantity;
                //oi.ListPrice = woli.List_Price__c;
                oi.UnitPrice = woli.UnitPrice != null ? woli.UnitPrice : 0;
                oi.Asset__c = wo.AssetID;
                oi.Case__c = woli.Case__c;
                oi.Consumed_Location_Stock__c = woli.FSO__LocationStock__c;
                oi.Entitlement__c = woli.Entitlement__c;
                oi.Exclude_from_Invoice__c = woli.Exclude_from_Invoice__c;
                //oi.RMA_Order_Line_Record_Id__c = woli.RMA_Work_Order_Line_Record_Id__c;
                oi.Ship_To_Site_Location__c = woli.Ship_to_Site_Location__c;
                oi.Work_Order_Line_Item__c = woli.Id;
                oi.Net_Price__c = woli.Net_Price__c;
                oi.Line_Type__c = woLineRTtoOILineTypes.get(woli.RecordType.DeveloperName);
                oi.Returned_Asset__c = woli.Returned_Asset__c;
                oi.Serial_Number__c = woli.Serial_Number__c; 
                oi.RMA_OrderItem__c = String.valueOf(woli.RecordTypeId).contains(recordTypeIds.WOLI_B_SH_RMA__c) ? true : false;
                oi.Consumed_Asset__c = String.valueOf(woli.RecordTypeId).contains(recordTypeIds.WOLI_Add_a_Part__c) ? woli.FSO__LocationStock__r.FSO__Asset__c : null;
                oi.Location__c = woli.FSO__Location__c;
                oi.Return_Reason_Code__c = woli.Return_Reason_Code__c;
                oi.Category_Code__c = woli.Category_Code__c;
                
                if(oi.RMA_OrderItem__c){
                    oi.RMA_Serial_Number__c = woli.Serial_Number__c;
                    oi.Serial_Number__c = null;
                } 
                
                if (wo.FSO__Completed_Date__c != null) {
                    oi.Due_Date__c = date.newinstance(wo.FSO__Completed_Date__c.year(), wo.FSO__Completed_Date__c.month(), wo.FSO__Completed_Date__c.day());
                }

                if (wo.StartDate != null) {
                    oi.Request_Date__c = date.newinstance(wo.StartDate.year(), wo.StartDate.month(), wo.StartDate.day());
                }

                newOrderItems.add(oi);
                woliIdToOrderItem.put(woli.Id, oi);

                oValue += (oi.Quantity * oi.UnitPrice);
            }
            orderItems.addAll(newOrderItems);
            orderToOrderItems.put(currentOrder.Id, newOrderItems);
            orderValue.put(currentOrder.Id, oValue);
        }
        // insert OrderItems
        insert orderItems;

        // Update the WorkOrderLineItem with OrderItemId
        Map<Id, WorkOrderLineItem> woliMap = new Map<Id, WorkOrderLineItem> ();
        for (Id woId : workOrderToWOLineItems.keySet()) {
            for (WorkOrderLineItem woli : workOrderToWOLineItems.get(woId)) {
                woli.Order_Line_Item__c = woliIdToOrderItem.get(woli.Id).Id;
                woliMap.put(woli.Id, woli);
            }
        }
        update woliMap.values();

        // Set Order Status to ENTERED
        for (Id woId : workOrderToOrder.keySet()) {
            Order o = workOrderToOrder.get(woId);
            Double oValue = orderValue.get(o.Id);

            if (oValue <= 0) {
                o.Status = orgDefaults.Order_Stage_Non_Billable_as_ENTERED__c ? 'BOOKED' : 'DRAFT';
            }
            else {
                o.Status = orgDefaults.Order_Stage_Billable_as_ENTERED__c ? 'BOOKED' : 'DRAFT';
            }
        }
        update workOrderToOrder.values();

        // Update WorkOrder with Order.Id
        for(Id woId : workOrderToOrder.keySet()){
          WorkOrder wo = closedWorkOrders.get(woId);
          Order currentOrder = workOrderToOrder.get(woId);
         
          wo.Order__c = currentOrder.Id;
          woList.add(wo);
          }

        /*for (WorkOrder wo1 : workOrders) {
            if (workOrderToOrder.containsKey(wo1.Id)) {
                //WorkOrder wo = closedWorkOrders.get(wo1.Id);
                Order currentOrder = workOrderToOrder.get(wo1.Id);

                wo1.Order__c = currentOrder.Id;
            }
        }*/

        wocreateOrderAndOrderItems = true;



        if(woList.size() > 0)
            update woList;
    }
    
    /*----------------------------------------------------------------------------------------
    Author:         Mani Sundaresan
    Description:    Method to send an email and a push notification to the WO Owner when updated.
                    Runs before update
    Inputs:         workOrders - The list of Work Orders
                    
    Returns:        N/A
    
    History:
    <Date>          <Authors Name>      <Brief Description of Change>
    09/27/2017       Mani Sundaresan      Initial Creation (US-0003385)
    11/29/2017       Mani Sundaresan     updated to trigger only when the push notification & escalation fields are enabled by the Entitlement Process (US-0003385)
    -------------------------------------------------------------------------------------------*/
    public static void sendOwnerNotification(List<WorkOrder> workOrders,Map<Id, WorkOrder> oldWorkOrders){
        
        //Variable Declaration
        List<HologicPushNotificationProcessUtility.Info> pushNotificationData = new List<HologicPushNotificationProcessUtility.Info>();
        List<Messaging.SingleEmailMessage> email = new List<Messaging.SingleEmailMessage> ();
        List<WorkOrder> woList = new List<WorkOrder>();
        Set<Id> woIdSet = new Set<Id>();
        Set<Id> currentOwnerIdSet = new Set<Id>();
        Set<Id> oldOwnerIdSet = new Set<Id>();
        List<String> toAddress = new List<String>();
        Map<Id, User> currentUserMap;
        Map<Id, User> oldUserMap;
        List<ConnectApi.BatchInput> chatterPosts = new List<ConnectApi.BatchInput>();
        Boolean thirtyMin = false;
        System.debug('sendOwnerEmail:'+sendOwnerEmail);
        
        if(!sendOwnerEmail){
        for(WorkOrder wo : workOrders){
            WorkOrder oldWO = oldWorkOrders.get(wo.Id);
            /*if(wo.OwnerId != oldWO.OwnerId && wo.OwnerId != null){
                woIdSet.add(wo.Id);
                currentOwnerIdSet.add(wo.OwnerId);
                oldOwnerIdSet.add(oldWO.OwnerId);
            }*/
            System.debug('oldOwnerId:'+oldWO.OwnerId);
            System.debug('currentOwnerId:'+wo.OwnerId);
            System.debug('currentStatus:'+wo.Status);
            System.debug('oldStatus:'+oldWO.Status);

            if(((wo.OwnerId != oldWO.OwnerId && wo.OwnerId != null && String.valueOf(wo.OwnerId).startsWith('005')) ||
               (wo.X15MIN_Sev1_Sev2_Push_Notification__c != oldWO.X15MIN_Sev1_Sev2_Push_Notification__c && wo.X15MIN_Sev1_Sev2_Push_Notification__c == true) ||
               (wo.X30MIN_Sev1_Sev2_Escalation__c != oldWO.X30MIN_Sev1_Sev2_Escalation__c && wo.X30MIN_Sev1_Sev2_Escalation__c == true) ||
               (wo.X45MIN_Sev1_Sev2_Push_Notification__c != oldWO.X45MIN_Sev1_Sev2_Push_Notification__c && wo.X45MIN_Sev1_Sev2_Push_Notification__c == true) ||
               (wo.X1HR_Sev1_Sev2_Escalation__c != oldWO.X1HR_Sev1_Sev2_Escalation__c && wo.X1HR_Sev1_Sev2_Escalation__c == true) ||
               (wo.X4HR_Sev1_Sev2_Violation__c != oldWO.X4HR_Sev1_Sev2_Violation__c && wo.X4HR_Sev1_Sev2_Violation__c == true)) && !String.valueOf(wo.RecordTypeId).contains(recordTypeIds.Case_B_SH_Applications__c)){
                    
                    woIdSet.add(wo.Id);
                    //currentOwnerIdSet.add(wo.OwnerId);
                    oldOwnerIdSet.add(oldWO.OwnerId);
                    
                    if((wo.X30MIN_Sev1_Sev2_Escalation__c != oldWO.X30MIN_Sev1_Sev2_Escalation__c && wo.X30MIN_Sev1_Sev2_Escalation__c == true) || (wo.OwnerId != oldWO.OwnerId && wo.OwnerId != null))
                        thirtyMin = true;
            }
        }
        
        System.debug('woIdSet:'+woIdSet);
        System.debug('currentOwnerIdSet:'+currentOwnerIdSet);
        System.debug('oldOwnerIdSet:'+oldOwnerIdSet);
        System.debug('thirtyMin:'+thirtyMin);
        
        if(woIdSet.size() > 0)
            woList = [SELECT Id, Case.CaseNumber, Status, OwnerId, Customer_Name__c, StartDate, Asset.Name, Account_Name__c, Subject, Description, WorkOrderNumber, X1HR_Sev1_Sev2_Escalation__c, X30MIN_Sev1_Sev2_Escalation__c  from WorkOrder where Id IN :woIdSet];
        
        if(woList.size() > 0)
            for(WorkOrder wo : woList)
                currentOwnerIdSet.add(wo.OwnerId);
        
        if(currentOwnerIdSet.size() > 0)
            currentUserMap = new Map<Id, User>([SELECT Id, Email, Name from User where Id IN :currentOwnerIdSet]);
        
        if(oldOwnerIdSet.size() > 0)
            oldUserMap = new Map<Id, User>([SELECT Id, Email, Name from User where Id IN :oldOwnerIdSet]);
        
        if(woList.size() > 0){
            for(WorkOrder currentWO : workOrders){
                for(WorkOrder wo : woList){
                    if(currentWO.Id == wo.Id){
                    System.debug('Inside WO:'+wo.Id);
                    System.debug('WO Owner:'+wo.OwnerId);
                    WorkOrder oldWO = oldWorkOrders.get(wo.Id);
                    
                        //Functionality to send out push notification to the owner
                        if(wo.X1HR_Sev1_Sev2_Escalation__c == false){
                            System.debug('Push Notification');
                            HologicPushNotificationProcessUtility.Info pushInfo = new HologicPushNotificationProcessUtility.Info();
                            pushInfo.messageUrl = 'com.salesforce.fse://workOrder?id='+wo.Id;
                            pushInfo.userID = wo.OwnerId;
                            pushInfo.messageText = 'Escalated Case '+ wo.Case.CaseNumber + ' has been assigned to you.';
                            
                            pushNotificationData.add(pushInfo);
                        }
                        
                        System.debug('currentUserMap:'+currentUserMap);
                        System.debug('WO Owner:'+wo.OwnerId);
                        //System.debug(currentUserMap.get(wo.OwnerId));
                        //SYstem.debug(toAddress.add(currentUserMap.get(wo.OwnerId).Email));
                        System.debug('StartDate:'+wo.StartDate);
                        System.debug('thirtyMin:'+thirtyMin);
                        
                        //Functionality to send out an email to the WO Owner
                        if(thirtyMin){
                            System.debug('Email Process');
                            toAddress.add(currentUserMap.get(wo.OwnerId).Email);
                            String subject = 'New Call Assigned, Case#: ' + wo.Case.CaseNumber;
                
                            String emailBody = '<html><body>Please go to FieldService mobile app to review and confirm the new call that has been assigned to you for '+ (wo.Customer_Name__c != null ? wo.Customer_Name__c : '') + '</BR></BR>' +
                                                '<b>Details</b></BR>'+
                                                'Previous WO Owner: '+(oldUserMap.get(oldWO.OwnerId) != null ? oldUserMap.get(oldWO.OwnerId).Name : '')+'</BR>'+
                                                'Customer: '+(wo.Customer_Name__c != null ? wo.Customer_Name__c : '')+'</BR>'+
                                                'Account: '+wo.Account_Name__c+'</BR>'+
                                                'Start Date: '+(String.valueOf(currentWO.StartDate) != null ? currentWO.StartDate.date().format() : '')+'</BR>'+
                                                'Case#: '+(wo.CaseId != null ? wo.Case.CaseNumber : '')+'</BR>'+
                                                'WO#: '+(wo.WorkOrderNumber != null ? wo.WorkOrderNumber : '')+'</BR>'+
                                                'Asset: '+(wo.AssetId != null ? wo.Asset.Name : '')+'</BR>'+
                                                'Subject: '+(wo.Subject != null ? wo.Subject : '')+'</BR>'+
                                                'Description: '+(wo.Description != null ? wo.Description : '')+'</BR></BR>'+
                                                
                                                'Thank you for you Service.</BR>'+
                                                'Hologic</body></html>';
                                                                  
                           
                           Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                           mail.setToAddresses(toAddress);
                           mail.setSaveAsActivity(false);
                           mail.setSubject(subject);
                           mail.setHtmlBody(emailBody);
                           
                           email.add(mail);
                          //emailCount++;
                      }
                      
                      
                      //Create a Chatter post on the record
                      ConnectApi.MessageBodyInput messageBodyInput = new ConnectApi.MessageBodyInput();
                      messageBodyInput.messageSegments = new List<ConnectApi.MessageSegmentInput>();
                        
                      ConnectApi.TextSegmentInput textSegmentInput = new ConnectApi.TextSegmentInput();
                      textSegmentInput.text = 'Case '+ (wo.CaseId != null ? wo.Case.CaseNumber : '')+' has been assigned to '+ currentUserMap.get(wo.OwnerId).Name;
                      messageBodyInput.messageSegments.add(textSegmentInput);
                        
                      ConnectApi.FeedItemInput feedItemInput = new ConnectApi.FeedItemInput();
                      feedItemInput.body = messageBodyInput;
                      feedItemInput.feedElementType = ConnectApi.FeedElementType.FeedItem;
                      feedItemInput.subjectId = wo.Id;
                        
                      ConnectApi.BatchInput batchInput = new ConnectApi.BatchInput(feedItemInput);
                      chatterPosts.add(batchInput);
                   } 
                }
            }
        }
        
        System.debug('pushNotificationData '+Json.serialize(pushNotificationData));
        
        if(pushNotificationData.size() > 0){
            HologicPushNotificationProcessUtility.SendPushNotification(pushNotificationData);
        }
        //04-03-2018 email.size() > 0 in condition added by krishna prasad as part of US-0004263
        if (email != null && !Test.isRunningTest() && email.size() > 0){
            Messaging.sendEmail(email);
        }    
        if(!Test.isRunningTest() && chatterPosts.size() > 0){
            ConnectApi.ChatterFeeds.postFeedElementBatch(Network.getNetworkId(), chatterPosts);
            sendOwnerEmail = true;
        }
        
        System.debug('Email being sent:'+email);   
        System.debug('sendOwnerEmail:'+sendOwnerEmail);
         
      }  
        
    }    
            

}