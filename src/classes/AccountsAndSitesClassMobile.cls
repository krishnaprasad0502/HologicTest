public class AccountsAndSitesClassMobile {
    public integer linenum {get;set;}
    public class QLWrapper {
        public Integer lineNumber {get; set;}
        public String productName {get; set;}
        public String productDescription {get; set;}
        
        public String productNameDescription {
            get {
                return productName +' - '+productDescription;
            }
        }
        public SBQQ__QuoteLine__c theLine {get; set;}
        public String qlId {get; set;}
        public List<SelectOption> billToSiteOptions {get; set;}
        public List<SelectOption> shipToSiteOptions {get; set;}
        public List<SelectOption> deliverToSiteOptions {get; set;}
        public String billToAcct {get;set;}
        public String shipToAcct {get;set;}
        public String deliverToAcct {get;set;}
        public String billToSite {get;set;}
        public String shipToSite {get;set;}
        public String deliverToSite {get;set;}
        public Integer count {get; set;}
    }   
    public List<QLWrapper> lines{get; set;}
    public String billToAcct {get;set;}
    public String shipToAcct {get;set;}
    public String deliverToAcct {get;set;}
    public String billToSite {get;set;}
    public String shipToSite {get;set;}
    public String deliverToSite {get;set;}
    public String myParentId{get;set;}
    public String myObjectType{get;set;}
    public boolean reloadNeeded{get;set;}
    private String theAccount {get; set; }
     public boolean show{get;set;}
    String[] countries = new String[]{};
        public SBQQ__Quote__c myquote{get;set;}
    public SBQQ__QuoteLine__c myquoteLines{get;set;}
    
    //public Map<ID, String> accountIDToNameMap = new Map<ID, String>();
    //public Set<ID> BillToAccounts = new Set<ID>();
    //public Set<ID> ShipToAccounts = new Set<ID>();
    //public Set<ID> DeliverToAccounts = new Set<ID>();
    //public Map<ID, Map<ID, Site_Location__c>> accountIdToBillToSitesMap = new Map<ID, Map<ID, Site_Location__c>>();
    //public Map<ID, Map<ID, Site_Location__c>> accountIdToShipToSitesMap = new Map<ID, Map<ID, Site_Location__c>>();
    //public Map<ID, Map<ID, Site_Location__c>> accountIdToDeliverSitesMap = new Map<ID, Map<ID, Site_Location__c>>();
    public List<SelectOption> billToAcctOptions{get;set;}
    public List<SelectOption> shipToAcctOptions{get;set;}
    public List<SelectOption> deliverToAcctOptions{get;set;}
    public List<SelectOption> billToSiteOptions {get; set;}
    public List<SelectOption> shipToSiteOptions {get; set;}
    public List<SelectOption> deliverToSiteOptions {get; set;}
    public Boolean invalidOperatingUnit{get;set;}
    public Boolean invalidOPartyId{get;set;}
    public Set<String> parentAccMapBill {get; set;}
    public Set<String> parentAccMapShip {get; set;}
    public Set<String> parentAccMapDeliver {get; set;}
    public Set<String> masterAccString {get; set;}
    
    public List<String> errors {get; set;}
    private Set<id> parentQLIds;
    
    public AccountsAndSitesClassMobile(ApexPages.StandardController ctrl){
    }
    public pageReference redirectToVf()
    {
        if(UserInfo.getUiTheme() != 'Theme4t')
        {
            PageReference r=new PageReference('/apex/AccountsAndSites?id='+ApexPages.currentPage().getParameters().get('id'));
            return r;
            
            
        }
        return null;
        
    }
    public AccountsAndSitesClassMobile(){
        parentQLIds = new Set<Id>();
        lines = new List<QLWrapper>();
        errors = new List<String>();
        String oraclePartyId;
        String operatingUnit='';
        show=false;
        Map<String, Customer_Relationship__x> CustRelMap = new Map<String, Customer_Relationship__x>();
        
        system.debug(myObjectType);
        myParentId = ApexPages.currentPage().getParameters().get('id');
        
        
        Schema.DescribeSObjectResult q = SBQQ__Quote__c.sObjectType.getDescribe();
        String prefixQuote = q.getKeyPrefix();
        Schema.DescribeSObjectResult ql = SBQQ__QuoteLine__c.sObjectType.getDescribe();
        String prefixQuoteLine = ql.getKeyPrefix();
        
        System.debug('URLid:'+myParentId);
        System.debug('prefixQuote:'+prefixQuote);
        if(myParentId != null && myParentId.substring(0,3)==prefixQuote){
            myObjectType='Quote';
        }else{
            myObjectType='QuoteLine';
        }     
        //ID thisQuoteId = stdController.getId();
        // this.thisQuote=(SBQQ__Quote__c)stdController.getRecord();
        if(myObjectType=='Quote'){
            
            myquote = [SELECT id, SBQQ__Account__c, SBQQ__Account__r.Oracle_Party_Id__c, Ship_Date__c, Requested_Date__c, Bill_To_Account__c, BillTo_Site__c, Ship_To_Account__c, ShipTo_Site__c, Deliver_To_Account__c, DeliverTo_Site__c, Operating_Unit__c FROM SBQQ__Quote__c WHERE id = :myParentId];
            oraclePartyId=myquote.SBQQ__Account__r.Oracle_Party_Id__c;
            operatingUnit=myquote.Operating_Unit__c;
            billToAcct = myquote.Bill_To_Account__c;
            shipToAcct = myquote.Ship_To_Account__c;
            deliverToAcct = myquote.Deliver_To_Account__c;
            billToSite = myquote.BillTo_Site__c;
            shipToSite = myquote.ShipTo_Site__c;
            deliverToSite = myquote.DeliverTo_Site__c;
            theAccount = myquote.SBQQ__Account__c;
            
            
        }else{
            
            myquoteLines = [SELECT id, SBQQ__Quote__r.SBQQ__Account__c, SBQQ__Quote__r.SBQQ__Account__r.Oracle_Party_Id__c, Requested_Date__c, Ship_Date__c,Bill_To_Account__c, BillTo_Site__c, Ship_To_Account__c, ShipTo_Site__c, Deliver_To_Account__c, DeliverTo_Site__c, SBQQ__Quote__r.Operating_Unit__c FROM SBQQ__QuoteLine__c WHERE id = :myParentId];
            oraclePartyId=myquoteLines.SBQQ__Quote__r.SBQQ__Account__r.Oracle_Party_Id__c;
            operatingUnit=myquoteLines.SBQQ__Quote__r.Operating_Unit__c;
            billToAcct = myquoteLines.Bill_To_Account__c;
            shipToAcct = myquoteLines.Ship_To_Account__c;
            deliverToAcct = myquoteLines.Deliver_To_Account__c;
            billToSite = myquoteLines.BillTo_Site__c;
            shipToSite = myquoteLines.ShipTo_Site__c;
            deliverToSite = myquoteLines.DeliverTo_Site__c;
            theAccount = myquoteLines.SBQQ__Quote__r.SBQQ__Account__c;
            myQuote = new SBQQ__Quote__c();
            myQuote.Ship_Date__c = myquoteLines.Ship_Date__c;
            myquote.Requested_Date__c = myquoteLines.Requested_Date__c;
        }
        
        //billToAcct = thisQuote.Bill_To_Account__c;
        //shipToAcct = thisQuote.Ship_To_Account__c;
        //deliverToAcct = thisQuote.Deliver_To_Account__c;
        
        
        billToAcctOptions=new List<SelectOption>();
        shipToAcctOptions=new List<SelectOption>();
        deliverToAcctOptions=new List<SelectOption>();
        billToSiteOptions=new List<SelectOption>();
        shipToSiteOptions=new List<SelectOption>();
        deliverToSiteOptions=new List<SelectOption>();
        
        //if (String.isBlank(thisQuote.Operating_Unit__c) || String.isBlank(thisQuote.SBQQ__Account__r.Oracle_Party_Id__c)) {
        //     errors.add('Could not find record in the External Table (Customer_Relationship__x)');
        //} else {    
        invalidOperatingUnit=false;
        invalidOPartyId=false;
        //operatingUnit='HOLX_US_OU';
        parentAccMapBill=new Set<String>();
        parentAccMapShip=new Set<String>();
        parentAccMapDeliver=new Set<String>();
        masterAccString=new Set<String>();
        
        
        if(operatingUnit=='' || operatingUnit==null){
            invalidOperatingUnit=true;
        }else if(oraclePartyId=='' || oraclePartyId==null){
            invalidOPartyId=true;
        }else{
            billToAcctOptions.add(new SelectOption('', '--None--'));
            shipToAcctOptions.add(new SelectOption('', '--None--'));
            deliverToAcctOptions.add(new SelectOption('', '--None--'));
            
            if(test.IsRunningTest()){
                
                for(Account acc:[Select id, Name from Account limit 1000]){
                    billToAcctOptions.add(new SelectOption(acc.id, acc.Name));
                    shipToAcctOptions.add(new SelectOption(acc.id, acc.Name));
                    deliverToAcctOptions.add(new SelectOption(acc.id, acc.Name));
                }
                
            }else{
                
                for (Customer_Relationship__x c : [select PartyId__c, Bill_To__c,Customer_Account_ID__c,Operating_Unit__c,Relationship_ID__c,Ship_To__c,Status__c,Status_Code__c 
                                                   from Customer_Relationship__x where (PartyId__c =:oraclePartyId or Related_Oracle_Party_ID__c = :oraclePartyId) AND Status__c = 'Active' AND Operating_Unit__c = :operatingUnit]) {
                                                       CustRelMap.put(c.PartyId__c, c);
                                                   }
                
                for (Account a : [Select Id, Name,Oracle_Party_Id__c,Oracle_Customer_Number__c from Account where Oracle_Party_Id__c in :CustRelMap.keyset() or Id=:theAccount Order by Name limit 1000]) {
                    //Bill To
                    //if (CustRelMap.get(a.Oracle_Party_Id__c).Bill_To__c == true) BillToIds.add(a.id);
                    String customerNumber=(a.Oracle_Customer_Number__c==NULL) ? '' : a.Oracle_Customer_Number__c;
                    
                    if (a.Id==theAccount || CustRelMap.get(a.Oracle_Party_Id__c).Bill_To__c == true){
                        billToAcctOptions.add(new SelectOption(a.id, a.Name + ' (' + customerNumber + ')'));
                        parentAccMapBill.add(a.id);
                    } // ;
                    //Ship To
                    if (a.Id==theAccount || CustRelMap.get(a.Oracle_Party_Id__c).Ship_To__c == true){
                        shipToAcctOptions.add(new SelectOption(a.id, a.Name + ' (' + customerNumber + ')'));
                        parentAccMapShip.add(a.id);
                    } //
                    //Deliver To
                    if (a.Id==theAccount || CustRelMap.get(a.Oracle_Party_Id__c).Ship_To__c == true ){
                        deliverToAcctOptions.add(new SelectOption(a.id, a.Name + ' (' + customerNumber + ')'));
                        parentAccMapDeliver.add(a.id);        
                    } //  
                }
                
                //masterAccString.addall(parentAccMapBill);
                //masterAccString.addall(parentAccMapShip);
                //masterAccString.addall(parentAccMapDeliver);
                
                //for(Account acc:[Select id, ParentID, Name from Account where ParentID IN: masterAccString and RecordType.Name='Site']){
                //    if (parentAccMapBill.contains(acc.ParentID)) billToAcctOptions.add(new SelectOption(acc.id, acc.Name));
                //    if (parentAccMapShip.contains(acc.ParentID)) shipToAcctOptions.add(new SelectOption(acc.id, acc.Name));
                //    if (parentAccMapDeliver.contains(acc.ParentID)) deliverToAcctOptions.add(new SelectOption(acc.id, acc.Name)); 
                //}
                
                /*
for (Customer_Relationship__x CustRel : [select Oracle_Party_Account__r.Id,  Bill_To__c,Customer_Account_ID__c, Oracle_Party_Account__r.Name, Customer_Reciprocal_Flag__c,Operating_Unit__c,Related_Account__c,Relationship_ID__c,Relationship_Type__c,Ship_To__c,Status__c,Status_Code__c 
from Customer_Relationship__x where Related_Party_ID__c = :oraclePartyId AND Status__c = 'Active' And Operating_Unit__c=:operatingUnit ]) {
//Bill To
if (CustRel.Bill_To__c == 'Y') billToAcctOptions.add(new SelectOption(CustRel.Oracle_Party_Account__r.id, CustRel.Oracle_Party_Account__r.Name));
//Ship To
if (CustRel.Ship_To__c == 'Y') shipToAcctOptions.add(new SelectOption(CustRel.Oracle_Party_Account__r.id, CustRel.Oracle_Party_Account__r.Name));
//Deliver To - need to verify this field
if (CustRel.Ship_To__c == 'Y') deliverToAcctOptions.add(new SelectOption(CustRel.Oracle_Party_Account__r.id, CustRel.Oracle_Party_Account__r.Name));
}
*/
                
            }
            
            //}    
            
            index='';
            BillToAcctChanged();
            ShipToAcctChanged();
            DeliverToAcctChanged();
            integer i = 0;
            List<Id> billToAccountList = new List<Id>();
            List<Id> shipToAccountList = new List<Id>();
            List<Id> deliverToAccountList = new List<Id>();
            Map<Id,List<SelectOption>> billToAccountMap = new Map<Id,List<SelectOption>>();
            Map<Id,List<SelectOption>> shipToAccountMap = new Map<Id,List<SelectOption>>();
            Map<Id,List<SelectOption>> deliverToAccountMap = new Map<Id,List<SelectOption>>();
            
            if(myObjectType=='Quote'){
                for(SBQQ__QuoteLine__c qline : [select Id, Name, SBQQ__ProductName__c, SBQQ__Product__r.CPQ_Bundle__c,SBQQ__Description__c, SBQQ__Number__c,Ship_Date__c,Requested_Date__c,
                                                Bill_To_Account__c, BillTo_Site__c, Ship_To_Account__c, ShipTo_Site__c, Deliver_To_Account__c, 
                                                DeliverTo_Site__c,SBQQ__Bundle__c  FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c=:myquote.Id and (SBQQ__Product__r.CPQ_Bundle__c=true or (SBQQ__RequiredBy__c=null and SBQQ__Product__r.CPQ_Bundle__c=false))]) {
                                                    if(qline.SBQQ__Product__r.CPQ_Bundle__c || (qline.SBQQ__Bundle__c && !qline.SBQQ__Product__r.CPQ_Bundle__c))
                                                        parentQLIds.add(qline.id);                                
                                                    QLWrapper qlw = new QLWrapper();
                                                    qlw.lineNumber = qline.SBQQ__Number__c.intValue();
                                                    qlw.productDescription = qline.SBQQ__Description__c;
                                                    qlw.qlId = qline.Id;                                
                                                    qlw.count=i++;
                                                    qlw.ProductName = qline.SBQQ__ProductName__c;                                
                                                    qlw.billToSite = qline.BillTo_Site__c;
                                                    qlw.billToAcct = qline.Bill_To_Account__c;
                                                    qlw.shipToAcct = qline.Ship_To_Account__c;
                                                    qlw.shipToSite = qline.ShipTo_Site__c;
                                                    qlw.deliverToAcct = qline.Deliver_To_Account__c;
                                                    qlw.deliverToSite = qline.DeliverTo_Site__c;
                                                    //qlw.billToSiteOptions = RefreshBillToSiteOptions(qline.Bill_to_Account__c);                               
                                                    //qlw.shipToSiteOptions = RefreshShipToSiteOptions(qline.Ship_to_Account__c);                               
                                                    //qlw.deliverToSiteOptions = RefreshDeliverToSiteOptions(qline.Deliver_to_Account__c);  
                                                    qlw.theLine = qline;
                                                    lines.add(qlw);  
                                                    
                                                    billToAccountList.add(qline.Bill_to_Account__c);
                                                    shipToAccountList.add(qline.Ship_to_Account__c);
                                                    deliverToAccountList.add(qline.Deliver_to_Account__c);
                                                    
                                                }
                
                if(billToAccountList.size() > 0){
                    billToAccountMap = RefreshBillToSiteOptions(billToAccountList);
                    List<SelectOption> billSiteOptions = new List<SelectOption>();
                    Integer qlCount = 0;
                    for(QLWrapper qlw : lines){
                        System.debug('BillTOSite:'+qlw.billToAcct);
                        System.debug('*****:'+billToAccountMap.get(billToAcct));
                        if(billToAccountMap.get(billToAcct) != null)
                            qlw.billToSiteOptions = billToAccountMap.get(billToAcct);
                        else{
                            if(qlCount == 0){
                                billSiteOptions.add(new SelectOption('', 'Select a Bill To Account first...'));
                                qlCount++;
                            }
                            qlw.billToSiteOptions = billSiteOptions;
                            
                        }
                    }
                }
                if(shipToAccountList.size() > 0){
                    shipToAccountMap = RefreshShipToSiteOptions(shipToAccountList);
                    List<SelectOption> shipToSiteOptions = new List<SelectOption>();
                    Integer qlCount = 0;
                    for(QLWrapper qlw : lines){
                        System.debug('shipToSite:'+qlw.shipToAcct);
                        System.debug('*****:'+shipToAccountMap.get(shipToAcct));
                        if(shipToAccountMap.get(shipToAcct) != null)
                            qlw.shipToSiteOptions = shipToAccountMap.get(shipToAcct);
                        else{
                            if(qlCount == 0){
                                shipToSiteOptions.add(new SelectOption('', 'Select a Ship To Account first...'));
                                qlCount++;
                            }
                            qlw.shipToSiteOptions = shipToSiteOptions;
                            
                        }
                    }
                }
                if(deliverToAccountList.size() > 0){
                    deliverToAccountMap = RefreshDeliverToSiteOptions(deliverToAccountList);
                    List<SelectOption> deliverToSiteOptions = new List<SelectOption>();
                    Integer qlCount = 0;
                    for(QLWrapper qlw : lines){
                        System.debug('deliverToSite:'+qlw.deliverToAcct);
                        System.debug('*****:'+deliverToAccountMap.get(deliverToAcct));
                        if(deliverToAccountMap.get(deliverToAcct) != null)
                            qlw.deliverToSiteOptions = deliverToAccountMap.get(deliverToAcct);
                        else{
                            if(qlCount == 0){
                                deliverToSiteOptions.add(new SelectOption('', 'Select a Deliver To Account first...'));
                                qlCount++;
                            }
                            qlw.deliverToSiteOptions = deliverToSiteOptions;
                            
                        }
                    }
                }    
                System.debug('Yo yo1:'+billToAccountMap);
                System.debug('Yo yo2:'+shipToAccountMap); 
                System.debug('Yo yo3:'+deliverToAccountMap);     
                
                for(SBQQ__QuoteLine__c qline : [select Id, Name, SBQQ__ProductName__c, SBQQ__Bundle__c,SBQQ__Product__r.CPQ_Bundle__c,SBQQ__Description__c, SBQQ__Number__c,Ship_Date__c,Requested_Date__c,
                                                Bill_To_Account__c, BillTo_Site__c, Ship_To_Account__c, ShipTo_Site__c, Deliver_To_Account__c, 
                                                DeliverTo_Site__c FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c=:myquote.Id and SBQQ__RequiredBy__c!=null and SBQQ__Product__r.CPQ_Bundle__c=false]) {
                                                    if(qline.SBQQ__Product__r.CPQ_Bundle__c || (qline.SBQQ__Bundle__c && !qline.SBQQ__Product__r.CPQ_Bundle__c))
                                                        
                                                        parentQLIds.add(qline.id);                                
                                                }
            }
        }
        
        
        
    }
    
    public boolean showCancel {
        get {
            return myObjectType=='Quote';
        }
    }
    public PageReference Cancel() {
        ApexPages.StandardController sc;
        PageReference pageRef;
        
        if(myObjectType=='Quote'){
            sc = new ApexPages.StandardController(myquote);  
            return sc.view();
        }else{
            index='';
            BillToAcctChanged();
            ShipToAcctChanged();
            DeliverToAcctChanged();
            
        }
        return null;
    }
    public String getPageURL() {
        //Allows re-Rendering of the Entire window after re-rendering the component
        ApexPages.StandardController sc;
        PageReference pageRef;
        
        if(myObjectType=='Quote'){
            sc = new ApexPages.StandardController(myquote);  
        }else{
            sc = new ApexPages.StandardController(myquoteLines);
        }
        
        pageRef= sc.view();
        system.debug('ttt'+pageRef.getUrl());
        return pageRef.getUrl();    
    }
    
    
    public PageReference SaveMe() {
        system.debug(myObjectType);
        List<SBQQ__QuoteLine__c> updatedlines = new List<SBQQ__QuoteLine__c>();
        show = false;
        for(QLWrapper qlw : lines) {
            if(qlw.theLine.Ship_Date__c>qlw.theLine.Requested_Date__c)
            {
                show =true;
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.Error,'Expected Ship Date cannot be after Requested Delivery Date');
                ApexPages.addMessage(myMsg);
                break;
                return null;
            }
            
        }
        if(!show){
        if(myObjectType=='Quote'){
            myquote.Bill_To_Account__c = (billToAcct == '') ? NULL : billToAcct;
            myquote.Ship_To_Account__c = (shipToAcct == '') ? NULL : shipToAcct;
            myquote.Deliver_To_Account__c = (deliverToAcct == '') ? NULL : deliverToAcct;
            myquote.BillTo_Site__c = (billToSite == '') ? NULL : billToSite;
            myquote.ShipTo_Site__c = (shipToSite == '') ? NULL : shipToSite;
            myquote.DeliverTo_Site__c = (deliverToSite == '') ? NULL : deliverToSite;
            
            system.debug(deliverToSite);
            system.debug(myquote);
            
            Map<Id,List<SBQQ__QuoteLine__c>> qlMap = new Map<Id,List<SBQQ__QuoteLine__c>>();
            
            for(SBQQ__QuoteLine__c ql : [select Id,SBQQ__RequiredBy__c,Bill_to_Account__c,BillTo_Site__c,Ship_To_Account__c,ShipTo_Site__c,Deliver_To_Account__c,
                                         DeliverTo_Site__c from SBQQ__QuoteLine__c where SBQQ__RequiredBy__c in :parentQLIds and SBQQ__Product__r.CPQ_Bundle__c=false]) {
                                             if(qlMap.get(ql.SBQQ__RequiredBy__c) == null)
                                                 qlMap.put(ql.SBQQ__RequiredBy__c,new List<SBQQ__QuoteLine__c>());
                                             qlMap.get(ql.SBQQ__RequiredBy__c).add(ql);
                                         }
            
            for(QLWrapper qlw : lines) {
                SBQQ__QuoteLine__c line = new SBQQ__QuoteLine__c();
                line.Id = qlw.qlId;
                line.Bill_To_Account__c = String.isBlank(qlw.billToAcct) ? null : qlw.billToAcct;
                line.BillTo_Site__c = String.isBlank(qlw.billToSite) ? null : qlw.billToSite;
                line.Ship_To_Account__c = String.isBlank(qlw.shipToAcct) ? null : qlw.shipToAcct;
                line.ShipTo_Site__c = String.isBlank(qlw.shipToSite) ? null : qlw.shipToSite;
                line.Deliver_To_Account__c = String.isBlank(qlw.deliverToAcct) ? null : qlw.deliverToAcct;
                line.DeliverTo_Site__c = String.isBlank(qlw.deliverToSite) ? null : qlw.deliverToSite;
                line.Ship_Date__c = qlw.theLine.Ship_Date__c;
                line.Requested_Date__c = qlw.theLine.Requested_Date__c;
                updatedlines.add(line);
                if(qlMap.get(line.Id) != null) {
                    List<SBQQ__QuoteLine__c> childLines = qlMap.get(line.Id);
                    for(SBQQ__QuoteLine__c cqline : childLines) {
                        cqline.Bill_To_Account__c = String.isBlank(qlw.billToAcct) ? null : qlw.billToAcct;
                        cqline.BillTo_Site__c = String.isBlank(qlw.billToSite) ? null : qlw.billToSite;
                        cqline.Ship_To_Account__c = String.isBlank(qlw.shipToAcct) ? null : qlw.shipToAcct;
                        cqline.ShipTo_Site__c = String.isBlank(qlw.shipToSite) ? null : qlw.shipToSite;
                        cqline.Deliver_To_Account__c = String.isBlank(qlw.deliverToAcct) ? null : qlw.deliverToAcct;
                        cqline.DeliverTo_Site__c = String.isBlank(qlw.deliverToSite) ? null : qlw.deliverToSite;
                        cqline.Ship_Date__c = qlw.theLine.Ship_Date__c;
                        cqline.Requested_Date__c = qlw.theLine.Requested_Date__c;
                        updatedlines.add(cqline);
                        if(qlMap.get(cqline.Id) != null) {
                            List<SBQQ__QuoteLine__c> cchildLines = qlMap.get(cqline.Id);
                            for(SBQQ__QuoteLine__c ccqline : cchildLines) {
                                ccqline.Bill_To_Account__c = String.isBlank(qlw.billToAcct) ? null : qlw.billToAcct;
                                ccqline.BillTo_Site__c = String.isBlank(qlw.billToSite) ? null : qlw.billToSite;
                                ccqline.Ship_To_Account__c = String.isBlank(qlw.shipToAcct) ? null : qlw.shipToAcct;
                                ccqline.ShipTo_Site__c = String.isBlank(qlw.shipToSite) ? null : qlw.shipToSite;
                                ccqline.Deliver_To_Account__c = String.isBlank(qlw.deliverToAcct) ? null : qlw.deliverToAcct;
                                ccqline.DeliverTo_Site__c = String.isBlank(qlw.deliverToSite) ? null : qlw.deliverToSite;
                                ccqline.Ship_Date__c = qlw.theLine.Ship_Date__c;
                                ccqline.Requested_Date__c = qlw.theLine.Requested_Date__c;
                                updatedlines.add(ccqline);
                                
                            }
                        }
                        
                    }
                }
            }
            try{
                update updatedlines;
                update myquote;
                reloadNeeded=true;
            }catch(DmlException d){
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.Error,d.getMessage());
                ApexPages.addMessage(myMsg);
            }
        }else{
            myquoteLines.Bill_To_Account__c = (billToAcct == '') ? NULL : billToAcct;
            myquoteLines.Ship_To_Account__c = (shipToAcct == '') ? NULL : shipToAcct;
            myquoteLines.Deliver_To_Account__c = (deliverToAcct == '') ? NULL : deliverToAcct;
            myquoteLines.BillTo_Site__c = (billToSite == '') ? NULL : billToSite;
            myquoteLines.ShipTo_Site__c = (shipToSite == '') ? NULL : shipToSite;
            myquoteLines.DeliverTo_Site__c = (deliverToSite == '') ? NULL : deliverToSite;
            myquoteLines.Ship_Date__c = myquote.Ship_Date__c;
            myquoteLines.Requested_Date__c = myquote.Requested_Date__c;
            updatedLines.add(myquoteLines);
            for(SBQQ__QuoteLine__c cqline : [select Id,SBQQ__RequiredBy__c,Bill_to_Account__c,BillTo_Site__c,Ship_To_Account__c,
                                             ShipTo_Site__c,Deliver_To_Account__c,DeliverTo_Site__c 
                                             from SBQQ__QuoteLine__c 
                                             where SBQQ__RequiredBy__c = :myquoteLines.Id and 
                                             SBQQ__Product__r.CPQ_Bundle__c=false]) {
                                                 cqline.Bill_To_Account__c = myquoteLines.Bill_To_Account__c;
                                                 cqline.BillTo_Site__c = myquoteLines.BillTo_Site__c ;
                                                 cqline.Ship_To_Account__c = myquoteLines.Ship_To_Account__c;
                                                 cqline.ShipTo_Site__c = myquoteLines.ShipTo_Site__c;
                                                 cqline.Deliver_To_Account__c = myquoteLines.Deliver_To_Account__c;
                                                 cqline.DeliverTo_Site__c = myquoteLines.DeliverTo_Site__c;
                                                 cqline.Ship_Date__c = myquoteLines.Ship_Date__c;
                                                 cqline.Requested_Date__c = myquoteLines.Requested_Date__c;
                                                 updatedlines.add(cqline);
                                             }
            
            system.debug(deliverToSite);
            system.debug(myquoteLines);
            
            try{
                update updatedLines;
                reloadNeeded=true;
            }catch(DmlException d){
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.Error,d.getMessage());
                ApexPages.addMessage(myMsg);
            }
        }
        
        }
        return null;//getPageUrl();
    }
    
    
    
    public string index {get; set;}
    public PageReference BillToAcctChanged() {
        if(String.isblank(index)) {
            billToSiteOptions = RefreshBillToSiteOptions1(billToAcct);  
            for(QLWrapper qlw : lines){
                qlw.billToAcct = billToAcct;
                qlw.billToSiteOptions = billToSiteOptions.clone();
            }
        } else {
            integer i = Integer.valueOf(index);
            system.debug('index: '+i);
            //lines[i].billToSiteOptions.clear();
            lines[i].billToSiteOptions = RefreshBillToSiteOptions1(lines[i].billToAcct);
        }
        return null;
    }
    public PageReference ShipToAcctChanged() {
        if(String.isblank(index)) {
            shipToSiteOptions = RefreshShipToSiteOptions1(shipToAcct);  
            for(QLWrapper qlw : lines){
                qlw.shipToAcct = shipToAcct;
                qlw.shipToSiteOptions = shipToSiteOptions.clone();
            }
        } else {
            integer i = Integer.valueOf(index);
            system.debug('index: '+i);
            //lines[i].shipToSiteOptions.clear();
            lines[i].shipToSiteOptions = RefreshShipToSiteOptions1(lines[i].shipToAcct);
        }
        return null;
    }
    public PageReference DeliverToAcctChanged() {
        if(String.isblank(index)) {
            deliverToSiteOptions = RefreshDeliverToSiteOptions1(deliverToAcct);        
            for(QLWrapper qlw : lines){
                qlw.deliverToAcct = deliverToAcct;
                qlw.deliverToSiteOptions = deliverToSiteOptions.clone();
            }
        } else {
            integer i = Integer.valueOf(index);
            //lines[i].deliverToSiteOptions.clear();
            lines[i].deliverToSiteOptions = RefreshDeliverToSiteOptions1(lines[i].deliverToAcct);
        }
        return null;
    }    
    
    public PageReference ShipToSiteChanged() {
        if(String.isblank(index)) {
            for(QLWrapper qlw : lines){
                qlw.shipToSite = shipToSite;
            }
        }
        return null;
    }
    
    public PageReference BillToSiteChanged() {
        if(String.isblank(index)) {
            for(QLWrapper qlw : lines){
                qlw.billToSite = billToSite;
            }
        }
        return null;
    }
    
    public PageReference DeliverToSiteChanged() {
        System.debug('Hello World DT');
        if(String.isblank(index)) {
            for(QLWrapper qlw : lines){
                qlw.deliverToSite = deliverToSite;
            }
        }
        return null;
    }
    
    public PageReference ShipDateChanged() {
        if(String.isblank(index)) {
            for(QLWrapper qlw : lines){
                qlw.theLine.Ship_Date__c = myquote.Ship_Date__c;
            }
        }
        return null;
    }
    
    public PageReference RequestedDateChanged() {
        if(String.isblank(index)) {
            for(QLWrapper qlw : lines){
                qlw.theLine.Requested_Date__c = myquote.Requested_Date__c;
                qlw.theLine.Ship_Date__c=myquote.Requested_Date__c;
            }
        }
        return null;
    }
    
    //Added method to  changed to display QuoteLine Ship Date as per Requested Date in Quote and Quote Line by Kasmoor Reddy
    
    
    public PageReference RequestedLineDateChanged () {
        
        // qlw.theLine.Requested_Date__c = myquote.Requested_Date__c;
        lines[lineNum].theLine.Ship_Date__c=lines[lineNum].theLine.Requested_Date__c ;
        
        
        return null;
    }      
    public Map<Id,List<SelectOption>> RefreshBillToSiteOptions(List<Id> billToAccountList) {
        
        System.debug('Hello World');
        Map<Id,Id> accMap = new Map<Id,Id>();
        Map<Id,List<SelectOption>> billToAccountMap = new Map<Id,List<SelectOption>>();
        List<SelectOption> billSiteOptions = new List<SelectOption>();
        Set<String> accIds=new Set<String>();
        List<Site_Location__c> siteLocList = new List<Site_Location__c>();
        system.debug('$$$$$$$$$$ billToAcct - ' + billToAccountList);
        
        if (billToAccountList != null) {
            System.debug('Inside Loop');
            billSiteOptions.add(new SelectOption('', '--Please Select a Site'));
            
            for(Account acc:[Select id, ParentID, Name from Account where ParentID IN :billToAccountList and RecordType.Name='Site']){
                if(parentAccMapBill.contains(acc.ParentID)){
                    accIds.add(acc.id);
                    accMap.put(acc.Id,acc.ParentId);
                }
            }
            
            if(accIds.size() > 0)
                siteLocList = [SELECT id, Name, Bill_To__c, Ship_To__c, Address_Line_2__c, Deliver_To__c, Account__c, Account__r.Name, Address_Line_3__c, City__c, State__c FROM Site_Location__c WHERE Bill_To__c = TRUE AND Active__c = TRUE AND Account__c IN :accIds Order by Name];
            
            
            System.debug('Acc Ids:'+accIds);
            for(String accId : accIds){
                for (Site_Location__c s : siteLocList) {
                    if(accId == s.Account__c){
                        //DE-22 Update Sites picklist to have more address info
                        String addrLine2=(s.Address_Line_2__c==NULL) ? '' : s.Address_Line_2__c;
                        String addrLine3=(s.Address_Line_3__c==NULL) ? '' : s.Address_Line_3__c;
                        
                        billSiteOptions.add(new SelectOption(s.Id, s.Name + ' (' + addrLine2 + ') ' + addrLine3 + ' ' + s.City__c + ' ' + s.State__c));
                        System.debug('Inside Site Location Loop');
                    }
                }
                billToAccountMap.put(accMap.get(accId),billSiteOptions);    
            }
        } 
        
        System.debug('billSiteOptions:'+billToAccountMap);
        return billToAccountMap;
    }
    
    public Map<Id,List<SelectOption>> RefreshShipToSiteOptions(List<Id> shipToAccountList) {
        
        System.debug('Hello World');
        Map<Id,Id> accMap = new Map<Id,Id>();
        Map<Id,List<SelectOption>> shipToAccountMap = new Map<Id,List<SelectOption>>();
        List<SelectOption> shipSiteOptions = new List<SelectOption>();
        Set<String> accIds=new Set<String>();
        List<Site_Location__c> siteLocList = new List<Site_Location__c>();
        
        if (shipToAccountList != null) {
            shipSiteOptions.add(new SelectOption('', '--Please Select a Site'));
            
            for(Account acc:[Select id, ParentID, Name from Account where ParentID IN :shipToAccountList and RecordType.Name='Site']){
                if(parentAccMapShip.contains(acc.ParentID)){
                    accIds.add(acc.id);
                    accMap.put(acc.Id,acc.ParentId);
                }
            }
            
            if(accIds.size() > 0)
                siteLocList = [SELECT id, Name, Bill_To__c, Ship_To__c, Address_Line_2__c, Deliver_To__c, Account__c, Account__r.Name, Address_Line_3__c, City__c, State__c FROM Site_Location__c WHERE Ship_To__c = TRUE AND Active__c = TRUE AND Account__c IN :accIds Order by Name];
            
            for(String accId : accIds){
                for (Site_Location__c s : siteLocList) {
                    if(accId == s.Account__c){
                        //DE-22 Update Sites picklist to have more address info
                        String addrLine2=(s.Address_Line_2__c==NULL) ? '' : s.Address_Line_2__c;
                        String addrLine3=(s.Address_Line_3__c==NULL) ? '' : s.Address_Line_3__c;
                        
                        shipSiteOptions.add(new SelectOption(s.Id, s.Name + ' (' + addrLine2 + ') ' + addrLine3 + ' ' + s.City__c + ' ' + s.State__c));
                        System.debug('Inside Site Location Loop');
                    }
                }
                shipToAccountMap.put(accMap.get(accId),shipSiteOptions);    
            }
        }
        
        return shipToAccountMap;
    }
    
    public Map<Id,List<SelectOption>> RefreshDeliverToSiteOptions(List<Id> deliverToAccountList) {
        
        
        System.debug('Hello World');
        Map<Id,Id> accMap = new Map<Id,Id>();
        Map<Id,List<SelectOption>> deliverToAccountMap = new Map<Id,List<SelectOption>>();
        List<SelectOption> deliverSiteOptions = new List<SelectOption>();
        Set<String> accIds=new Set<String>();
        List<Site_Location__c> siteLocList = new List<Site_Location__c>();
        
        if (deliverToAccountList != null) {
            deliverSiteOptions.add(new SelectOption('', '--Please Select a Site'));
            
            for(Account acc:[Select id, ParentID, Name from Account where ParentID IN :deliverToAccountList and RecordType.Name='Site']){
                if(parentAccMapDeliver.contains(acc.ParentID)){
                    accIds.add(acc.id);
                    system.debug('accountids:'+accIds);
                    accMap.put(acc.Id,acc.ParentId);
                }
            }
            
            if(accIds.size() > 0)
                siteLocList = [SELECT id, Name, Bill_To__c, Ship_To__c, Deliver_To__c,  Address_Line_2__c, Account__c, Account__r.Name, Address_Line_3__c, City__c, State__c FROM Site_Location__c WHERE Deliver_To__c = TRUE AND Active__c = TRUE AND Account__c IN :accIds Order by Name];    
            
            System.debug('siteLocList:'+siteLocList);
            
            for(String accId : accIds){
                System.debug('DeliverToacc Ids:'+accId);
                //DE-22 Update Sites picklist to have more address info
                for (Site_Location__c s : siteLocList) {
                    if(accId == s.Account__c){
                        String addrLine2=(s.Address_Line_2__c==NULL) ? '' : s.Address_Line_2__c;
                        String addrLine3=(s.Address_Line_3__c==NULL) ? '' : s.Address_Line_3__c;
                        
                        deliverSiteOptions.add(new SelectOption(s.Id, s.Name + ' (' + addrLine2 + ') ' + addrLine3 + ' ' + s.City__c + ' ' + s.State__c));
                        System.debug('Inside Site Location Loop');
                    }
                }
                deliverToAccountMap.put(accMap.get(accId),deliverSiteOptions);    
            }
        }
        System.debug('delivertomap:'+deliverToAccountMap);
        return deliverToAccountMap;
    }
    
    public List<SelectOption> RefreshBillToSiteOptions1(String billToAccount) {
        
        
        List<SelectOption> billSiteOptions = new List<SelectOption>();
        Set<String> accIds=new Set<String>();
        system.debug('$$$$$$$$$$ billToAcct - ' + billToAcct);
        
        if (billToAccount != null) {
            billSiteOptions.add(new SelectOption('', '--Please Select a Site'));
            
            for(Account acc:[Select id, ParentID, Name from Account where ParentID = :billToAccount and RecordType.Name='Site']){
                if (parentAccMapBill.contains(acc.ParentID)) accIds.add(acc.id);
                //if (parentAccMapShip.contains(acc.ParentID)) shipToAcctOptions.add(new SelectOption(acc.id, acc.Name));
                //if (parentAccMapDeliver.contains(acc.ParentID)) deliverToAcctOptions.add(new SelectOption(acc.id, acc.Name)); 
            }
            //DE-22 Update Sites picklist to have more address info
            for (Site_Location__c s : [SELECT id, Name, Bill_To__c, Ship_To__c, Address_Line_2__c, Deliver_To__c, Account__c, Account__r.Name, Address_Line_3__c, City__c, State__c FROM Site_Location__c WHERE Bill_To__c = TRUE AND Active__c = TRUE AND Account__c IN :accIds Order by Name]) {
                String addrLine2=(s.Address_Line_2__c==NULL) ? '' : s.Address_Line_2__c;
                String addrLine3=(s.Address_Line_3__c==NULL) ? '' : s.Address_Line_3__c;
                
                billSiteOptions.add(new SelectOption(s.Id, s.Name + ' (' + addrLine2 + ') ' + addrLine3 + ' ' + s.City__c + ' ' + s.State__c));
            }
        } else {
            billSiteOptions.add(new SelectOption('', 'Select a Bill To Account first...'));
        }
        
        return billSiteOptions;
    }
    
    public List<SelectOption> RefreshShipToSiteOptions1(String shipToAccount) {
        
        
        List<SelectOption> shipSiteOptions = new List<SelectOption>();
        Set<String> accIds=new Set<String>();
        
        if (shipToAccount != null) {
            shipSiteOptions.add(new SelectOption('', '--Please Select a Site'));
            
            for(Account acc:[Select id, ParentID, Name from Account where ParentID = :shipToAccount and RecordType.Name='Site']){
                if (parentAccMapShip.contains(acc.ParentID)) accIds.add(acc.id);
                //if (parentAccMapShip.contains(acc.ParentID)) shipToAcctOptions.add(new SelectOption(acc.id, acc.Name));
                //if (parentAccMapDeliver.contains(acc.ParentID)) deliverToAcctOptions.add(new SelectOption(acc.id, acc.Name)); 
            }
            //DE-22 Update Sites picklist to have more address info
            for (Site_Location__c s : [SELECT id, Name, Bill_To__c, Ship_To__c, Deliver_To__c,  Address_Line_2__c, Account__c, Account__r.Name, Address_Line_3__c, City__c, State__c FROM Site_Location__c WHERE Ship_To__c = TRUE AND Active__c = TRUE AND Account__c IN :accIds Order by Name]) {
                String addrLine2=(s.Address_Line_2__c==NULL) ? '' : s.Address_Line_2__c;
                String addrLine3=(s.Address_Line_3__c==NULL) ? '' : s.Address_Line_3__c;
                
                shipSiteOptions.add(new SelectOption(s.Id, s.Name + ' (' + addrLine2 + ') ' + addrLine3 + ' ' + s.City__c + ' ' + s.State__c));
            }
        } else {
            shipSiteOptions.add(new SelectOption('', 'Select a Ship To Account first...'));
        }
        
        return shipSiteOptions;
    }
    
    public List<SelectOption> RefreshDeliverToSiteOptions1(String deliverToAccount) {
        
        
        List<SelectOption> deliverSiteOptions = new List<SelectOption>();
        Set<String> accIds=new Set<String>();
        
        system.debug('Deliver: ' + deliverToAccount);
        
        if (deliverToAccount != null) {
            deliverSiteOptions.add(new SelectOption('', '--Please Select a Site'));
            for(Account acc:[Select id, ParentID, Name from Account where ParentID = :deliverToAccount and RecordType.Name='Site']){
                if (parentAccMapDeliver.contains(acc.ParentID)) accIds.add(acc.id);
                system.debug('Account name:'+acc.Name);
                //if (parentAccMapShip.contains(acc.ParentID)) shipToAcctOptions.add(new SelectOption(acc.id, acc.Name));
                //if (parentAccMapDeliver.contains(acc.ParentID)) deliverToAcctOptions.add(new SelectOption(acc.id, acc.Name)); 
            }
            //DE-22 Update Sites picklist to have more address info
            for (Site_Location__c s : [SELECT id, Name, Bill_To__c, Ship_To__c, Deliver_To__c,  Address_Line_2__c, Account__c, Account__r.Name, Address_Line_3__c, City__c, State__c FROM Site_Location__c WHERE Deliver_To__c = TRUE AND Active__c = TRUE AND Account__c IN :accIds Order by Name]) {
                String addrLine2=(s.Address_Line_2__c==NULL) ? '' : s.Address_Line_2__c;
                String addrLine3=(s.Address_Line_3__c==NULL) ? '' : s.Address_Line_3__c;
                
                deliverSiteOptions.add(new SelectOption(s.Id, s.Name + ' (' + addrLine2 + ') ' + addrLine3 + ' ' + s.City__c + ' ' + s.State__c));
            }
        } else {
            deliverSiteOptions.add(new SelectOption('', 'Select a Deliver To Account first...'));
        }
        
        return deliverSiteOptions;
    }
    
}