/*------------------------------------------------------------
Author:         Raj Sharan
Company:        AppsAssociates 
Description:    Adding the service billing schedule lines from the contract line item detail page and Service Contract Page.
Class Name:     ContractItemAndBilling          
Test Class:     ContractItemAndBilling_Test	

History:
<Date>          <Authors Name>          <Brief Description of Change>
04/03/2017       Raj Sharan             Initial Creation(US-0002746) to accommodate the functionality related to US-0002765
19/02/2018       Kasmoor Reddy			Updated with Control actions for VF Page ServiceContractAndBilling as per (US-0003871)
------------------------------------------------------------*/
public with sharing class ContractItemAndBilling 
{
    //standard controller for the record
    private ApexPages.StandardController stdcontroller;
    //to store the list of contractlineitems
     Public List<ContractLineItem> itemlist{get;set;}
    //to store value of header record
    public ContractLineItem cntrctlnitem{get; set;}
    //to store the value of record need to be remove
    public integer RemoveItemKey { get; set; }
    //to store the list of FCO Language Notification Lines
    public List<ServiceBillingWrapper> ListOfServiceBilling{get; set;}
    //to store value of header record
    public servicecontract SC {get;set;}
    //to store the list of FCO Language Notification Lines
    public List<ServicecontractBillingWrapper> ListOfServiceContractBilling{get; set;}
    public list<Service_Billing_Schedule__c> ServiceBillingList {get;set;}
    public list<Service_Billing_Schedule__c> SBSList {get;set;}
    //To display Picklist values of Period__c in Service_Billing_Schedule__c
    public List<SelectOption> getOptions(){
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('None','--None--'));
        options.add(new SelectOption('Day','Day'));
        options.add(new SelectOption('Month','Month'));
        options.add(new SelectOption('Quarter','Quarter'));
        options.add(new SelectOption('Week','Week'));
        options.add(new SelectOption('Year','Year'));
        return options;
    }
    
/*-----------------------------------------------------------------------------
    Author:      Raj Sharan
    Company:     Apps Associates
    Description: Constructor for Variable initializion and fetching the contract line item details 
                 to display on the intial load of VF Page
    Returns:     N/A
      
    History:
    <Date>          <Authors Name>             <Brief Description of Change>
    04/03/2017      Raj Sharan              Initial Creation (US2752)
	19/02/2018       Kasmoor Reddy			Updated with Control actions for VF Page ServiceContractAndBilling as per (US-0003871)

-----------------------------------------------------------------------------------*/
    public ContractItemAndBilling(ApexPages.StandardController controller) 
    {
       
        stdcontroller = controller;
        itemlist = new List<ContractLineItem>();
        system.debug('controller***'+controller);	
        string currentRecordId;
             currentRecordId  = ApexPages.CurrentPage().getparameters().get('id');
             //   String NewValue = stdcontroller.getRecord().getSObjectType().getDescribe().getName(); 

        
             if(currentRecordId.startswith('811')){
        
        //assigning record
        cntrctlnitem = (ContractLineItem )stdcontroller.getRecord();
        //when initially its null then assign it
        if(ListOfServiceBilling == null) 
        {
            //create instance of Service_Billing_Schedule__c
            ListOfServiceBilling = new List<ServiceBillingWrapper>();
            
            //getting from database and adding to wrapper list
            for(Service_Billing_Schedule__c  fcoLn: [Select Amount__c, Contract_Line_Item__c, CurrencyIsoCode, Duration__c, End_Date__c, Id, Interface_Offset__c, 
              Invoice_Offset__c, Name, Number_of_Periods__c, Oracle_Billing_Schedule_ID__c, OwnerId, Period__c, Quote_Line__c, Sequence__c, Start_Date__c  
              FROM Service_Billing_Schedule__c  where Contract_Line_Item__c = :cntrctlnitem.Id]) 
                
            ListOfServiceBilling.add(new ServiceBillingWrapper(fcoLn,ListOfServiceBilling.size()));
              
        }
        }
        else if(currentRecordId.startswith('810')){
             //assigning record
        Sc = (Servicecontract )stdcontroller.getRecord();
        itemList = [select id,assetid,Asset.name,startdate,enddate,LineItemNumber,TotalPrice,(select id from Service_Billing_Schedules__r ) from ContractLineItem Where servicecontract.ID =:sc.Id];    

        //when initially its null then assign it 
        if(ListOfServicecontractBilling == null) 
        {
            //create instance of Service_Billing_Schedule__c
            ListOfServicecontractBilling = new List<ServicecontractBillingWrapper>(); 

            system.debug('****'+sc.id);
            //Fetching values baseed on the current Page ID
            servicecontract src = [select id,BS_Number_of_Periods__c,BS_Period__c from servicecontract where id=:sc.id];
            integer sequence=1;
            set<id> crid= new set<id>();
            
            //getting from database and adding to wrapper list
            for(contractlineitem  fcoLn: [select id,assetid,Asset.name,startdate,enddate,LineItemNumber,TotalPrice,servicecontractid,(Select id,Amount__c, Contract_Line_Item__c, CurrencyIsoCode, Duration__c, End_Date__c, Interface_Offset__c, 
            Invoice_Offset__c, Name, Number_of_Periods__c, Oracle_Billing_Schedule_ID__c, OwnerId, Period__c, Quote_Line__c, Sequence__c, Start_Date__c from Service_Billing_Schedules__r )  from ContractLineItem Where servicecontract.ID =:sc.Id]){
                if(fcoLn.Service_Billing_Schedules__r.size()==0){
                    ListOfServicecontractBilling.add(new ServicecontractBillingWrapper(fcoLn,src,sequence,fcoln.TotalPrice,null,fcoLn.Service_Billing_Schedules__r.size()));
                }
                else if(fcoLn.Service_Billing_Schedules__r.size()>0){
                    for(Service_Billing_Schedule__c sbl:fcoLn.Service_Billing_Schedules__r){
                    system.debug('in else');
                    system.debug(sbl);
                        ListOfServicecontractBilling.add(new ServicecontractBillingWrapper(fcoln,src,sequence,fcoln.TotalPrice,sbl,fcoLn.Service_Billing_Schedules__r.size()));
                    }
                }
                system.debug('****'+ListOfServicecontractBilling);

            }
        }

            
        }
    }

/*-------------------------------------------------------------
    Author:      Raj Sharan
    Company:     Apps Associates
    Description:  Method to save the service billing schedule values
                     
    Inputs:      N/A 
    Returns: 
    History:
    <Date>      <Authors Name>     <Brief Description of Change>
    04/03/2017     Raj Sharan     Initial Creation(US-0002725)
--------------------------------------------------------------*/
    public pagereference saveBillingschedules()
    {
      
        //to store FCO Language Notification Lines for upsert
        List<Service_Billing_Schedule__c> listOfServiceBillingToUpdate = new List<Service_Billing_Schedule__c>();
        
        try
        {
            //getting the line items records
            for(ServiceBillingWrapper serviceBillingWrapper : ListOfServiceBilling)
                listOfServiceBillingToUpdate.add(serviceBillingWrapper.fcoLang);
            
            //upserting lines
            upsert listOfServiceBillingToUpdate;
            
            itemList = [select id, Total_Billing_Schedule__c, (Select Id, Amount__c from Service_Billing_Schedules__r) from ContractLineItem Where ID =:cntrctlnitem.Id];    
            system.debug('itemList========='+itemList);
            for(ContractLineItem conlineitem : itemList){
                
                conlineitem.Total_Billing_Schedule__c = 0;
                for(Service_Billing_Schedule__c servicebill : conlineitem.Service_Billing_Schedules__r) {
                    conlineitem.Total_Billing_Schedule__c += servicebill.Amount__c;
                }
            }
            update itemList;
         }
        catch(Exception e)
        {
            ApexPages.addMessages(e);
        }
       
        /*PageReference pageRef = new PageReference(ApexPages.currentPage().getUrl());
        pageRef.setRedirect(true);
        return pageRef;*/
        PageReference pageRef = new Pagereference('/apex/ContractItemAndBilling?Id='+cntrctlnitem.Id);
        pageRef.setRedirect(true);
        return pageRef;
        
   
    }

/*-------------------------------------------------------------
    Author:      Raj Sharan
    Company:     Apps Associates
    Description:  Method to remove the record which is accidently added.
                     
    Inputs:      N/A 
    Returns: 
    History:
    <Date>      <Authors Name>     <Brief Description of Change>
    04/03/2017     Raj Sharan     Initial Creation(US-0002725)
--------------------------------------------------------------*/    
    public pagereference Removebilling() {
         system.debug('RemoveItemKey====='+RemoveItemKey);
          //Iterating the orderitems
            for(Integer i = 0; i < ListOfServiceBilling.size(); i++) {
               
                //if the key matches then the orderitem is removed from the list
                if(ListOfServiceBilling.get(i).key == RemoveItemKey) {
                    ListOfServiceBilling.remove(i);
                }
            }
        
        saveBillingschedules();
        return NULL;
        
    }

/*-------------------------------------------------------------
    Author:      Raj Sharan
    Company:     Apps Associates
    Description:  Method to redirect to current contract line item page from vf page.
                     
    Inputs:      N/A 
    Returns: 
    History:
    <Date>      <Authors Name>     <Brief Description of Change>
    04/03/2017     Raj Sharan     Initial Creation(US-0002725)
--------------------------------------------------------------*/    
    public PageReference backTocontractlineitem() {
        
        PageReference pageRef = new PageReference('/' + cntrctlnitem.id);
        pageRef.setRedirect(TRUE);
        return pageRef;     
    }
    
    /*-----------------------------------------------------------------------------
    Author:      Kasmoor Reddy
    Company:     Apps Associates
    Description: Method to allows to redirect the current visual force page. 
    Returns:     N/A
      
    History:
    <Date>         <Authors Name>      <Brief Description of Change>
    02/19/2018     Kasmoor Reddy        Initial Creation (US3871)
-----------------------------------------------------------------------------------*/ 
    public PageReference backToServiceContract() { 
        //Redirection to the Service Contract Detail Page
        PageReference pageRef = new PageReference('/' + sc.id);
        pageRef.setRedirect(TRUE);
        return pageRef;     
    }


 
/*-------------------------------------------------------------
    Author:      Raj Sharan
    Company:     Apps Associates
    Description:  Method to add the service billing schedules on vf page.
                     
    Inputs:      N/A 
    Returns: 
    History:
    <Date>      <Authors Name>     <Brief Description of Change>
    04/03/2017     Raj Sharan     Initial Creation(US-0002725)
--------------------------------------------------------------*/     
    public void addLine()
    {  
        ListOfServiceBilling.add(new ServiceBillingWrapper(new Service_Billing_Schedule__c(Contract_Line_Item__c = cntrctlnitem.Id),ListOfServiceBilling.size()));
    }
    
/*-------------------------------------------------------------
    Author:      Raj Sharan
    Company:     Apps Associates
    Description:  wrapper class for to get the service billing schedule records.
                     
    Inputs:      N/A 
    Returns: 
    History:
    <Date>      <Authors Name>     <Brief Description of Change>
    04/03/2017     Raj Sharan     Initial Creation(US-0002725)
--------------------------------------------------------------*/    
    public class ServiceBillingWrapper
    {
        public Service_Billing_Schedule__c fcoLang {get; set;}
        public Boolean selected {get; set;}
        public integer key { get; set; }
      
        public ServiceBillingWrapper(Service_Billing_Schedule__c fcoLn,integer i) 
        {
            fcoLang = fcoLn;
            selected = false;
            key = i;
            
        }
    }
    
    /*-----------------------------------------------------------------------------
    Author:      Kasmoor Reddy
    Company:     Apps Associates
    Description: wrapper Class to store the records which need to be displayed in VFPage 
    Returns:     N/A
      
    History:
    <Date>         <Authors Name>      <Brief Description of Change>
    02/19/2018     Kasmoor Reddy        Initial Creation (US3871)
-----------------------------------------------------------------------------------*/ 
    public class ServiceContractBillingWrapper
    {
        public Service_Billing_Schedule__c fcolang {get;set;}
       
        public Boolean selected {get; set;}
        public integer key { get; set; }
        public contractlineitem clri {get;set;}
        public id sbid{get;set;}
        public servicecontract scr{get;set;}
        public Decimal sequence {get;set;}
        public Decimal  amount1 {get;set;}
        public date sDate {get;set;}
        public date eDate {get;set;}
        public Decimal nPeriod{get;set;}
        public string Period{get;set;}
  /*-----------------------------------------------------------------------------
    Author:      Kasmoor Reddy
    Company:     Apps Associates
    Description: wrapper Class Constructor to get records from other method (in Outer Class - ServiceContractItemAndBilling) 
    Returns:     N/A
      
    History:
    <Date>         <Authors Name>      <Brief Description of Change>
    02/19/2018     Kasmoor Reddy        Initial Creation (US3871)
-----------------------------------------------------------------------------------*/ 

        public ServiceContractBillingWrapper(contractlineitem fcoLn,servicecontract src ,integer sequence,decimal amount,Service_Billing_Schedule__c fcolang,integer i) 
        {
             system.debug('in wrapper:'+fcolang);
            if(i >0){
                clri=fcoLn;
                system.debug(fcolang);
                this.fcolang=fcolang;
                sbid=fcolang.Id;
                this.sdate = fcolang.Start_Date__c;
                this.edate = fcolang.End_Date__c;
                scr=src;
                this.nPeriod = fcolang.Number_of_Periods__c;
                this.Period = fcolang.Period__c;
                fcolang.id=fcolang.id;
                this.amount1=fcolang.Amount__c;
                this.sequence=fcolang.sequence__c;
                selected = false;
                key = i;
            }else{
            
                clri=fcoLn;
                this.sdate = fcoln.startdate;
                this.edate = fcoln.enddate;
                scr=src;
                this.amount1=clri.TotalPrice;
                this.sequence=1;
                this.nPeriod=src.BS_Number_of_Periods__c;
                this.Period=src.BS_Period__c;
                selected = false;
                key = i;
            
            }
        }
    }
    
    /*-----------------------------------------------------------------------------
    Author:      Kasmoor Reddy
    Company:     Apps Associates
    Description: Method to allow the insertion and updation of service billing schedule records
                 with respective to their contract line items. 
    Returns:     N/A
      
    History:
    <Date>         <Authors Name>      <Brief Description of Change>
    02/19/2018     Kasmoor Reddy        Initial Creation (US3871)
-----------------------------------------------------------------------------------*/  
    public pagereference saveSCBillingschedules()
    {
        
        id newid;  
        //Fetching the updated or inserted data from VF through Wrapper Class
        newid= ListOfServicecontractBilling[0].scr.id;
        list<contractlineitem> clilist ;
        //Quering data based on the current Page ID
        Clilist = [select id,assetid,Asset.name,startdate,enddate,LineItemNumber,TotalPrice,(select id from Service_Billing_Schedules__r ) from ContractLineItem Where servicecontract.ID =:newid];

        SBSList= [Select Amount__c, Contract_Line_Item__c, CurrencyIsoCode, Duration__c, End_Date__c, Id, Interface_Offset__c, 
        Invoice_Offset__c, Name, Number_of_Periods__c, Oracle_Billing_Schedule_ID__c, OwnerId, Period__c, Quote_Line__c, Sequence__c, Start_Date__c  
        FROM Service_Billing_Schedule__c  where Contract_Line_Item__c in :Clilist];
        system.debug('saveBillingschedules start::'); 
        //to store FCO Language Notification Lines for upsert
        
        List<Service_Billing_Schedule__c> listOfServicecontractBillingToUpdate = new List<Service_Billing_Schedule__c>();
        
        system.debug('saveBillingschedules'+ListOfServicecontractBilling); 

        //getting the line items records
        for(ServicecontractBillingWrapper serviceContractBillingWrapperDetail : ListOfServicecontractBilling){
            Service_Billing_Schedule__c sbs = new Service_Billing_Schedule__c();
            system.debug('serviceBillingWrapperDetail::'+serviceContractBillingWrapperDetail);
            sbs.Id=serviceContractBillingWrapperDetail.sbid;
            sbs.Contract_Line_Item__c=serviceContractBillingWrapperDetail.clri.id;
            sbs.Amount__c=serviceContractBillingWrapperDetail.amount1;
            sbs.Start_Date__c=serviceContractBillingWrapperDetail.sdate;
            sbs.End_Date__c=serviceContractBillingWrapperDetail.edate;
            sbs.Sequence__c=serviceContractBillingWrapperDetail.sequence;
            sbs.Number_of_Periods__c=serviceContractBillingWrapperDetail.nPeriod;
            sbs.Period__c=serviceContractBillingWrapperDetail.Period;
            sbs.Name='Billing Schedule - '+string.valueof(serviceContractBillingWrapperDetail.clri.Asset.name);
            system.debug(serviceContractBillingWrapperDetail.sbid);
            system.debug(sbs);
           
            //Adding to list 
            listOfServicecontractBillingToUpdate.add(sbs);
                
            

        }
        //Upserting the data to Service_Billing_Schedule__c
        if(listOfServicecontractBillingToUpdate.size()>0){
            try{
           upsert listOfServicecontractBillingToUpdate;
            }
            catch(exception e){
   
                
                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.FATAL,'Period and Number of Periods field values of Service Billing Schedules cannot be null'));
				 return null;
                
               
            }
        }
        //Redirection to the same Page after updating/inserting the records
        /*PageReference pageRef = new PageReference(ApexPages.currentPage().getUrl());
        pageRef.setRedirect(true);
        return pageRef;*/
             PageReference pageRef = new Pagereference('/apex/ServiceContractandbilling?Id='+newid);
        pageRef.setRedirect(true);
        return pageRef;
        
    }
     /*-----------------------------------------------------------------------------
    Author:      Kasmoor Reddy
    Company:     Apps Associates
    Description: Method to Insert/Update and Cascade Service Contract fields to  Service Billing Schedule records. 
    Returns:     N/A
      
    History:
    <Date>         <Authors Name>      <Brief Description of Change>
    02/19/2018     Kasmoor Reddy        Initial Creation (US3871)
-----------------------------------------------------------------------------------*/  
  
      public pagereference saveServiceContract(){
           integer sequence=1;
        servicecontract scr; //= new servicecontract();
              Scr = (Servicecontract)stdcontroller.getRecord();
        system.debug(Scr);
          try {
            update scr;
        }
        catch(Exception e) {
            return null;
        } 
        ListOfServicecontractBilling.clear();
       for(contractlineitem  fcoLn: [select id,assetid,Asset.name,startdate,enddate,LineItemNumber,TotalPrice,servicecontractid,(Select id,Amount__c, Contract_Line_Item__c, CurrencyIsoCode, Duration__c, End_Date__c, Interface_Offset__c, 
            Invoice_Offset__c, Name, Number_of_Periods__c, Oracle_Billing_Schedule_ID__c, OwnerId, Period__c, Quote_Line__c, Sequence__c, Start_Date__c from Service_Billing_Schedules__r )  from ContractLineItem Where servicecontract.ID =:scr.Id]){
                
                if(fcoLn.Service_Billing_Schedules__r.size()==0){
           
                    ListOfServicecontractBilling.add(new ServiceContractBillingWrapper(fcoLn,Scr,sequence,fcoln.TotalPrice,null,fcoLn.Service_Billing_Schedules__r.size()));
                }
                 else if(fcoLn.Service_Billing_Schedules__r.size()>0){
                    for(Service_Billing_Schedule__c sbl:fcoLn.Service_Billing_Schedules__r){
                    system.debug('in else');
                    system.debug(sbl);
                        ListOfServicecontractBilling.add(new ServiceContractBillingWrapper(fcoln,Scr,sequence,fcoln.TotalPrice,sbl,fcoLn.Service_Billing_Schedules__r.size()));
                    }
                }
                       
                
            }
      
        //Redirection to the same Page after cascading
       /* PageReference pageRef = new Pagereference('/apex/ServiceContractandbilling?Id='+scr.Id);
        pageRef.setRedirect(true);
        return pageRef;*/
        return null;
    }

}