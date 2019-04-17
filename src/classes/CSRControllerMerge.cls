/*---------------------------------------------------------------------------------------------------------------------------------------------
Author:     Mani Sundaresan
Description:  Controller class for Customer Service Report functionality

Test Class:   Test_CSRControllerMerge 

History:
<Date>      <Authors Name>    <Brief Description of Change>
05/04/2017   Mani Sundaresan    Initial Creation (US2248)
07/18/2018   Krishna prasad     Added the logic as part of US-5182
01/11/2019   Nomita Walke       Added finalAssetWrapper to constructor for community reports. US-0006454
01/28/2019   Kasmoor Reddy      Modified the workorder queries to apply some filter criteria and added new hologic logo in pdf as part of US-0006558
------------------------------------------------------------------------------------------------------------------------------------------------*/


public with sharing class CSRControllerMerge {
    
    public Id sObjectId {get; set;}
    public Boolean fromPDF=false;
    public String sObjectRT {get; set;}
    transient List<Asset> AssetListWithoutCase;
    public List<Id> AssetIdWithoutCase {get;set;}
    public Boolean fromAsset=true;
    public Boolean fromMaster=false;
    public Integer TotalWorkOrderSearch {get;set;}
    public Integer PaginationWorkOrder {get;set;}
    public Integer TotalCaseSearch {get;set;}
    public Integer Pagination {get;set;}
    public Boolean fromButton=false;
    public List<Account> accountList {get; set;}
    public List<Asset> assetList {get; set;}
    public List<Case> caseList {get; set;}
    transient List<WorkOrder> woList = new List<WorkOrder>();
    //07/18/2018-add by krishna Prasad as part of US-5182
    public List<ServiceAppointment> saList = new List<ServiceAppointment>();
    public String accountAddress {get; set;}
    @testVisible transient List<case_Wrapper> newCaseWrapper ;
    //public List<finalWrapper> finalWrapperList {get; set;}
    public List<asset_Wrapper> assetWrapper {get; set;}
    public List<case_Wrapper> caseWrapper {get; set;}
    @testVisible transient list<wo_Wrapper> woWrapper {get; set;}
    public transient List<asset_Wrapper> finalAssetWrapper {get; set;}
    transient List<case_Wrapper> finalCaseWrapper;
    transient List<wo_Wrapper> finalWOWrapper;
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
    public SelectOption[] wrselectedRTs { get; set; }
    @testVisible Set<Id> SelectedCaseIds;
    public SelectOption[] allRTs { get; set; }
    public SelectOption[] callRTs { get; set; }
    public SelectOption[] selectedCaseTypes { get; set; }
    public SelectOption[] allCaseTypes { get; set; }
    public Set<Id> caseRTs = new Set<Id>();
    public Set<Id> woRTs = new Set<Id>();
    public Id woliRTId = GlobalUtility.getRecordTypeId('WorkOrderLineItem','B&SH Add a Note');
    public Id systemAssetRTId = GlobalUtility.getRecordTypeId('Asset','System');
    public Integer FirstTimeGetAllCases {get;set;}
    public list<wo_Wrapper> woWrapperDup  {get; set;}
    //Added a variable to get recordtypeId to ensure workorder's recordtype as part of US-0006558 on 01/28/2019 byKasmoor Reddy      
    public CSRWOTypes__c PMID=CSRWOTypes__c.getValues('PM');
    public CSRControllerMerge(){
        woWrapper=new List<wo_Wrapper>();
        woWrapperDup=new list<wo_Wrapper>();
        TotalWorkOrderSearch=0;
        PaginationWorkOrder=0;
        AssetIdWithoutCase=new List<Id>();
        AssetListWithoutCase=new List<Asset>();
        sObjectId = ApexPages.currentPage().getParameters().get('Id');
        sObjectRT = ApexPages.currentPage().getParameters().get('RecordType');
        SelectedCaseIds=new Set<Id>();
        newCaseWrapper=new List<Case_Wrapper>();
        FirstTimeGetAllCases=0;
        fromButton=false;
        Pagination=0;
        totalCaseSearch=0;
        assetList = new List<Asset>();
        accountList = new List<Account>();
        assetWrapper = new List<asset_Wrapper>();
        caseWrapper = new List<case_Wrapper>();
        allRTs = new List<SelectOption>();
        callRTs  = new List<SelectOption>();
        allCaseTypes = new List<SelectOption>();
        selectedRTs = new List<SelectOption>();
        wrselectedRTs = new List<SelectOption>();
        selectedCaseTypes = new List<SelectOption>();
        List<Asset> tempAssetList = new List<Asset>();
        fromMaster=false;
        finalAssetWrapper = new List<asset_Wrapper>();

        
        for(CSRPriority__c csrp : CSRPriority__c.getAll().values())
            allCaseTypes.add(new SelectOption(csrp.Case_Priority__c, csrp.Case_Priority__c));
        
        for(CSRTypes__c csrt : CSRTypes__c.getAll().values()){
            callRTs.add(new SelectOption(csrt.RecordType_Id__c, csrt.RecordType_Name__c));
            caseRTs.add(csrt.RecordType_Id__c);
        }
        //07/18/2018-added by krishna Prasad as part of US-5182
        for(CSRWOTypes__c csrwo : CSRWOTypes__c.getAll().values()){
            allRTs.add(new SelectOption(csrwo.RecordType_Id__c, csrwo.RecordType_Name__c));
            woRTs.add(csrwo.RecordType_Id__c);     
        }  
        
        
        System.debug('sObjectId:'+sObjectId);
        System.debug('sObjectRT:'+sObjectRT);
        
        if(String.valueOf(sObjectId).substring(0,3) == '001'){
            
            isAccount = true;
            
            accountList = [SELECT Id, Name, Parent.Name, Parent.RecordTypeId, BillingCity, BillingCountry, BillingPostalCode, BillingState, BillingStreet, (SELECT Id, Name, SerialNumber, Product2.Name, Description, Account.Name, RecordTypeId from Assets) from Account where Id = :sObjectId];
            AssetListWithoutCase=[SELECT Id, Name, SerialNumber, Product2.Name, Description, Account.Name, Account.Parent.Name, Account.ParentId, AccountId, Account.BillingCity, Account.BillingCountry, Account.BillingPostalCode, Account.BillingState, Account.BillingStreet from Asset where AccountId = :sObjectId and RecordTypeId = :systemAssetRTId and id not in (SELECT AssetId from Case) ];
            for(Asset ass:AssetListWithoutCase)
            {
                AssetIdWithoutCase.add(ass.Id);
            }
            system.debug('AssetIdWithoutCase'+AssetIdWithoutCase);
            if(accountList.size() > 0){
                accountAddress = accountList[0].BillingStreet + ', ' + accountList[0].BillingCity + ', ' + accountList[0].BillingState + ', ' + accountList[0].BillingCountry + ' ' + accountList[0].BillingPostalCode;
                
                if(sObjectRT == 'Site'){
                    if(accountList[0].getSObjects('Assets') != null)
                        for(Asset asse : accountList[0].getSObjects('Assets')){
                            if(asse.RecordTypeId == systemAssetRTId){
                                asset_Wrapper assewrap = new asset_Wrapper(asse,false,null,null); 
                                assetWrapper.add(assewrap);
                                System.debug('Inside Sites');
                            }
                        }
                    
                    
                    
                    
                }
                else if(sObjectRT == 'Customer'){
                    AssetListWithoutCase=[SELECT Id, Name, SerialNumber, Product2.Name, Description, Account.Name, Account.Parent.Name, Account.ParentId, AccountId, Account.BillingCity, Account.BillingCountry, Account.BillingPostalCode, Account.BillingState, Account.BillingStreet from Asset where Account.ParentId= :sObjectId and RecordTypeId = :systemAssetRTId and id not in (SELECT AssetId from Case) ];
                    for(Asset ass:AssetListWithoutCase)
                    {
                        AssetIdWithoutCase.add(ass.Id);
                    }
                    system.debug('AssetIdWithoutCase'+AssetIdWithoutCase);
                    for(Asset asse : [SELECT Id, Name, SerialNumber, Product2.Name, Description, Account.ParentId, Account.BillingCity, Account.BillingCountry, Account.BillingPostalCode, Account.BillingState, Account.BillingStreet, Account.Name from Asset where Account.ParentId = :sObjectId and RecordTypeId = :systemAssetRTId]){
                        asset_Wrapper assewrap = new asset_Wrapper(asse,false,null,null); 
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
            AssetIdWithoutCase.add(sobjectId);
            
            assetList = [SELECT Id, Name, SerialNumber, Product2.Name, Description, Account.Name, Account.Parent.Name, Account.ParentId, AccountId, Account.BillingCity, Account.BillingCountry, Account.BillingPostalCode, Account.BillingState, Account.BillingStreet, (SELECT Id, CaseNumber, Subject, CreatedDate, ClosedDate, RecordType.Id, RecordType.Name, Priority, AssetId, Asset.Name, Asset.SerialNumber, PO_Number__c, PO_Cap__c  from Cases ) from Asset where Id = :sObjectId and RecordTypeId = :systemAssetRTId];
            AssetListWithoutCase=[SELECT Id, Name, SerialNumber, Product2.Name, Description, Account.Name, Account.Parent.Name, Account.ParentId, AccountId, Account.BillingCity, Account.BillingCountry, Account.BillingPostalCode, Account.BillingState, Account.BillingStreet from Asset where Id = :sObjectId and RecordTypeId = :systemAssetRTId and id not in (SELECT AssetId from Case) ];
            for(Asset ass:AssetListWithoutCase)
            {
                AssetIdWithoutCase.add(ass.Id);
            }
            system.debug('assets without case:'+AssetIdWithoutCase);
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
                    caseList = [SELECT Id, CaseNumber, Subject,Case_Summary__c,Case_Summary__r.TS_Resolution__c, CreatedDate, AssetId, Asset.Name, Asset.SerialNumber, ClosedDate, RecordType.Id, RecordType.Name, Priority, PO_Number__c, PO_Cap__c, Type, (SELECT Id, Description, Note_Type__c from Tasks) from Case where Id IN :caseIdList ORDER BY CaseNumber];   
                totalCaseSearch=[select count() from case where Id IN :caseIdList ];
                if(caseList.size() > 0)
                    for(Case cs : caseList){
                        //07/18/2018-added by krishna Prasad as part of US-5182
                        case_Wrapper caseWrap = new case_Wrapper(cs,false,null,cs.getSObjects('Tasks'),null,null,null,null);
                        newcaseWrapper.add(caseWrap);    
                    }
                if(caseIdList.size() > 0)
                    caseList = [SELECT Id, CaseNumber, Subject,Case_Summary__c,Case_Summary__r.TS_Resolution__c, CreatedDate, AssetId, Asset.Name, Asset.SerialNumber, ClosedDate, RecordType.Id, RecordType.Name, Priority, PO_Number__c, PO_Cap__c, Type, (SELECT Id, Description, Note_Type__c from Tasks) from Case where Id IN :caseIdList ORDER BY CaseNumber limit 5 offset: pagination];   
                //totalCaseSearch=[select count() from case where Id IN :caseIdList ];
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
                        //07/18/2018-added by krishna Prasad as part of US-5182
                        case_Wrapper caseWrap = new case_Wrapper(cs,false,null,cs.getSObjects('Tasks'),null,null,null,null);
                        caseWrapper.add(caseWrap);    
                    }
                 
                List<WorkOrderLineItem> wolis;
                wowrapper=new List<wo_wrapper>();
      //Modified the workorder queries to apply some filter criteria as part of US-0006558 on 01/28/2019 by Kasmoor Reddy          
      List<workorder> workorderlist =new List<workorder>([SELECT Id, WorkOrderNumber,FE_Resolution__c,AssetId,Asset.SerialNumber,Description,Subject, Completed_Date__c, StartDate, Type__c, EndDate, Case.CaseNumber, CaseId, Owner.Name, (SELECT Id, Description, TotalPrice, RecordTypeId, WorkOrderId, Note_Type__c, RecordType.Name  from WorkOrderLineItems) from WorkOrder where AssetId =: sobjectId and caseId=null and Status!='Cancelled' and (Status!='New' or RecordTypeId!=: PMID.RecordType_Id__c)]);
                       if(workorderlist.size()>0)
                for(WorkOrder wo : workorderlist){
                     wolis = new List<WorkOrderLineItem>();
                        System.debug('wo  :::val:'+wo);
                        for(WorkOrderLineItem woli : wo.getSObjects('WorkOrderLineItems')){
                            System.debug('woli rt:'+woli.RecordTypeId);
                            System.debug('woliRTId:'+woliRTId);
                            if(woli.Note_Type__c != 'FE Resolution')
                                wolis.add(woli);
                            
                            System.debug('wolis val:'+wolis);
                        } 
                        
                        
                        wo_Wrapper csrw = new wo_Wrapper(wo,wolis,null);
                        woWrapper.add(csrw);
                    }
               
                
                for(Asset asse : assetList){
                    asset_Wrapper assewrap = new asset_Wrapper(asse,true,caseWrapper,woWrapper); 
                    assetWrapper.add(assewrap);
                }  
                
                totalWorkOrderSearch=woWrapper.size();
                 for(integer i=PaginationWorkOrder;i<PaginationWorkOrder+5;i++)
                {
                    if(i>=0&&i<totalWorkOrderSearch)
                        woWrapperDup.add(woWrapper[i]);
                } 
                 if(woWrapper.size() > 0)
                    woWrapperSize = true;
                else
                    woWrapperSize = false;     
                
                
                caseSize = newcaseWrapper.size();
                
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
            //Modified the workorder queries to apply some filter criteria as part of US-0006558 on 01/28/2019 by Kasmoor Reddy 
            caseList = [SELECT Id, AssetId, Asset.Name, Asset.Account.Parent.Name,Case_Summary__c,Case_Summary__r.TS_Resolution__c,Asset.Account.ParentId, Asset.Account.Parent.RecordTypeId, Asset.Account.Name, Asset.Account.BillingAddress, Asset.Account.BillingCity, Asset.Account.BillingCountry, Asset.Account.BillingPostalCode, Asset.Account.BillingState, Asset.Account.BillingStreet, Asset.SerialNumber, Asset.Product2.Name, Asset.Description, CaseNumber, Subject, CreatedDate, PO_Number__c, PO_Cap__c, Type, RecordType.Name, RecordTypeId, (SELECT Id, FE_Resolution__c ,WorkOrderNumber, CaseId, Case.CaseNumber, Subject, StartDate, EndDate, Type__c, Owner.Name, Completed_Date__c,Description,RecordTypeId from WorkOrders where Status!='Cancelled' and (Status!='New' or RecordTypeId!=: PMID.RecordType_Id__c)),(SELECT Id, Description, Note_Type__c from Tasks) from Case where Id = :sObjectId AND RecordTypeId IN :caseRTs ];
            AssetIdWithoutCase.add(caseList[0].assetId);
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
                    for(WorkOrder wo : [SELECT Id, WorkOrderNumber,FE_Resolution__c,AssetId,Asset.SerialNumber,Description,Subject, Completed_Date__c, StartDate, Type__c, EndDate, Case.CaseNumber, CaseId, Owner.Name, (SELECT Id, Description, TotalPrice, RecordTypeId, WorkOrderId, Note_Type__c, RecordType.Name  from WorkOrderLineItems) from WorkOrder where Id IN :woIdList and Status!='Cancelled' and (Status!='New' or RecordTypeId!=: PMID.RecordType_Id__c)  ]){
                        //Modified the workorder queries to apply some filter criteria as part of US-0006558 on 01/28/2019 by Kasmoor Reddy 
                        wolis = new List<WorkOrderLineItem>();
                        System.debug('wo  :::val:'+wo);
                        for(WorkOrderLineItem woli : wo.getSObjects('WorkOrderLineItems')){
                            System.debug('woli rt:'+woli.RecordTypeId);
                            System.debug('woliRTId:'+woliRTId);
                            if(woli.Note_Type__c != 'FE Resolution')
                                wolis.add(woli);
                            
                            System.debug('wolis val:'+wolis);
                        } 
                        
                        
                        wo_Wrapper csrw = new wo_Wrapper(wo,wolis,null);
                        woWrapper.add(csrw);
                    }
                totalWorkOrderSearch=woWrapper.size();
                
                for(integer i=PaginationWorkOrder;i<PaginationWorkOrder+5;i++)
                {
                    if(i>=0&&i<totalWorkOrderSearch)
                        woWrapperDup.add(woWrapper[i]);
                } 
                
                 
                
                Account parentAcc = new Account(Id=caseList[0].Asset.Account.ParentId, Name = caseList[0].Asset.Account.Parent.Name);
                
                Account acc = new Account(Name = caseList[0].Asset.Account.Name, Parent=parentAcc, ParentId=caseList[0].Asset.Account.ParentId, BillingStreet = caseList[0].Asset.Account.BillingStreet, BillingCity = caseList[0].Asset.Account.BillingCity, BillingState = caseList[0].Asset.Account.BillingState, BillingCountry = caseList[0].Asset.Account.BillingCountry, BillingPostalCode = caseList[0].Asset.Account.BillingPostalCode);
                accountList.add(acc);
                accountAddress = caseList[0].Asset.Account.BillingStreet + ', ' + caseList[0].Asset.Account.BillingCity + ', ' + caseList[0].Asset.Account.BillingState + ', ' + caseList[0].Asset.Account.BillingCountry + ' ' + caseList[0].Asset.Account.BillingPostalCode;   
                //if(caseList[0].Asset.Account.Parent.RecordTypeId == GlobalUtility.getRecordTypeId('Account','Customer'))
                //customerName = caseList[0].Asset.Account.Parent.Name;
                //selectedAsset.add(caseList[0].AssetId);
                sObjectRT = 'Site';
                
                for(Case cae : caseList){
                    
                    taskList = new List<Task>();
                    for(Task t : cae.getSObjects('Tasks')){
                        if(t.Note_Type__c == 'FE Resolution' || t.Note_Type__c == 'Resolution')
                            taskList.add(t);    
                    }
                    case_Wrapper casewrap;
                    //07/18/2018-added by krishna Prasad as part of US-5182
                    if(taskList.size() > 0)
                        casewrap = new case_Wrapper(cae,false,woWrapper,taskList,null,null,null,null);
                    else
                        casewrap = new case_Wrapper(cae,false,woWrapper,null,null,null,null,null);
                    
                    //case_Wrapper caseWrap = new case_Wrapper(cae,false,woWrapper,cae.getSObjects('Tasks')); 
                    caseWrapper.add(caseWrap);
                    
                    Product2 pro = new Product2(Id=cae.Asset.Product2Id, Name=cae.Asset.Product2.Name);
                    Asset asse = new Asset(Id=cae.AssetId, Name=cae.Asset.Name, Description = cae.Asset.Description, SerialNumber = cae.Asset.SerialNumber, Product2Id=cae.Asset.Product2Id, Account=acc, Product2 = pro);
                    asset_Wrapper assetWrap = new asset_Wrapper(asse,true,caseWrapper,null);
                    assetWrapper.add(assetWrap);
                    finalAssetWrapper.add(assetWrap);
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
        public list<wo_Wrapper> woWrapperWithOutCase {get; set;}
        public asset_Wrapper(Asset asse, Boolean selected, List<case_Wrapper> caseWrapper,List<wo_Wrapper> woWrapperWithOutCase){
            //this.acc = acc;
            this.selected = selected;
            this.asse = asse;
            this.caseWrapper = caseWrapper;
            this.woWrapperWithOutCase=woWrapperWithOutCase;
        }
    }
    
    //Wrapper Class for Cases
    public Class case_Wrapper{
        
        public Case caseVal {get; set;}
        public Boolean selected {get; set;}
        public list<wo_Wrapper> woWrapper {get; set;}
        public List<Task> caseTaskList {get; set;}
        //07/18/2018-add by krishna Prasad as part of US-5182
        
        public String woRTs {get; set;}
        public Date servStartDate {get; set;}
        public Date servEndDate {get; set;}
        
        
        
        
        public case_Wrapper(Case c, Boolean selected, list<wo_Wrapper> woWrapper, List<Task> caseTaskList,String woRTs,string cRTS,Date servStartDate,Date servEndDate){
            caseVal = c;
            this.selected = selected;
            this.woWrapper = woWrapper;
            this.caseTaskList = caseTaskList;
            //07/18/2018-added by krishna Prasad as part of US-5182
            if(woRTs != null)
                this.woRTs = woRTs;
            if(servStartDate != null)
                this.servStartDate = servStartDate;
            if(servEndDate != null)
                this.servEndDate = servEndDate;
            
        }
    }
    
    //Wrapper Class for WorkOrders
    public Class wo_Wrapper{
        
        public WorkOrder wo {get; set;}
        public List<WorkOrderLineItem> woliList {get; set;}
        public list<ProductConsumed> pcList{get; set;}
        
        public wo_Wrapper(WorkOrder wo, List<WorkOrderLineItem> woliList,list<ProductConsumed> pcList){
            this.wo = wo;
            this.pcList= pcList;
            this.woliList = woliList;
            
        }
    }
    
    
    //Pagination
    public boolean getprev()
    {
        if(Pagination == 0)
            return true;
        else
            return false;
        
    }
    public boolean getnxt()
    {
        if((Pagination + 5) > totalCaseSearch)
            return true;
        else
            return false;
        
    }  
    public void Previous()
    {
        FirstTimeGetAllCases=1;
        if(pagination != 0)
        {
            pagination -= 5;
        }else{
            pagination = 0; 
        }
        if((selectedCaseTypes==null||selectedCaseTypes.isEmpty())&&(selectedRTs==null||selectedRTs.isEmpty())&&servEndDate==null&&servStartDate==null)
        {
            system.debug('no filters');
            setSelected();  
        }
        
        else
        {
            fromButton=true;    system.debug(' filters');
            filterCaseRecs(); 
        }
        
    }
    public void Next()
    {
        FirstTimeGetAllCases=1;
        if(pagination < totalCaseSearch){
            pagination += 5;
        }else{
            pagination = totalCaseSearch;
        }
        if((selectedCaseTypes==null||selectedCaseTypes.isEmpty())&&(selectedRTs==null||selectedRTs.isEmpty())&&servEndDate==null&&servStartDate==null)
        {
            system.debug('no filters');
            setSelected();  
        }
        
        else
        {
            fromButton=true;
            system.debug(' filters');
            filterCaseRecs(); 
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
                asset_Wrapper assetWrap = new asset_Wrapper(aw.asse,true,null,null);
                finalAssetWrapper.add(assetWrap);
                
            }
            
        }
        
        System.debug('selected asset:'+selectedAsset);
        
        if(selectedAsset.size() > 0)
        { TotalCaseSearch=[select count() from Case where AssetId IN :selectedAsset AND RecordTypeId IN :caseRTs];
         caseList = [SELECT Id, CaseNumber, Subject,Case_Summary__c,Case_Summary__r.TS_Resolution__c,CreatedDate, AssetId, Asset.Name, Asset.SerialNumber, ClosedDate, RecordType.Id, RecordType.Name, Priority, PO_Number__c, PO_Cap__c, Type, (SELECT Id, Description, Note_Type__c from Tasks) from Case where AssetId IN :selectedAsset AND RecordTypeId IN :caseRTs  ORDER BY CaseNumber limit 5 offset: pagination];
        }  
        else
           TotalCaseSearch=0; 
        if(caseList != null)
            for(Case c : caseList){
                taskList = new List<Task>();
                for(Task t : c.getSObjects('Tasks')){
                    if(t.Note_Type__c == 'FE Resolution' || t.Note_Type__c == 'Resolution')
                        taskList.add(t);    
                }
                case_Wrapper casewrap;
                
                if(caseMasterChkBox==true)
                {
                    if(taskList.size() > 0)
                        casewrap = new case_Wrapper(c,true,null,taskList,null,null,null,null);
                    else
                        casewrap = new case_Wrapper(c,true,null,null,null,null,null,null); 
                    
                }
                else
                {
                    if(SelectedCaseIds.contains(c.id))
                    {
                        if(taskList.size() > 0)
                            casewrap = new case_Wrapper(c,true,null,taskList,null,null,null,null);
                        else
                            casewrap = new case_Wrapper(c,true,null,null,null,null,null,null); 
                        
                        
                    }
                    
                    else
                    {
                        //07/18/2018-added by krishna Prasad as part of US-5182  
                        if(taskList.size() > 0)
                            casewrap = new case_Wrapper(c,false,null,taskList,null,null,null,null);
                        else
                            casewrap = new case_Wrapper(c,false,null,null,null,null,null,null); 
                        
                        
                    }   
                }
                
                caseWrapper.add(casewrap); 
                
            }
        
        System.debug('caseWrapper2:'+TotalCaseSearch);
        
        
        caseSize = TotalCaseSearch;
        
        if(TotalCaseSearch > 0)
            caseWrapperSize = true;
        else{
            caseWrapperSize = false;
            woWrapperSize = false;
        }
        if(AssetIdWithoutCase!=null && selectedAsset!=null)
        {
            fromAsset=true;
            setCaseSelected();    
        }
        
        return null;
    }
    
    //Selected Case Records
    public PageReference setCaseSelected(){
        if(fromAsset==true)
        {
            paginationWorkOrder=0;
            woWrapperDup.clear();
            
        }
        newCaseWrapper=new List<Case_Wrapper>();
        Id oi = (Id)System.currentPagereference().getParameters().get('CaseId');
        String selected = System.currentPagereference().getParameters().get('Selected');
        String master = System.currentPagereference().getParameters().get('Master');
        List<Id> selectedCaseList = new List<Id>();
        //fromMaster=true;
        //List<WorkOrder> woList = new List<WorkOrder>();
        woWrapper = new List<wo_Wrapper>();
        finalCaseWrapper = new List<case_Wrapper>();
        finalAssetWrapper = new List<asset_Wrapper>();
        List<wo_Wrapper> tempWOWrapper;
        List<case_Wrapper> tempCaseWrapper;
        List<WorkOrderLineItem> wolis = new List<WorkOrderLineItem>();
        List<Task> taskList = new List<Task>();
        //woliRTId = GlobalUtility.getRecordTypeId('WorkOrderLineItem','B&SH Add a Note');
        //07/18/2018-add by krishna Prasad as part of US-5182
        String woRTsFilter ;
        Date servStartDate ;
        Date servEndDate ;
        List<ServiceAppointment> finalSAList = new List<ServiceAppointment>();
        list<id> woIdList = new list<id>();
        list<WorkOrder> woListx = new list<WorkOrder>() ;
        List<String> lstwoRTsFilter = new List<String>();
        list<ProductConsumed> pcList = new list<ProductConsumed>();
        List<Id> selectedAsset = new List<Id>();
        //selectedCaseIds.clear();
        newCaseWrapper.clear();
        System.debug('Case record:'+oi);
        System.debug('selected:'+selected);
        System.debug('master:'+master);
        System.debug('caseWrapper:'+caseSize);
        //07/18/2018-added by krishna Prasad as part of US-5182
        for(case_Wrapper cwrap : caseWrapper){
            system.debug('cwrap:::'+cwrap);
            system.debug('cwrap.woRTs:::'+cwrap.woRTs);
            if(cwrap.woRTs != null){
                system.debug('cwrap.woRTs:::in'+cwrap.woRTs);
                if(cwrap.woRTs.length()>2){
                    woRTsFilter = cwrap.woRTs;
                    system.debug('woRTsFilter:::in'+woRTsFilter);
                    
                    lstwoRTsFilter = woRTsFilter.split(',');
                    system.debug('lstwoRTsFilter:::in'+lstwoRTsFilter);
                }
            }
            
            system.debug(':cwrap.servStartDate::'+cwrap.servStartDate);        
            system.debug(':cwrap.servEndDate::'+cwrap.servEndDate); 
            if(cwrap.servStartDate != null){
                system.debug(':cwrap.servStartDate:in:'+cwrap.servStartDate);
                servStartDate = cwrap.servStartDate;
            }
            if(cwrap.servEndDate != null){
                servEndDate = cwrap.servEndDate;
            }
            system.debug(':servStartDate::'+servStartDate);     
            system.debug(':servEndDate::'+servEndDate);
            
            System.debug('1st level:'+caseMasterChkBox);
            System.debug('2nd level:'+cwrap.selected);
            if((cwrap.selected == true && master == null) || caseMasterChkBox == true){ 
                System.debug('inside');
                selectedCaseList.add(cwrap.caseVal.Id);
                SelectedCaseIds.add(cwrap.caseVal.Id);
            }    
            else
            {
                if(cwrap.selected==false && SelectedCaseIds.contains(cwrap.caseVal.id))
                {
                    SelectedCaseIds.remove(cwrap.caseVal.id); 
                }
            }  
        }
        if(true)
        {
            
            
            List<Case> caseList;
            
            
            for(asset_Wrapper aw : assetWrapper){
                System.debug('1st level:'+MasterChkBox);
                System.debug('2nd level:'+aw.selected);
                if((aw.selected == true ) || MasterChkBox == true){ 
                    System.debug('inside');
                    selectedAsset.add(aw.asse.Id);
                    asset_Wrapper assetWrap = new asset_Wrapper(aw.asse,true,null,null);
                    finalAssetWrapper.add(assetWrap);
                    
                }
                
            }
            
            system.debug('first time'+FirstTimeGetAllCases);
            system.debug('selectedCaseIdds:'+ SelectedCaseIds);
            system.debug(selectedAsset);
            if(isAsset==true)
                selectedAsset.add(sobjectId);
            if(selectedAsset.size() > 0)
            {
               system.debug(selectedAsset); 
                if((selectedCaseTypes==null||selectedCaseTypes.isEmpty())&&(selectedRTs==null||selectedRTs.isEmpty())&&servEndDate==null&&servStartDate==null)
                {
                    system.debug(selectedAsset);
                    system.debug(caseRTs);
                    caseList = [SELECT Id, CaseNumber, Subject, CreatedDate, AssetId,Case_Summary__c,Case_Summary__r.TS_Resolution__c, Asset.Name, Asset.SerialNumber, ClosedDate, RecordType.Id, RecordType.Name, Priority, PO_Number__c, PO_Cap__c, Type, (SELECT Id, Description, Note_Type__c from Tasks) from Case where AssetId IN :selectedAsset AND RecordTypeId IN :caseRTs Order by createdDate desc ];
                    system.debug(caseList);
                    if(caseList != null)
                        for(Case c : caseList){
                            taskList = new List<Task>();
                            for(Task t : c.getSObjects('Tasks')){
                                if(t.Note_Type__c == 'FE Resolution' || t.Note_Type__c == 'Resolution')
                                    taskList.add(t);    
                            }
                            case_Wrapper casewrap;
                            
                            if(SelectedCaseIds.contains(c.id))
                            {
                                if(taskList.size() > 0)
                                    casewrap = new case_Wrapper(c,true,null,taskList,null,null,null,null);
                                else
                                    casewrap = new case_Wrapper(c,true,null,null,null,null,null,null); 
                                
                                
                            }
                            
                            else
                            {
                                //07/18/2018-added by krishna Prasad as part of US-5182  
                                if(taskList.size() > 0)
                                    casewrap = new case_Wrapper(c,false,null,taskList,null,null,null,null);
                                else
                                    casewrap = new case_Wrapper(c,false,null,null,null,null,null,null); 
                                
                                
                            }  
                            NewCaseWrapper.add(casewrap);
                            
                        }
                    system.debug('newcaseWrapper'+NewCaseWrapper);
                }
                
                else
                {
                    String caseRTs = '';
                    string wrRTs = '';
                    String casePriority = '';
                    String caseIds = '';
                    List<Id> assetList=new List<Id>();
                    //DateTime servStartDT;
                    //DateTime servStopDT;
                    
                    for(asset_Wrapper aw : assetWrapper){
                        if(aw.selected == true || MasterChkBox == true){ 
                            System.debug('inside');
                            assetList.add(aw.asse.Id);
                        }
                        
                    }
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
                    
                    if(wrselectedRTs.size() > 0){
                        System.debug('Yo yo:');
                        Integer totalcount = wrselectedRTs.size();
                        Integer count = 0;
                        System.debug('totalcount:'+totalcount);
                        for(SelectOption so : wrselectedRTs){
                            
                            System.debug('count:'+count);
                            if(count == 0){
                                wrRTs += '\''+so.getValue()+'\'';
                                System.debug('wrRTs2:'+wrRTs);
                            }
                            else {
                                wrRTs += ','+'\''+so.getValue()+'\''; 
                                System.debug('wrRTs:'+wrRTs);       
                            }
                            count++;
                        }
                    }
                    
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
                    
                    // System.debug('caseList:'+caseList.size());
                    
                    System.debug('assetList:'+assetList);
                    
                    
                    String caseQuery;
                    
                    
                    
                    caseQuery = 'SELECT  Id, CaseNumber, Case_Summary__c,Case_Summary__r.TS_Resolution__c,Subject, CreatedDate, AssetId, Asset.Name, Asset.SerialNumber, ClosedDate, RecordType.Id, RecordType.Name, Priority,PO_Number__c,PO_Cap__c  from Case where AssetId IN :assetList';
                    
                    if(servStartDate != null){
                        //servStartDT = DateTime.newInstance(servStartDate.year(), servStartDate.month(), servStartDate.day(),00, 00, 00);
                        System.debug(DateTime.newInstance(servStartDate.year(), servStartDate.month(), servStartDate.day()).format('yyyy-MM-dd')+'T00:00:00Z');
                        caseQuery += ' AND CreatedDate >=' + DateTime.newInstance(servStartDate.year(), servStartDate.month(), servStartDate.day()).format('yyyy-MM-dd')+'T00:00:00Z';
                    }
                    if(servEndDate != null){
                        //servStopDT = DateTime.newInstance(servEndDate.year(), servEndDate.month(), servEndDate.day());
                        caseQuery += ' AND ClosedDate <= '+DateTime.newInstance(servEndDate.year(), servEndDate.month(), servEndDate.day()).format('yyyy-MM-dd')+'T11:59:59Z';
                    }
                    //07/18/2018-commented by krishna Prasad as part of US-5182
                    //k
                    if(caseRTs != '' && caseRTs != null )
                        caseQuery += ' AND RecordTypeId IN ('+caseRTs+')';
                    if(casePriority != '' && casePriority != null)
                        caseQuery += ' AND Priority IN ('+casePriority+')';
                    
                    caseQuery+='Order by createdDate desc';
                    System.debug('c:::::::'+caseQuery);      
                    
                    if(caseQuery != null)
                    {
                        
                        CaseList = Database.query(caseQuery);
                    }
                    if(CaseList.size() > 0){
                        caseWrapper = new List<case_Wrapper>();  
                        for(Case c1 : CaseList){
                            case_Wrapper casewrap;
                            if(SelectedCaseIds.contains(c1.id))
                            {
                                casewrap = new case_Wrapper(c1,true,null,null,wrRTs,caseRTs,servStartDate,servEndDate); 
                            }
                            else
                            {
                                casewrap = new case_Wrapper(c1,false,null,null,wrRTs,caseRTs,servStartDate,servEndDate); 
                            }
                            
                            newcaseWrapper.add(casewrap); 
                        }    
                    }
                }
            }
        }  
        
        //07/18/2018-added by krishna Prasad as part of US-5182
        System.debug('selectedCaseList:'+selectedCaseList); 
        system.debug('SelectedCaseIds'+SelectedCaseIds);
        system.debug(caseMasterChkBox);
        system.debug(newCaseWrapper);
        woWrapper.clear();
        if(fromMaster==true && fromPDF==false)
        {
            system.debug('in if');
            if(oi==null&&master!=null&&caseMasterChkBox==false)
            {
                system.debug(newCaseWrapper);
                for(case_wrapper cwrap:newCaseWrapper)
                {
                    SelectedCaseIds.remove(cwrap.caseVal.id);
                    //caseMasterChkBox=false;
                     system.debug('if'+selectedCaseIds);
                } 
            }
            else
            {
                SelectedCaseIds.remove(oi);
                system.debug('else'+selectedCaseIds);
            }
            fromMaster=false;
        }
         system.debug(selectedCaseIds);
        if(caseMasterChkBox==true)
        {
            for(case_wrapper cwrap:newCaseWrapper)
            {
                SelectedCaseIds.add(cwrap.caseVal.id);
            }
            fromMaster=true;
        }
        system.debug(selectedCaseIds);
        String saQuery; 
        
        
        
        saQuery = 'SELECT Related_Work_Order__c,SchedEndTime,SchedStartTime,Work_Order__c  from ServiceAppointment where ';
        
        if(servStartDate != null){
            //servStartDT = DateTime.newInstance(servStartDate.year(), servStartDate.month(), servStartDate.day(),00, 00, 00);
            System.debug(DateTime.newInstance(servStartDate.year(), servStartDate.month(), servStartDate.day()).format('yyyy-MM-dd')+'T00:00:00Z');
            saQuery += '  SchedStartTime >=' + DateTime.newInstance(servStartDate.year(), servStartDate.month(), servStartDate.day()).format('yyyy-MM-dd')+'T00:00:00Z';
        }
        if(servEndDate != null){
            //servStopDT = DateTime.newInstance(servEndDate.year(), servEndDate.month(), servEndDate.day());
            if(servStartDate != null){
            saQuery += ' AND SchedEndTime <= '+DateTime.newInstance(servEndDate.year(), servEndDate.month(), servEndDate.day()).format('yyyy-MM-dd')+'T11:59:59Z';
            }else{
            saQuery += ' SchedEndTime <= '+DateTime.newInstance(servEndDate.year(), servEndDate.month(), servEndDate.day()).format('yyyy-MM-dd')+'T11:59:59Z';
            }    
        }
        //saQuery += ';';
        system.debug(':saQuery::'+saQuery);
        
        if(saQuery != null && (servStartDate != null || servEndDate != null ))            
            finalSAList = Database.query(saQuery);
        system.debug(':finalSAList.size()::'+finalSAList.size());
        if(finalSAList.size()>0){
            for(ServiceAppointment spWo:finalSAList){
                woIdList.add(spWo.Related_Work_Order__c);
            }
        }
        
        System.debug('finalCaseList:'+finalSAList);
        System.debug('selectedCaseIds:'+selectedCaseIds);
        if(selectedCaseIds != null || (AssetIdWithoutCase!=null && selectedAsset!=null)){
            system.debug('AssetIdWithoutCase'+AssetIdWithoutCase);
            String Cancelled='Cancelled';
            String NewStatus='New';
            String RecordTypeId= PMID.RecordType_Id__c;
            //Modified the workorder queries to apply some filter criteria as part of US-0006558 on 01/28/2019 by Kasmoor Reddy 
            string woListQuery = 'SELECT Id, WorkOrderNumber,AssetId,Asset.SerialNumber,Description,FE_Resolution__c, Completed_Date__c, Subject, StartDate, Type__c, EndDate, Case.CaseNumber, CaseId, Owner.Name, (SELECT Id, Description, TotalPrice, Note_Type__c, RecordTypeId, WorkOrderId, RecordType.Name from WorkOrderLineItems), (SELECT id,WorkOrderId,Product_Description__c FROM ProductsConsumed)  from WorkOrder where (CaseId IN: selectedCaseIds or (AssetId in: selectedAsset and AssetId in: AssetIdWithoutCase and caseid=null ) )and Status!= :Cancelled and (Status!=: NewStatus or RecordTypeId!=:RecordTypeId) ';
            system.debug('woListQuery:::::'+woListQuery);
            system.debug('lstwoRTsFilter:::::::'+lstwoRTsFilter);
            system.debug('lstwoRTsFilter:size::::::'+lstwoRTsFilter.size());
            if(lstwoRTsFilter.size()>0  ){
                system.debug('lstwoRTsFilter:::111'+lstwoRTsFilter);
                woListQuery += ' AND RecordTypeId IN '+lstwoRTsFilter+'';
            }
            woListQuery+=' order by case.createdDate desc , Completed_Date__c desc';
            //System.debug('woIdList::::'+woIdList);
            
            //woListQuery+= ';';
            woList = new List<Workorder>();
            System.debug('woListQuery:::'+woListQuery);
            woListx = Database.query(woListQuery);
             //woListx = Database.query(woListQuery);
            Map<Id,Workorder> woListDup=new Map<Id,Workorder>(woListx);
            if(woIdList.size()>0 && woListx.size()>0 ){
                for(Id soa:woIdList){
                    if(woListDup.containsKey(soa))
                        woList.add(woListDup.get(soa));
                    }
            }else{
                
                woList = woListx;
                
            }
            
        }
        
        System.debug('woList..size():'+woList.size());
        System.debug('woList:'+woList);
        woWrapper.clear();
        system.debug('caseMasterChkBox'+caseMasterChkBox);
        if(woList != null && woList.size() > 0){
            for(case_Wrapper cwrap : newcaseWrapper){
                
                if(cwrap.selected == true || caseMasterChkBox == true){
                    tempWOWrapper = new List<wo_Wrapper>();
                    system.debug('in if where case is selected');
                    //pcList.clear();
                    for(WorkOrder wod : woList){
                        System.debug('wod.getSObjects:::::'+wod);
                        if(cwrap.caseVal.Id == wod.CaseId && (cwrap.selected == true || caseMasterChkBox == true)){
                            
                            wolis = new List<WorkOrderLineItem>();
                            for(WorkOrderLineItem woli : wod.getSObjects('WorkOrderLineItems')){
                                System.debug('woli rt:'+woli.RecordTypeId);
                                System.debug('woliRTId:'+woliRTId);
                                if(woli.Note_Type__c != 'FE Resolution')
                                    wolis.add(woli);
                                
                                System.debug('wolis val:'+wolis);
                            }
                            pcList= new List<ProductConsumed >();   
                            for(ProductConsumed pc : wod.getSObjects('ProductsConsumed')){
                                
                                //if(pc.Product_Description__c != null)
                                pcList.add(pc);
                                
                                System.debug('pcList val:'+pcList);
                            }  
                            
                            wo_Wrapper woWrap = new wo_Wrapper(wod,wolis,pcList);  
                            woWrapper.add(woWrap); 
                            system.debug(woWrapper);
                            tempWOWrapper.add(woWrap); 
                        }
                    }
                    
                    taskList = new List<Task>();
                    if(cwrap.caseTaskList != null)
                        for(Task t : cwrap.caseTaskList){
                            if(t.Note_Type__c == 'FE Resolution' || t.Note_Type__c == 'Resolution')
                                taskList.add(t);    
                        }
                    
                    
                    //07/18/2018-added by krishna Prasad as part of US-5182
                    case_Wrapper caseWrap = new case_Wrapper(cwrap.caseVal,true,tempWOWrapper,taskList,null,null,null,null);
                    finalCaseWrapper.add(caseWrap);
                }  
            }
        }
        else{
            for(case_Wrapper cwrap : newcaseWrapper){
                if(cwrap.selected == true || caseMasterChkBox == true || selectedCaseIds.contains(cwrap.caseVal.id)){
                    taskList = new List<Task>();
                    if(cwrap.caseTaskList != null){
                        for(Task t : cwrap.caseTaskList){
                            if(t.Note_Type__c == 'FE Resolution' || t.Note_Type__c == 'Resolution')
                                taskList.add(t);    
                        }
                    }
                    //07/18/2018-added by krishna Prasad as part of US-5182
                    case_Wrapper caseWrap = new case_Wrapper(cwrap.caseVal,true,null,taskList,null,null,null,null);
                    finalCaseWrapper.add(caseWrap);
                }    
            }
            
        }
        caseSize = newcaseWrapper.size();
        // if(tempWOWrapper==null)
       
        
        //System.debug('finalCaseWrappersize:'+finalCaseWrapper.size());
          List<wo_Wrapper> tempWOWrapperDup;
        if(finalCaseWrapper.size() > 0)
            for(asset_Wrapper aswr : assetWrapper){
                
                tempCaseWrapper = new List<case_Wrapper>();
                for(case_Wrapper cswr : finalCaseWrapper){
                    if(aswr.asse.Id == cswr.caseVal.AssetId ){
                        tempCaseWrapper.add(cswr);     
                    }
                }
                  tempWOWrapperDup = new List<wo_Wrapper>();
                //pcList.clear();
                for(WorkOrder wod : woList){
                    System.debug('wod.getSObjects:::::'+wod);
                    if(aswr.asse.Id == wod.AssetId && (aswr.selected == true || MasterChkBox == true)&&wod.caseId==null){
                        
                        wolis = new List<WorkOrderLineItem>();
                        for(WorkOrderLineItem woli : wod.getSObjects('WorkOrderLineItems')){
                            System.debug('woli rt:'+woli.RecordTypeId);
                            System.debug('woliRTId:'+woliRTId);
                            if(woli.Note_Type__c != 'FE Resolution')
                                wolis.add(woli);
                            
                            System.debug('wolis val:'+wolis);
                        }
                        pcList= new List<ProductConsumed >();   
                        for(ProductConsumed pc : wod.getSObjects('ProductsConsumed')){
                            
                            //if(pc.Product_Description__c != null)
                            pcList.add(pc);
                            
                            System.debug('pcList val:'+pcList);
                        }  
                        
                        wo_Wrapper woWrap = new wo_Wrapper(wod,wolis,pcList);  
                        woWrapper.add(woWrap); 
                        tempWOWrapperDup.add(woWrap); 
                    }
                }
              if(aswr.selected == true || MasterChkBox == true){
                    asset_Wrapper assetWrap = new asset_Wrapper(aswr.asse,true,tempCaseWrapper,tempWOWrapperDup);
                    finalAssetWrapper.add(assetWrap);
                }
                
            }
       
      
        totalWorkOrderSearch=woWrapper.size();
        fromAsset=true;
        for(integer i=PaginationWorkOrder;i<PaginationWorkOrder+5;i++)
        {
            if(i>=0&&i<totalWorkOrderSearch)
                woWrapperDup.add(woWrapper[i]);
        }
        System.debug('finalAssetWrapper size:'+finalAssetWrapper.size());
        system.debug(finalAssetWrapper);
        if(totalWorkOrderSearch> 0)
            woWrapperSize = true;
        else
            woWrapperSize = false;
        
        System.debug('woWrapperSize:'+woWrapperSize);
        
        System.debug('WoWrapperList:'+woWrapper);
        System.debug('selected case:'+selectedCaseList);
        fromPDF=false;
        return null;
    }
    public Boolean getprevWorkOrder()
    {
        if(PaginationWorkOrder == 0)
            return true;
        else
            return false;
    }
    public Boolean getnxtWorkOrder()
    {
        if((PaginationWorkOrder + 5) >= totalWorkOrderSearch)
            return true;
        else
            return false;
        
    }
    public void previousWorkOrder()
    {
        //fromCase=true;
        //woWrapperDup.clear();
        fromAsset=false;
        system.debug(PaginationWorkOrder);
        if(PaginationWorkOrder != 0)
        {
            PaginationWorkOrder -= 5;
        }else{
            PaginationWorkOrder = 0; 
        }
        system.debug(PaginationWorkOrder);
        // setCaseSelected();
        woWrapperDup.clear();
        
        setCaseSelected();  
    }
    public void NextWorkOrder()
    {
        // fromCase=true;
        //woWrapperDup.clear();
        fromAsset=false;
        if(PaginationWorkOrder < totalWorkOrderSearch){
            PaginationWorkOrder += 5;
        }else{
            PaginationWorkOrder = totalWorkOrderSearch;
        } 
        system.debug(PaginationWorkOrder);
        system.debug(totalWorkOrderSearch);
        woWrapperDup.clear();
        setCaseSelected();
        system.debug(PaginationWorkOrder);
        system.debug(totalWorkOrderSearch);
        
        
        //setCaseSelected();
    }
    
    //Case Filter Method
    public PageReference filterCaseRecs(){
        if(fromButton==false)
        {
            SelectedCaseIds.clear();
            caseMasterChkBox=false;
            Pagination=0;
            woWrapperDup.clear();
            woWrapperSize=false;
        }
        List<Id> caseList = new List<Id>();
        List<Id> assetList = new List<Id>();
        List<case> finalCaseList = new List<Case>();
        List<case_Wrapper> newCaseWrap = new List<case_Wrapper>();
        String caseRTs = '';
        string wrRTs = '';
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
        
        if(wrselectedRTs.size() > 0){
            System.debug('Yo yo:');
            Integer totalcount = wrselectedRTs.size();
            Integer count = 0;
            System.debug('totalcount:'+totalcount);
            for(SelectOption so : wrselectedRTs){
                
                System.debug('count:'+count);
                if(count == 0){
                    wrRTs += '\''+so.getValue()+'\'';
                    System.debug('wrRTs2:'+wrRTs);
                }
                else {
                    wrRTs += ','+'\''+so.getValue()+'\''; 
                    System.debug('wrRTs:'+wrRTs);       
                }
                count++;
            }
        }
        
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
        
        System.debug('assetList:'+assetList);
        
        
        String caseQuery;
        
        if(caseList.size() > 0){
            
            caseQuery = 'SELECT Id, CaseNumber, Case_Summary__c,Case_Summary__r.TS_Resolution__c,Subject, CreatedDate, AssetId, Asset.Name, Asset.SerialNumber, ClosedDate, RecordType.Id, RecordType.Name, Priority,PO_Number__c,PO_Cap__c  from Case where AssetId IN :assetList';
            
            if(servStartDate != null){
                //servStartDT = DateTime.newInstance(servStartDate.year(), servStartDate.month(), servStartDate.day(),00, 00, 00);
                System.debug(DateTime.newInstance(servStartDate.year(), servStartDate.month(), servStartDate.day()).format('yyyy-MM-dd')+'T00:00:00Z');
                caseQuery += ' AND CreatedDate >=' + DateTime.newInstance(servStartDate.year(), servStartDate.month(), servStartDate.day()).format('yyyy-MM-dd')+'T00:00:00Z';
            }
            if(servEndDate != null){
                //servStopDT = DateTime.newInstance(servEndDate.year(), servEndDate.month(), servEndDate.day());
                caseQuery += ' AND ClosedDate <= '+DateTime.newInstance(servEndDate.year(), servEndDate.month(), servEndDate.day()).format('yyyy-MM-dd')+'T11:59:59Z';
            }
            //07/18/2018-commented by krishna Prasad as part of US-5182
            //k
            if(caseRTs != '' && caseRTs != null )
                caseQuery += ' AND RecordTypeId IN ('+caseRTs+')';
            if(casePriority != '' && casePriority != null)
                caseQuery += ' AND Priority IN ('+casePriority+')';
        }
        
        System.debug('c:::::::'+caseQuery);      
        if(caseQuery != null)
        {
            
            finalCaseList = Database.query(caseQuery);
            totalCaseSearch=finalCaseList.size();
        }
        
        if(caseQuery != null)
        {
            caseQuery+=' limit 5 offset '+Pagination; 
            finalCaseList = Database.query(caseQuery);
            
        }
        
        System.debug('finalCaseList:::::'+finalCaseList);
        //07/18/2018-added by krishna Prasad as part of US-5182    
        if(totalCaseSearch > 0){
            caseWrapper = new List<case_Wrapper>();  
            for(Case c1 : finalCaseList){
                case_Wrapper casewrap;
                if(SelectedCaseIds.contains(c1.id))
                {
                    casewrap = new case_Wrapper(c1,true,null,null,wrRTs,caseRTs,servStartDate,servEndDate); 
                }
                else
                {
                    casewrap = new case_Wrapper(c1,false,null,null,wrRTs,caseRTs,servStartDate,servEndDate); 
                }
                
                caseWrapper.add(casewrap); 
            }    
        }
        else 
            caseWrapper = new List<case_Wrapper>();
        
        if(totalCaseSearch > 0)
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
        
        PageReference pageref = new PageReference('/apex/New_CustomerServiceReport?Id='+sObjectId);
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
    //Method to create an attachment in the Account when click on submit
    public pageReference PDFAttached()
    {
        fromPDF=true;
        setCaseSelected();
        if(isAccount==true)
        ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM,'PDF has been successfully generated.Please check the Account Attachments for PDF.Thank you!'));
        if(isAsset==true)
        ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM,'PDF has been successfully generated.Please check the Asset Attachments for PDF.Thank you!'));
        if(isCase==true)
        ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM,'PDF has been successfully generated.Please check the Case Attachments for PDF.Thank you!'));
        
        if(finalAssetWrapper == null)
            finalAssetWrapper = new List<asset_Wrapper>();
        if(finalCaseWrapper == null)
            finalCaseWrapper = new List<case_Wrapper>();
        
        //finalAssetWrapper = new List<asset_Wrapper>();
        //finalCaseWrapper = new List<case_Wrapper>();
        finalWOWrapper = new List<wo_Wrapper>();
        if(isCase != null && isCase == true){
            finalAssetWrapper =  assetWrapper;
            finalCaseWrapper = newcaseWrapper;
            finalWOWrapper = woWrapper;
        }
        //use the relative url of your page
        String pdf;
        //Added new hologic logo in pdf as part of US-0006558 on 01/28/2019 by Kasmoor Reddy 
        pdf='<html><body style="font-family: arial; font-size: 9pt;"><center ><div align="center"><img src="https://hologic--c.na34.content.force.com/servlet/servlet.ImageServer?id=01561000002RxFV&oid=00D61000000YX6X&lastMod=1469646160000" align="middle" alt="Logo" width="95" height="95"/><br> <b><h2> Customer Service Request Report </h2></b></div></center> <br> <br>';
        pdf+='<table cellpadding="6" width="100%"  >';
        //iterate over list and output columns/data into table rows...
        for(Account acc : accountList){
            
            pdf += '<tr><td><b> Customer Name: </b> ' + acc.Parent.Name + '</td></tr>';
            pdf += '<tr><td><b> Party Name </b> ' + acc.Name + '</td></tr>';
            pdf += '<tr><td><b> Address: </b> ' + accountAddress + '</td></tr>';
        }
        
        //close table...
        pdf += '</table>';
        // pdf+='<br/> <br/> <br/> <br/> <br/> <br/> <br/> <br/> <br/> <br/>';
         Map<Date,List<Id>> objects = new Map<Date,List<Id>>();
        Map<Id,Map<Id,case_Wrapper>> caseWrapperId=new Map<Id,Map<Id,case_Wrapper>>();
        Map<Id,Map<Id,wo_Wrapper>> woWrapperId=new Map<Id,Map<Id,Wo_Wrapper>>();
        List<Id> woWrapperWithNoCompletedDate=new List<Id>(); 
        if(finalAssetWrapper!=null)
            for(asset_Wrapper asset : finalAssetWrapper){
              if(asset.caseWrapper!=null)
               for(case_Wrapper case1: asset.caseWrapper )
                {
                    Map<Id,case_wrapper> assetwithcase=new Map<Id,case_wrapper>();
                    assetwithcase.put(asset.asse.id,case1);
                   caseWrapperId.put(case1.caseVal.Id,assetwithcase);
                    if(objects.containsKey(case1.caseVal.CreatedDate.date()))
                    {
                        List<Id> caseWrap=new List<Id>(objects.get(case1.caseVal.CreatedDate.date()));
                        caseWrap.add(case1.caseVal.Id);
                        objects.put(case1.caseVal.CreatedDate.date(),caseWrap);
                    }
                    else
                        objects.put(case1.caseVal.CreatedDate.date(),new List<Id> { case1.caseVal.Id});  
                    
                }
                
               if(asset.woWrapperWithOutCase!=null)
                for(WO_Wrapper wo1:asset.woWrapperWithOutCase)
                {
                    Map<Id,wo_wrapper> assetwithwo=new Map<Id,wo_wrapper>();
                    assetwithwo.put(asset.asse.id,wo1);
                    woWrapperId.put(wo1.wo.id,assetwithwo);
                    system.debug('wo1.wo.Completed_Date__c.date---'+wo1.wo.Completed_Date__c+'wo id'+wo1.wo.Id);
                    if(wo1.wo.Completed_Date__c!=null)
                    {
                    if(objects.containsKey(wo1.wo.Completed_Date__c.date()))
                    {
                        List<Id> woWrap=new List<Id>(objects.get(wo1.wo.Completed_Date__c.date()));
                        woWrap.add(wo1.wo.id);
                        objects.put(wo1.wo.Completed_Date__c.date(),woWrap);
                    }
                    else
                    {
                         objects.put(wo1.wo.Completed_Date__c.date(),new List<Id> { wo1.wo.Id}); 
                    }
                    }
                    else
                    {
                        woWrapperWithNoCompletedDate.add(wo1.wo.Id);
                    }
                         
                }
                
            }
        List<Date> dates=new List<Date>();
        dates.addAll(objects.keySet());
        dates.sort();
        
        Map<Date,List<Id>> SortedList =new Map<Date,List<Id>>();
       for(Integer i=Dates.size()-1;i>=0;i--)
        {
            SortedList.put(dates[i],objects.get(dates[i]));
        }
        system.debug(SortedList);
        //iterate over list and output columns/data into table rows...
        Integer i=0;
        if(finalAssetWrapper!=null)
            for(asset_Wrapper asset : finalAssetWrapper){
                pdf+='<style="page-break-after:always" /> '; 
                pdf+=' <table style="width:100%;border: 1px solid black;" border="1">';
                
                pdf += '<tr><td><b> Serial #: </b> ' + asset.asse.SerialNumber + '<br>';
                pdf += '<b> Site: </b> ' + asset.asse.Account.Name + '<br>';
                pdf += '<b> Product: </b> ' + asset.asse.Product2.Name + '<br>';
                pdf += '<b> Description: </b> ' + asset.asse.Description + '</td></tr><br>';
                if(asset.caseWrapper!=null || asset.woWrapperWithOutCase!=null)
                {
                    for(List<Id> ids:SortedList.values())
                {
                    for(Id casewoId:ids)
                    {
                        if(caseWrapperId.containsKey(casewoId))
                        {
                            Map<Id,case_Wrapper> CaseIdWrap=new Map<Id,case_Wrapper>(caseWrapperId.get(casewoId));
                            case_Wrapper case1=CaseIdWrap.get(asset.asse.Id);
                            system.debug('in case');
                            if(case1!=null)
                            {
                            pdf += '<tr><td><b> Case #:  </b> ' + case1.caseVal.CaseNumber + '<br>';
                            pdf += '<b> Date/Time Opened: </b> ' + case1.caseVal.CreatedDate + '<br>';
                            pdf += '<b> Type: </b> ' + case1.caseVal.RecordType.Name + '<br>';
                            if(case1.caseVal.PO_Number__c!=null)
                                pdf += '<b> PO Number: </b> ' + case1.caseVal.PO_Number__c + '<br>';
                            if(case1.caseVal.PO_Cap__c!=null)
                                pdf += '<b> PO Cap: </b> ' + case1.caseVal.PO_Cap__c + '<br>';
                            if(case1.caseVal.Case_Summary__c!=null)
                                if(case1.caseVal.Case_Summary__r.TS_Resolution__c!=null)
                                pdf += '<b> TS Resolution: </b> ' + case1.caseVal.Case_Summary__r.TS_Resolution__c + '<br>';
                            pdf += '<b> Subject: </b> ' + case1.caseVal.Subject + '</td></tr>';
                            
                            if(case1.woWrapper!=null)
                                for( wo_Wrapper wo1:case1.woWrapper)
                            {
                                pdf+='<tr><td><table border="1" style="border-collapse: collapse" >';
                                pdf += '<tr><td><b> Work Order #: </b> ' + wo1.wo.WorkOrderNumber + '<br>';  
                                if(wo1.wo.Completed_Date__c!=null)
                                    pdf += '<b> Completed Date:</b> ' + wo1.wo.Completed_Date__c + '<br>';
                                pdf += '<b> Type:</b> ' + wo1.wo.Type__c + '<br>';
                                // pdf += '<tr><td><b> Field Engineer:</b> ' + wo1.wo.Owner.Name + '</td></tr>';
                                pdf += '<b>Description:</b> ' + wo1.wo.Description + '<br>';
                                if(wo1.wo.FE_Resolution__c !=null)
                                    pdf += '<b> FE Resolution:</b> ' + wo1.wo.FE_Resolution__c + '</td></tr>';
                                if(wo1.woliList!=null)
                                { integer j=0;
                                 for(WorkOrderLineItem woli:wo1.woliList)
                                 {
                                     if(j==0)
                                         pdf+='<b> Work Order Details  </b>';
                                     if(woli.RecordType.Name == 'B&SH Add a Part')
                                         pdf += '<tr><td><b> Parts Used:</b> ' +woli.Description + '</td></tr>';
                                     if(woli.RecordType.Name != 'B&SH Add a Part')
                                         pdf += '<tr><td> ' + woli.Description + '</td></tr>';
                                     if(includePricing!=null && woli.TotalPrice != null)
                                         if(includePricing)
                                         pdf += '<tr><td><b> Total Price:</b> ' +woli.TotalPrice + '</td></tr>';
                                     j++;
                                 }
                                }
                                if(wo1.pcList!=null)
                                {
                                    Integer z=0;
                                    for(ProductConsumed pcli:wo1.pcList)
                                    {
                                        if(z==0)
                                            pdf+='<b><h1> Products Consumed Details </h1> </b>';
                                        pdf += '<tr><td><b> Parts Used:</b> ' +pcli.Product_Description__c + '</td></tr>';
                                        z++; 
                                    }
                                }
                                
                                pdf+='</table> </td></tr> '; 
                            }
                            }
                        }
                        if(woWrapperId.containsKey(casewoId))
                        {
                             Map<Id,WO_Wrapper> WoIdWrap=new Map<Id,WO_Wrapper>(woWrapperId.get(casewoId));
                            
                            WO_Wrapper wo1=WoIdWrap.get(asset.asse.Id);
                            system.debug('in work orders');
                            pdf+='<tr><td><table border="1" style="border-collapse: collapse" >';
                            pdf += '<tr><td><b> Work Order #: </b> ' + wo1.wo.WorkOrderNumber + '<br>';  
                            if(wo1.wo.Completed_Date__c!=null)
                                pdf += '<b> Completed Date:</b> ' + wo1.wo.Completed_Date__c + '<br>';
                            pdf += '<b> Type:</b> ' + wo1.wo.Type__c + '<br>';
                            // pdf += '<tr><td><b> Field Engineer:</b> ' + wo1.wo.Owner.Name + '</td></tr>';
                            pdf += '<b>Description:</b> ' + wo1.wo.Description + '<br>';
                            if(wo1.wo.FE_Resolution__c !=null)
                                pdf += '<b> FE Resolution:</b> ' + wo1.wo.FE_Resolution__c + '</td></tr>';
                            Integer x=0;
                            if(wo1.woliList!=null)
                                for(WorkOrderLineItem woli:wo1.woliList)
                            {
                                if(x==0)
                                    pdf+='<b> Work Order Details </b>';
                                if(woli.RecordType.Name == 'B&SH Add a Part')
                                    pdf += '<tr><td><b> Parts Used:</b> ' +woli.Description + '</td></tr>';
                                if(woli.RecordType.Name != 'B&SH Add a Part')
                                    pdf += '<tr><td> ' + woli.Description + '</td></tr>';
                                if(includePricing!=null && woli.TotalPrice != null)
                                    if(includePricing)
                                    pdf += '<tr><td><b> Total Price:</b> ' +woli.TotalPrice + '</td></tr>';
                            }
                            if(wo1.pcList!=null)
                                for(ProductConsumed pcli:wo1.pcList)
                            {
                                if(i==0)
                                    pdf+='<b><h1> Products Consumed Details </h1> </b>';
                                pdf += '<tr><td><b> Parts Used:</b> ' +pcli.Product_Description__c + '</td></tr>';
                                
                            }
                            
                            pdf+='</table> </td></tr> '; 
                        }
                       
                        }

                    }
                   for(Id woId:woWrapperWithNoCompletedDate)
                    {
                         Map<Id,WO_Wrapper> WoIdWrap=new Map<Id,WO_Wrapper>(woWrapperId.get(woId));
                            
                            WO_Wrapper wo1=WoIdWrap.get(asset.asse.Id);
                            system.debug('in work orders');
                            pdf+='<tr><td><table border="1" style="border-collapse: collapse" >';
                            pdf += '<tr><td><b> Work Order #: </b> ' + wo1.wo.WorkOrderNumber + '<br>';  
                            if(wo1.wo.Completed_Date__c!=null)
                                pdf += '<b> Completed Date:</b> ' + wo1.wo.Completed_Date__c + '<br>';
                            pdf += '<b> Type:</b> ' + wo1.wo.Type__c + '<br>';
                            // pdf += '<tr><td><b> Field Engineer:</b> ' + wo1.wo.Owner.Name + '</td></tr>';
                            pdf += '<b>Description:</b> ' + wo1.wo.Description + '<br>';
                            if(wo1.wo.FE_Resolution__c !=null)
                                pdf += '<b> FE Resolution:</b> ' + wo1.wo.FE_Resolution__c + '</td></tr>';
                            Integer x=0;
                            if(wo1.woliList!=null)
                                for(WorkOrderLineItem woli:wo1.woliList)
                            {
                                if(x==0)
                                    pdf+='<b> Work Order Details </b>';
                                if(woli.RecordType.Name == 'B&SH Add a Part')
                                    pdf += '<tr><td><b> Parts Used:</b> ' +woli.Description + '</td></tr>';
                                if(woli.RecordType.Name != 'B&SH Add a Part')
                                    pdf += '<tr><td> ' + woli.Description + '</td></tr>';
                                if(includePricing!=null && woli.TotalPrice != null)
                                    if(includePricing)
                                    pdf += '<tr><td><b> Total Price:</b> ' +woli.TotalPrice + '</td></tr>';
                            }
                            if(wo1.pcList!=null)
                                for(ProductConsumed pcli:wo1.pcList)
                            {
                                if(i==0)
                                    pdf+='<b><h1> Products Consumed Details </h1> </b>';
                                pdf += '<tr><td><b> Parts Used:</b> ' +pcli.Product_Description__c + '</td></tr>';
                                
                            }
                            
                            pdf+='</table> </td></tr> '; 
                        
                    }
                }
               i++;
              pdf += '</table>';  
            }
        
        pdf+=' </body> </html> ';
        system.debug(pdf);
        Blob data = blob.toPDF(pdf); 
        
        //save the PDF as an attachment on the record
        
        /* Attachment a= new Attachment(
Name = 'Customer Service Report.pdf',
IsPrivate = false,
Body = data,
ParentId = sobjectId

);
insert a;
system.debug('attchment:'+a.id);*/
        
        ContentVersion conVer = new ContentVersion();
        conVer.ContentLocation = 'S'; // S specify this document is in SF, use E for external files
        conVer.PathOnClient = 'Customer Service Report.pdf'; // The files name, extension is very important here which will help the file in preview.
        conVer.Title = 'Customer Service Report '; // Display name of the files
        conVer.VersionData = data; 
        insert conVer;
        Id conDoc = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:conVer.Id].ContentDocumentId;
        
        //Create ContentDocumentLink
        ContentDocumentLink cDe = new ContentDocumentLink();
        cDe.ContentDocumentId = conDoc;
        cDe.LinkedEntityId = sobjectId; // you can use objectId,GroupId etc
        cDe.ShareType = 'I'; // Inferred permission, checkout description of ContentDocumentLink object for more details
        cDe.Visibility = 'InternalUsers';
        insert cDe;
        
        
        return null;
    }
    
    
}