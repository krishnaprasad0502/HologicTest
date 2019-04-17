/*---------------------------------------------------------------------------------------------------------------------------------------------
Author:     Mani Sundaresan
Description:  Controller class for Customer Service Report functionality

Test Class:   Test_CSRController 

History:
<Date>      <Authors Name>    <Brief Description of Change>
05/04/2017   Mani Sundaresan    Initial Creation (US2248)
------------------------------------------------------------------------------------------------------------------------------------------------*/


public with sharing class CSRController {

    public Id sObjectId {get; set;}
    public String sObjectRT {get; set;}
    public List<Account> accountList {get; set;}
    public List<Asset> assetList {get; set;}
    public List<Case> caseList {get; set;}
    public List<WorkOrder> woList = new List<WorkOrder>();
    public String accountAddress {get; set;}
    //public List<finalWrapper> finalWrapperList {get; set;}
    public List<asset_Wrapper> assetWrapper {get; set;}
    public List<case_Wrapper> caseWrapper {get; set;}
    public List<wo_Wrapper> woWrapper {get; set;}
    public List<asset_Wrapper> finalAssetWrapper {get; set;}
    public List<case_Wrapper> finalCaseWrapper {get; set;}
    public List<wo_Wrapper> finalWOWrapper {get; set;}
    public Boolean MasterChkBox {get; set;}
    public Integer size{get; set;}
    public Integer caseSize {get; set;}
    public Boolean caseMasterChkBox {get; set;}
    public Boolean woWrapperSize {get; set;}
    public Boolean caseWrapperSize {get; set;}
    public Boolean isAccount {get; set;}
    public Boolean isAsset {get; set;}
    public Boolean isCase {get; set;}
    public Date servStartDate {get; set;}
    public Date servEndDate {get; set;}
    public Boolean includePricing {get; set;}
    public SelectOption[] selectedRTs { get; set; }
    public SelectOption[] allRTs { get; set; }
    public SelectOption[] selectedCaseTypes { get; set; }
    public SelectOption[] allCaseTypes { get; set; }
    public Set<Id> caseRTs = new Set<Id>();
    public Set<Id> woRTs = new Set<Id>();
    public Id woliRTId = GlobalUtility.getRecordTypeId('WorkOrderLineItem','B&SH Add a Note');
    public Id systemAssetRTId = GlobalUtility.getRecordTypeId('Asset','System');
        
    

    
    public CSRController(){
    
        sObjectId = ApexPages.currentPage().getParameters().get('Id');
        sObjectRT = ApexPages.currentPage().getParameters().get('RecordType');
        assetList = new List<Asset>();
        accountList = new List<Account>();
        assetWrapper = new List<asset_Wrapper>();
        caseWrapper = new List<case_Wrapper>();
        allRTs = new List<SelectOption>();
        allCaseTypes = new List<SelectOption>();
        selectedRTs = new List<SelectOption>();
        selectedCaseTypes = new List<SelectOption>();
        List<Asset> tempAssetList = new List<Asset>();
        
        for(CSRPriority__c csrp : CSRPriority__c.getAll().values())
            allCaseTypes.add(new SelectOption(csrp.Case_Priority__c, csrp.Case_Priority__c));
        
        for(CSRTypes__c csrt : CSRTypes__c.getAll().values()){
            allRTs.add(new SelectOption(csrt.RecordType_Id__c, csrt.RecordType_Name__c));
            caseRTs.add(csrt.RecordType_Id__c);
        }
        
        for(CSRWOTypes__c csrwo : CSRWOTypes__c.getAll().values())
            woRTs.add(csrwo.RecordType_Id__c);       
        
        
        System.debug('sObjectId:'+sObjectId);
        System.debug('sObjectRT:'+sObjectRT);
        
        if(String.valueOf(sObjectId).substring(0,3) == '001'){
        
            isAccount = true;
            
            accountList = [SELECT Id, Name, Parent.Name, Parent.RecordTypeId, BillingCity, BillingCountry, BillingPostalCode, BillingState, BillingStreet, (SELECT Id, Name, SerialNumber, Product2.Name, Description, Account.Name, RecordTypeId from Assets) from Account where Id = :sObjectId];
                    
                if(accountList.size() > 0){
                    accountAddress = accountList[0].BillingStreet + ', ' + accountList[0].BillingCity + ', ' + accountList[0].BillingState + ', ' + accountList[0].BillingCountry + ' ' + accountList[0].BillingPostalCode;
                    
                        if(sObjectRT == 'Site'){
                            if(accountList[0].getSObjects('Assets') != null)
                                for(Asset asse : accountList[0].getSObjects('Assets')){
                                    if(asse.RecordTypeId == systemAssetRTId){
                                        asset_Wrapper assewrap = new asset_Wrapper(asse,false,null); 
                                        assetWrapper.add(assewrap);
                                        System.debug('Inside Sites');
                                    }
                                }
                                        
                                
                                
                            
                        }
                        else if(sObjectRT == 'Customer'){
                            for(Asset asse : [SELECT Id, Name, SerialNumber, Product2.Name, Description, Account.ParentId, Account.BillingCity, Account.BillingCountry, Account.BillingPostalCode, Account.BillingState, Account.BillingStreet, Account.Name from Asset where Account.ParentId = :sObjectId and RecordTypeId = :systemAssetRTId]){
                                asset_Wrapper assewrap = new asset_Wrapper(asse,false,null); 
                                assetWrapper.add(assewrap);
                                System.debug('Inside Customer');    
                            }
                        }
                    size = assetWrapper.size();
                    caseSize = caseWrapper.size();
                    
                }
                
                System.debug('AssetList:'+assetList);
        }
        if(String.valueOf(sObjectId).substring(0,3) == '02i'){
            
            
            isAsset = true;
            
            List<Id> caseIdList = new List<Id>();
            List<Case> caseList = new List<Case>();
            List<Task> taskList = new List<Task>();
        
            
            assetList = [SELECT Id, Name, SerialNumber, Product2.Name, Description, Account.Name, Account.Parent.Name, Account.ParentId, AccountId, Account.BillingCity, Account.BillingCountry, Account.BillingPostalCode, Account.BillingState, Account.BillingStreet, (SELECT Id, CaseNumber, Subject, CreatedDate, ClosedDate, RecordType.Id, RecordType.Name, Priority, AssetId, Asset.Name, Asset.SerialNumber, PO_Number__c, PO_Cap__c  from Cases ) from Asset where Id = :sObjectId and RecordTypeId = :systemAssetRTId];
            
            System.debug('ParentId:'+assetList[0].Account.ParentId);
            
            if(assetList != null && assetList.size() > 0){
                
                Account parentAcc = new Account(Id=assetList[0].Account.ParentId, Name = assetList[0].Account.Parent.Name);
                
                Account acc = new Account(Name=assetList[0].Account.Name, Id=assetList[0].AccountId, Parent=parentAcc, ParentId=assetList[0].Account.ParentId);
                accountList.add(acc);
                
                sObjectRT = 'Site';
                
                accountAddress = assetList[0].Account.BillingStreet + ', ' + assetList[0].Account.BillingCity + ', ' + assetList[0].Account.BillingState + ', ' + assetList[0].Account.BillingCountry + ' ' + assetList[0].Account.BillingPostalCode;
                
                
                
                if(assetList[0].getSObjects('Cases') != null){
                    for(Case cs : assetList[0].getSObjects('Cases')){
                        if(caseRTs.contains(cs.RecordTypeId)){
                            caseIdList.add(cs.Id);
                            //case_Wrapper caseWrap = new case_Wrapper(cs,false,null, null);
                            //caseWrapper.add(caseWrap);
                        }
                    }
                }
                
               if(caseIdList.size() > 0)
                    caseList = [SELECT Id, CaseNumber, Subject, CreatedDate, AssetId, Asset.Name, Asset.SerialNumber, ClosedDate, RecordType.Id, RecordType.Name, Priority, PO_Number__c, PO_Cap__c, Type, (SELECT Id, Description, Note_Type__c from Tasks) from Case where Id IN :caseIdList ORDER BY CaseNumber];   
                
                if(caseList.size() > 0)
                    for(Case cs : caseList){
                    
                        /*taskList = new List<Task>();
                        for(Task t : cs.getSObjects('Tasks')){
                            if(t.Note_Type__c == 'FE Resolution' || t.Note_Type__c == 'Resolution')
                            taskList.add(t);    
                        }
                        case_Wrapper casewrap;
                        if(taskList.size() > 0)
                            casewrap = new case_Wrapper(cs,false,null,taskList);
                        else
                            casewrap = new case_Wrapper(cs,false,null,null); */
                    
                        case_Wrapper caseWrap = new case_Wrapper(cs,false,null,cs.getSObjects('Tasks'));
                        caseWrapper.add(caseWrap);    
                    }
                
                
                for(Asset asse : assetList){
                    asset_Wrapper assewrap = new asset_Wrapper(asse,true,caseWrapper); 
                    assetWrapper.add(assewrap);
                }  
                
                 
                
                caseSize = caseWrapper.size();
                
                if(caseWrapper.size() > 0)
                   caseWrapperSize = true;
               else
                   caseWrapperSize = false; 
            
            
            }
            
        
        }
        
        if(sObjectId != null & String.valueOf(sObjectId).substring(0,3).contains('500')){
            isCase = true;
            
            caseList = new List<Case>();
            List<Id> woIdList = new List<Id>();
            List<Task> taskList = new List<Task>();
            List<WorkOrderLineItem> wolis = new List<WorkOrderLineItem>();
            caseList = [SELECT Id, AssetId, Asset.Name, Asset.Account.Parent.Name, Asset.Account.ParentId, Asset.Account.Parent.RecordTypeId, Asset.Account.Name, Asset.Account.BillingAddress, Asset.Account.BillingCity, Asset.Account.BillingCountry, Asset.Account.BillingPostalCode, Asset.Account.BillingState, Asset.Account.BillingStreet, Asset.SerialNumber, Asset.Product2.Name, Asset.Description, CaseNumber, Subject, CreatedDate, PO_Number__c, PO_Cap__c, Type, RecordType.Name, RecordTypeId, (SELECT Id, WorkOrderNumber, CaseId, Case.CaseNumber, Subject, StartDate, EndDate, FSO__Type__c, Owner.Name, FSO__Completed_Date__c, RecordTypeId from WorkOrders),(SELECT Id, Description, Note_Type__c from Tasks) from Case where Id = :sObjectId AND RecordTypeId IN :caseRTs];
            System.debug('caseList:'+caseList);
            
            if(caseList != null && caseList.size() > 0){
                caseWrapper = new List<case_Wrapper>();
                woWrapper = new List<wo_Wrapper>();
                assetWrapper = new List<asset_Wrapper>();
                //for(Case c : caseList){
                    for(WorkOrder wo : caseList[0].getSObjects('WorkOrders')){
                        if(woRTs.contains(wo.RecordTypeId)){
                            woIdList.add(wo.Id);
                            //wo_Wrapper csrw = new wo_Wrapper(wo,null);
                            //woWrapper.add(csrw);   
                        }
                    }
                    
                    if(woIdList.size() > 0)
                        for(WorkOrder wo : [SELECT Id, WorkOrderNumber, Subject, FSO__Completed_Date__c, StartDate, FSO__Type__c, EndDate, Case.CaseNumber, CaseId, Owner.Name, (SELECT Id, Description, TotalPrice, RecordTypeId, WorkOrderId, Note_Type__c, RecordType.Name  from WorkOrderLineItems) from WorkOrder where Id IN :woIdList]){
                            wolis = new List<WorkOrderLineItem>();
                            for(WorkOrderLineItem woli : wo.getSObjects('WorkOrderLineItems')){
                                System.debug('woli rt:'+woli.RecordTypeId);
                                System.debug('woliRTId:'+woliRTId);
                                if(woli.Note_Type__c != 'FE Resolution')
                                    wolis.add(woli);
                                        
                                    System.debug('wolis val:'+wolis);
                              }  
                            
                            wo_Wrapper csrw = new wo_Wrapper(wo,wolis);
                            woWrapper.add(csrw);
                        }
                    
                    
                    
                    
                    Account parentAcc = new Account(Id=caseList[0].Asset.Account.ParentId, Name = caseList[0].Asset.Account.Parent.Name);
                    
                    Account acc = new Account(Name = caseList[0].Asset.Account.Name, Parent=parentAcc, ParentId=caseList[0].Asset.Account.ParentId, BillingStreet = caseList[0].Asset.Account.BillingStreet, BillingCity = caseList[0].Asset.Account.BillingCity, BillingState = caseList[0].Asset.Account.BillingState, BillingCountry = caseList[0].Asset.Account.BillingCountry, BillingPostalCode = caseList[0].Asset.Account.BillingPostalCode);
                    accountList.add(acc);
                    accountAddress = caseList[0].Asset.Account.BillingStreet + ', ' + caseList[0].Asset.Account.BillingCity + ', ' + caseList[0].Asset.Account.BillingState + ', ' + caseList[0].Asset.Account.BillingCountry + ' ' + caseList[0].Asset.Account.BillingPostalCode;   
                    //if(caseList[0].Asset.Account.Parent.RecordTypeId == GlobalUtility.getRecordTypeId('Account','Customer'))
                        //customerName = caseList[0].Asset.Account.Parent.Name;
                   
                    sObjectRT = 'Site';
                    
                    for(Case cae : caseList){
                    
                        taskList = new List<Task>();
                        for(Task t : cae.getSObjects('Tasks')){
                            if(t.Note_Type__c == 'FE Resolution' || t.Note_Type__c == 'Resolution')
                            taskList.add(t);    
                        }
                        case_Wrapper casewrap;
                        if(taskList.size() > 0)
                            casewrap = new case_Wrapper(cae,false,woWrapper,taskList);
                        else
                            casewrap = new case_Wrapper(cae,false,woWrapper,null);
                    
                        //case_Wrapper caseWrap = new case_Wrapper(cae,false,woWrapper,cae.getSObjects('Tasks')); 
                        caseWrapper.add(caseWrap);
                        
                        Product2 pro = new Product2(Id=cae.Asset.Product2Id, Name=cae.Asset.Product2.Name);
                        Asset asse = new Asset(Id=cae.AssetId, Name=cae.Asset.Name, Description = cae.Asset.Description, SerialNumber = cae.Asset.SerialNumber, Product2Id=cae.Asset.Product2Id, Account=acc, Product2 = pro);
                        asset_Wrapper assetWrap = new asset_Wrapper(asse,true,caseWrapper);
                        assetWrapper.add(assetWrap);
                    
                    }
                    
                    caseSize = caseWrapper.size();
                
                    if(caseWrapper.size() > 0)
                       caseWrapperSize = true;
                   else
                       caseWrapperSize = false;
                       
                    if(woWrapper.size() > 0)
                        woWrapperSize = true;
                    else
                        woWrapperSize = false;     
             
                    
                //}
            }
            
            
        }
    
    }
    
    //Wrapper Class for Assets
    public Class asset_Wrapper{
        //public Account acc {get; set;}
        public Asset asse {get; set;}
        public Boolean selected{get; set;}
        public List<case_Wrapper> caseWrapper {get; set;}
        
        public asset_Wrapper(Asset asse, Boolean selected, List<case_Wrapper> caseWrapper){
            //this.acc = acc;
            this.selected = selected;
            this.asse = asse;
            this.caseWrapper = caseWrapper;
        }
    }
    
    //Wrapper Class for Cases
    public Class case_Wrapper{
        
        public Case caseVal {get; set;}
        public Boolean selected {get; set;}
        public List<wo_Wrapper> woWrapper {get; set;}
        public List<Task> caseTaskList {get; set;}
        
        public case_Wrapper(Case c, Boolean selected, List<wo_Wrapper> woWrapper, List<Task> caseTaskList){
            caseVal = c;
            this.selected = selected;
            this.woWrapper = woWrapper;
            this.caseTaskList = caseTaskList;
        }
    }
    
    //Wrapper Class for WorkOrders
    public Class wo_Wrapper{
    
        public WorkOrder wo {get; set;}
        public List<WorkOrderLineItem> woliList {get; set;}
        
        public wo_Wrapper(WorkOrder wo, List<WorkOrderLineItem> woliList){
            this.wo = wo;
            this.woliList = woliList;
        }
    }
    
   
    
    //Method for maintaining the state of the checkbox in VF page
    public PageReference setSelected(){
    
        Id oi = (Id)System.currentPagereference().getParameters().get('AssetId');
        String selected = System.currentPagereference().getParameters().get('Selected');
        String master = System.currentPagereference().getParameters().get('Master');
        caseWrapper = new List<case_Wrapper>();
        woWrapper = new List<wo_Wrapper>();
        Map<Id, List<case_Wrapper>> assetCaseMap = new Map<Id, List<case_Wrapper>>();
        List<case_Wrapper> tempCaseWrapper = new List<case_Wrapper>();
        finalAssetWrapper = new List<asset_Wrapper>();
        
        List<Id> selectedAsset = new List<Id>();
        List<Case> caseList;
        List<Task> taskList = new List<Task>();
        
        System.debug('AssetId:'+oi);
        System.debug('selected:'+selected);
        System.debug('MasterChkBox:'+MasterChkBox);
        System.debug('master:'+master);
        System.debug('caseWrapper1:'+caseWrapper.size());
        
        
        for(asset_Wrapper aw : assetWrapper){
            System.debug('1st level:'+MasterChkBox);
            System.debug('2nd level:'+aw.selected);
            if((aw.selected == true && master == null) || MasterChkBox == true){ 
                    System.debug('inside');
                    selectedAsset.add(aw.asse.Id);
                    asset_Wrapper assetWrap = new asset_Wrapper(aw.asse,true,null);
                    finalAssetWrapper.add(assetWrap);
                    
                }
                              
        }
        
        System.debug('selected asset:'+selectedAsset);
        
        if(selectedAsset.size() > 0)
            caseList = [SELECT Id, CaseNumber, Subject, CreatedDate, AssetId, Asset.Name, Asset.SerialNumber, ClosedDate, RecordType.Id, RecordType.Name, Priority, PO_Number__c, PO_Cap__c, Type, (SELECT Id, Description, Note_Type__c from Tasks) from Case where AssetId IN :selectedAsset AND RecordTypeId IN :caseRTs ORDER BY CaseNumber];
            
        if(caseList != null)
            for(Case c : caseList){
                taskList = new List<Task>();
                for(Task t : c.getSObjects('Tasks')){
                    if(t.Note_Type__c == 'FE Resolution' || t.Note_Type__c == 'Resolution')
                        taskList.add(t);    
                }
                case_Wrapper casewrap;
                if(taskList.size() > 0)
                    casewrap = new case_Wrapper(c,false,null,taskList);
                else
                    casewrap = new case_Wrapper(c,false,null,null); 
                
                caseWrapper.add(casewrap);  
            }
            
       System.debug('caseWrapper2:'+caseWrapper.size());
       
       
       caseSize = caseWrapper.size();
       
       if(caseWrapper.size() > 0)
           caseWrapperSize = true;
       else{
           caseWrapperSize = false;
           woWrapperSize = false;
           }
    
        return null;
    }
    
    //Selected Case Records
    public PageReference setCaseSelected(){
        
        Id oi = (Id)System.currentPagereference().getParameters().get('CaseId');
        String selected = System.currentPagereference().getParameters().get('Selected');
        String master = System.currentPagereference().getParameters().get('Master');
        List<Id> selectedCaseList = new List<Id>();
        //List<WorkOrder> woList = new List<WorkOrder>();
        woWrapper = new List<wo_Wrapper>();
        finalCaseWrapper = new List<case_Wrapper>();
        finalAssetWrapper = new List<asset_Wrapper>();
        List<wo_Wrapper> tempWOWrapper;
        List<case_Wrapper> tempCaseWrapper;
        List<WorkOrderLineItem> wolis = new List<WorkOrderLineItem>();
        List<Task> taskList = new List<Task>();
        //woliRTId = GlobalUtility.getRecordTypeId('WorkOrderLineItem','B&SH Add a Note');
        
        
        
        System.debug('Case record:'+oi);
        System.debug('selected:'+selected);
        System.debug('master:'+master);
        System.debug('caseWrapper:'+caseSize);
        
        for(case_Wrapper cwrap : caseWrapper){
            System.debug('1st level:'+caseMasterChkBox);
            System.debug('2nd level:'+cwrap.selected);
            if((cwrap.selected == true && master == null) || caseMasterChkBox == true){ 
                    System.debug('inside');
                    selectedCaseList.add(cwrap.caseVal.Id);
            }    
        }
        
        System.debug('selectedCaseList:'+selectedCaseList);
        
        if(selectedCaseList != null){
            woList = [SELECT Id, WorkOrderNumber, FSO__Completed_Date__c, Subject, StartDate, FSO__Type__c, EndDate, Case.CaseNumber, CaseId, Owner.Name, (SELECT Id, Description, TotalPrice, Note_Type__c, RecordTypeId, WorkOrderId, RecordType.Name from WorkOrderLineItems) from WorkOrder where CaseId IN :selectedCaseList AND RecordTypeId IN :woRTs];
         }
        System.debug('woList:'+woList);
        
        if(woList != null && woList.size() > 0){
            for(case_Wrapper cwrap : caseWrapper){
                
                if(cwrap.selected == true || caseMasterChkBox == true){
                    tempWOWrapper = new List<wo_Wrapper>();
                    for(WorkOrder wod : woList){
                        if(cwrap.caseVal.Id == wod.CaseId && (cwrap.selected == true || caseMasterChkBox == true)){
                            
                                wolis = new List<WorkOrderLineItem>();
                                for(WorkOrderLineItem woli : wod.getSObjects('WorkOrderLineItems')){
                                    System.debug('woli rt:'+woli.RecordTypeId);
                                    System.debug('woliRTId:'+woliRTId);
                                    if(woli.Note_Type__c != 'FE Resolution')
                                        wolis.add(woli);
                                        
                                    System.debug('wolis val:'+wolis);
                                }   
                            
                            wo_Wrapper woWrap = new wo_Wrapper(wod,wolis);  
                            woWrapper.add(woWrap); 
                            tempWOWrapper.add(woWrap); 
                        }
                    }
                    
                    taskList = new List<Task>();
                    if(cwrap.caseTaskList != null)
                        for(Task t : cwrap.caseTaskList){
                            if(t.Note_Type__c == 'FE Resolution' || t.Note_Type__c == 'Resolution')
                                taskList.add(t);    
                        }
                    
                    
                    
                    case_Wrapper caseWrap = new case_Wrapper(cwrap.caseVal,true,tempWOWrapper,taskList);
                    finalCaseWrapper.add(caseWrap);
                }  
            }
        }
        else{
            for(case_Wrapper cwrap : caseWrapper){
                if(cwrap.selected == true || caseMasterChkBox == true){
                    taskList = new List<Task>();
                    if(cwrap.caseTaskList != null){
                        for(Task t : cwrap.caseTaskList){
                            if(t.Note_Type__c == 'FE Resolution' || t.Note_Type__c == 'Resolution')
                                taskList.add(t);    
                        }
                    }
                    
                    case_Wrapper caseWrap = new case_Wrapper(cwrap.caseVal,true,null,taskList);
                    finalCaseWrapper.add(caseWrap);
                }    
            }
            
        }
        caseSize = caseWrapper.size();
        
        System.debug('finalCaseWrappersize:'+finalCaseWrapper.size());
        
        if(finalCaseWrapper.size() > 0)
            for(asset_Wrapper aswr : assetWrapper){
                tempCaseWrapper = new List<case_Wrapper>();
                for(case_Wrapper cswr : finalCaseWrapper){
                    if(aswr.asse.Id == cswr.caseVal.AssetId){
                        tempCaseWrapper.add(cswr);     
                    }
                }
                
                if(aswr.selected == true || MasterChkBox == true){
                    asset_Wrapper assetWrap = new asset_Wrapper(aswr.asse,true,tempCaseWrapper);
                    finalAssetWrapper.add(assetWrap);
                }
                
            }
            
            System.debug('finalAssetWrapper size:'+finalAssetWrapper.size());
            
        if(woWrapper.size() > 0)
            woWrapperSize = true;
        else
            woWrapperSize = false;
            
       System.debug('woWrapperSize:'+woWrapperSize);
        
        System.debug('WoWrapperList:'+woWrapper);
        System.debug('selected case:'+selectedCaseList);
        return null;
    }
    
    //Case Filter Method
    public PageReference filterCaseRecs(){
    
        List<Id> caseList = new List<Id>();
        List<Id> assetList = new List<Id>();
        List<case> finalCaseList = new List<Case>();
        List<case_Wrapper> newCaseWrap = new List<case_Wrapper>();
        String caseRTs = '';
        String casePriority = '';
        String caseIds = '';
        //DateTime servStartDT;
        //DateTime servStopDT;
        
        for(asset_Wrapper aw : assetWrapper){
            if(aw.selected == true || MasterChkBox == true){ 
                    System.debug('inside');
                    assetList.add(aw.asse.Id);
                }
                              
        }
        
        System.debug('assetList:'+assetList);
        
        if(caseWrapper != null && caseWrapper.size() > 0){
            for(case_Wrapper cw : caseWrapper){
                caseList.add(cw.caseVal.Id);
            }
        }
        
        System.debug('caseList:'+caseList);
        System.debug('selectedRTs:'+selectedRTs);
        if(selectedRTs.size() > 0){
            System.debug('Yo yo:');
            Integer totalcount = selectedRTs.size();
            Integer count = 0;
            System.debug('totalcount:'+totalcount);
            for(SelectOption so : selectedRTs){
                
                System.debug('count:'+count);
                if(count == 0){
                    caseRTs += '\''+so.getValue()+'\'';
                    System.debug('caseRTs1:'+caseRTs);
                    }
                else {
                    caseRTs += ','+'\''+so.getValue()+'\''; 
                    System.debug('caseRTs2:'+caseRTs);       
                }
                count++;
            }
        }
        
        System.debug('caseRTs:'+caseRTs);
        
        System.debug('selectedCaseTypes:'+selectedCaseTypes);
        if(selectedCaseTypes.size() > 0){
            Integer totalcount = selectedCaseTypes.size();
            Integer count = 0;
            for(SelectOption so : selectedCaseTypes){
               
                if(count != totalcount && casePriority == '')
                    casePriority += '\''+so.getValue()+'\'';
                else if(casePriority != '')
                    casePriority += ','+'\''+so.getValue()+'\'';
            
                 count++;           
            }
        }
        
        System.debug('casePriority:'+casePriority);
        
        System.debug('caseList:'+caseList.size());
        
        String caseQuery;
        
        if(caseList.size() > 0){
        
            caseQuery = 'SELECT Id, CaseNumber, Subject, CreatedDate, AssetId, Asset.Name, Asset.SerialNumber, ClosedDate, RecordType.Id, RecordType.Name, Priority,PO_Number__c,PO_Cap__c  from Case where AssetId IN :assetList';
            
            if(servStartDate != null){
                //servStartDT = DateTime.newInstance(servStartDate.year(), servStartDate.month(), servStartDate.day(),00, 00, 00);
                System.debug(DateTime.newInstance(servStartDate.year(), servStartDate.month(), servStartDate.day()).format('yyyy-MM-dd')+'T00:00:00Z');
                caseQuery += ' AND CreatedDate >=' + DateTime.newInstance(servStartDate.year(), servStartDate.month(), servStartDate.day()).format('yyyy-MM-dd')+'T00:00:00Z';
            }
            if(servEndDate != null){
                //servStopDT = DateTime.newInstance(servEndDate.year(), servEndDate.month(), servEndDate.day());
                caseQuery += ' AND ClosedDate <= '+DateTime.newInstance(servEndDate.year(), servEndDate.month(), servEndDate.day()).format('yyyy-MM-dd')+'T11:59:59Z';
            }
            if(caseRTs != '' && caseRTs != null)
                caseQuery += ' AND RecordTypeId IN ('+caseRTs+')';
            if(casePriority != '' && casePriority != null)
                caseQuery += ' AND Priority IN ('+casePriority+')';
        }
          
        System.debug('c'+caseQuery);      
              
        
        if(caseQuery != null)
        finalCaseList = Database.query(caseQuery);

        System.debug('finalCaseList:'+finalCaseList);
            
        if(finalCaseList.size() > 0){
            caseWrapper = new List<case_Wrapper>();  
                for(Case c1 : finalCaseList){
                    case_Wrapper casewrap = new case_Wrapper(c1,false,null,null); 
                    caseWrapper.add(casewrap); 
                    }    
        }
        else 
            caseWrapper = new List<case_Wrapper>();
        
        if(caseWrapper.size() > 0)
           caseWrapperSize = true;
       else{
           caseWrapperSize = false;
           woWrapperSize = false;
           }

        
       
            
    
        return null;
        
    }
    
    
    //Redirect to report page
    public PageReference generateReport(){
    
       List<WorkOrder> finalWOList = new List<WorkOrder>();
       Map<Id,List<WorkOrder>> finalWOMap = new Map<Id,List<WorkOrder>>();
       List<Case> caseList = new List<Case>();
       //finalWrapperList = new List<finalWrapper>();
       if(finalAssetWrapper == null)
           finalAssetWrapper = new List<asset_Wrapper>();
       if(finalCaseWrapper == null)
           finalCaseWrapper = new List<case_Wrapper>();
           
       //finalAssetWrapper = new List<asset_Wrapper>();
       //finalCaseWrapper = new List<case_Wrapper>();
       finalWOWrapper = new List<wo_Wrapper>();
        
       PageReference pageref = new PageReference('/apex/CustomerServiceReport?Id='+sObjectId);
       pageref.setredirect(false);
       
       if(!Test.isRunningTest()){
           Blob pdf1 = pageref.getcontentAsPdf();
           
           Attachment attach = new Attachment();
           attach.Body = pdf1;
           attach.Name = 'Customer Service Report.pdf';
           attach.IsPrivate = false;
           attach.ParentId = sObjectId;
           insert attach;
       }
       
       if(isCase != null && isCase == true){
           finalAssetWrapper =  assetWrapper;
           finalCaseWrapper = caseWrapper;
           finalWOWrapper = woWrapper;
       }
       
       System.debug('finalAssetWrapper:'+finalAssetWrapper.size());
       System.debug('finalCaseWrapper:'+finalCaseWrapper.size());
       //System.debug('woWrapper:'+woWrapper.size());
       
       for(asset_Wrapper aw : finalAssetWrapper){
           System.debug('caseNumber:'+aw.asse.SerialNumber);
           System.debug('caseWrapperList:'+aw.caseWrapper);
       }
       
       //System.debug('finalWrap:'+finalWrapperList.size());
       //System.debug('fffinalll:'+finalWrapperList);
       
       
        
       return pageref;
       //return null;
    }
    
    //Cancel Method to redirect the users to the record of Origination
    public PageReference Cancel() {
       PageReference pageref = new PageReference('/'+sobjectId);
       pageref.setredirect(true);
      
       return pageref;
    }
    
 
}