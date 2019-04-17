/****************************************************************************************
Author : Niraj
Company : Hexaware Technologies
Description : Service Report Controller
Test Class : ServiceReportController_Test    

History:
<Date>         <Author Name>      <Brief Description of Change>     <Copa.do US#>
8/22/2018      Niraj            Initial Creation                     US-0005791
11/02/2018      Nomita Walke    Added method fetchConfigData()        US-0006062
11/13/2018      Niraj Wani    Updated sharing issue                US-0006075
1/11/2019    Yogitha Malireddy  Updated GetSADetailsData()to get asset serial number  US-0006454
                  
****************************************************************************************/
public with sharing class ServiceReportController {
    //Wrapper Container Class To Return Selection Records & JSON
    public class MasterResult{
        @AuraEnabled public Master mas {get; set;}
        @AuraEnabled public String masterJSON {get; set;}
        public MasterResult () {
            mas = new Master();
            masterJSON = '';
        }
    }
    //Wrapper Container Class To Return Selection Records
    public class Master{
        @AuraEnabled public List<asset_Wrapper> assetWrapper{get; set;}
        @AuraEnabled public Integer size{get; set;}
        @AuraEnabled public String sObjectRT{get; set;}
        @AuraEnabled public List<Account> accountList{get; set;}
        @AuraEnabled public String accountAddress {get; set;}
        //Constructor
        public Master(){
            assetWrapper = new List<asset_Wrapper>();
            size =0; 
            sObjectRT=''; 
            accountList =  new List<Account>();
            accountAddress = '';
        }
    }
    
    //Wrapper Container Class To Return Selection Records
    public class CaseStepResult{
        @AuraEnabled public String serviceStartDate; 
        @AuraEnabled public String serviceEndDate;
        @AuraEnabled public List<case_Wrapper> caseWrapper;
        //Constructor
        public CaseStepResult(){
            caseWrapper = new List<case_Wrapper>();
            serviceStartDate = null;
            serviceEndDate = null;
        }
    }
    
    
    //Wrapper Container Class To Return Selection Records
    public class AccountStepResult{
        @AuraEnabled public List<account_Wrapper> accountWrapper;
        //Constructor
        public AccountStepResult(){
            accountWrapper = new List<account_Wrapper>();             
        }
    }
    
    //Get Work Order details based selection of cases          
    @AuraEnabled
    public static String GetWODetailsData(String sObjectId, String sObjectRT, String selectedCases, String strCaseStepResult, String strAssetStepResult, String selectedAssets){
        List<case_Wrapper> finalCaseWrapper = new List<case_Wrapper>();
        List<asset_Wrapper> finalAssetWrapper = new List<asset_Wrapper>();
        List<wo_Wrapper> tempWOWrapper;
        List<case_Wrapper> tempCaseWrapper;
        List<wo_Wrapper> woWrapper = new List<wo_Wrapper>();
        List<WorkOrderLineItem> wolis = new List<WorkOrderLineItem>();
        List<Task> taskList = new List<Task>(); 
        //Below hardcoded RecordTypes based on current Service Report VF Code
        Id woliRTId = GlobalUtility.getRecordTypeId('WorkOrderLineItem','B&SH Add a Note');
        List<String> lstSelectedCases = selectedCases.split(',');
        Master woStepResults = new Master();
        List<WorkOrder> woList = new List<WorkOrder>();
        Set<Id> woRTs = new Set<Id>();    
        Master assetStepResultFromUI;
        //Get Case Selection from previous step
        CaseStepResult caseStepResultFromUI = (CaseStepResult) System.JSON.deserialize(strCaseStepResult, CaseStepResult.class);
        System.debug('strAssetStepResult: ' + strAssetStepResult);
        //Get Asset Selection results 
        if(String.valueOf(sObjectId).substring(0,3) != '02i') //Account  
        {
             assetStepResultFromUI = (Master) System.JSON.deserialize(strAssetStepResult, Master.class);
        }
        else if(String.valueOf(sObjectId).substring(0,3) == '02i') //Asset
        {
            Id assetID = sObjectId;
            selectedAssets = assetID;
            System.debug('selectedAssets' + selectedAssets);
            MasterResult mRes = GetAssetData( sObjectId,  'Site', '');
            assetStepResultFromUI = mRes.mas ;
            for( asset_Wrapper asWrap:  assetStepResultFromUI.assetWrapper)
            {
                asWrap.selected = true; //Set data that asset is selected to fit into this data structure for report
            }
            
        }
        System.debug('caseStepResultFromUI: ' + caseStepResultFromUI);
        System.debug('assetStepResultFromUI: ' + assetStepResultFromUI);
        //Get WO record types 
        for(CSRWOTypes__c csrwo : CSRWOTypes__c.getAll().values())
            woRTs.add(csrwo.RecordType_Id__c);  
        System.debug('woRTs:'+woRTs);
        //Query Work Orders based selected cases
        if(selectedCases != null){
            System.debug('Get WO for cases :'+ selectedCases);
            //woList = [SELECT Id, WorkOrderNumber, FSO__Completed_Date__c, Subject, StartDate, FSO__Type__c, EndDate, Case.CaseNumber, CaseId, Owner.Name, (SELECT Id, Description, TotalPrice, Note_Type__c, RecordTypeId, WorkOrderId, RecordType.Name from WorkOrderLineItems) from WorkOrder where CaseId IN :lstSelectedCases AND RecordTypeId IN :woRTs];
            woList = [SELECT Id, WorkOrderNumber, Subject, StartDate, EndDate, Case.CaseNumber, CaseId, Owner.Name, (SELECT Id, Description, TotalPrice, Note_Type__c, RecordTypeId, WorkOrderId, RecordType.Name from WorkOrderLineItems) from WorkOrder where CaseId IN :lstSelectedCases AND RecordTypeId IN :woRTs];
        }
        System.debug('woList:'+woList);
        //Prepare Final Wrapper data for using in report
        for(case_Wrapper cwrap : caseStepResultFromUI.caseWrapper){
            if(cwrap.selected == true ){
                tempWOWrapper = new List<wo_Wrapper>();
                for(WorkOrder wod : woList){
                    if(cwrap.caseVal.Id == wod.CaseId && (cwrap.selected == true )){
                        
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
        System.debug('finalCaseWrapper: ' + finalCaseWrapper);
        for(asset_Wrapper aswr : assetStepResultFromUI.assetWrapper){
            tempCaseWrapper = new List<case_Wrapper>();
            for(case_Wrapper cswr : finalCaseWrapper){
                if(aswr.asse.Id == cswr.caseVal.AssetId){
                    tempCaseWrapper.add(cswr);     
                }
            }
            System.debug('Final Asset Wrapper Prep: aswr.asse.Id ' + aswr.asse.Id + ' selectedAssets: ' + selectedAssets);
            // if(aswr.selected == true ){
            if(selectedAssets.contains(aswr.asse.Id)){
                asset_Wrapper assetWrap = new asset_Wrapper(aswr.asse,true,tempCaseWrapper);
                finalAssetWrapper.add(assetWrap);
            }
        }
        
        System.debug('finalAssetWrapper: ' + finalAssetWrapper);
        //Send all data to Component
        woStepResults.assetWrapper = finalAssetWrapper;
        woStepResults.sObjectRT = sObjectRT;
        woStepResults.accountList  = assetStepResultFromUI.accountList;
        woStepResults.accountAddress = assetStepResultFromUI.accountAddress;
        //Prepare JSON data and pass on to component
        String outputJSON = JSON.serialize(woStepResults);
        System.debug('woStepResults - serialize: ' + outputJSON  );
        //return woStepResults;
        return outputJSON;
    }
    
    //Get Case details based on asset selection from earlier step
    @AuraEnabled
    public static CaseStepResult GetCaseDetailsData(String sObjectId, String sObjectRT, String selectedAssets, String serviceStartDate, String serviceEndDate){
        CaseStepResult caseStepResults = new CaseStepResult();
        String caseQuery; 
        List<case> finalCaseList = new List<Case>();
        List<case_Wrapper> caseWrapper = new List<case_Wrapper>();
        Date servStartDate; 
        Date servEndDate ;
        List<String> lstSelectedAssets = selectedAssets.split(',');
        System.debug('serviceStartDate: ' + serviceStartDate + ' serviceEndDate: ' + serviceEndDate);
        System.debug('servStartDate: ' + serviceStartDate + 'serviceEndDate: ' + serviceEndDate  );
        if(serviceStartDate != null)
            servStartDate =  Date.valueOf(serviceStartDate) ; 
        if(serviceEndDate != null)
            servEndDate = Date.valueOf(serviceEndDate);
        //Query cases based on asset selection from previous step and date range filter
        if(String.valueOf(sObjectId).substring(0,3) == '500'){
        caseQuery = 'SELECT Id, CaseNumber, Subject, Case_Summary__c,Case_Summary__r.TS_Resolution__c,CreatedDate,Community_CreatedDate__c, AssetId, Asset.Name, Asset.SerialNumber, ClosedDate, RecordType.Id, RecordType.Name, Priority,PO_Number__c,PO_Cap__c  from Case where Id =: sObjectId';
        
        }
        else{
        caseQuery = 'SELECT Id, CaseNumber, Subject,Case_Summary__c,Case_Summary__r.TS_Resolution__c, CreatedDate,Community_CreatedDate__c, AssetId, Asset.Name, Asset.SerialNumber, ClosedDate, RecordType.Id, RecordType.Name, Priority,PO_Number__c,PO_Cap__c  from Case where AssetId IN :lstSelectedAssets';
        }
        if(servStartDate != null){
            caseQuery += ' AND CreatedDate >=' + DateTime.newInstance(servStartDate.year(), servStartDate.month(), servStartDate.day()).format('yyyy-MM-dd')+'T00:00:00Z';
        }
        if(servEndDate != null){
            //servStopDT = DateTime.newInstance(servEndDate.year(), servEndDate.month(), servEndDate.day());
            caseQuery += ' AND ClosedDate <= '+DateTime.newInstance(servEndDate.year(), servEndDate.month(), servEndDate.day()).format('yyyy-MM-dd')+'T23:59:59Z';
        }
        finalCaseList = Database.query(caseQuery);
        //Prepare case wrapper 
        if(finalCaseList.size() > 0){
            caseWrapper = new List<case_Wrapper>();  
            for(Case c1 : finalCaseList){
                case_Wrapper casewrap = new case_Wrapper(c1,false,null,null); 
                caseWrapper.add(casewrap); 
            }    
        }
        
        caseStepResults.caseWrapper = caseWrapper;        
        system.debug('caseQuery: ' + caseQuery + ' lstSelectedAssets:' + lstSelectedAssets);
        //system.debug('finalCaseList: ' + finalCaseList); 
        system.debug('caseStepResults: ' + caseStepResults); 
        //Pass Case data to Component for user selection
        return caseStepResults;
    }
    
    //Get Service Appointments details based on asset selection from earlier step
    @AuraEnabled
    public static List<ServiceAppointment> GetSADetailsData(String sObjectId, String sObjectRT, String selectedAssets, String serviceStartDate, String serviceEndDate){
        String sApptQuery; 
        List<ServiceAppointment> finalSAList = new List<ServiceAppointment>();
        Date servStartDate; 
        Date servEndDate ;
        List<String> lstSelectedAssets = selectedAssets.split(',');
        system.debug('serviceStartDate: ' + serviceStartDate + ' serviceEndDate: ' + serviceEndDate);
        if(serviceStartDate != null)
            servStartDate =  Date.valueOf(serviceStartDate) ; 
        if(serviceEndDate != null)
            servEndDate = Date.valueOf(serviceEndDate);
        //Query Service Appointments based on asset selection from previous step and date range filter
        sApptQuery = 'SELECT Id, AppointmentNumber,Subject,ParentRecordType, CreatedDate, Date_Time_Dispatched__c, ParentRecordId, Case__c,Related_Work_Order__r.Asset.SerialNumber, Community_CreatedDate__c, Work_Order__c, Owner.Name, (SELECT Id From ServiceReports LIMIT 1) FROM ServiceAppointment where (Related_Work_Order__r.Asset.Id IN :lstSelectedAssets OR ParentRecordId IN :lstSelectedAssets ) ';
        //sApptQuery = 'SELECT Id, AppointmentNumber,Subject,ParentRecordType, CreatedDate, Date_Time_Dispatched__c, ParentRecordId, Case__c, Community_CreatedDate__c, Work_Order__c, Owner.Name FROM ServiceAppointment where (Related_Work_Order__r.Asset.Id IN :lstSelectedAssets OR ParentRecordId IN :lstSelectedAssets ) ';
        if(servStartDate != null){
            sApptQuery += ' AND SchedStartTime >=' + DateTime.newInstance(servStartDate.year(), servStartDate.month(), servStartDate.day()).format('yyyy-MM-dd')+'T00:00:00Z';
        }
        if(servEndDate != null){
            //servStopDT = DateTime.newInstance(servEndDate.year(), servEndDate.month(), servEndDate.day());
            sApptQuery += ' AND SchedEndTime <= '+DateTime.newInstance(servEndDate.year(), servEndDate.month(), servEndDate.day()).format('yyyy-MM-dd')+'T23:59:59Z';
        }
        system.debug('sApptQuery:' + sApptQuery);
        finalSAList = Database.query(sApptQuery);        
        //Pass SA data to Component for user to click specific SA
        return finalSAList;
    }
    
    //Get the assets for selection
    @AuraEnabled
    public static MasterResult GetAssetData(String sObjectId, String sObjectRT, String searchAssetText){
        Master mas = new Master();
        List<Account> accountList =  new List<Account>();
         List<Asset> lstAssets  = new List<Asset>();
        String accountAddress;
        //Record Type Hardcoding is based on current Service Report Visualforce controller code
        Id systemAssetRTId = GlobalUtility.getRecordTypeId('Asset','System');
        //List<asset_Wrapper> assetWrapper = new List<asset_Wrapper>();
        //When ID passed is Account 
        if(String.valueOf(sObjectId).substring(0,3) == '001'){            
            accountList = [SELECT Id, Name, Parent.Name, Parent.RecordTypeId, BillingCity, BillingCountry, BillingPostalCode, BillingState, BillingStreet, (SELECT Id, Name, SerialNumber, Product2.Name, Description, Account.Name, RecordTypeId from Assets) from Account where Id = :sObjectId];
            if(accountList.size() > 0){
                accountAddress = accountList[0].BillingStreet + ', ' + accountList[0].BillingCity + ', ' + accountList[0].BillingState + ', ' + accountList[0].BillingCountry + ' ' + accountList[0].BillingPostalCode;
                System.debug('accountaddress:' + accountAddress );
                if(sObjectRT == 'Site'){
                    if(accountList[0].getSObjects('Assets') != null)
                       // for(Asset asse : accountList[0].getSObjects('Assets')){
                       if (searchAssetText == '')
                            lstAssets = [SELECT Id, Name, SerialNumber, Product2.Name, Description, Account.ParentId, Account.BillingCity, Account.BillingCountry, Account.BillingPostalCode, Account.BillingState, Account.BillingStreet, Account.Name, Product2.Community_Visible__c, RecordTypeId, Install_Location_Label__c from Asset where AccountId = :sObjectId and RecordTypeId = :systemAssetRTId and Product2.Community_Visible__c = true];
                       else
                       {
                           String soslQuery = 'FIND :searchAssetText RETURNING Asset'
                               + '(Id, Name, SerialNumber, Product2.Name, Description, Account.ParentId, Account.BillingCity, Account.BillingCountry, Account.BillingPostalCode, Account.BillingState, Account.BillingStreet, Account.Name, Product2.Community_Visible__c, RecordTypeId, Install_Location_Label__c WHERE AccountId = :sObjectId and RecordTypeId = :systemAssetRTId and Product2.Community_Visible__c = true )';
                           list<list<SObject>> assetsSearchResults = Search.query(soslQuery);                                 
                           lstAssets = assetsSearchResults[0];
                       }
                       for(Asset asse : lstAssets){
                           if(asse.RecordTypeId == systemAssetRTId ){ // only display assets visible in community and System Record Type
                                asset_Wrapper assewrap = new asset_Wrapper(asse,false,null);  
                                mas.assetWrapper.add(assewrap);
                                System.debug('Inside Sites');
                            }
                        }
                }
                else if(sObjectRT == 'Customer'){
                    // only display assets visible in community and System Record Type
                    if (searchAssetText == '')
                            lstAssets = [SELECT Id, Name, SerialNumber, Product2.Name, Description, Account.ParentId, Account.BillingCity, Account.BillingCountry, Account.BillingPostalCode, Account.BillingState, Account.BillingStreet, Account.Name, Product2.Community_Visible__c, RecordTypeId, Install_Location_Label__c from Asset where Account.ParentId = :sObjectId and RecordTypeId = :systemAssetRTId and Product2.Community_Visible__c = true];
                    else
                    {
                           String soslQuery = 'FIND :searchAssetText RETURNING Asset'
                               + '(Id, Name, SerialNumber, Product2.Name, Description, Account.ParentId, Account.BillingCity, Account.BillingCountry, Account.BillingPostalCode, Account.BillingState, Account.BillingStreet, Account.Name, Product2.Community_Visible__c, RecordTypeId, Install_Location_Label__c where Account.ParentId = :sObjectId and RecordTypeId = :systemAssetRTId and Product2.Community_Visible__c = true )';
                           list<list<SObject>> assetsSearchResults = Search.query(soslQuery);                                 
                           lstAssets = assetsSearchResults[0];
                     }
                    for(Asset asse : lstAssets){
                        asset_Wrapper assewrap = new asset_Wrapper(asse,false,null); 
                        mas.assetWrapper.add(assewrap);
                        System.debug('Inside Customer:' + asse.Name);    
                    }
                }
                mas.size = mas.assetWrapper.size();
                mas.accountList = accountList;
                mas.accountAddress = accountAddress;
                //caseSize = caseWrapper.size();
            }
            System.debug('AssetList:'+ mas.assetWrapper);
        }
        else if(String.valueOf(sObjectId).substring(0,3) == '02i'){ //Asset
            Id AccountId;
            for(Asset asse : [SELECT Id, Name, SerialNumber, Product2.Name, Description, Account.ParentId, Account.BillingCity, Account.BillingCountry, Account.BillingPostalCode, Account.BillingState, Account.BillingStreet, Account.Name from Asset where Id = :sObjectId ]){
                        asset_Wrapper assewrap = new asset_Wrapper(asse,false,null); 
                        AccountId = asse.AccountId;
                        mas.assetWrapper.add(assewrap);
                        //System.debug('Inside Customer:' + asse.Name);    
            }
            
            
            accountList = [SELECT Id, Name, Parent.Name, Parent.RecordTypeId, BillingCity, BillingCountry, BillingPostalCode, BillingState, BillingStreet from Account where Id = :AccountId];
            if(accountList.size() > 0){
                accountAddress = accountList[0].BillingStreet + ', ' + accountList[0].BillingCity + ', ' + accountList[0].BillingState + ', ' + accountList[0].BillingCountry + ' ' + accountList[0].BillingPostalCode;
                System.debug('accountaddress - single asset:' + accountAddress );
            }
            mas.size = mas.assetWrapper.size();
            mas.accountList = accountList;
            mas.accountAddress = accountAddress;
        }
            
        //Prepare Return 
        MasterResult masResult = new MasterResult();
        masResult.mas = mas; 
        masResult.masterJSON = System.JSON.serialize(mas);
        
        return masResult;
    }
    
    //Get the assets for selection
    @AuraEnabled
    public static AccountStepResult GetAccountData(){
        AccountStepResult accountResult = new AccountStepResult();
        boolean selectFirstAccount = true;
        List<Account> accountList =  new List<Account>();
        Id profileId=userinfo.getProfileId();
        String profileName=[Select Id,Name from Profile where Id=:profileId].Name;
        
        accountList = [SELECT Id, Name, RecordType.Name, BillingCity, BillingCountry, BillingPostalCode, BillingStateCode, BillingStreet, Parent.Name from Account];
        
       
        for(Account acc : accountList){
            account_Wrapper accwrap = new account_Wrapper(acc,selectFirstAccount); 
            accountResult.accountWrapper.add(accwrap);
            selectFirstAccount = false;//set all other accounts to unselected excpet first
            //System.debug('Inside Customer:' + asse.Name);    
        }
        
        return accountResult;        
    }
    
    //Wrapper Class for Accounts
    public Class account_Wrapper{
        @AuraEnabled public Account acc{get; set;}
        @AuraEnabled public Boolean selected {get; set;}
        public account_Wrapper(Account acc, Boolean selected){
            this.selected = selected;
            this.acc = acc;
        }
    }
    
    //Wrapper Class for Assets
    public Class asset_Wrapper{
        @AuraEnabled public Asset asse{get; set;}
        @AuraEnabled public Boolean selected {get; set;}
        @AuraEnabled public List<case_Wrapper> caseWrapper {get; set;}      
        public asset_Wrapper(Asset asse, Boolean selected, List<case_Wrapper> caseWrapper){
            this.selected = selected;
            this.asse = asse;
            this.caseWrapper = caseWrapper;
        }
    }
    
    //Wrapper Class for Cases
    public Class case_Wrapper{
        @AuraEnabled public Case caseVal {get; set;}
        @AuraEnabled public Boolean selected {get; set;}
        @AuraEnabled public List<wo_Wrapper> woWrapper {get; set;}
        @AuraEnabled public List<Task> caseTaskList {get; set;}
        
        public case_Wrapper(Case c, Boolean selected, List<wo_Wrapper> woWrapper, List<Task> caseTaskList){
            caseVal = c;
            this.selected = selected;
            this.woWrapper = woWrapper;
            this.caseTaskList = caseTaskList;
        }
    }
    
    //Wrapper Class for WorkOrders
    public Class wo_Wrapper{
        
        @AuraEnabled public WorkOrder wo {get; set;}
        @AuraEnabled public List<WorkOrderLineItem> woliList {get; set;}
        
        public wo_Wrapper(WorkOrder wo, List<WorkOrderLineItem> woliList){
            this.wo = wo;
            this.woliList = woliList;
        }
    }
    
    /*
    * Method Name: fetchConfigData()
    * Input Param: No inputs required
    * Return: Service_Community_Config__c 
    * Description: fetch Global Menu from Custom Setting
    */
    @AuraEnabled
    public static Service_Community_Config__c fetchConfigData(){
       Service_Community_Config__c config = Service_Community_Config__c.getOrgDefaults();
       return config;
    }    
    
}