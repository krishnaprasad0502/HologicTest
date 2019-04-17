/*------------------------------------------------------------
Author:         Denise Bacher
Company:        Salesforce.com
Description:    Allows setting of Bill/Ship to Account and Site from related Accounts via Customer_Relationship__x
Test Class:     CaseBillShipTo_ControllerX_Test

History:
<Date>          <Authors Name>      <Brief Description of Change>
11/08/2016      Denise Bacher       Initial Creation (US-0001169)
14/06/2017      Amarendra Nagireddy Added logic to build pagination on Bill to site address to avoid Visual Force page collectin size issue.
15/06/2017      Amarendra Nagireddy Added logic to search the site_location record based on user enterd key and maped user 
                                    selected to Bill to site value to current case Bill_to_Site_Location__c field
19/06/2017      Amarendra Nagireddy Added logic to build pagination on ship to site address to avoid Visual Force page collectin size issue.
                                     and to search the site_location record based on user user enterd key on Ship to site and maped user 
                                    selected to Ship to site value to current case Ship_to_Site_Location__c filed
26/06/2017     Amarendra Nagireddy  Added logic to update Ship to site address based on user selection of "Bill To Customer" or "Ship To Customer"
11/01/2017     Kasmoor Reddy        Added the logic in the methods "shipToAcctSelected" and "billToAcctSelected" to fix the pagination issues.
------------------------------------------------------------*/
public with sharing class CaseBillShipTo_ControllerX{
    @TestVisible private final Case currCase;
    private ApexPages.StandardController standardCtrl;
    private Map<String, Customer_Relationship__x> customerRelationshipMap = new Map<String, Customer_Relationship__x>();
    @TestVisible private static List<Customer_Relationship__x> mockCustomerRelationships = new List<Customer_Relationship__x>();
    //Bill To
    public String searchkey {set;get;}
    public String getsearchkey {set;get;}
    public Set<Id> BillTo_siteAccountIds {set;get;}
    public Integer BillTo_totalcount {set;get;}
    public List<InnerClass> Billtosite {set;get;}
    public Integer pagination {set;get;}
    //Ship To
    public String STSsearchkey;
    public String STSgetsearchkey;
    Public Set<Id> ShipTo_siteAccountIds {set;get;}
    public Integer ShipTo_totalcount {set;get;}
    public List<InnerClass> Shiptosite {set;get;}
    public List<Site_Location__c> siteloclist {get;set;}
    public Integer STSpagination {set;get;}
    public List<SelectOption> billToAcctOptions{
        get{
            if(billToAcctOptions == null){
                billToAcctOptions = new List<SelectOption>();
                billToAcctOptions.add(new SelectOption('', '--None--'));
            }
            return billToAcctOptions;
        }
        private set;
    }
    
    public List<SelectOption> shipToAcctOptions{
        get{
            if(shipToAcctOptions == null){
                shipToAcctOptions = new List<SelectOption>();
                shipToAcctOptions.add(new SelectOption('', '--None--'));
            }
            return shipToAcctOptions;
        }
        private set;
    }
    
    public List<SelectOption> billToSiteOptions{
        get{
            if(billToSiteOptions == null){
                billToSiteOptions = new List<SelectOption>();
                billToSiteOptions.add(new SelectOption('', '--None--'));
            }
            return billToSiteOptions;
        }
        private set;
    }
    
    public List<SelectOption> shipToSiteOptions{
        get{
            if(shipToSiteOptions == null){
                shipToSiteOptions = new List<SelectOption>();
                shipToSiteOptions.add(new SelectOption('', '--None--'));
            }
            return shipToSiteOptions;
        }
        private set;
    }
    
    public CaseBillShipTo_ControllerX(ApexPages.StandardController ctrl){
        pagination=0;
        BillTo_totalcount=0;
        STSpagination=0;
        ShipTo_totalcount=0;
        BillTo_siteAccountIds = new Set<Id>();
        siteloclist = new List<Site_Location__c>();
        if(!Test.isRunningTest()){
            ctrl.addFields(new List<String>{'AccountId', 'Customer_Name__c', 'Customer_Name__r.Oracle_Party_Id__c'});
        }
        standardCtrl = ctrl;
        currCase = (Case)ctrl.getRecord();
        if(currCase.Customer_Name__c == null || String.isBlank(currCase.Customer_Name__r.Oracle_Party_Id__c)){
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.WARNING, 'The Case is missing a Customer Name, or a Customer Name with an Oracle Party Id.');
            ApexPages.addMessage(myMsg);
        }
        Billtosite=new List<InnerClass>();
        Shiptosite=new List<InnerClass>();
        // get the Customer_Relationship__x records
        customerRelationshipMap = getCustomerRelationships(currCase.Customer_Name__r.Oracle_Party_Id__c);
        // get the Bill/Ship to Accounts related to the Customer_Relationship__x retrieved
        string bill;
        string ship;
        for(Account a : [Select Id, Name, Oracle_Party_Id__c, Oracle_Customer_Number__c From Account Where Oracle_Party_Id__c IN: customerRelationshipMap.keyset() OR Id =: currCase.Customer_Name__c Order By Name]){
            String customerNumber = String.isBlank(a.Oracle_Customer_Number__c) ? '' : a.Oracle_Customer_Number__c;
            Customer_Relationship__x customerRelationship = customerRelationshipMap.get(a.Oracle_Party_Id__c);
            
            // Bill To
            if (a.Id == currCase.Customer_Name__c || customerRelationship.Bill_To__c == true){
            	bill = bill+',  '+a.id;
            	billToAcctOptions.add(new SelectOption(a.id, a.Name + ' (' + customerNumber + ')'));
            }
            // Ship To 
            
            if (a.Id == currCase.Customer_Name__c || customerRelationship.Ship_To__c == true){
            	ship = ship+',  '+a.id;
            	shipToAcctOptions.add(new SelectOption(a.id, a.Name + ' (' + customerNumber + ')'));
                
            }
           
        }
        system.debug(bill);
        system.debug(ship);
        billToAcctSelected();
        shipToAcctSelected();
    }
    
    /*------------------------------------------------------------
    Author:         Denise Bacher
    Company:        Salesforce.com
    Description:    fetch the Site Locations realted to the selected Bill_to_Customer__c
    
    History:
    <Date>          <Authors Name>      <Brief Description of Change>
    11/08/2016      Denise Bacher        Initial Creation
    14/06/2017      Amarendra Nagireddy  Set total count of Site_locations records retrived based on BillTo_siteAccountIds and Get site_location 
                                         records  
    ------------------------------------------------------------*/
    public void billToAcctSelected() {
        billToSiteOptions = null;
        system.debug('currCase.Bill_to_Customer__c==='+currCase.Bill_to_Customer__c);
       if(currCase.Bill_to_Customer__c != null){
       	   string SelType=Apexpages.currentPage().getParameters().get('Type');
           //11/02/2017(Kasmoor Reddy) Declared caseAcc variable to assign "Bill to Customer" or "Ship to customer" value based on "SelType" variable
           id caseAcc;
          //11/02/2017(Kasmoor Reddy) Based on the "SelType" value assign "Bill to Customer" or "Ship to customer" value to caseAcc
            if(SelType=='BTA')
            {
               caseAcc=currCase.Bill_to_Customer__c; 
            }else{
            	caseAcc=currCase.Bill_to_Customer__c;
            }
            BillTo_siteAccountIds = new Set<Id>();
         system.debug('currCase.Bill_to_Customer__c==='+currCase.Bill_to_Customer__c);
           system.debug('caseAcc----'+caseAcc);
           for(Account a : [Select Id From Account Where ParentID =: caseAcc And RecordTypeId =: GlobalUtility.getRecordTypeId('Account', 'Site')]){
                BillTo_siteAccountIds.add(a.Id);
            }
            system.debug('BillTo_siteAccountIds--'+BillTo_siteAccountIds.size());
       //14/06/2017(Amarendra Nagireddy)BillTo_siteAccountIds are not null,run the querys.   
       if(BillTo_siteAccountIds.size()>0){
           //14/06/2017(Amarendra Nagireddy) Set total count of Site_locations records retrived based on BillTo_siteAccountIds
           BillTo_totalcount=[SELECT count() FROM Site_Location__c WHERE Bill_To__c = true AND Active__c = true AND Account__c IN: BillTo_siteAccountIds];
           Billtosite.clear();
         //siteloclist = [SELECT Id, Name, Bill_To__c, Ship_To__c, Address_Line_2__c, Deliver_To__c, Account__c, Account__r.Name FROM Site_Location__c WHERE Bill_To__c = true AND Active__c = true AND Account__c IN: BillTo_siteAccountIds Order by Name limit 10 offset :pagination];
           
           //14/06/2017(Amarendra Nagireddy) Run the query and get Site_locations Records
          for (Site_Location__c s : [SELECT Id, Name, Bill_To__c, Ship_To__c, Address_Line_2__c,Address_Line_3__c, Deliver_To__c,City__c, Account__c,State__c, Account__r.Name FROM Site_Location__c WHERE Bill_To__c = true AND Active__c = true AND Account__c IN: BillTo_siteAccountIds Order by Name limit 10 offset :pagination]){
                String addrLine2=(s.Address_Line_2__c==NULL) ? '' : s.Address_Line_2__c;
		        String addrLine3=(s.Address_Line_3__c==NULL) ? '' : s.Address_Line_3__c;
		        String city=(s.City__c==NULL) ? '' : s.City__c;
		        String state=(s.State__c==NULL) ? '' : s.State__c;
                billToSiteOptions.add(new SelectOption(s.Id, s.Name + ' (' + addrLine2 + ')'));
                if(addrLine3 == ''  && addrLine2 == ''){
                  Billtosite.add(new InnerClass(s.Id, s.Name + '  |  ' + city + ',  ' + state)); 	
                }
                else if(addrLine2 == ''){
                	Billtosite.add(new InnerClass(s.Id, s.Name + '  |  ' + addrLine3 + '  |  ' + city + ',  ' + state));
                }
                else if(addrLine3 == ''){
                	Billtosite.add(new InnerClass(s.Id, s.Name + '  |  ' + addrLine2 + '  |  ' + city + ',  ' + state));
                }
                else if(addrLine3 != null && addrLine2 != null){
                  Billtosite.add(new InnerClass(s.Id, s.Name + '  |  ' + addrLine2 + '  |  ' + addrLine3 + '  |  ' + city + ',  ' + state)); 	
                }
                system.debug('Billtosite--'+Billtosite);
                
              }
           
           }
        }
        
      }
     /*------------------------------------------------------------
    Author:         Amarendra Nagireddy
    Company:        Apps Associates
    Description:    To set the previous link pagination count of Bill To Site.
    Inputs:         N/A 
    Returns:        N/A
    
    History:
    <Date>          <Authors Name>        <Brief Description of Change>
    14/06/2017     Amarendra Nagireddy    Initial Creation(US-0003039)
    ------------------------------------------------------------*/
    public void setPrevious(){
      if(pagination != 0){
          pagination -= 10;
      }else{
          pagination = 0; 
      }
      if(searchkey!=null){
           Runsearch(); 
      }else{
        runQuery(); 
      }
   }
   /*------------------------------------------------------------
    Author:         Amarendra Nagireddy
    Company:        Apps Associates
    Description:    To set the next link pagination count of Bill To Site.
    Inputs:         N/A 
    Returns:        N/A
    
    History:
    <Date>          <Authors Name>        <Brief Description of Change>
    14/06/2017      Amarendra Nagireddy    Initial Creation(US-0003039)
    ------------------------------------------------------------*/
   public void setNext(){
     if(pagination < BillTo_totalcount){
          pagination += 10;
      }else{
          pagination = BillTo_totalcount;
      }
      if(searchkey!=null){
           Runsearch(); 
      }else{
           runQuery(); 
      }
  }
    

    /*------------------------------------------------------------
    Author:         Amarendra Nagireddy
    Company:        Hologic
    Description:    Method will run the query and pass set of Bill to site records, Based on pagination count 
    Inputs:         N/A 
    Returns:        N/A
    
    History:
    <Date>          <Authors Name>      <Brief Description of Change>
    14/06/2017     Amarendra Nagireddy  Initial Creation(US-0003039)
    ------------------------------------------------------------*/
    public void runQuery() 
    {
        Billtosite.clear();
        //14/06/2017(Amarendra Nagireddy) Based on Bill to site pagination count, run the query and get Site_location records which has Bill_To__c is true
        for (Site_Location__c s : [SELECT Id, Name, Bill_To__c, Ship_To__c, Address_Line_2__c,Address_Line_3__c,City__c,State__c, Deliver_To__c, Account__c, Account__r.Name FROM Site_Location__c WHERE Bill_To__c = true AND Active__c = true AND Account__c IN: BillTo_siteAccountIds Order by Name limit 10 OFFSET :pagination])
        {
         String addrLine2=(s.Address_Line_2__c==NULL) ? '' : s.Address_Line_2__c;
		        String addrLine3=(s.Address_Line_3__c==NULL) ? '' : s.Address_Line_3__c;
		        String city=(s.City__c==NULL) ? '' : s.City__c;
		        String state=(s.State__c==NULL) ? '' : s.State__c;
		        if(addrLine3 == ''  && addrLine2 == ''){
                  Billtosite.add(new InnerClass(s.Id, s.Name + '  |  ' + city + ',  ' + state)); 	
                }
                else if(addrLine2 == ''){
                	Billtosite.add(new InnerClass(s.Id, s.Name + '  |  ' + addrLine3 + '  |  ' + city + ',  ' + state));
                }
                else if(addrLine3 == ''){
                	Billtosite.add(new InnerClass(s.Id, s.Name + '  |  ' + addrLine2 + '  |  ' + city + ',  ' + state));
                }
                else if(addrLine3 != null && addrLine2 != null){
                  Billtosite.add(new InnerClass(s.Id, s.Name + '  |  ' + addrLine2 + '  |  ' + addrLine3 + '  |  ' + city + ',  ' + state)); 	
                }
          //Billtosite.add(new InnerClass(s.Id, s.Name + '|' + addrLine2 + '|' + addrLine3 + '|' + city + ',  ' + state));
        }
    }
  /*------------------------------------------------------------
    Author:         Amarendra Nagireddy
    Company:        Apps Associates
    Description:    runs the Site Location search with parameters passed via Javascript
    Inputs:         N/A 
    Returns:        PageReference
    
    History:
    <Date>          <Authors Name>             <Brief Description of Change>
    15/06/2017      Amarendra Nagireddy         Initial Creation(US-0003039)
  ------------------------------------------------------------*/
  public pagereference runSearch() {
      if(getsearchkey == null ||getsearchkey!=Apexpages.currentPage().getParameters().get('searchkey') ){
          getsearchkey = Apexpages.currentPage().getParameters().get('searchkey'); 
          //pagination=0;
      }
      //11/02/2017(Kasmoor Reddy) added as part of US-3586
      if(searchkey==null || (searchkey != getsearchkey && getsearchkey != null)){
        searchkey=getsearchkey; 
      } 
      Billtosite.clear();
      //Based on user entred Key on Bill To site field, query Site_Location records which has Bill_To__c is true
      if(!string.isEmpty(searchkey)){
        list<string> st = new list<string>();
        st.add('%'+searchkey+'%');
        BillTo_totalcount=[SELECT count() FROM Site_Location__c WHERE Bill_To__c = true AND Active__c = true AND  Account__c IN:BillTo_siteAccountIds and Address_Line_1__c like :st];
        List<Site_Location__c> totalsites11 =[SELECT Id, Name, Bill_To__c, Ship_To__c, Address_Line_2__c,City__c,State__c,Address_Line_3__c, Deliver_To__c, Account__c, Account__r.Name FROM Site_Location__c WHERE Bill_To__c = true AND Active__c = true AND  Account__c IN:BillTo_siteAccountIds and Address_Line_1__c like :st Order by Name limit 10 OFFSET :pagination];
        for (Site_Location__c s : totalsites11 )
        {
         String addrLine2=(s.Address_Line_2__c==NULL) ? '' : s.Address_Line_2__c;
		        String addrLine3=(s.Address_Line_3__c==NULL) ? '' : s.Address_Line_3__c;
		        String city=(s.City__c==NULL) ? '' : s.City__c;
		        String state=(s.State__c==NULL) ? '' : s.State__c;
		        if(addrLine3 == ''  && addrLine2 == ''){
                  Billtosite.add(new InnerClass(s.Id, s.Name + '  |  ' + city + ',  ' + state)); 	
                }
                else if(addrLine2 == ''){
                	Billtosite.add(new InnerClass(s.Id, s.Name + '  |  ' + addrLine3 + '  |  ' + city + ',  ' + state));
                }
                else if(addrLine3 == ''){
                	Billtosite.add(new InnerClass(s.Id, s.Name + '  |  ' + addrLine2 + '  |  ' + city + ',  ' + state));
                }
                else if(addrLine3 != null && addrLine2 != null){
                  Billtosite.add(new InnerClass(s.Id, s.Name + '  |  ' + addrLine2 + '  |  ' + addrLine3 + '  |  ' + city + ',  ' + state)); 	
                }
          //Billtosite.add(new InnerClass(s.Id, s.Name + '|' + addrLine2 + '|' + addrLine3 + '|' + city + ',  ' + state));
        }
      }else{
         billToAcctSelected(); 
      }
        
       
    return null;
   }  
   /*------------------------------------------------------------
    Author:         Amarendra Nagireddy
    Company:        Apps Associates
    Description:    Set user selected Bill to site value to current case Bill_to_Site_Location__c field
    Inputs:         N/A 
    Returns:        N/A
    
    History:
    <Date>          <Authors Name>             <Brief Description of Change>
    15/06/2017      Amarendra Nagireddy         Initial Creation(US-0003039)
  ------------------------------------------------------------*/
   public void SelectedBTS()
   {
       //Map user selected Bill To Site value to current case Bill_to_Site_Location__c
       currCase.Bill_to_Site_Location__c=Apexpages.currentPage().getParameters().get('selectedBTS');
   }
    /*------------------------------------------------------------
    Author:         Denise Bacher
    Company:        Salesforce.com
    Description:    fetch the Site Locations realted to the selected Ship_to_Customer__c
    
    History:
    <Date>          <Authors Name>      <Brief Description of Change>
    11/08/2016      Denise Bacher         Initial Creation
    19/06/2017      Amarendra Nagireddy   Set total count of Site_locations records retrived based on ShipTo_siteAccountIds and Get site_location 
                                          records
    ------------------------------------------------------------*/
    public void shipToAcctSelected() {
    	system.debug('currCase.Ship_to_Customer__c==='+currCase.Ship_to_Customer__c);
       
        shipToSiteOptions = null;
        if(currCase.Ship_to_Customer__c != null){
            //26/06/2017(Amarendra Nagireddy) Declared SelType variable to differentiate user Selection Type
           string SelType=Apexpages.currentPage().getParameters().get('Type');
           //26/06/2017(Amarendra Nagireddy) Declared caseAcc variable to assign "Bill to Customer" or "Ship to customer" value based on "SelType" variable
           id caseAcc;
          //26/06/2017(Amarendra Nagireddy) Based on the "SelType" value assign "Bill to Customer" or "Ship to customer" value to caseAcc
            //11/02/2017(Kasmoor Reddy) added as part of US-3586
            if(SelType=='STA')
            {
               caseAcc=currCase.Ship_to_Customer__c; 
            }else{
                caseAcc=currCase.Ship_to_Customer__c; 
            }
            ShipTo_siteAccountIds = new Set<Id>();
            system.debug(caseAcc);
            // fetch site accounts realted to the currently selected ship to account
            for(Account a : [Select Id From Account Where ParentID =:caseAcc And RecordTypeId =: GlobalUtility.getRecordTypeId('Account', 'Site')]){
                ShipTo_siteAccountIds.add(a.Id);
            }
            system.debug('ShipTo_siteAccountIds '+ShipTo_siteAccountIds);
            //19/06/2017(Amarendra Nagireddy)ShipTo_siteAccountIds are not null,run the querys.
            if(ShipTo_siteAccountIds.size()>0){
                //19/06/2017(Amarendra Nagireddy) Set total count of Site_locations records retrived based on ShipTo_siteAccountIds to ShipTo_totalcount
                ShipTo_totalcount=[SELECT count() FROM Site_Location__c WHERE Ship_To__c = true AND Active__c = true AND Account__c IN: ShipTo_siteAccountIds];
                Shiptosite.clear();
                 //19/06/2017(Amarendra Nagireddy) Run the query and get Site_locations Records
                for (Site_Location__c s : [SELECT Id, Name, Bill_To__c, Ship_To__c,Address_Line_3__c, Address_Line_2__c, Deliver_To__c, Account__c,City__c,State__c, Account__r.Name FROM Site_Location__c WHERE Ship_To__c = true AND Active__c = true AND Account__c IN: ShipTo_siteAccountIds Order by Name limit 10 offset :STSpagination]){
                    String addrLine2=(s.Address_Line_2__c==NULL) ? '' : s.Address_Line_2__c;
		            String addrLine3=(s.Address_Line_3__c==NULL) ? '' : s.Address_Line_3__c;
		            String city=(s.City__c==NULL) ? '' : s.City__c;
		        String state=(s.State__c==NULL) ? '' : s.State__c;
                    shipToSiteOptions.add(new SelectOption(s.Id, s.Name + ' (' + addrLine2 + ')'));
                    if(addrLine3 == ''  && addrLine2 == ''){
                  Shiptosite.add(new InnerClass(s.Id, s.Name + '  |  ' + city + ',  ' + state)); 	
                }
                else if(addrLine2 == ''){
                	Shiptosite.add(new InnerClass(s.Id, s.Name + '  |  ' + addrLine3 + '  |  ' + city + ',  ' + state));
                }
                else if(addrLine3 == ''){
                	Shiptosite.add(new InnerClass(s.Id, s.Name + '  |  ' + addrLine2 + '  |  ' + city + ',  ' + state));
                }
                else if(addrLine3 != null && addrLine2 != null){
                  Shiptosite.add(new InnerClass(s.Id, s.Name + '  |  ' + addrLine2 + '  |  ' + addrLine3 + '  |  ' + city + ',  ' + state)); 	
                }
                    //Shiptosite.add(new InnerClass(s.Id, s.Name + '|' + addrLine2 + '|' + addrLine3 + '|' + city + ',  ' + state));
                }
            }
        }
    }
     /*------------------------------------------------------------
    Author:         Amarendra Nagireddy
    Company:        Apps Associates
    Description:    To set the previous link pagination count of Ship To Site.
    Inputs:         N/A 
    Returns:        N/A
    
    History:
    <Date>          <Authors Name>        <Brief Description of Change>
    19/06/2017     Amarendra Nagireddy    Initial Creation(US-0003039)
    ------------------------------------------------------------*/
    public void STSsetPrevious(){
      if(STSpagination != 0){
          STSpagination -= 10;
      }
      else{
          STSpagination = 0; 
      }
      if(STSsearchkey!=null){
           STSRunsearch(); 
      }
      else{
           STSrunQuery(); 
      }
   }
   /*------------------------------------------------------------
    Author:         Amarendra Nagireddy
    Company:        Apps Associates
    Description:    To set the next link pagination count of Ship To Site.
    Inputs:         N/A 
    Returns:        N/A
    
    History:
    <Date>          <Authors Name>        <Brief Description of Change>
    19/06/2017      Amarendra Nagireddy    Initial Creation(US-0003039)
    ------------------------------------------------------------*/
   public void STSsetNext(){
      if(STSpagination < ShipTo_totalcount){
          STSpagination += 10;
      }else{
          STSpagination = ShipTo_totalcount;
      }
      if(STSsearchkey!=null){
           STSRunsearch(); 
      }else{
           STSrunQuery(); 
      }
  }
    /*------------------------------------------------------------
    Author:         Amarendra Nagireddy
    Company:        Hologic
    Description:    Based on pagination count of Ship to site, Method will run the query and pass set of site location records.
    Inputs:         N/A 
    Returns:        N/A
    
    History:
    <Date>          <Authors Name>      <Brief Description of Change>
    20/06/2017      Amarendra Nagireddy  Initial Creation(US-0003039)
    ------------------------------------------------------------*/
    public void STSrunQuery() 
    {
        Shiptosite.clear();
        //Based on Ship to site pagination count, Run the query to get Site_Location which has Ship_To__c is true
        for (Site_Location__c s : [SELECT Id, Name, Bill_To__c, Ship_To__c, Address_Line_2__c,Address_Line_3__c, Deliver_To__c,City__c,State__c, Account__c, Account__r.Name FROM Site_Location__c WHERE Ship_To__c = true AND Active__c = true AND Account__c IN: ShipTo_siteAccountIds Order by Name limit 10 offset :STSpagination])
        {
          String addrLine2=(s.Address_Line_2__c==NULL) ? '' : s.Address_Line_2__c;
		  String addrLine3=(s.Address_Line_3__c==NULL) ? '' : s.Address_Line_3__c;
		  String city=(s.City__c==NULL) ? '' : s.City__c;
		        String state=(s.State__c==NULL) ? '' : s.State__c;
		         if(addrLine3 == ''  && addrLine2 == ''){
                  Shiptosite.add(new InnerClass(s.Id, s.Name + '  |  ' + city + ',  ' + state)); 	
                }
                else if(addrLine2 == ''){
                	Shiptosite.add(new InnerClass(s.Id, s.Name + '  |  ' + addrLine3 + '  |  ' + city + ',  ' + state));
                }
                else if(addrLine3 == ''){
                	Shiptosite.add(new InnerClass(s.Id, s.Name + '  |  ' + addrLine2 + '  |  ' + city + ',  ' + state));
                }
                else if(addrLine3 != null && addrLine2 != null){
                  Shiptosite.add(new InnerClass(s.Id, s.Name + '  |  ' + addrLine2 + '  |  ' + addrLine3 + '  |  ' + city + ',  ' + state)); 	
                }
          //Shiptosite.add(new InnerClass(s.Id, s.Name + '|' + addrLine2 + '|' + addrLine3 + '|' + city + ',  ' + state));
        }
    }
    /*------------------------------------------------------------
    Author:         Amarendra Nagireddy
    Company:        Apps Associates
    Description:    Based on user entred key on Ship to site,runs the Site Location search
    Inputs:         N/A 
    Returns:        PageReference
    
    History:
    <Date>          <Authors Name>             <Brief Description of Change>
    20/06/2017      Amarendra Nagireddy         Initial Creation(US-0003039)
    11/01/2017      Kasmoor Reddy               modified some piece of code to fix pagination issue on search keyword
  ------------------------------------------------------------*/
    public pagereference STSrunSearch() {
    	system.debug(STssearchkey);
      if(STSgetsearchkey == null || STSgetsearchkey!=Apexpages.currentPage().getParameters().get('STSsearchkey')){
          STSgetsearchkey = Apexpages.currentPage().getParameters().get('STSsearchkey'); 
          //STSpagination=0;
      }
      system.debug(STssearchkey);
       system.debug(STSgetsearchkey);
       //11/02/2017(Kasmoor Reddy) added as part of US-3586
      if(STssearchkey==null || (STssearchkey != STSgetsearchkey && STSgetsearchkey != null)){
        STssearchkey=STSgetsearchkey; 
      }
      Shiptosite.clear();
      system.debug(STssearchkey);
      system.debug(STSpagination);
        //Based on user entred Key on Ship To site field, query Site_Location which has Ship_to is true
      if(!string.isEmpty(STssearchkey)){
        list<string> st = new list<string>();
        st.add('%'+STssearchkey+'%');
        ShipTo_totalcount=[SELECT count() FROM Site_Location__c WHERE Ship_To__c = true AND Active__c = true AND Account__c IN: ShipTo_siteAccountIds and Address_Line_1__c like :st];
        system.debug(ShipTo_totalcount);
        List<Site_Location__c> totalsites11 =[SELECT Id, Name, Bill_To__c, Ship_To__c, Address_Line_2__c,Address_Line_3__c, Deliver_To__c,City__c,State__c, Account__c, Account__r.Name FROM Site_Location__c WHERE Ship_To__c = true AND Active__c = true AND Account__c IN: ShipTo_siteAccountIds and Address_Line_1__c like :st Order by Name limit 10 OFFSET :STSpagination];
        system.debug(totalsites11.size());
        for (Site_Location__c s : totalsites11 )
        {
          String addrLine2=(s.Address_Line_2__c==NULL) ? '' : s.Address_Line_2__c;
		  String addrLine3=(s.Address_Line_3__c==NULL) ? '' : s.Address_Line_3__c;
		  String city=(s.City__c==NULL) ? '' : s.City__c;
		        String state=(s.State__c==NULL) ? '' : s.State__c;
		         if(addrLine3 == ''  && addrLine2 == ''){
                  Shiptosite.add(new InnerClass(s.Id, s.Name + '  |  ' + city + ',  ' + state)); 	
                }
                else if(addrLine2 == ''){
                	Shiptosite.add(new InnerClass(s.Id, s.Name + '  |  ' + addrLine3 + '  |  ' + city + ',  ' + state));
                }
                else if(addrLine3 == ''){
                	Shiptosite.add(new InnerClass(s.Id, s.Name + '  |  ' + addrLine2 + '  |  ' + city + ',  ' + state));
                }
                else if(addrLine3 != null && addrLine2 != null){
                  Shiptosite.add(new InnerClass(s.Id, s.Name + '  |  ' + addrLine2 + '  |  ' + addrLine3 + '  |  ' + city + ',  ' + state)); 	
                }
          //Shiptosite.add(new InnerClass(s.Id, s.Name + '|' + addrLine2 + '|' + addrLine3 + '|' + city + ',  ' + state));
          system.debug(Shiptosite);
        }
      }else{
      	 //Shiptosite.clear();
         shipToAcctSelected();
         //STSrunQuery();
      }
     return null;
   } 
     /*------------------------------------------------------------
    Author:         Amarendra Nagireddy
    Company:        Apps Associates
    Description:    Set user selected Ship to site value to current case Ship_to_Site_Location__c field
    Inputs:         N/A 
    Returns:        N/A
    
    History:
    <Date>          <Authors Name>             <Brief Description of Change>
    20/06/2017      Amarendra Nagireddy         Initial Creation(US-0003039)
  ------------------------------------------------------------*/
    public void SelectedSTS()
   {   //Map user selected Ship To Site value to current case Ship_to_Site_Location__c
       currCase.Ship_to_Site_Location__c=Apexpages.currentPage().getParameters().get('selectedSTS');
   }
    /*------------------------------------------------------------
    Author:         Denise Bacher
    Company:        Salesforce.com
    Description:    fetch the Customer_Relationship__x related to the Case.
    
    History:
    <Date>          <Authors Name>      <Brief Description of Change>
    11/08/2016      Denise Bacher       Initial Creation
    ------------------------------------------------------------*/
    private static Map<String, Customer_Relationship__x> getCustomerRelationships(String oraclePartyId){
         Map<String, Customer_Relationship__x> tempCustomerRelationshipMap = new Map<String, Customer_Relationship__x>();
        List<Customer_Relationship__x> tempCustomerRelationships = new List<Customer_Relationship__x>();
        
        // if a unit test is running, return the mock list since external object records are not currently creatable for unit tests
        if(Test.isRunningTest()){
            tempCustomerRelationships = mockCustomerRelationships;
        }
        else if(String.isNotBlank(oraclePartyId)){
            tempCustomerRelationships = [Select PartyId__c, Related_Oracle_Party_ID__c, Bill_To__c, Ship_To__c, Status__c 
                From Customer_Relationship__x 
                Where (PartyId__c =: oraclePartyId or Related_Oracle_Party_ID__c =: oraclePartyId) 
                AND Status__c = 'Active'];
        }
        
        for(Customer_Relationship__x cr : tempCustomerRelationships){
            tempCustomerRelationshipMap.put(cr.PartyId__c, cr);
        }
        
        return tempCustomerRelationshipMap;
    }


    public class InnerClass{
        public ID Site_id {set;get;}
        public String Site_Address {set;get;}
         //public String Address_line_2 {set;get;}
        //public String Address_line_3 {set;get;}
        public Innerclass(ID Site_id,String Site_Address)
        {
          this.Site_id=Site_id;
          this.Site_Address=Site_Address;
          //this.Address_line_2=Address_line_2;
          //this.Address_line_3=Address_line_3;
        }
    }
}