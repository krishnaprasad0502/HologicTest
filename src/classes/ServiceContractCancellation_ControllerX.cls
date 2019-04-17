/*------------------------------------------------------------
Author:         Denise Bacher
Company:        Salesforce.com
Description:    Provides ability to cancel ServiceContracts and ContractLineItems
Test Class:     ServiceContractCancellation_CtrlX_Test

History:
<Date>          <Authors Name>      <Brief Description of Change>
08/01/2015      Denise Bacher       Initial Creation (US1333)
10/14/2015      Mani                Update to round "Final Refound Amount" to 2 decimal places (HD-1629)
09/13/2017      John Christy        Update to include Termination Reason (US0003375)
11/07/2018      Krishna             Update Prorated Amount based on Termination date (US-0005708)
01/18/2018      Krishna             Consider Future paid invoices in Contract Termination(US-0006574)
------------------------------------------------------------*/
public with sharing class ServiceContractCancellation_ControllerX {
    //External Object dummy variable initialization
    @TestVisible private static List<Billing_Schedule_History__x> mockedRequests = new List<Billing_Schedule_History__x>();
    public ServiceContract serviceContract {get; set;} // service contract this page was launched from
    public List<ContractLineItem> contractLineItems {get; set;} // contract lines related to the service contract
    public String selectedContractLineId {get; set;} // id of the contract line that has been modified on the UI
    public Boolean serviceContractTermination {get; set;} // boolean to indicate cancellation is occuring at the service contract
    public Boolean serviceContractTerminationReason {get; set;} // boolean to indicate cancellation is occuring at the service contract
    public Boolean contractLineTermination {get; set;} // boolean to indicate cancellation is occuring at the individial contract lines
    public Boolean contractLineTerminationReason {get; set;} // boolean to indicate cancellation is occuring at the individial contract lines
    //Krishna
    List<String> contractLineIdList = new List<String>();
    
    @TestVisible private Map<Id, ContractLineItem> mapContractLineItems;
    private ApexPages.StandardController standardCtrl;
        
    public ServiceContractCancellation_ControllerX (ApexPages.StandardController ctrl){
        if(!Test.isRunningTest()){
            ctrl.addFields(new List<String>{'Original_End_Date__c'});
        }
        standardCtrl = ctrl;
        serviceContract = (ServiceContract)ctrl.getRecord();
        
        serviceContractTermination = true;
        contractLineTermination = true;
        serviceContractTerminationReason = true;
        contractLineTerminationReason = true;
        
        // if service contract termination date has already been set - do not allow editing of individual contract lines
        if(serviceContract.Terminated_Date__c != null){
            contractLineTermination = false;
        }
        
        mapContractLineItems = new Map<Id, ContractLineItem>();
        contractLineItems = new List<ContractLineItem>();
        
        // query the contract lines and their children - doing this so we can group children under their parents
        for(ContractLineItem cli : [Select Id, LineItemNumber, ParentContractLineItem.LineItemNumber,Oracle_Covered_Line_ID__c 
            , StartDate, EndDate, SBQQSC__TerminatedDate__c, Termination_Reason__c, Original_End_Date__c
            , PricebookEntry.Product2.Name, PricebookEntry.Product2.ProductCode, Asset.SerialNumber
            , TotalPrice, UnitPrice, Quantity, Prorated_Amount__c, Refund_Amount__c, Final_Refund_Amount__c, Suppress_Credit__c, Full_Credit__c
            , (Select Id, LineItemNumber, ParentContractLineItemId, ParentContractLineItem.LineItemNumber,Oracle_Covered_Line_ID__c
                , StartDate, EndDate, SBQQSC__TerminatedDate__c,Termination_Reason__c, Original_End_Date__c
                , PricebookEntry.Product2.Name, PricebookEntry.Product2.ProductCode, Asset.SerialNumber
                , TotalPrice, UnitPrice, Quantity, Prorated_Amount__c, Refund_Amount__c, Final_Refund_Amount__c, Suppress_Credit__c, Full_Credit__c
                From ChildContractLineItems
                Order By StartDate, EndDate, LineItemNumber)
            From ContractLineItem
            Where ServiceContractId =: serviceContract.Id and Service_Type__c != 'Warranty'
            Order By StartDate, EndDate, LineItemNumber])
        {
            if(!mapContractLineItems.containsKey(cli.Id)){
                mapContractLineItems.put(cli.Id, cli);
                contractLineItems.add(cli);
                //11/07/2018        Krishna             Update Prorated Amount based on Termination date (US-0005708)
                //listing Oracle_Covered_Line_ID__c for Billing_Schedule_History__x
                contractLineIdList.add(cli.Oracle_Covered_Line_ID__c);
                
                for(ContractLineItem childCLI : cli.ChildContractLineItems){
                    mapContractLineItems.put(childCLI.Id, childCLI);
                    contractLineItems.add(childCLI);
                    //11/07/2018        Krishna             Update Prorated Amount based on Termination date (US-0005708)
                    ////listing Oracle_Covered_Line_ID__c for Billing_Schedule_History__x
                    contractLineIdList.add(cli.Oracle_Covered_Line_ID__c);
                }
            }
            
            // disable editing at service contract level if contract lines have already been edited
            if(contractLineTermination && serviceContractTermination && cli.SBQQSC__TerminatedDate__c != null){
                serviceContractTermination = false;
            }
            if(contractLineTerminationReason && serviceContractTerminationReason && cli.Termination_Reason__c != null){
                serviceContractTerminationReason = false;
            }
        }
    }
    
    /*------------------------------------------------------------
    Author:         Denise Bacher
    Company:        Salesforce.com
    Description:    Set contract line termination dates and prorated amounts
                    Disable setting of individual contrat line item termination dates 
    
    History:
    <Date>          <Authors Name>      <Brief Description of Change>
    08/01/2015      Denise Bacher       Initial Creation (US1333)
    10/14/2015      Mani                Update to round "Final Refound Amount" to 2 decimal places (HD-1629)
    11/07/2018      Krishna             Update Prorated Amount based on Termination date (US-0005708)
    ------------------------------------------------------------*/
    public void serviceContractTerminationDateChanged(){
        serviceContractTermination = true;
        contractLineTermination = false;
        
        if(serviceContract.Terminated_Date__c != null){
            serviceContract.Refund_Amount__c = 0;
            serviceContract.Prorated_Amount__c = 0;
            serviceContract.Final_Refund_Amount__c = 0;
        }
        else{
            serviceContract.Refund_Amount__c = null;
            serviceContract.Prorated_Amount__c = null;
            serviceContract.Final_Refund_Amount__c = null;
            serviceContract.Suppress_Credit__c = false;
            serviceContract.Full_Credit__c = false;
        }  

        //11/13/2018        Krishna             Update Prorated Amount based on Termination date (US-0005708)
            Map<string,set<Billing_Schedule_History__x>> billSchHismap = new  map<string,set<Billing_Schedule_History__x>> ();
        
            Date terminatedDate = Date.valueOf(serviceContract.Terminated_Date__c);
            DateTime dtConverted =Datetime.newInstance(terminatedDate.year(), terminatedDate.month(),terminatedDate.day(),0,0,0);   
         dtConverted.addHours(4);
         terminatedDate = date.valueOf(dtConverted);            
            system.debug('terminatedDate::::'+terminatedDate);
            system.debug('contractLineIdList::::'+contractLineIdList);
            list<Billing_Schedule_History__x> billSchHislist =[select Bill_From__c,Bill_To__c,Invoiced_Date__c,Amount__c,Contract_Line_Item__c,Oracle_Contract_Number__c from Billing_Schedule_History__x where Contract_Line_Item__c IN:contractLineIdList  ];
             //External Object dummy variable initialization
             if(Test.isRunningTest()) {
                 if(mockedRequests.size()>0)
            billSchHislist.add(mockedRequests[0]);
        }   
       
        for(Billing_Schedule_History__x bshDetail:billSchHisList){
            if((bshDetail.Bill_From__c  <= date.valueof(terminatedDate) && bshDetail.Bill_To__c >=  date.valueof(terminatedDate)) || (bshDetail.Bill_From__c  <=  system.today() && bshDetail.Bill_To__c >= system.today())){
                if(String.isNotBlank(bshDetail.Contract_Line_Item__c)){
                    if(!billSchHismap.containsKey(bshDetail.Contract_Line_Item__c)) {
                        billSchHismap.put(bshDetail.Contract_Line_Item__c, new set<Billing_Schedule_History__x>());
                    }
                    billSchHismap.get(bshDetail.Contract_Line_Item__c).add(bshDetail);
                }
            }

        }
           
            
        system.debug('billSchHismap.size::SER::'+billSchHismap.size());
        system.debug('billSchHismap.size::SER::'+billSchHismap);
        //(Bill_From__c  <=: terminatedDate and Bill_To__c >=: terminatedDate)

        
                
                
        map<string,ContractLineItem> cliMap =  new map<string,ContractLineItem>();
        for(ContractLineItem cli : contractLineItems){
            cli.SBQQSC__TerminatedDate__c = serviceContract.Terminated_Date__c == null || serviceContract.Terminated_Date__c >= cli.StartDate
                ? serviceContract.Terminated_Date__c : cli.StartDate;
            
            calculateContractLineRefund(cli);
                  date finalTermDate ;
                  double refundAmount =0;
                  date checkSetDate;
            if(serviceContract.Terminated_Date__c != null){
                //11/07/2018        Krishna             commented due to  (US-0005708)
                //serviceContract.Prorated_Amount__c += cli.Prorated_Amount__c;
                //serviceContract.Prorated_Amount__c = serviceContract.Prorated_Amount__c.setScale(2, RoundingMode.HALF_UP);
             if(billSchHismap.size() > 0){
                    for(set<Billing_Schedule_History__x> bsh:billSchHismap.values()){
                        System.debug(' bsh::::ser:: '+bsh); 
                        for (Billing_Schedule_History__x  bshRecord : bsh)
                            {
                                if(bshRecord.Bill_From__c  <= terminatedDate && bshRecord.Bill_To__c >=  terminatedDate && bshRecord.Invoiced_Date__c != null){
                                    if(!cliMap.containskey(cli.Oracle_Covered_Line_ID__c)){
                                        if(bshRecord.Contract_Line_Item__c == cli.Oracle_Covered_Line_ID__c){
                                            cliMap.put(cli.Oracle_Covered_Line_ID__c,cli);
                                            System.debug(' Contract_Line_Item__c::::ser:: '+bshRecord.Contract_Line_Item__c);   
                                            System.debug(' Bill_From__c::::ser:: '+bshRecord.Bill_From__c); 
                                            if(bshRecord.Bill_From__c  <= terminatedDate && bshRecord.Bill_To__c >=  terminatedDate){
                                                finalTermDate = terminatedDate;
                                            }else{
                                                finalTermDate = system.today();
                                            }
                                            Date Bill_From = Date.newInstance(bshRecord.Bill_From__c.YEAR(),bshRecord.Bill_From__c.MONTH(),bshRecord.Bill_From__c.DAY());//
                                                Date Bill_To = Date.newInstance(bshRecord.Bill_To__c.YEAR(),bshRecord.Bill_To__c.MONTH(),bshRecord.Bill_To__c.DAY());
                                         
                                                integer noOfDaysBetweenTerminateDates = Bill_From.daysBetween(finalTermDate); 
                                                //noOfDaysBetweenTerminateDates = noOfDaysBetweenTerminateDates+1   ;                                   
                                                Integer noOfDaysBetweenDates = Bill_From.daysBetween(Bill_To);                 
                                                decimal dayAmount = (bshRecord.Amount__c/noOfDaysBetweenDates); 
                                                System.debug(' noOfDaysBetweenDates::::ser:: ' + noOfDaysBetweenDates);
                                                System.debug(' bshRecord.Amount__c::ser::: ' + bshRecord.Amount__c);
                                                System.debug('dayAmount:::ser:::: ' + dayAmount);
                                                System.debug(' dayAmount*noOfDaysBetweenTerminateDates:::ser::::: ' + dayAmount*noOfDaysBetweenTerminateDates);
                                                refundAmount += bshRecord.Amount__c; 
                                                System.debug('refundAmount:::ser:::: ' + refundAmount);
                                                System.debug('serviceContract.Prorated_Amount__c:::ser:::11: ' + serviceContract.Prorated_Amount__c);
                                                serviceContract.Prorated_Amount__c += (dayAmount*noOfDaysBetweenTerminateDates);
                                                System.debug('serviceContract.Prorated_Amount__c:::ser:::22: ' + serviceContract.Prorated_Amount__c);
                                                serviceContract.Final_Refund_Amount__c = (refundAmount- serviceContract.Prorated_Amount__c);
                                                    System.debug('cli.Refund_Amount__c:::ser:::11: ' + cli.Refund_Amount__c);
                                                serviceContract.Refund_Amount__c += cli.Refund_Amount__c;
                                                System.debug('cli.Refund_Amount__c:::ser:::22: ' + cli.Refund_Amount__c);
                                                serviceContract.Refund_Amount__c = serviceContract.Refund_Amount__c.setScale(2, RoundingMode.HALF_UP);
                                                System.debug('cli.Refund_Amount__c:::ser:::33: ' + cli.Refund_Amount__c);
                                        }
                                    }
                                }/*else{
                                    
                                    refundAmount += bshRecord.Amount__c;
                                     serviceContract.Refund_Amount__c = refundAmount;
                                     serviceContract.Final_Refund_Amount__c = (refundAmount- serviceContract.Prorated_Amount__c);
                                    
                                }*/
                            }
                        
                    }
                }
                                
                
                
                //serviceContract.Refund_Amount__c += cli.Refund_Amount__c;
                //serviceContract.Refund_Amount__c = serviceContract.Refund_Amount__c.setScale(2, RoundingMode.HALF_UP);
                
                if(serviceContract.Suppress_Credit__c){
                    serviceContract.Final_Refund_Amount__c = 0;
                } else if(serviceContract.Full_Credit__c){
                    serviceContract.Final_Refund_Amount__c = serviceContract.Refund_Amount__c;
                } else {
                    serviceContract.Final_Refund_Amount__c = serviceContract.Refund_Amount__c;
                }
                serviceContract.Final_Refund_Amount__c = serviceContract.Final_Refund_Amount__c.setScale(2, RoundingMode.HALF_UP);
            }
        }
        
        
        



        
        
        
        
    }
        
    /*------------------------------------------------------------
    Author:         John Christy
    Company:        Apps Associates
    Description:    Set contract line termination reason 
    
    History:
    <Date>          <Authors Name>      <Brief Description of Change>
    09/13/2017      John Christy        Initial Creation (US0003375)
    ------------------------------------------------------------*/
    public void serviceContractTerminationReasonChanged(){
        serviceContractTerminationReason = true;
        contractLineTerminationReason = false;  
        
        for(ContractLineItem cli : contractLineItems){
            cli.Termination_Reason__c  = serviceContract.Termination_Reason__c  ;

        }       
    }
    
    /*------------------------------------------------------------
    Author:         Denise Bacher
    Company:        Salesforce.com
    Description:    When Service Contract Supress Credit is checked, set Final Refund Amount to 0
    
    History:
    <Date>          <Authors Name>      <Brief Description of Change>
    08/02/2015      Denise Bacher       Initial Creation (US1333)
    10/14/2015      Mani                Update to round "Final Refound Amount" to 2 decimal places (HD-1629)
    ------------------------------------------------------------*/
    public void serviceContractSupressCreditChanged(){
        serviceContract.Full_Credit__c = false;
        
        serviceContract.Final_Refund_Amount__c = serviceContract.Suppress_Credit__c ? 0 : serviceContract.Refund_Amount__c;
        serviceContract.Final_Refund_Amount__c = serviceContract.Final_Refund_Amount__c.setScale(2, RoundingMode.HALF_UP);
        
        for(ContractLineItem cli : contractLineItems){
            cli.Suppress_Credit__c = serviceContract.Suppress_Credit__c;
            cli.Final_Refund_Amount__c = cli.Suppress_Credit__c ? 0 : cli.Refund_Amount__c;
        }
    }
    
    /*------------------------------------------------------------
    Author:         Dave Mansell
    Company:        Salesforce.com
    Description:    When Service Contract Full Credit is checked, set Final Refund Amount to total amount
    
    History:
    <Date>          <Authors Name>      <Brief Description of Change>
    09/17/2018      Dave Mansell        Initial Creation (US5626)
    ------------------------------------------------------------*/
    public void serviceContractFullCreditChanged(){
        serviceContract.Suppress_Credit__c = false;
        
        serviceContract.Final_Refund_Amount__c = serviceContract.Full_Credit__c ? serviceContract.Refund_Amount__c : serviceContract.Refund_Amount__c;
        serviceContract.Final_Refund_Amount__c = serviceContract.Final_Refund_Amount__c.setScale(2, RoundingMode.HALF_UP);
        
        for(ContractLineItem cli : contractLineItems){
            cli.Full_Credit__c = serviceContract.Full_Credit__c;
            //cli.Final_Refund_Amount__c = cli.Full_Credit__c ? cli.TotalPrice : cli.Refund_Amount__c;
            cli.Final_Refund_Amount__c = cli.Full_Credit__c ? cli.Refund_Amount__c : cli.Refund_Amount__c;
        }
    }
    
    /*------------------------------------------------------------
    Author:         Denise Bacher
    Company:        Salesforce.com
    Description:    When Service Contract Final Refund Amount is chaged/overwritten, recalculate the contract lines
    
    History:
    <Date>          <Authors Name>      <Brief Description of Change>
    08/02/2015      Denise Bacher       Initial Creation (US1333)
    10/14/2015      Mani                Update to round "Final Refound Amount" to 2 decimal places (HD-1629)
    ------------------------------------------------------------*/
    public void serviceContractFinalRefundOverride(){
        serviceContract.Final_Refund_Amount__c = serviceContract.Final_Refund_Amount__c ==  null ? 0 : serviceContract.Final_Refund_Amount__c;
        serviceContract.Final_Refund_Amount__c = serviceContract.Final_Refund_Amount__c.setScale(2, RoundingMode.HALF_UP);
        for(ContractLineItem cli : contractLineItems){
            calculateContractLineRefundServiceContractOverride(cli);
        }
    }
    
    /*------------------------------------------------------------
    Author:         Denise Bacher
    Company:        Salesforce.com
    Description:    Disable setting of service contract termination date
                    Calculate single line prorated amount 
    
    History:
    <Date>          <Authors Name>      <Brief Description of Change>
    08/01/2015      Denise Bacher       Initial Creation (US1333)
    ------------------------------------------------------------*/
    public void contractLineTerminationDateChanged(){
        contractLineTermination = true;
        serviceContractTermination = false;
        
        ContractLineItem cli = mapContractLineItems.containsKey(selectedContractLineId) ? mapContractLineItems.get(selectedContractLineId) : null;
        if(cli != null){
            cli.SBQQSC__TerminatedDate__c = cli.SBQQSC__TerminatedDate__c == null || cli.SBQQSC__TerminatedDate__c >= cli.StartDate
                ? cli.SBQQSC__TerminatedDate__c : cli.StartDate;
            
            calculateContractLineRefund(cli);
            rollupServiceContractTotals();
        }
    }
    
    /*------------------------------------------------------------
    Author:         John Christy
    Company:        Apps Associates
    Description:    Disable setting of service contract termination reason 
    
    History:
    <Date>          <Authors Name>      <Brief Description of Change>
    09/13/2017      John Christy        Initial Creation (US0003375)
    ------------------------------------------------------------*/
    public void contractLineTerminationReasonChanged(){
        contractLineTerminationReason = true;
        serviceContractTerminationReason = false;
        
        ContractLineItem cli = mapContractLineItems.containsKey(selectedContractLineId) ? mapContractLineItems.get(selectedContractLineId) : null;
        if(cli != null){
            serviceContract.Termination_Reason__c = cli.Termination_Reason__c ;
        }
    }   
    
    /*------------------------------------------------------------
    Author:         Denise Bacher
    Company:        Salesforce.com
    Description:    When Contract Line Supress Credit is checked, set Final Refund Amount to 0
    
    History:
    <Date>          <Authors Name>      <Brief Description of Change>
    08/02/2015      Denise Bacher       Initial Creation (US1333)
    ------------------------------------------------------------*/
    public void contractLineSupressCreditChanged(){
        ContractLineItem cli = mapContractLineItems.containsKey(selectedContractLineId) ? mapContractLineItems.get(selectedContractLineId) : null;
        if(cli != null){
            cli.Full_Credit__c = false;
            cli.Final_Refund_Amount__c = cli.Suppress_Credit__c ? 0 : cli.Refund_Amount__c;
            rollupServiceContractTotals();
        }
    }
    
    /*------------------------------------------------------------
    Author:         Dave Mansell
    Company:        Salesforce.com
    Description:    When Contract Line Supress Credit is checked, set Final Refund Amount to total amount
    
    History:
    <Date>          <Authors Name>      <Brief Description of Change>
    09/17/2018      Dave Mansell        Initial Creation (US5626)
    ------------------------------------------------------------*/
    public void contractLineFullCreditChanged(){
        ContractLineItem cli = mapContractLineItems.containsKey(selectedContractLineId) ? mapContractLineItems.get(selectedContractLineId) : null;
        if(cli != null){
            cli.Suppress_Credit__c = false;
            cli.Final_Refund_Amount__c = cli.Full_Credit__c ? cli.Refund_Amount__c : cli.Refund_Amount__c;
            rollupServiceContractTotals();
        }
    }
    
    /*------------------------------------------------------------
    Author:         Denise Bacher
    Company:        Salesforce.com
    Description:    When Contract Line Final Refund Amount is chaged/overwritten, recalculate the totals
    
    History:
    <Date>          <Authors Name>      <Brief Description of Change>
    08/02/2015      Denise Bacher       Initial Creation (US1333)
    ------------------------------------------------------------*/
    public void contractLineFinalRefundOverride(){
        ContractLineItem cli = mapContractLineItems.containsKey(selectedContractLineId) ? mapContractLineItems.get(selectedContractLineId) : null;
        if(cli != null){
            cli.Final_Refund_Amount__c = cli.Final_Refund_Amount__c ==  null ? 0 : cli.Final_Refund_Amount__c;
            rollupServiceContractTotals();
        }
    }
    
    /*------------------------------------------------------------
    Author:         Denise Bacher
    Company:        Salesforce.com
    Description:    Save the Cancellation changes
    
    History:
    <Date>          <Authors Name>      <Brief Description of Change>
    08/02/2015      Denise Bacher       Initial Creation (US1333)
    ------------------------------------------------------------*/
    public PageReference saveCancellation(){
        System.Savepoint sp = Database.setSavepoint();
        PageReference pageRef;
        
        if(serviceContractTermination && serviceContract.Terminated_Date__c != null){
            serviceContract.Original_End_Date__c = serviceContract.EndDate;
            serviceContract.EndDate = serviceContract.Terminated_Date__c;
        }
        
        for(ContractLineItem cli : contractLineItems){
            if(cli.SBQQSC__TerminatedDate__c != null){
                cli.Original_End_Date__c = cli.EndDate;
                cli.EndDate = cli.SBQQSC__TerminatedDate__c;
                
                Decimal newTotal = cli.TotalPrice - cli.Final_Refund_Amount__c;
                cli.UnitPrice = newTotal/cli.Quantity;
            }
        }
        
        try{
            update serviceContract;
            update contractLineItems;
            
            pageRef = standardCtrl.view();
        }
        catch(DMLException e){
            Database.rollback(sp);
            System.debug(e);
            System.debug(e.getMessage());
            ApexPages.addMessages(e);
        }
        
        return pageRef;
    }
    
    /*------------------------------------------------------------
    Author:         Denise Bacher
    Company:        Salesforce.com
    Description:    For a given ContractLineItem, calculate the prorated and refund amounts
    
    History:
    <Date>          <Authors Name>      <Brief Description of Change>
    08/01/2015      Denise Bacher       Initial Creation (US1333)
    11/13/2018        Krishna             Update Prorated Amount based on Termination date (US-0005708)
    01/18/2018      Krishna             Consider Future paid invoices in Contract Termination(US-0006574)
    ------------------------------------------------------------*/
    private void calculateContractLineRefund(ContractLineItem cli){
        if(cli.SBQQSC__TerminatedDate__c != null){
            Date startDate = cli.StartDate;
            Date endDate = cli.EndDate.addDays(1);
            //Date terminatedDate = cli.StartDate == cli.SBQQSC__TerminatedDate__c ? cli.SBQQSC__TerminatedDate__c : cli.SBQQSC__TerminatedDate__c.addDays(1);
            Date terminatedDate =  cli.SBQQSC__TerminatedDate__c;
            system.debug(terminatedDate);
            //11/13/2018        Krishna             Update Prorated Amount based on Termination date (US-0005708)
           Map<string,list<Billing_Schedule_History__x>> billSchmap = new  map<string,list<Billing_Schedule_History__x>> ();
                  
            system.debug('terminatedDate::::'+terminatedDate);
            system.debug('contractLineIdList::::'+contractLineIdList);
            list<Billing_Schedule_History__x> billSchHislist =[select Bill_From__c,Bill_To__c,Invoice_Date__c,Invoiced_Date__c,Amount__c,Contract_Line_Item__c,Oracle_Contract_Number__c from Billing_Schedule_History__x where Contract_Line_Item__c =:cli.Oracle_Covered_Line_ID__c ];
                //External Object dummy variable initialization
             if(Test.isRunningTest()) {
                 if(mockedRequests.size()>0)
            billSchHislist.add(mockedRequests[0]);
        }   
       system.debug('billSchHislist.size::::'+billSchHislist.size());
        
    Date stDate;
    Date enDate;
    Date invoStartDate;
    for(Billing_Schedule_History__x bshDetail:billSchHisList){
        //system.debug('bshDetail.Bill_To__c::::'+bshDetail.Bill_To__c);
        system.debug('system.today()::::'+system.today());
        //DateTime myDateTime = datetime.valueof(terminatedDate.year(),terminatedDate.month(),terminatedDate.day(),0,0,0);
        
        DateTime dtConverted =Datetime.newInstance(terminatedDate.year(), terminatedDate.month(),terminatedDate.day(),0,0,0);   
         dtConverted.addHours(4);
         terminatedDate = date.valueOf(dtConverted);
        if(bshDetail.Bill_From__c  <= system.today() && bshDetail.Bill_To__c >=  system.today()){
            stDate=bshDetail.Bill_From__c;
            enDate=bshDetail.Bill_To__c;
        }
           system.debug('innn::@::terminatedDate!!!!'+terminatedDate);
            system.debug('innn::@::bshDetail.Bill_To__c!!!!'+bshDetail.Bill_To__c);
              system.debug('innn::@::bshDetail.Bill_From__c!!!!'+bshDetail.Bill_From__c);
         if(bshDetail.Bill_From__c  <= terminatedDate && bshDetail.Bill_To__c >=  terminatedDate){
             system.debug('innnnnnnn::::bshDetail.Bill_From__c!!!!'+bshDetail.Bill_From__c);
            invoStartDate=bshDetail.Bill_From__c;
            
        }
         system.debug('innn::::stDate!!!!'+stDate);
         system.debug('innn::::enDate!!!!'+enDate);
    }
    if(stDate  <= terminatedDate && enDate >=  terminatedDate){
          system.debug('innn::::222!!!!');
        for(Billing_Schedule_History__x bshDetail:billSchHisList){
            if(bshDetail.Bill_From__c  <= terminatedDate && bshDetail.Bill_To__c >=  terminatedDate){
                if(String.isNotBlank(bshDetail.Contract_Line_Item__c)){
                    if(!billSchmap.containsKey(bshDetail.Contract_Line_Item__c)) {
                        billSchmap.put(bshDetail.Contract_Line_Item__c, new List<Billing_Schedule_History__x>());
                    }
                billSchmap.get(bshDetail.Contract_Line_Item__c).add(bshDetail);
                }
            }
        }

    }else {
        for(Billing_Schedule_History__x bshDetail:billSchHisList){
            system.debug('innn::::111!!!!');
              system.debug('innn::::111!!!invoStartDate!'+invoStartDate);
            system.debug('innn::::111!!!bshDetail.Invoiced_Date__c!'+bshDetail.Invoiced_Date__c);
              system.debug('innn::::111!!!system.today()!'+system.today());
           // if( bshDetail.Bill_From__c   <= invoStartDate){
              // 01/18/2018      Krishna             Consider Future paid invoices in Contract Termination(US-0006574)
               //if( bshDetail.Invoiced_Date__c  <= system.today() && bshDetail.Invoiced_Date__c >= invoStartDate){
               if(  bshDetail.Invoiced_Date__c >= invoStartDate){
                system.debug('innn::::1111!4!!invoStartDate!'+invoStartDate);
                if(String.isNotBlank(bshDetail.Contract_Line_Item__c)){
                    system.debug('innn::::11111!5!!invoStartDate!'+invoStartDate);
                    if(!billSchmap.containsKey(bshDetail.Contract_Line_Item__c)) {
                    billSchmap.put(bshDetail.Contract_Line_Item__c, new List<Billing_Schedule_History__x>());
                    }
                billSchmap.get(bshDetail.Contract_Line_Item__c).add(bshDetail);
                }
            }
        }
    }


        system.debug('billSchmap.size::::'+billSchmap.size());
        system.debug('billSchmap.size::::'+billSchmap);
              cli.Prorated_Amount__c = 0;
              cli.Refund_Amount__c  = 0;
              cli.Final_Refund_Amount__c =0;
              double refundAmount =0;
              
              date finalTermDate ;
                if(billSchmap.size() > 0){
                    for(list<Billing_Schedule_History__x> bsh:billSchmap.values()){
                        
                        for (Billing_Schedule_History__x  bshRecord : bsh){
                                if(bshRecord.Invoiced_Date__c != null){
                                     if(bshRecord.Bill_From__c  <= terminatedDate && bshRecord.Bill_To__c >=  terminatedDate){
                                            System.debug('bshRecord::::11 ' + bshRecord.Amount__c);  
                                        finalTermDate = terminatedDate;
                                         Date Bill_From = Date.newInstance(bshRecord.Bill_From__c.YEAR(),bshRecord.Bill_From__c.MONTH(),bshRecord.Bill_From__c.DAY());//
                                            Date Bill_To = Date.newInstance(bshRecord.Bill_To__c.YEAR(),bshRecord.Bill_To__c.MONTH(),bshRecord.Bill_To__c.DAY());
                                            System.debug(' finalTermDate::::::: ' + finalTermDate);
                                            integer noOfDaysBetweenTerminateDates = Bill_From.daysBetween(finalTermDate);
                                            noOfDaysBetweenTerminateDates = noOfDaysBetweenTerminateDates;
                                            Integer noOfDaysBetweenDates = Bill_From.daysBetween(Bill_To)+1;                 
                                            decimal dayAmount = (bshRecord.Amount__c/noOfDaysBetweenDates); 
                                            System.debug(' noOfDaysBetweenDates:::::1!:: ' + noOfDaysBetweenDates);
                                            System.debug(' bshRecord.Amount__c:::::1!:: ' + bshRecord.Amount__c);
                                            System.debug('dayAmount:::::1!:: ' + dayAmount);
                                            system.debug('Bill_From:::::1!:: ' + Bill_From);
                                            system.debug('Bill_To:::::1!:: ' + Bill_To);
                                            System.debug('noOfDaysBetweenTerminateDates::1!::::: ' + noOfDaysBetweenTerminateDates);
                                            System.debug('serviceContract.Prorated_Amount__c:::1!:::: ' + serviceContract.Prorated_Amount__c);
                                            System.debug(' dayAmount*noOfDaysBetweenTerminateDates::::1!::: ' + dayAmount*noOfDaysBetweenTerminateDates);
                                            
                                            System.debug('cli.Prorated_Amount__c:::11:1!::: ' + cli.Prorated_Amount__c);  
                                            cli.Prorated_Amount__c += (dayAmount*noOfDaysBetweenTerminateDates);   
                                            System.debug('cli.Prorated_Amount__c:::22:::: ' + cli.Prorated_Amount__c);  
                                            System.debug('cli.Refund_Amount__c:::11:::: ' + cli.Refund_Amount__c);  
                                            
                                            refundAmount += bshRecord.Amount__c;                        
                                            cli.Refund_Amount__c += (refundAmount - cli.Prorated_Amount__c);
                                            System.debug('cli.Refund_Amount__c:::22:::: ' + cli.Refund_Amount__c);  
                                            System.debug('cli.Final_Refund_Amount__c:::11:::: ' + cli.Final_Refund_Amount__c);  
                                            cli.Final_Refund_Amount__c += cli.Suppress_Credit__c ? 0 : ( refundAmount - cli.Prorated_Amount__c);
                                        System.debug('cli.Final_Refund_Amount__c:::22:::: ' + cli.Final_Refund_Amount__c);
                                    }else{
                                            System.debug('bshRecord::::22 ' + bshRecord.Amount__c);  
                                            System.debug('cli.Refund_Amount__c:::22:in::: ' + bshRecord.Amount__c);
                                            System.debug('cli.cli.Prorated_Amount__c :::22:in::: ' + cli.Prorated_Amount__c );                                      
                                            
                                            cli.Prorated_Amount__c += 0;
                                            System.debug('cli.Refund_Amount__c:::22::in:: ' + cli.Refund_Amount__c);  
                                             System.debug(' cli.Prorated_Amount__cc:::22::in:: ' + cli.Prorated_Amount__c);  
                                            cli.Refund_Amount__c += bshRecord.Amount__c ;
                                            System.debug('cli.Refund_Amount__c:::33::in:: ' + cli.Refund_Amount__c);  
                                            System.debug('cli.Final_Refund_Amount__c:::11: in::: ' + cli.Final_Refund_Amount__c);  
                                            cli.Final_Refund_Amount__c += cli.Suppress_Credit__c ? 0 : ( bshRecord.Amount__c );
                                       
                                    }
                                }
                            }
                        
                    }
                }
            
            Double origianlDuration = startDate.daysBetween(endDate);
            Double cancelledDuration = startDate.daysBetween(terminatedDate);
            
            //cli.Refund_Amount__c = (origianlDuration - cancelledDuration) / origianlDuration * cli.TotalPrice;
            //cli.Prorated_Amount__c = cli.TotalPrice - cli.Refund_Amount__c;
            //cli.Final_Refund_Amount__c = cli.Suppress_Credit__c ? 0 : cli.Refund_Amount__c;
            
            /*System.debug(cli.LineItemNumber + ' start date ' + startDate);
            System.debug(cli.LineItemNumber + ' end date ' + endDate);
            System.debug(cli.LineItemNumber + ' term date ' + terminatedDate);
            System.debug(cli.LineItemNumber + ' days between end and start ' + origianlDuration);
            System.debug(cli.LineItemNumber + ' days between terminated and start ' + cancelledDuration);
            System.debug(cli.LineItemNumber + ' totalPrice ' + cli.TotalPrice);
            System.debug(cli.LineItemNumber + ' proratedAmount ' + cli.Prorated_Amount__c);
            System.debug(cli.LineItemNumber + ' refundAmount ' + cli.Refund_Amount__c);
            System.debug(cli.LineItemNumber + ' finalRefundAmount ' + cli.Final_Refund_Amount__c);*/
        }
        else{
            cli.Prorated_Amount__c = null;
            cli.Refund_Amount__c = null;
            cli.Final_Refund_Amount__c = null;
            cli.Suppress_Credit__c = false;
        }
    }
    
    /*------------------------------------------------------------
    Author:         Denise Bacher
    Company:        Salesforce.com
    Description:    For a given ContractLineItem, calculate the prorated and refund amounts based on the service contract override
    
    History:
    <Date>          <Authors Name>      <Brief Description of Change>
    08/01/2015      Denise Bacher       Initial Creation (US1333)
    ------------------------------------------------------------*/
    private void calculateContractLineRefundServiceContractOverride(ContractLineItem cli){
        cli.Final_Refund_Amount__c = cli.Refund_Amount__c / serviceContract.Refund_Amount__c * serviceContract.Final_Refund_Amount__c;
    }
    
    /*------------------------------------------------------------
    Author:         Denise Bacher
    Company:        Salesforce.com
    Description:    For a given ContractLineItem, calculate the prorated and refund amounts based on the service contract override
    
    History:
    <Date>          <Authors Name>      <Brief Description of Change>
    08/01/2015      Denise Bacher       Initial Creation (US1333)
    10/14/2015      Mani                Update to round "Final Refound Amount" to 2 decimal places (HD-1629)
    ------------------------------------------------------------*/
    private void rollupServiceContractTotals(){
        Boolean hasTerminationDate = false;
        serviceContract.Refund_Amount__c = 0;
        serviceContract.Prorated_Amount__c = 0;
        serviceContract.Final_Refund_Amount__c = 0;
        
        for(ContractLineItem cli : contractLineItems){
            if(cli.SBQQSC__TerminatedDate__c != null){
                hasTerminationDate = true;
                serviceContract.Prorated_Amount__c += cli.Prorated_Amount__c == null ? 0 : cli.Prorated_Amount__c;
                serviceContract.Prorated_Amount__c = serviceContract.Prorated_Amount__c.setScale(2, RoundingMode.HALF_UP);
                serviceContract.Refund_Amount__c += cli.Refund_Amount__c == null ? 0 : cli.Refund_Amount__c;
                serviceContract.Refund_Amount__c = serviceContract.Refund_Amount__c.setScale(2, RoundingMode.HALF_UP);
                serviceContract.Final_Refund_Amount__c += cli.Final_Refund_Amount__c == null ? 0 : cli.Final_Refund_Amount__c;
                serviceContract.Final_Refund_Amount__c = serviceContract.Final_Refund_Amount__c.setScale(2, RoundingMode.HALF_UP);
            }
        }
        
        if(!hasTerminationDate){
            serviceContract.Refund_Amount__c = null;
            serviceContract.Prorated_Amount__c = null;
            serviceContract.Final_Refund_Amount__c = null;
        }   
    }
}