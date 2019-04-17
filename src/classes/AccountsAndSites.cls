/*--------------------------------------------------------------------------------------------------------------
Author:         Kasmoor Reddy
Description:    Class which supports the VFPage 'Accountsandsites' on quote object which allows to select the Billto,
Shipto,Deliverytoaccounts and Billtosite,Shiptosite,Deliverytosite on quote object.

History:
<Date>          <Authors Name>         <Brief Description of Change>
01/02/2018      Kasmoor Reddy       Initial Creation (US3714)
05/16/2018      kasmoor Reddy       Modified as part of US-4502 (changed to display QuoteLine Ship Date as per Requested Date in Quote and Quote Line)
11/19/2018      Kasmoor Reddy       Modified as part of US-5533
----------------------------------------------------------------------------------------------------------------*/
public class AccountsAndSites {

    //Variable declarations 
    
    
    public Integer LineNumber{get;set;}
    public Id shiplineid{get;set;}
    public Id billlineid{get;set;}
    public Id deliverlineid{get;set;}
    public Id deliverToSiteId {set;get;}
    public Id deliverToSiteId1 {set;get;}
    public Id billToSiteId {set;get;}
    public Id billToSiteId1 {set;get;}
    public Id shipToSiteId {set;get;}
    public Id shipToSiteId1 {set;get;}
    //wrapper declaration
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
        //public List<SelectOption> billToSiteOptions {get; set;}
        //public List<SelectOption> shipToSiteOptions {get; set;}
        //public List<SelectOption> deliverToSiteOptions {get; set;}
        public String billToAcct {get;set;}
        public String shipToAcct {get;set;}
        public String deliverToAcct {get;set;}
        public String billToSite {get;set;}
        public String shipToSite {get;set;}
        public id billtositeId {get;set;}
        public Id deliverToSiteId1 {set;get;}
        public Id billToSiteId1 {set;get;}
        
        public Id shipToSiteId1 {set;get;}
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
    public String billToSiteline {get;set;}
    public String shipToSiteline {get;set;}
    public String deliverToSiteline {get;set;}
    public String myParentId{get;set;}
    public String myObjectType{get;set;}
    public boolean reloadNeeded{get;set;}
    private String theAccount {get; set; }
    public integer linenum {get;set;}
    
    String[] countries = new String[]{};
        public SBQQ__Quote__c myquote{get;set;}
    public SBQQ__QuoteLine__c myquoteLines{get;set;}
    public List<SelectOption> billToAcctOptions{get;set;}
    public List<SelectOption> shipToAcctOptions{get;set;}
    public List<SelectOption> deliverToAcctOptions{get;set;}
    //public List<SelectOption> billToSiteOptions {get; set;}
    //public List<SelectOption> shipToSiteOptions {get; set;}
    //public List<SelectOption> deliverToSiteOptions {get; set;}
    public Boolean invalidOperatingUnit{get;set;}
    public Boolean invalidOPartyId{get;set;}
    public Set<String> parentAccMapBill {get; set;}
    public Set<String> parentAccMapShip {get; set;}
    public Set<String> parentAccMapDeliver {get; set;}
    public Set<String> masterAccString {get; set;}
    
    public boolean message {set;get;}
    private ApexPages.StandardController standardCtrl;
    public string quotelinerelatedshiptosite {set;get;}
    public string quotelinerelatedbilltosite {set;get;}
    public string quotelinerelateddelivertosite {set;get;}
    
    public List<String> errors {get; set;}
    private Set<id> parentQLIds;
    public string callfunc{get;set;}
    public boolean show{get;set;}
    
    /*-----------------------------------------------------------------------------
Author:      Kasmoor Reddy
Company:     Apps Associates
Description: Constructor for Variable initializion and fetching the customer accounts 
and sitelocations related to site account to display on the intial load of VF Page
Returns:     N/A

History:
<Date>          <Authors Name>             <Brief Description of Change>
01/02/2018      Kasmoor Reddy       Initial Creation (US3714)
-----------------------------------------------------------------------------------*/
    public AccountsAndSites(ApexPages.StandardController ctrl){
        parentQLIds = new Set<Id>();
        lines = new List<QLWrapper>();
        errors = new List<String>();
        String oraclePartyId;
        String operatingUnit='';
        show=false;
        message = true;
        Map<String, Customer_Relationship__x> CustRelMap = new Map<String, Customer_Relationship__x>();
        
        system.debug(myObjectType);
        standardCtrl = ctrl;
        //getting the quote id from the vf page
        myParentId = ApexPages.currentPage().getParameters().get('id');
        system.debug('shipToSite---'+shipToSite);
        system.debug('shipToAcct---'+shipToAcct);
        
        
        
        Schema.DescribeSObjectResult q = SBQQ__Quote__c.sObjectType.getDescribe();
        String prefixQuote = q.getKeyPrefix();
        Schema.DescribeSObjectResult ql = SBQQ__QuoteLine__c.sObjectType.getDescribe();
        String prefixQuoteLine = ql.getKeyPrefix();
        
        System.debug('URLid:'+myParentId);
        System.debug('prefixQuote:'+prefixQuote);
        //object initialisation based on the current id
        if(myParentId != null && myParentId.substring(0,3)==prefixQuote){
            myObjectType='Quote';
        }else{
            myObjectType='QuoteLine';
        }     
        
        //if selection on quote object
        if(myObjectType=='Quote'){
            
            myquote = [SELECT id, SBQQ__Account__c, SBQQ__Account__r.Oracle_Party_Id__c, Ship_Date__c, Requested_Date__c, Bill_To_Account__c, BillTo_Site__c, Ship_To_Account__c, ShipTo_Site__c, Deliver_To_Account__c, DeliverTo_Site__c, Operating_Unit__c ,ShipTo_Site__r.Address_Line_2__c,ShipTo_Site__r.Address_Line_3__c,ShipTo_Site__r.City__c,ShipTo_Site__r.State__c,ShipTo_Site__r.Name,BillTo_Site__r.Name,BillTo_Site__r.Address_Line_2__c,BillTo_Site__r.Address_Line_3__c,BillTo_Site__r.City__c,BillTo_Site__r.State__c,DeliverTo_Site__r.Name,DeliverTo_Site__r.Address_Line_2__c,DeliverTo_Site__r.Address_Line_3__c,DeliverTo_Site__r.City__c,DeliverTo_Site__r.State__c FROM SBQQ__Quote__c WHERE id = :myParentId];
            oraclePartyId=myquote.SBQQ__Account__r.Oracle_Party_Id__c;
            operatingUnit=myquote.Operating_Unit__c;
            billToAcct = myquote.Bill_To_Account__c;
            shipToAcct = myquote.Ship_To_Account__c;
            deliverToAcct = myquote.Deliver_To_Account__c;
            String addrLine2=(myquote.BillTo_Site__r.Address_Line_2__c==NULL) ? '' :myquote.BillTo_Site__r.Address_Line_2__c;
            String addrLine3=(myquote.BillTo_Site__r.Address_Line_3__c==NULL) ? '' : myquote.BillTo_Site__r.Address_Line_3__c;
            String billToSiteValue = myquote.BillTo_Site__r.Name +'('+addrLine2 +')'+ addrLine3 + ' ' + myquote.BillTo_Site__r.City__c + ' ' + myquote.BillTo_Site__r.State__c;
            billToSite=(billToSiteValue=='null() null null')?'':billToSiteValue;
            system.debug(billToSiteValue);
            system.debug(billToSite);
            billToSiteId=myquote.BillTo_Site__c;
            String shipaddrLine2=(myquote.ShipTo_Site__r.Address_Line_2__c==NULL) ? '' :myquote.ShipTo_Site__r.Address_Line_2__c;
            String shipaddrLine3=(myquote.ShipTo_Site__r.Address_Line_3__c==NULL) ? '' : myquote.ShipTo_Site__r.Address_Line_3__c;
            String shipToSiteValue = myquote.ShipTo_Site__r.Name +'('+ shipaddrLine2 +')'+ shipaddrLine3 + ' ' + myquote.ShipTo_Site__r.City__c + ' ' + myquote.ShipTo_Site__r.State__c;
            shipToSite=(shipToSiteValue=='null() null null')?'':shipToSiteValue;
            shipToSiteId=myquote.ShipTo_Site__c;
            String devaddrLine2=(myquote.DeliverTo_Site__r.Address_Line_2__c==NULL) ? '' :myquote.DeliverTo_Site__r.Address_Line_2__c;
            String devaddrLine3=(myquote.DeliverTo_Site__r.Address_Line_3__c==NULL) ? '' : myquote.DeliverTo_Site__r.Address_Line_3__c;
            String deliverToSiteValue = myquote.DeliverTo_Site__r.Name +'('+ devaddrLine2 +')'+ devaddrLine3 + ' ' + myquote.DeliverTo_Site__r.City__c + ' ' + myquote.DeliverTo_Site__r.State__c;
            deliverToSite=(deliverToSiteValue=='null() null null')?'':deliverToSiteValue;
            
            deliverToSiteId= myquote.DeliverTo_Site__c;
            theAccount = myquote.SBQQ__Account__c;
            
            
        }else{
            
            myquoteLines = [SELECT id, SBQQ__Quote__r.SBQQ__Account__c, SBQQ__Quote__r.SBQQ__Account__r.Oracle_Party_Id__c, Requested_Date__c, Ship_Date__c,Bill_To_Account__c, BillTo_Site__c, Ship_To_Account__c, ShipTo_Site__c, Deliver_To_Account__c, DeliverTo_Site__c, SBQQ__Quote__r.Operating_Unit__c,ShipTo_Site__r.Address_Line_2__c,ShipTo_Site__r.Address_Line_3__c,ShipTo_Site__r.City__c,ShipTo_Site__r.State__c,ShipTo_Site__r.Name,BillTo_Site__r.Name,BillTo_Site__r.Address_Line_2__c,BillTo_Site__r.Address_Line_3__c,BillTo_Site__r.City__c,BillTo_Site__r.State__c,DeliverTo_Site__r.Name,DeliverTo_Site__r.Address_Line_2__c,DeliverTo_Site__r.Address_Line_3__c,DeliverTo_Site__r.City__c,DeliverTo_Site__r.State__c FROM SBQQ__QuoteLine__c WHERE id = :myParentId];
            
            oraclePartyId=myquoteLines.SBQQ__Quote__r.SBQQ__Account__r.Oracle_Party_Id__c;
            operatingUnit=myquoteLines.SBQQ__Quote__r.Operating_Unit__c;
            billToAcct = myquoteLines.Bill_To_Account__c;
            shipToAcct = myquoteLines.Ship_To_Account__c;
            deliverToAcct = myquoteLines.Deliver_To_Account__c;
            String addrLine2=(myquoteLines.BillTo_Site__r.Address_Line_2__c==NULL) ? '' :myquoteLines.BillTo_Site__r.Address_Line_2__c;
            String addrLine3=(myquoteLines.BillTo_Site__r.Address_Line_3__c==NULL) ? '' : myquoteLines.BillTo_Site__r.Address_Line_3__c;
            String billToSiteValue = myquoteLines.BillTo_Site__r.Name +'('+addrLine2 +')'+ addrLine3 + ' ' + myquoteLines.BillTo_Site__r.City__c + ' ' + myquoteLines.BillTo_Site__r.State__c;
            billToSiteline =  (billToSiteValue=='null() null null')?'':billToSiteValue;
            billToSiteId1=myquoteLines.BillTo_Site__c;
            String shipaddrLine2=(myquoteLines.ShipTo_Site__r.Address_Line_2__c==NULL) ? '' :myquoteLines.ShipTo_Site__r.Address_Line_2__c;
            String shipaddrLine3=(myquoteLines.ShipTo_Site__r.Address_Line_3__c==NULL) ? '' : myquoteLines.ShipTo_Site__r.Address_Line_3__c;
            String shipToSiteValue = myquoteLines.ShipTo_Site__r.Name +'('+ shipaddrLine2 +')'+ shipaddrLine3 + ' ' + myquoteLines.ShipTo_Site__r.City__c + ' ' + myquoteLines.ShipTo_Site__r.State__c;
            shipToSiteline=(shipToSiteValue=='null() null null')?'':shipToSiteValue;
            
            shipToSiteId1=myquoteLines.ShipTo_Site__c;
            String devaddrLine2=(myquoteLines.DeliverTo_Site__r.Address_Line_2__c==NULL) ? '' :myquoteLines.DeliverTo_Site__r.Address_Line_2__c;
            String devaddrLine3=(myquoteLines.DeliverTo_Site__r.Address_Line_3__c==NULL) ? '' : myquoteLines.DeliverTo_Site__r.Address_Line_3__c;
            String deliverToSiteValue = myquoteLines.DeliverTo_Site__r.Name +'('+ devaddrLine2 +')'+ devaddrLine3 + ' ' + myquoteLines.DeliverTo_Site__r.City__c + ' ' + myquoteLines.DeliverTo_Site__r.State__c;
            deliverToSiteline=(deliverToSiteValue=='null() null null')?'':deliverToSiteValue;
            
            deliverToSiteId1=myquoteLines.DeliverTo_Site__c;
            
            theAccount = myquoteLines.SBQQ__Quote__r.SBQQ__Account__c;
            myQuote = new SBQQ__Quote__c();
            myQuote.Ship_Date__c = myquoteLines.Ship_Date__c;
            myquote.Requested_Date__c = myquoteLines.Requested_Date__c;
        }
        
        billToAcctOptions=new List<SelectOption>();
        shipToAcctOptions=new List<SelectOption>();
        deliverToAcctOptions=new List<SelectOption>();
        
        invalidOperatingUnit=false;
        invalidOPartyId=false;
        //operatingUnit='HOLX_US_OU';
        parentAccMapBill=new Set<String>();
        parentAccMapShip=new Set<String>();
        parentAccMapDeliver=new Set<String>();
        masterAccString=new Set<String>();
        
        //adding the list of customer accounts based on the external odate
        if(operatingUnit=='' || operatingUnit==null){
            invalidOperatingUnit=true;
        }
        
     //06-05-2018-- Added by Kasmoor Reddy as part of US-4696//
        else{
      List<Account>  Acclist = new List<Account> ();
      billToAcctOptions.add(new SelectOption('', '--None--'));
            shipToAcctOptions.add(new SelectOption('', '--None--'));
            deliverToAcctOptions.add(new SelectOption('', '--None--'));
        if(oraclePartyId=='' || oraclePartyId==null){
          system.debug('in oracle party id');
          Acclist = [Select Id, Name,Oracle_Party_Id__c,Oracle_Customer_Number__c from Account where Id=:theAccount Order by Name];               
                     
          invalidOPartyId=false;


        }
            else
            {
            
            //List<Account>  Acclist = new List<Account> ();
        if(test.IsRunningTest()){
          
          for(Account acc:[Select id, Name from Account]){
            billToAcctOptions.add(new SelectOption(acc.id, acc.Name));
            shipToAcctOptions.add(new SelectOption(acc.id, acc.Name));
            deliverToAcctOptions.add(new SelectOption(acc.id, acc.Name));
          }
          
        }else{
                
                 for (Customer_Relationship__x c : [select PartyId__c, Bill_To__c,Customer_Account_ID__c,Operating_Unit__c,Relationship_ID__c,Ship_To__c,Status__c,Status_Code__c 
                                                   from Customer_Relationship__x where (PartyId__c =:oraclePartyId or Related_Oracle_Party_ID__c = :oraclePartyId) AND Status__c = 'Active' AND Operating_Unit__c = :operatingUnit]) {
                                                       CustRelMap.put(c.PartyId__c, c);
                                                   }
                                                                Acclist = [Select Id, Name,Oracle_Party_Id__c,Oracle_Customer_Number__c from Account where Oracle_Party_Id__c in :CustRelMap.keyset() or Id=:theAccount Order by Name];
                
                
                }
        
      }
               //06-05-2018-- end of code Added by Kasmoor Reddy as part of US-4696//  
                 /*if(test.IsRunningTest())
                     Acclist = [Select id, Name, Oracle_Customer_Number__c, Oracle_Party_Id__c from Account];*/ 
                for (Account a : Acclist) {
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
           index='';
            //BillToAcctChanged();
            //ShipToAcctChanged();
            //DeliverToAcctChanged();
            integer i = 0;
            List<Id> billToAccountList = new List<Id>();
            List<Id> shipToAccountList = new List<Id>();
            List<Id> deliverToAccountList = new List<Id>();
            Map<Id,List<SelectOption>> billToAccountMap = new Map<Id,List<SelectOption>>();
            Map<Id,List<SelectOption>> shipToAccountMap = new Map<Id,List<SelectOption>>();
            Map<Id,List<SelectOption>> deliverToAccountMap = new Map<Id,List<SelectOption>>();
            //if selected object is quote
            if(myObjectType=='Quote'){
                //Modified Query on 11/19/2018 by Kasmoor Reddy as part of US-5533
               // system.debug('in if of Quote in 317');
                for(SBQQ__QuoteLine__c qline : [select Id, Name, SBQQ__ProductName__c, SBQQ__Product__r.CPQ_Bundle__c,SBQQ__Description__c, SBQQ__Number__c,Ship_Date__c,Requested_Date__c,
                                                Bill_To_Account__c, BillTo_Site__c, Ship_To_Account__c, ShipTo_Site__c, Deliver_To_Account__c, 
                                                DeliverTo_Site__c,SBQQ__Bundle__c,ShipTo_Site__r.Address_Line_2__c,
                                                ShipTo_Site__r.Address_Line_3__c,ShipTo_Site__r.City__c,ShipTo_Site__r.State__c,ShipTo_Site__r.Name,BillTo_Site__r.Name,BillTo_Site__r.Address_Line_2__c,BillTo_Site__r.Address_Line_3__c,BillTo_Site__r.City__c,BillTo_Site__r.State__c,DeliverTo_Site__r.Name,DeliverTo_Site__r.Address_Line_2__c,DeliverTo_Site__r.Address_Line_3__c,
                                                DeliverTo_Site__r.City__c,DeliverTo_Site__r.State__c   FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c=:myquote.Id and (SBQQ__Product__r.CPQ_Bundle__c=true or (SBQQ__RequiredBy__c=null and SBQQ__Product__r.CPQ_Bundle__c=false)) order by  SBQQ__Product__r.description]) {
                                                    if(qline.Ship_Date__c==null)
                                                    {
                                                        qline.Ship_Date__c=qline.Requested_Date__c;
                                                    }
                                                    
                                                    if(qline.SBQQ__Product__r.CPQ_Bundle__c || (qline.SBQQ__Bundle__c && !qline.SBQQ__Product__r.CPQ_Bundle__c))
                                                        parentQLIds.add(qline.id);                                
                                                    QLWrapper qlw = new QLWrapper();
                                                    qlw.lineNumber = qline.SBQQ__Number__c.intValue();
                                                    linenum = qline.SBQQ__Number__c.intValue();
                                                    qlw.productDescription = qline.SBQQ__Description__c;
                                                    qlw.qlId = qline.Id;                                
                                                    qlw.count=i++;
                                                    qlw.ProductName = qline.SBQQ__ProductName__c;   
                                                    String addrLine2=(qline.BillTo_Site__r.Address_Line_2__c==NULL) ? '' :qline.BillTo_Site__r.Address_Line_2__c;
                                                    String addrLine3=(qline.BillTo_Site__r.Address_Line_3__c==NULL) ? '' : qline.BillTo_Site__r.Address_Line_3__c;
                                                    String billToSiteValue = qline.BillTo_Site__r.Name +'('+addrLine2 +')'+ addrLine3 + ' ' + qline.BillTo_Site__r.City__c + ' ' + qline.BillTo_Site__r.State__c;
                                                    qlw.billToSite = (billToSiteValue=='null() null null')?'':billToSiteValue;  
                                                    qlw.billToSiteId1=qline.BillTo_Site__c; 
                                                    if(qline.BillTo_Site__c!=null){
                                                        if(quotelinerelatedbilltosite==null||quotelinerelatedbilltosite=='')
                                                        {
                                                            quotelinerelatedbilltosite=qline.id+'-'+qline.BillTo_Site__c; 
                                                        }
                                                        else
                                                        {
                                                            quotelinerelatedbilltosite=quotelinerelatedbilltosite+','+qline.id+'-'+qline.BillTo_Site__c; 
                                                        }
                                                    }
                                                    qlw.billToAcct = qline.Bill_To_Account__c;
                                                    qlw.shipToAcct = qline.Ship_To_Account__c;
                                                    String shipaddrLine2=(qline.ShipTo_Site__r.Address_Line_2__c==NULL) ? '' :qline.ShipTo_Site__r.Address_Line_2__c;
                                                    String shipaddrLine3=(qline.ShipTo_Site__r.Address_Line_3__c==NULL) ? '' : qline.ShipTo_Site__r.Address_Line_3__c;
                                                    String shipToSiteValue = qline.ShipTo_Site__r.Name +'('+ shipaddrLine2 +')'+ shipaddrLine3 + ' ' + qline.ShipTo_Site__r.City__c + ' ' + qline.ShipTo_Site__r.State__c;
                                                    qlw.shipToSite=(shipToSiteValue=='null() null null')?'':shipToSiteValue;                              
                                                    qlw.shipToSiteId1 = qline.ShipTo_Site__c;
                                                    if(qline.ShipTo_Site__c!=null){
                                                        if(quotelinerelatedshiptosite==null||quotelinerelatedshiptosite=='')
                                                        {
                                                            quotelinerelatedshiptosite=qline.id+'-'+qline.ShipTo_Site__c; 
                                                        }
                                                        else
                                                        {
                                                            quotelinerelatedshiptosite=quotelinerelatedshiptosite+','+qline.id+'-'+qline.ShipTo_Site__c; 
                                                        }
                                                    }
                                                    String devaddrLine2=(qline.DeliverTo_Site__r.Address_Line_2__c==NULL) ? '' :qline.DeliverTo_Site__r.Address_Line_2__c;
                                                    String devaddrLine3=(qline.DeliverTo_Site__r.Address_Line_3__c==NULL) ? '' : qline.DeliverTo_Site__r.Address_Line_3__c;
                                                    String deliverToSiteValue = qline.DeliverTo_Site__r.Name +'('+ devaddrLine2 +')'+ devaddrLine3 + ' ' + qline.DeliverTo_Site__r.City__c + ' ' + qline.DeliverTo_Site__r.State__c;
                                                    qlw.deliverToSite=(deliverToSiteValue=='null() null null')?'':deliverToSiteValue;                             
                                                    qlw.deliverToAcct = qline.Deliver_To_Account__c;
                                                    qlw.deliverToSiteId1 = qline.DeliverTo_Site__c;
                                                    if(qline.DeliverTo_Site__c!=null)
                                                    {
                                                        if(quotelinerelateddelivertosite==null||quotelinerelateddelivertosite=='')
                                                        {
                                                            quotelinerelateddelivertosite=qline.id+'-'+qline.DeliverTo_Site__c; 
                                                        }
                                                        else
                                                        {
                                                            quotelinerelateddelivertosite=quotelinerelateddelivertosite+','+qline.id+'-'+qline.DeliverTo_Site__c; 
                                                        }
                                                    }
                                                    
                                                    
                                                    qlw.theLine = qline;
                                                    lines.add(qlw);  
                                                    
                                                    billToAccountList.add(qline.Bill_to_Account__c);
                                                    shipToAccountList.add(qline.Ship_to_Account__c);
                                                    deliverToAccountList.add(qline.Deliver_to_Account__c);
                                                    
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
    //boolean variable for cancel button
    public boolean showCancel {
        get {
            return myObjectType=='Quote';
        }
    }
    
    /*-----------------------------------------------------------------------------
Author:      Kasmoor Reddy
Company:     Apps Associates
Description: After click on cancel button it will redirect to main vf page.
Returns:     N/A

History:
<Date>          <Authors Name>             <Brief Description of Change>
01/02/2018      Kasmoor Reddy       Initial Creation (US3714)
-----------------------------------------------------------------------------------*/
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
    
    /*-----------------------------------------------------------------------------
Author:      Kasmoor Reddy
Company:     Apps Associates
Description: getting the url details from the vf page into the class.
Returns:     N/A

History:
<Date>          <Authors Name>             <Brief Description of Change>
01/02/2018      Kasmoor Reddy       Initial Creation (US3714)
-----------------------------------------------------------------------------------*/
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
    
    /*-----------------------------------------------------------------------------
Author:      Kasmoor Reddy
Company:     Apps Associates
Description: In this method we are updating the quote and quotelines with selected billto,shipto,deliverto
accounts and billto,shipto,deliverto sites.
Returns:     N/A

History:
<Date>          <Authors Name>             <Brief Description of Change>
01/02/2018      Kasmoor Reddy       Initial Creation (US3714)
05/16/2018      Kasmoor Reddy       Modified as part of US-4502 ( changed to display QuoteLine Ship Date as per Requested Date in Quote and Quote Line)
-----------------------------------------------------------------------------------*/
    
    public PageReference SaveMe() {
        //Modified as part of US-4502 (changed to display QuoteLine Ship Date as per Requested Date in Quote and Quote Line)
        system.debug('in save');
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
            system.debug(myObjectType);
            Map<id,id> quoteline_shittosite=new Map<id,id>();
            system.debug(quotelinerelatedshiptosite);
            if(quotelinerelatedshiptosite!=null&&quotelinerelatedshiptosite!='')
            {
                List<string> getqlids=quotelinerelatedshiptosite.split(',');
                for(string s:getqlids)
                {
                    
                    List<id> ids=s.split('-');
                    quoteline_shittosite.put(ids[0],ids[1]);
                }
            }
            Map<id,id> quoteline_billtosite=new Map<id,id>();
            if(quotelinerelatedbilltosite!=null&&quotelinerelatedbilltosite!='')
            {
                List<string> getqlids=quotelinerelatedbilltosite.split(',');
                for(string s:getqlids)
                {
                    List<id> ids=s.split('-');
                    quoteline_billtosite.put(ids[0],ids[1]);
                }
            }
            Map<id,id> quoteline_delivertosite=new Map<id,id>();
            if(quotelinerelateddelivertosite!=null&&quotelinerelateddelivertosite!='')
            {
                List<string> getqlids=quotelinerelateddelivertosite.split(',');
                for(string s:getqlids)
                {
                    List<id> ids=s.split('-');
                    quoteline_delivertosite.put(ids[0],ids[1]);
                }
            }
            List<SBQQ__QuoteLine__c> updatedlines = new List<SBQQ__QuoteLine__c>();
            
            system.debug('bill to account---'+billToAcct);
            system.debug('ship to account---'+shipToAcct);
            system.debug('deliver to account---'+deliverToAcct);
            system.debug('bill to site id---'+billtoSiteid);
            system.debug('ship to siteid---'+shipToSiteid);
            system.debug('deliver to site id---'+deliverToSiteid);
            system.debug('bill to site id1---'+billtoSiteid1);
            //system.debug('ship to siteid1---'+shipToSiteid1);
            //system.debug('deliver to site id1---'+deliverToSiteid1);
            
            
            if(myObjectType=='Quote'){
                myquote.Bill_To_Account__c = (billToAcct == '') ? NULL : billToAcct;
                myquote.Ship_To_Account__c = (shipToAcct == '') ? NULL : shipToAcct;
                myquote.Deliver_To_Account__c = (deliverToAcct == '') ? NULL : deliverToAcct;
                
                myquote.BillTo_Site__c = (billToSite == '') ? NULL : billtoSiteid;
                myquote.ShipTo_Site__c = (shipToSite == '') ? NULL : shipToSiteid;
                myquote.DeliverTo_Site__c = (deliverToSite == '') ? NULL : deliverToSiteid;
                system.debug('hi');
                system.debug('shiptositeid'+shipToSiteid);
                system.debug(myquote);
                
                Map<Id,List<SBQQ__QuoteLine__c>> qlMap = new Map<Id,List<SBQQ__QuoteLine__c>>();
                
                for(SBQQ__QuoteLine__c ql : [select Id,SBQQ__RequiredBy__c,Bill_to_Account__c,BillTo_Site__c,Ship_To_Account__c,ShipTo_Site__c,Deliver_To_Account__c,
                                             DeliverTo_Site__c from SBQQ__QuoteLine__c where SBQQ__RequiredBy__c in :parentQLIds and SBQQ__Product__r.CPQ_Bundle__c=false]) {
                                                 if(qlMap.get(ql.SBQQ__RequiredBy__c) == null)
                                                     qlMap.put(ql.SBQQ__RequiredBy__c,new List<SBQQ__QuoteLine__c>());
                                                 qlMap.get(ql.SBQQ__RequiredBy__c).add(ql);
                                             }
                
                for(QLWrapper qlw : lines) {
                    
                    //system.debug('ship to siteid---'+shipToSiteId1);
                    SBQQ__QuoteLine__c line = new SBQQ__QuoteLine__c();
                    line.Id = qlw.qlId;
                    line.Bill_To_Account__c = String.isBlank(qlw.billToAcct) ? null : qlw.billToAcct;
                    if( line.Bill_To_Account__c==null)
                    {
                        line.BillTo_Site__c =null; 
                    }
                    else
                    {
                        if(quoteline_billtosite!=null && !quoteline_billtosite.isEmpty())
                        {
                            system.debug('in if:'+quoteline_billtosite); 
                            if(quoteline_billtosite.containsKey(qlw.qlId))
                            {
                                line.BillTo_Site__c =quoteline_billtosite.get(qlw.qlId);
                            }
                            else
                            {
                                line.BillTo_Site__c =null;
                            }
                            
                        }
                        else
                        {
                            if( line.Bill_To_Account__c==billToAcct)
                            {
                                line.BillTo_Site__c =billtoSiteId;
                            }
                            else
                            {
                                line.BillTo_Site__c =null;
                            }
                            
                        }
                    }
                    line.Ship_To_Account__c = String.isBlank(qlw.shipToAcct) ? null : qlw.shipToAcct;
                    system.debug(quoteline_shittosite);
                    if( line.Ship_To_Account__c==null)
                    {
                        line.ShipTo_Site__c =null; 
                    }
                    else
                    {
                        if(quoteline_shittosite!=null && !quoteline_shittosite.isEmpty())
                        {
                            if(quoteline_shittosite.containsKey(qlw.qlId))
                            {
                                
                                line.ShipTo_Site__c =quoteline_shittosite.get(qlw.qlId);
                                
                            }
                            
                            
                            else
                            {
                                line.ShipTo_Site__c =null;
                            }
                            
                            
                        }
                        else
                        {
                            if( line.Ship_To_Account__c==shipToAcct)
                            {
                                line.ShipTo_Site__c =shiptoSiteId;
                            }
                            else
                            {
                                line.ShipTo_Site__c =null;
                            }
                        }
                    }
                    
                    line.Deliver_To_Account__c = String.isBlank(qlw.deliverToAcct) ? null : qlw.deliverToAcct;
                    if( line.Deliver_To_Account__c==null)
                    {
                        line.DeliverTo_Site__c =null; 
                    }
                    else
                    {
                        if(quoteline_delivertosite!=null && !quoteline_delivertosite.isEmpty())
                        {
                            if(quoteline_delivertosite.containsKey(qlw.qlId))
                            {
                                line.DeliverTo_Site__c =quoteline_delivertosite.get(qlw.qlId);
                            }
                            else
                            {
                                line.DeliverTo_Site__c =null;
                            }
                        }
                        else
                        {
                            if( line.Deliver_To_Account__c==deliverToAcct)
                            {
                                line.DeliverTo_Site__c  =deliverToSiteId;
                            }
                            else
                            {
                                line.DeliverTo_Site__c =null;
                            }
                        }
                    }
                    line.Ship_Date__c = qlw.theLine.Ship_Date__c;
                    line.Requested_Date__c = qlw.theLine.Requested_Date__c;
                    updatedlines.add(line);
                    system.debug('updatedlines----'+updatedlines);
                    if(qlMap.get(line.Id) != null) {
                        List<SBQQ__QuoteLine__c> childLines = qlMap.get(line.Id);
                        for(SBQQ__QuoteLine__c cqline : childLines) {
                            cqline.Bill_To_Account__c = String.isBlank(qlw.billToAcct) ? null : qlw.billToAcct;
                            if( cqline.Bill_To_Account__c==null)
                            {
                                cqline.BillTo_Site__c =null;
                            }
                            else
                            {
                                if(quoteline_billtosite!=null && !quoteline_billtosite.isEmpty())
                                {
                                    if(quoteline_billtosite.containsKey(qlw.qlId))
                                    {
                                        cqline.BillTo_Site__c =quoteline_billtosite.get(qlw.qlId);
                                    }
                                    else
                                    {
                                        cqline.BillTo_Site__c =null;
                                    }
                                }
                                else
                                {
                                    if( cqline.Bill_To_Account__c==billToAcct)
                                    {
                                        cqline.BillTo_Site__c =billtoSiteId;
                                    }
                                    else
                                    {
                                        cqline.BillTo_Site__c =null;
                                    }
                                    
                                }
                            }
                            
                            cqline.Ship_To_Account__c = String.isBlank(qlw.shipToAcct) ? null : qlw.shipToAcct;
                            if( cqline.Ship_To_Account__c ==null)
                            {
                                cqline.ShipTo_Site__c=null;
                            }
                            else
                            {
                                if(quoteline_shittosite!=null && !quoteline_shittosite.isEmpty())
                                {
                                    if(quoteline_shittosite.containsKey(qlw.qlId))
                                    {
                                        cqline.ShipTo_Site__c =quoteline_shittosite.get(qlw.qlId);
                                    }
                                    else
                                    {
                                        cqline.ShipTo_Site__c =null;
                                    }
                                    
                                }
                                else
                                {
                                    if( cqline.Ship_To_Account__c==shipToAcct)
                                    {
                                        cqline.ShipTo_Site__c =shiptoSiteId;
                                    }
                                    else
                                    {
                                        cqline.ShipTo_Site__c =null;
                                    }
                                    
                                }
                            }
                            
                            cqline.Deliver_To_Account__c = String.isBlank(qlw.deliverToAcct) ? null : qlw.deliverToAcct;
                            if( cqline.Deliver_To_Account__c ==null)
                            {
                                cqline.DeliverTo_Site__c =null;   
                            }
                            else
                            {
                                if(quoteline_delivertosite!=null && !quoteline_delivertosite.isEmpty())
                                {
                                    if(quoteline_delivertosite.containsKey(qlw.qlId))
                                    {
                                        cqline.DeliverTo_Site__c =quoteline_delivertosite.get(qlw.qlId);
                                    }
                                    else
                                    {
                                        cqline.DeliverTo_Site__c =null;
                                    }
                                    
                                }
                                else
                                {
                                    if( cqline.Deliver_To_Account__c==deliverToAcct)
                                    {
                                        cqline.DeliverTo_Site__c  =deliverToSiteId;
                                    }
                                    else
                                    {
                                        cqline.DeliverTo_Site__c =null;
                                    }
                                }
                            }
                            cqline.Ship_Date__c = qlw.theLine.Ship_Date__c;
                            cqline.Requested_Date__c = qlw.theLine.Requested_Date__c;
                            updatedlines.add(cqline);
                            system.debug('updatedlines----'+updatedlines);
                            if(qlMap.get(cqline.Id) != null) {
                                List<SBQQ__QuoteLine__c> cchildLines = qlMap.get(cqline.Id);
                                for(SBQQ__QuoteLine__c ccqline : cchildLines) {
                                    ccqline.Bill_To_Account__c = String.isBlank(qlw.billToAcct) ? null : qlw.billToAcct;
                                    if(ccqline.Bill_To_Account__c==null)
                                    {
                                        ccqline.BillTo_Site__c =null;
                                    }
                                    else
                                    {
                                        if(quoteline_billtosite!=null && !quoteline_billtosite.isEmpty())
                                        {
                                            if(quoteline_billtosite.containsKey(qlw.qlId))
                                            {
                                                ccqline.BillTo_Site__c =quoteline_billtosite.get(qlw.qlId);
                                            }
                                        }
                                        else
                                        {
                                            if( ccqline.Bill_To_Account__c==billToAcct)
                                            {
                                                ccqline.BillTo_Site__c =billtoSiteId;
                                            }
                                            else
                                            {
                                                ccqline.BillTo_Site__c =null;
                                            }
                                            
                                        }
                                    }
                                    ccqline.Ship_To_Account__c = String.isBlank(qlw.shipToAcct) ? null : qlw.shipToAcct;
                                    
                                    
                                    if(ccqline.Ship_To_Account__c==null)
                                    {
                                        ccqline.ShipTo_Site__c =null;
                                    }
                                    else
                                    {
                                        if(quoteline_shittosite!=null && !quoteline_shittosite.isEmpty())
                                        {
                                            if(quoteline_shittosite.containsKey(qlw.qlId))
                                            {
                                                ccqline.ShipTo_Site__c =quoteline_shittosite.get(qlw.qlId);
                                            }
                                            else
                                            {
                                                ccqline.ShipTo_Site__c =shiptoSiteId;
                                            }
                                        }
                                        else
                                        {
                                            if( ccqline.Ship_To_Account__c==shipToAcct)
                                            {
                                                ccqline.ShipTo_Site__c =shiptoSiteId;
                                            }
                                            else
                                            {
                                                ccqline.ShipTo_Site__c =null;
                                            }
                                            
                                        }
                                    }
                                    ccqline.Deliver_To_Account__c = String.isBlank(qlw.deliverToAcct) ? null : qlw.deliverToAcct;
                                    if(ccqline.Deliver_To_Account__c==null)
                                    {
                                        ccqline.DeliverTo_Site__c =null;
                                    }
                                    else
                                    {
                                        if(quoteline_delivertosite!=null && !quoteline_delivertosite.isEmpty())
                                        {
                                            if(quoteline_delivertosite.containsKey(qlw.qlId))
                                            {
                                                ccqline.DeliverTo_Site__c =quoteline_delivertosite.get(qlw.qlId);
                                            }
                                            else
                                            {
                                                ccqline.DeliverTo_Site__c =deliverToSiteId;
                                            }
                                            
                                        }
                                        else
                                        {
                                            if( ccqline.Deliver_To_Account__c==deliverToAcct)
                                            {
                                                ccqline.DeliverTo_Site__c  =deliverToSiteId;
                                            }
                                            else
                                            {
                                                ccqline.DeliverTo_Site__c =null;
                                            }
                                        }
                                    }
                                    ccqline.Ship_Date__c = qlw.theLine.Ship_Date__c;
                                    ccqline.Requested_Date__c = qlw.theLine.Requested_Date__c;
                                    updatedlines.add(ccqline);
                                    system.debug('updatedlines----'+updatedlines);
                                    
                                }
                            }
                            
                        }
                    }
                }
                try{
                    system.debug(updatedlines);
                    update updatedlines;
                    update myquote;
                    reloadNeeded=true;
                    
                    
                    
                }catch(DmlException d){
                    ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.Error,d.getMessage());
                    ApexPages.addMessage(myMsg);
                }
            }else{
                system.debug('in else');
                myquoteLines.Bill_To_Account__c = (billToAcct == '') ? NULL : billToAcct;
                myquoteLines.Ship_To_Account__c = (shipToAcct == '') ? NULL : shipToAcct;
                myquoteLines.Deliver_To_Account__c = (deliverToAcct == '') ? NULL : deliverToAcct;
                
                if(quoteline_billtosite.containsKey(myquoteLines.Id))
                {
                    myquoteLines.BillTo_Site__c=quoteline_billtosite.get(myquoteLines.Id);
                }
                if(quoteline_shittosite.containsKey(myquoteLines.Id))
                {
                    myquoteLines.ShipTo_Site__c =quoteline_shittosite.get(myquoteLines.Id);
                }  
                if(quoteline_delivertosite.containsKey(myquoteLines.Id))
                {
                    myquoteLines.DeliverTo_Site__c =quoteline_delivertosite.get(myquoteLines.Id);
                }
                
                
                myquoteLines.Ship_Date__c = myquote.Ship_Date__c;
                myquoteLines.Requested_Date__c = myquote.Requested_Date__c;
                
                updatedLines.add(myquoteLines);
                system.debug('updatedlines----'+updatedlines);
                for(SBQQ__QuoteLine__c cqline : [select Id,SBQQ__RequiredBy__c,Bill_to_Account__c,BillTo_Site__c,Ship_To_Account__c,
                                                 ShipTo_Site__c,Deliver_To_Account__c,DeliverTo_Site__c 
                                                 from SBQQ__QuoteLine__c 
                                                 where SBQQ__RequiredBy__c = :myquoteLines.Id and 
                                                 SBQQ__Product__r.CPQ_Bundle__c=false]) {
                                                     cqline.Bill_To_Account__c = myquoteLines.Bill_To_Account__c;
                                                     
                                                     cqline.BillTo_Site__c =myquoteLines.BillTo_Site__c;
                                                     
                                                     
                                                     cqline.Ship_To_Account__c = myquoteLines.Ship_To_Account__c;
                                                     
                                                     cqline.ShipTo_Site__c =myquoteLines.ShipTo_Site__c;
                                                     
                                                     
                                                     cqline.Deliver_To_Account__c = myquoteLines.Deliver_To_Account__c;
                                                     
                                                     cqline.DeliverTo_Site__c =myquoteLines.DeliverTo_Site__c;
                                                     cqline.Ship_Date__c = myquoteLines.Ship_Date__c;
                                                     cqline.Requested_Date__c = myquoteLines.Requested_Date__c;
                                                     updatedlines.add(cqline);
                                                     system.debug('updatedlines----'+updatedlines);
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
    
    /*-----------------------------------------------------------------------------
Author:      Kasmoor Reddy
Company:     Apps Associates
Description: This method will calls on vf page when the billto account changes.
Returns:     N/A

History:
<Date>          <Authors Name>             <Brief Description of Change>
01/02/2018      Kasmoor Reddy       Initial Creation (US3714)
-----------------------------------------------------------------------------------*/
    public PageReference BillToAcctChanged() {
        billToSite=null;
        billToSiteId=null;
        billToSiteId1=null;
        quotelinerelatedbilltosite='';
        if(String.isblank(index)) {
            //billToSiteOptions = RefreshBillToSiteOptions1(billToAcct);  
            for(QLWrapper qlw : lines){
                qlw.billToAcct = billToAcct;
                qlw.billToSite=null;
                //qlw.billToSiteOptions = billToSiteOptions.clone();
            }
        } 
        return null;
    }
    /*-----------------------------------------------------------------------------
Author:      Kasmoor Reddy
Company:     Apps Associates
Description: In this method we are updating the quote and quotelines with selected billto,shipto,deliverto
accounts and billto,shipto,deliverto sites.
Returns:     N/A

History:
<Date>          <Authors Name>             <Brief Description of Change>
01/02/2018      Kasmoor Reddy       Initial Creation (US3714)
----------------------------------------------------------------------------------*/    
    public PageReference BillToAcctLineChanged()
    {
        billlineid=apexpages.currentPage().getParameters().get('billlineid'); 
        Map<id,id> quoteline_billtosite=new Map<id,id>();
        if(quotelinerelatedbilltosite!=null&&quotelinerelatedbilltosite!='')
        {
            List<string> getqlids=quotelinerelatedbilltosite.split(',');
            for(string s:getqlids)
            {
                List<id> ids=s.split('-');
                quoteline_billtosite.put(ids[0],ids[1]);
            }
        }
        
        billToSiteId1=null;
        system.debug('quoteline_shittosite:'+quotelinerelatedbilltosite);
        quotelinerelatedbilltosite=null;
        for(QLWrapper qlw : lines){
            if(quoteline_billtosite.containsKey(billlineid))
            {
                quoteline_billtosite.remove(billlineid);
            }
            qlw.billToAcct = billToAcct;
            qlw.billToSite=null;
            //qlw.billToSiteOptions = billToSiteOptions.clone();
        }
        for(id qlid:quoteline_billtosite.keySet())
        {
            if(quotelinerelatedbilltosite==null||quotelinerelatedbilltosite=='')
            {
                quotelinerelatedbilltosite=qlid+'-'+quoteline_billtosite.get(qlid);
            }
            else
            {
                quotelinerelatedbilltosite=quotelinerelatedbilltosite+','+qlid+'-'+quoteline_billtosite.get(qlid);
            }
        }
        system.debug('quoteline_shittosite:'+quotelinerelatedbilltosite);
        return null;
    }
    /*-----------------------------------------------------------------------------
Author:      Kasmoor Reddy
Company:     Apps Associates
Description: In this method we are updating the quote and quotelines with selected billto,shipto,deliverto
accounts and billto,shipto,deliverto sites.
Returns:     N/A

History:
<Date>          <Authors Name>             <Brief Description of Change>
01/02/2018      Kasmoor Reddy       Initial Creation (US3714)
----------------------------------------------------------------------------------*/
    public PageReference ShipToAcctLineChanged()
    {
        shiplineid=apexpages.currentPage().getParameters().get('shiplineid'); 
        Map<id,id> quoteline_shittosite=new Map<id,id>();
        if(quotelinerelatedshiptosite!=null&&quotelinerelatedshiptosite!='')
        {
            List<string> getqlids=quotelinerelatedshiptosite.split(',');
            for(string s:getqlids)
            {
                List<id> ids=s.split('-');
                quoteline_shittosite.put(ids[0],ids[1]);
            }
        }
        system.debug('string value before:'+quotelinerelatedshiptosite);
        shipToSiteId1=null;
        quotelinerelatedshiptosite='';
        for(QLWrapper qlw : lines){
            system.debug(shiplineid);
            if(quoteline_shittosite.containsKey(shiplineid))
            {
                system.debug('in if:'+ shiplineid);
                quoteline_shittosite.remove(shiplineid);
                //quoteline_shittosite.put(shiplineid,null);
            }
            system.debug('string value after:'+quoteline_shittosite);
            qlw.shipToAcct = shipToAcct;
            qlw.shipToSite=null;
            system.debug(qlw.shipToSite);
            //qlw.billToSiteOptions = billToSiteOptions.clone();
        }
        for(id qlid:quoteline_shittosite.keySet())
        {
            if(quotelinerelatedshiptosite==''||quotelinerelatedshiptosite==null)
            {
                quotelinerelatedshiptosite=qlid+'-'+quoteline_shittosite.get(qlid);
            }
            else
            {
                quotelinerelatedshiptosite=quotelinerelatedshiptosite+','+qlid+'-'+quoteline_shittosite.get(qlid);
            }
        }
        system.debug('quoteline_shittosite:'+quotelinerelatedshiptosite);
        system.debug('string value after:'+quoteline_shittosite);
        return null;
    }
    /*-----------------------------------------------------------------------------
Author:      Kasmoor Reddy
Company:     Apps Associates
Description: In this method we are updating the quote and quotelines with selected billto,shipto,deliverto
accounts and billto,shipto,deliverto sites.
Returns:     N/A

History:
<Date>          <Authors Name>             <Brief Description of Change>
01/02/2018      Kasmoor Reddy       Initial Creation (US3714)
----------------------------------------------------------------------------------*/
    public PageReference DeliverToAcctLineChanged()
    {
        deliverlineid=apexpages.currentPage().getParameters().get('deliverlineid'); 
        Map<id,id> quoteline_delivertosite=new Map<id,id>();
        if(quotelinerelateddelivertosite!=null&&quotelinerelateddelivertosite!='')
        {
            List<string> getqlids=quotelinerelateddelivertosite.split(',');
            for(string s:getqlids)
            {
                List<id> ids=s.split('-');
                quoteline_delivertosite.put(ids[0],ids[1]);
            }
        }
        deliverToSiteId1=null;
        quotelinerelateddelivertosite=null;
        for(QLWrapper qlw : lines){
            if(quoteline_delivertosite.containsKey(deliverlineid))
            {
                quoteline_delivertosite.remove(deliverlineid);
            }
            qlw.deliverToAcct = deliverToAcct;
            qlw.deliverToSite=null;
            //qlw.billToSiteOptions = billToSiteOptions.clone();
        }
        for(id qlid:quoteline_delivertosite.keySet())
        {
            if(quotelinerelateddelivertosite==null||quotelinerelateddelivertosite=='')
            {
                quotelinerelateddelivertosite=qlid+'-'+quoteline_delivertosite.get(qlid);
            }
            else
            {
                quotelinerelateddelivertosite=quotelinerelateddelivertosite+','+qlid+'-'+quoteline_delivertosite.get(qlid);
            }
        }
        return null;
    }
    /*-----------------------------------------------------------------------------
Author:      Kasmoor Reddy
Company:     Apps Associates
Description: This method will calls on vf page when the shipto account changes.
Returns:     N/A

History:
<Date>          <Authors Name>             <Brief Description of Change>
01/02/2018      Kasmoor Reddy       Initial Creation (US3714)
-----------------------------------------------------------------------------------*/
    public PageReference ShipToAcctChanged() {
        shipToSite=null;
        shipToSiteId=null;
        shipToSiteId1=null;
        system.debug('string value:'+quotelinerelatedshiptosite);
        quotelinerelatedshiptosite='';
        system.debug('string value:'+quotelinerelatedshiptosite);
        if(String.isblank(index)) {
            //shipToSiteOptions = RefreshShipToSiteOptions1(shipToAcct);  
            for(QLWrapper qlw : lines){
                qlw.shipToAcct = shipToAcct;
                qlw.shipToSite=null;
                //qlw.shipToSiteOptions = shipToSiteOptions.clone();
            }
        } 
        return null;
    }
    /*-----------------------------------------------------------------------------
Author:      Kasmoor Reddy
Company:     Apps Associates
Description: This method will calls on vf page when the deliverto account changes.
Returns:     N/A

History:
<Date>          <Authors Name>             <Brief Description of Change>
01/02/2018      Kasmoor Reddy       Initial Creation (US3714)
-----------------------------------------------------------------------------------*/
    public PageReference DeliverToAcctChanged() {
        deliverToSite=null;
        deliverToSiteId=null;
        deliverToSiteId1=null;
        quotelinerelateddelivertosite='';
        if(String.isblank(index)) {
            //deliverToSiteOptions = RefreshDeliverToSiteOptions1(deliverToAcct);        
            for(QLWrapper qlw : lines){
                qlw.deliverToAcct = deliverToAcct;
                qlw.deliverToSite=null;
                //qlw.deliverToSiteOptions = deliverToSiteOptions.clone();
            }
        } 
        return null;
    }    
    
    /*-----------------------------------------------------------------------------
Author:      Kasmoor Reddy
Company:     Apps Associates
Description: This method will calls on vf page when the shipto date changes.
Returns:     N/A

History:
<Date>          <Authors Name>             <Brief Description of Change>
01/02/2018      Kasmoor Reddy       Initial Creation (US3714)
-----------------------------------------------------------------------------------*/ 
    
    public PageReference ShipDateChanged() {
        if(String.isblank(index)) {
            for(QLWrapper qlw : lines){
                qlw.theLine.Ship_Date__c = myquote.Ship_Date__c;
            }
        }
        return null;
    }
    /*-----------------------------------------------------------------------------
Author:      Kasmoor Reddy
Company:     Apps Associates
Description: This method will calls on vf page when the requested date changes.
Returns:     N/A

History:
<Date>          <Authors Name>             <Brief Description of Change>
01/02/2018      Kasmoor Reddy       Initial Creation (US3714)
-----------------------------------------------------------------------------------*/
    public PageReference RequestedDateChanged() {
        if(String.isblank(index)) {
            for(QLWrapper qlw : lines){
                qlw.theLine.Requested_Date__c = myquote.Requested_Date__c;
                qlw.theLine.Ship_Date__c=myquote.Requested_Date__c;
            }
        }
        return null;
    }
    /*-----------------------------------------------------------------------------
Author:      Kasmoor Reddy
Company:     Apps Associates
Description: In this method we are updating the quote and quotelines with selected billto,shipto,deliverto
accounts and billto,shipto,deliverto sites.
Returns:     N/A

History:
<Date>          <Authors Name>             <Brief Description of Change>
01/02/2018      Kasmoor Reddy       Initial Creation (US3714)
05/16/2018      Kasmoor Reddy       Modified as part of US-4502 ( changed to display QuoteLine Ship Date as per Requested Date in Quote and Quote Line)
-----------------------------------------------------------------------------------*/
    
    public PageReference RequestedLineDateChanged () {
        
        // qlw.theLine.Requested_Date__c = myquote.Requested_Date__c;
        lines[lineNum].theLine.Ship_Date__c=lines[lineNum].theLine.Requested_Date__c ;
        
        
        return null;
    }
    
    /*@TestVisible private static List<Customer_Relationship__x> mockCustomerRelationships = new List<Customer_Relationship__x>();
public static Customer_Relationship__x findById(Id custrelid) {
if(Test.isRunningTest()) {
return (mockCustomerRelationships.size() > 0) ? mockCustomerRelationships[0] : null;

}
return null;

}*/  
    
    
    
}