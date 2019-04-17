/*------------------------------------------------------------


History:
<Date>          <Authors Name>          <Brief Description of Change>
14/2/2018       KRISHNA PRASAD          Update Quote Order Form (US-0003896) -- Lastest Updation
------------------------------------------------------------*/
public class OrderConfirmationPageController {

    public SBQQ__Quote__c quote {get;set;} 
    //public SBQQ__QuoteLine__c line {get;set;} 
    //public String quoteId {get;set;}
    public List<QuoteWrapper> QuoteWrapperList {get;set;}
    public List<QuoteLineWrapper> QuoteLineWrapperList {get;set;}
    
    //public String QuoteNumber {get;set;}
    //public String AcctId {get;set;}
    //public String OUName {get;set;}

    public Set<String> BillToIds {get;set;}
    public Set<String> ShipToIds {get;set;}
    public Set<String> DeliverToIds {get;set;}

    public Boolean ALlGood {get;set;}

    public Boolean testFlipper {get;set;}
    public List<String> errors {get; set;}
    
    public Integer OffsetSize = 0;
    public Integer QueryLimit = 100;
    public Integer initialOffsetSize = 0;
    private Integer initialQueryLimit = 100;
    public List<QuoteLineWrapper> paginationQuoteLineWrapperList = new List<QuoteLineWrapper>();
    public Map<String,QuoteLineWrapper> paginationQuoteLineWrapperSet = new Map<String,QuoteLineWrapper>();
    public Integer CountTotalRecords{get;set;}
    public  Map<Id,QuoteLineWrapper> qlProductsMap = new Map<Id,QuoteLineWrapper>();
    public List<QuoteLineWrapper> tempQuoteLWList = new List<QuoteLineWrapper>();
    
    public List<Integer> pageNumbers {get; set;}
    Decimal totalPage = 0;
    
    private String sortDirection = 'ASC';
    private String sortExp = '';
    
    public Boolean prevDuplicate{get; set;}
    public Integer dupeCount = 0;
    
    
    private ApexPages.StandardController stdController;


    public class QuoteWrapper
    {
        public SBQQ__Quote__c relatedQuote {get; set;}
        public Boolean isQuoteValid {get; set;}
        public String QuoteStatus {get;set;}

        public QuoteWrapper(SBQQ__Quote__C quote, Boolean isValid, String status)
        { 
            this.relatedQuote = quote;
            this.isQuoteValid = isValid;
            this.QuoteStatus = status;
        }
    }
    
    public class QuoteLineWrapper
    {
        public SBQQ__QuoteLine__c relatedQuoteLine {get; set;}
        public Boolean isQuoteLineValid {get; set;}
        public String QuoteLineStatus {get;set;}
        public Boolean tempIncludeInOrder {get;set;}
      
        public QuoteLineWrapper(SBQQ__QuoteLine__C quoteline, Boolean isValid, String linestatus, Boolean tempIncludeInOrder)
        { 
           
            this.relatedQuoteLine = quoteline;
            this.isQuoteLineValid = isValid;
            this.QuoteLineStatus = linestatus;
            this.tempIncludeInOrder = tempIncludeInOrder;
           
            
        }
    }    
        
    public OrderConfirmationPageController(ApexPages.StandardController stdController) {
        
        this.quote = (SBQQ__Quote__c)stdController.getRecord();
        //quoteId = this.stdController.getRecord().Id;

        //this.quote = [SELECT Id, zqu__ZuoraAccountID__c, zqu__ZuoraSubscriptionID__c, zqu__Opportunity__c, zqu__Opportunity__r.Account.Id, zqu__SubscriptionType__c, zqu__Status__c, zqu__Currency__c, zqu__Customer_Acceptance_Date__c, zqu__StartDate__c FROM zqu__Quote__c WHERE id = :quoteId LIMIT 1];
        this.quote = getQuote(quote.id);
        //QuoteNumber = quote.Name;
        //AcctId = quote.SBQQ__Account__r.Oracle_Party_Id__c;
        //OUName = quote.Operating_Unit__c;

            
    }

    public void ValidateOrder() {

        errors = new List<String>();
        //quote = [select SBQQ__Account__r.Oracle_Party_Id__c from SBQQ__Quote__C where Id = :quote.id];
        system.debug('$$$$$$$$$$ quote - ' + quote);
        testFlipper = true;
        String outmessage = '';
        Boolean tempIncludeInOrder = false;
        prevDuplicate = false;

        Map<String, Customer_Relationship__x> CustRelMap = new Map<String, Customer_Relationship__x>();

        //first set ALlGood to true to display the sections when quote is validated.   This will be set to false whenever an error is found
        ALlGood = true;  //testing puposes.  Set default to true when validation code is completed


        //Pseudo Code:
        // 1 - Build a set of account ids to Bill to account id's - this will use the External Data Object whoich does not exist yet
        // 2 - Build a set of account ids to Ship to account id's - this will use the External Data Object whoich does not exist yet
        // 3 - Build a set of account ids to Deliver account id's - this will use the External Data Object whoich does not exist yet

        BillToIds = new Set<String>();
        ShipToIds = new Set<String>();
        DeliverToIds = new Set<String>();
        //:quote.SBQQ__Account__r.Oracle_Party_Id__c
        
        //if quote.SBQQ__Account__r.Oracle_Party_Id__c is null show error message

        //We need to add in the Org_id = from quote to this query.  First, must check to make sure Orgid is not null.  
        //quote.Operating_Unit__c  = Operating_Unit__c

        //check for null :quote.SBQQ__Account__r.Oracle_Party_Id__c here
        
        /*if(String.isBlank(quote.Bill_To_Account__c)){
             errors.add('The Quote is missing the Bill To Account and cannot be Confirmed.  Please edit the Quote and add the Bill To Account.');
             AllGood = false; 
        }
        if(String.isBlank(quote.BillTo_Site__c)){
             errors.add('The Quote is missing the Bill To Site and cannot be Confirmed.  Please edit the Quote and add the Bill To Site.');
             AllGood = false; 
        }
        if(String.isBlank(quote.Ship_To_Account__c)){
             errors.add('The Quote is missing the Ship To Account and cannot be Confirmed.  Please edit the Quote and add the Ship To Account.');
             AllGood = false; 
        }
        if(String.isBlank(quote.ShipTo_Site__c)){
             errors.add('The Quote is missing the Ship To Site and cannot be Confirmed.  Please edit the Quote and add the Ship To Site.');
             AllGood = false; 
        }*/

        if (String.isBlank(quote.Operating_Unit__c)) {
             /*
             for (Customer_Relationship__x CustRel : [select Oracle_Party_Account__r.id, Bill_To__c,Customer_Account_ID__c,Customer_Reciprocal_Flag__c,Operating_Unit__c,Related_Account__c,Relationship_ID__c,Relationship_Type__c,Ship_To__c,Status__c,Status_Code__c 
                                                        from Customer_Relationship__x where Related_Account__c = :quote.SBQQ__Account__r.Oracle_Party_Id__c AND Status__c = 'Active']) {
                //Bill To
                if (CustRel.Bill_To__c == 'Y') BillToIds.add(CustRel.Oracle_Party_Account__r.id);
                //Ship To
                if (CustRel.Ship_To__c == 'Y') ShipToIds.add(CustRel.ty_ty_Account__r.id);
                //Deliver To - need to verify this field
                if (CustRel.Ship_To__c == 'Y') DeliverToIds.add(CustRel.Oracle_Party_Account__r.id);
             }
             */
             errors.add('The Quote is Missing an Operating Unit and cannot be Confirmed.  Please edit the Quote and add the Operating Unit.');
             AllGood = false;
        } else if (String.isBlank(quote.SBQQ__Account__r.Oracle_Party_Id__c)) {
              errors.add('The Account on this Quote is missing an Oracle Party Id and cannot be Confirmed.  Please edit the Account and add the Oracle Party Id');
             AllGood = false;             
        }else {
            String partyId=quote.SBQQ__Account__r.Oracle_Party_Id__c;

            //Related_Oracle_Party_ID__c replaces Related_Party_ID__c
            //PartyId__c replaces Oracle_Party_Account__c
            //1st loop gather all of the PartyId__c and place into a Map <String, record> 1111111, custRelRecord
            //second loop is a query of accounts that include that party ID /// where Oracle_Party_ID__c IN: map.keyset()
            //Bill to and Ship to are now checkboxes, true false now
            Set<String> parentAccMapBill=new Set<String>();
            Set<String> parentAccMapShip=new Set<String>();
            Set<String> parentAccMapDeliver=new Set<String>();
            Set<String> masterAccString=new Set<String>();

            for (Customer_Relationship__x c : [select PartyId__c, Bill_To__c,Customer_Account_ID__c,Operating_Unit__c,Relationship_ID__c,Ship_To__c,Status__c,Status_Code__c 
                                                        from Customer_Relationship__x where (PartyId__c=:partyId or Related_Oracle_Party_ID__c = :partyId) AND Status__c = 'Active' AND Operating_Unit__c = :quote.Operating_Unit__c]) {
                CustRelMap.put(c.PartyId__c, c);
            }

           
            for (Account a : [Select Id, Name,Oracle_Party_Id__c from Account where Oracle_Party_Id__c in :CustRelMap.keyset()]) {
                //Bill To
                if (CustRelMap.get(a.Oracle_Party_Id__c).Bill_To__c == true) BillToIds.add(a.id);
                //Ship To
                if (CustRelMap.get(a.Oracle_Party_Id__c).Ship_To__c == true) ShipToIds.add(a.id);
                //Deliver To
                if (CustRelMap.get(a.Oracle_Party_Id__c).Ship_To__c == true) DeliverToIds.add(a.id);            
            }
           
             /*
            for (Account a : [Select Id, Name,Oracle_Party_Id__c from Account where Oracle_Party_Id__c in :CustRelMap.keyset()]) {
                //Bill To
                //if (CustRelMap.get(a.Oracle_Party_Id__c).Bill_To__c == true) BillToIds.add(a.id);

                if (CustRelMap.get(a.Oracle_Party_Id__c).Bill_To__c == true) parentAccMapBill.add(a.id);
                //Ship To
                if (CustRelMap.get(a.Oracle_Party_Id__c).Ship_To__c == true) parentAccMapShip.add(a.id);
                //Deliver To
                if (CustRelMap.get(a.Oracle_Party_Id__c).Ship_To__c == true) parentAccMapDeliver.add(a.id);           
            }

            masterAccString.addall(parentAccMapBill);
            masterAccString.addall(parentAccMapShip);
            masterAccString.addall(parentAccMapDeliver);

            for(Account acc:[Select id, ParentID, Name from Account where ParentID IN: masterAccString and RecordType.Name='Site']){
                if (parentAccMapBill.contains(acc.ParentID)) BillToIds.add(acc.id);
                if (parentAccMapShip.contains(acc.ParentID)) ShipToIds.add(acc.id);
                if (parentAccMapDeliver.contains(acc.ParentID)) DeliverToIds.add(acc.id);
            }
        */

            /*
             for (Customer_Relationship__x CustRel : [select Oracle_Party_Account__r.Id, Bill_To__c,Customer_Account_ID__c,Customer_Reciprocal_Flag__c,Operating_Unit__c,Related_Account__c,Relationship_ID__c,Relationship_Type__c,Ship_To__c,Status__c,Status_Code__c 
                                                        from Customer_Relationship__x where Related_Oracle_Party_ID__c = :partyId AND Status__c = 'Active' AND Operating_Unit__c = :quote.Operating_Unit__c]) {
                //Bill To
                if (CustRel.Bill_To__c == 'Y') BillToIds.add(CustRel.Oracle_Party_Account__r.id);
                //Ship To
                if (CustRel.Ship_To__c == 'Y') ShipToIds.add(CustRel.Oracle_Party_Account__r.id);
                //Deliver To - need to verify this field
                if (CustRel.Ship_To__c == 'Y') DeliverToIds.add(CustRel.Oracle_Party_Account__r.id);
             }
             */
        }


        system.debug('$$$$$$$$$$ BillToIds ' + BillToIds);
        system.debug('$$$$$$$$$$ ShipToIds ' + ShipToIds);

        // 4 - validate the Bill To, Ship To, and Deliver to accounts on the Quote is part of the sets from above
        // 5 - if quote is valid, no error messages
        // 6 - if any fields are invalid on quote - error message - list every error and set isValid to false in QuoteWrapper
        //      -  Query for all related QuoteLInes where 'Received_by_Integration__c' equals FALSE
        QuoteWrapperList = new List<QuoteWrapper>();
        //Validate Quote here
        if(String.isBlank(quote.BillTo_Site__c)){
            outmessage += 'Please add the Bill To Site on the Quote.</br>';
            testFlipper = false;
            AllGood = false;
    
        }
        if(String.isBlank(quote.ShipTo_Site__c)){
            outmessage += 'Please add the Ship To Site on the Quote.</br>';
            testFlipper = false;
            AllGood = false;    
        }
        if(String.isBlank(quote.Bill_To_Account__c)){
            outmessage += 'Please add the Bill To Account on the Quote.</br>';
            testFlipper = false;
            AllGood = false;    
        }else if (!BillToIds.contains(quote.Bill_To_Account__c) && quote.Bill_To_Account__c != quote.SBQQ__Account__c) {
            outmessage += 'The Bill To Account on the Quote does not match the Customer Relationship on the Account.</br>';
            testFlipper = false;
            AllGood = false;
        }
        if(String.isBlank(quote.Ship_To_Account__c)){
            outmessage += 'Please add the Ship To Account on the Quote.</br>';
            testFlipper = false;
            AllGood = false;    
        }else if (!ShipToIds.contains(quote.Ship_To_Account__c) && quote.Ship_To_Account__c != quote.SBQQ__Account__c) {
            outmessage += 'The Ship To Account on the Quote does not match the Customer Relationship on the Account.</br>';
            testFlipper = false;
            AllGood = false;
        }
        
        /*
        if (!DeliverToIds.contains(quote.Deliver_To_Account__c)) {
            outmessage += 'The Deliver To Account on the Quote does not match the Customer Relationship on the Account.</br>';
            testFlipper = false;
            AllGood = false;
        }
        */


system.debug('xxxxxxx '  + Allgood);

        /* Rich Varga Apps Associates */
        /* Check for oracle customer number */
        /* HD-4288 */
        if(String.isBlank(quote.SBQQ__Account__r.Oracle_Customer_Number__c)){
            outmessage += 'Account on the quote does not have an Oracle Customer Number. Contact CDQ through the CDQ Update Request action in the Account Profile</br>';
            testFlipper = false;
            AllGood = false; }

       /* Rich 
        Apps Associates */
        /* Check status and usage of Bill to ,  Ship to and Deliver to */
        /* HD-4288 */
        /* bill to and ship to sites should be checked */
        /* deliver to can be skipped if no entered */
        system.debug('deliver to site:'+quote.DeliverTo_Site__r.Active__c+ quote.DeliverTo_Site__c );
        if((!quote.DeliverTo_Site__r.Active__c) && (quote.DeliverTo_Site__c !=null))
        {
            outmessage += 'The Deliver to Site on the Quote not active</br>';
            testFlipper = false;
            AllGood = false; }
            
            
          if((!quote.DeliverTo_Site__r.Deliver_To__c)  && (quote.DeliverTo_Site__c !=null)                    ){
            outmessage += 'The Deliver to Site on the Quote does not have active Deliver Site usage</br>';
            testFlipper = false;
            AllGood = false; }
            
            
          if((!quote.BillTo_Site__r.Active__c)){
            outmessage += 'The Bill to Site on the Quote not active</br>';
            testFlipper = false;
            AllGood = false; }
            
            
          if((!quote.BillTo_Site__r.Bill_To__c)){
            outmessage += 'The Bill to Site on the Quote does not have active Bill Site usage</br>';
            testFlipper = false;
            AllGood = false; }
            
            if((!quote.ShipTo_Site__r.Active__c)){
            outmessage += 'The Ship to Site on the Quote not active</br>';
            testFlipper = false;
            AllGood = false; }
            
            
          if((!quote.ShipTo_Site__r.Ship_To__c)){
            outmessage += 'The Ship to Site on the Quote does not have active Ship Site usage</br>';
            testFlipper = false;
            AllGood = false; }


        if (AllGood == false) errors.add('Please review the Quote Status Message(s) below.');

        QuoteWrapperList.add(new QuoteWrapper(quote,testFlipper,outmessage));


        // 7 - validate the Bill To, Ship To, and Deliver to accounts on each Quote Line is part of the sets from above
        // 8 - if quote line are valid, no error messages
        // 9 - if any fields are invalid on any quote line - error message and link to quote line - list every error and set isValid to false in QuoteLineWrapper
        // 10 - If everything is valid, then allow user to check the 'Include_In_Order__c' checkbox and save the entry on the quote lines
        //          - also a Save and Calcel button to just save the updates to the Quote Lines and exit Confirmation
        // 11 - Also, if all data is valid, show a button labeled 'Create Order'.  When pressed update the 'Create_Order__c' field to TRUE on the Quote and all updates to Quote Line saved.
        // Notes : 
        // only allow user to see and click 'Create Order' when all quotes and quote lines pass validation checks
        // only allow user to see and update the 'Include_in_Order__c' checkbox on each quote line if the quote and all quote lines pass validation checks
        // only show quote lines on OrderConfirmationPage if the 'Received_by_Integration__c' equals false - 
        //            - don't validate quote lines or allow for user to check 'Include_in_Order__c' if 'Received_by_Integration__c' equals true

        List<SBQQ__QuoteLine__c> quoteLines = new List<SBQQ__QuoteLine__c>();
        quoteLines=getQuoteLines(quote.id);
      /* Rich Varga Apps Associates */
       /* HD-4288 */
       /* Error string is being reset in quote line loop */
       /*outmessage = '';*/
       
        
        System.debug('quoteLine:'+quoteLines);
        //paginationQuoteLineWrapperSet = quoteLines;
        
       
        
        QuoteLineWrapperList = new List<QuoteLineWrapper>();
        for (SBQQ__QuoteLine__c line : quoteLines) {
            /* Rich Varga Apps Associates */
            /* HD-4288 */
            
             outmessage = '';
             
            //paginationQuoteLineWrapperSet.add(line);
                //Display header values where null in UI but keep actual population as part of trigger.  These are not save in this controller
            if (line.ShipTo_Site__c==null) line.ShipTo_Site__c = line.SBQQ__Quote__r.ShipTo_Site__c;
            if (line.DeliverTo_Site__c==null) line.DeliverTo_Site__c = line.SBQQ__Quote__r.DeliverTo_Site__c;
            if (line.BillTo_Site__c==null) line.BillTo_Site__c = line.SBQQ__Quote__r.BillTo_Site__c;             
            if (line.Ship_To_Account__c==null) line.Ship_To_Account__c = line.SBQQ__Quote__r.Ship_To_Account__c;
            if (line.Deliver_To_Account__c==null) line.Deliver_To_Account__c = line.SBQQ__Quote__r.Deliver_To_Account__c;
            if (line.Bill_To_Account__c==null) line.Bill_To_Account__c = line.SBQQ__Quote__r.Bill_To_Account__c;
            if (String.isBlank(line.FOB__c)) line.FOB__c = line.SBQQ__Quote__r.FOB__c;
            if (line.Ship_Date__c==null) line.Ship_Date__c = line.SBQQ__Quote__r.Ship_Date__c;
            if (line.Requested_Date__c==null) line.Requested_Date__c = line.SBQQ__Quote__r.Requested_Date__c;
            //if (String.isBlank(line.Payment_Terms_Freight__c)) line.Payment_Terms_Freight__c = line.SBQQ__Quote__r.Payment_Terms_Freight__c;
            if(String.isBlank(line.Payment_Terms__c)) line.Payment_Terms__c = line.SBQQ__Quote__r.SBQQ__PaymentTerms__c;
            if (String.isBlank(line.Shipping_Method_Code__c)) line.Shipping_Method_Code__c = line.SBQQ__Quote__r.Shipping_Method_Code__c;
            if(line.Sales_Rep__c==null) line.Sales_Rep__c=line.SBQQ__Quote__r.SBQQ__SalesRep__c;
            //validate the quote line here
            if (!BillToIds.contains(line.Bill_To_Account__c) && line.Bill_To_Account__c != line.SBQQ__Quote__r.SBQQ__Account__c) {
                outmessage = 'The Bill To Account on the Quote Line does not match the Customer Relationship on the Account.</br>';
                testFlipper = false;
                AllGood = false;
            }
            if (!ShipToIds.contains(line.Ship_To_Account__c) && line.Ship_To_Account__c != line.SBQQ__Quote__r.SBQQ__Account__c) {
                outmessage += 'The Ship To Account on the Quote Line does not match the Customer Relationship on the Account.</br>';
                testFlipper = false;
                AllGood = false;
            }
            if (!line.Quotable__c) {
                outmessage += 'The product on the Quote Line is no longer quotable.</br>';
                testFlipper = false;
                AllGood = false;
            }
            /*
            if (!DeliverToIds.contains(line.Deliver_To_Account__c)) {
                outmessage += 'The Deliver To Account on the Quote Line does not match the Customer Relationship on the Account.</br>';
                testFlipper = false;
                AllGood = false;
            }
            */
            
            
                       /* Rich Varga  Apps Assoicates */
                       /* HD-4288 */
                       /* Validations for Bill, Ship and Deliver */
                       
                       
                               
           if(!line.BillTo_Site__r.Active__c)
               { outmessage  += 'The Bill to Site on the Quote Line is not active.</br>';
                testFlipper = false;
                AllGood = false;
                               }
             
               
                 if(!line.BillTo_Site__r.Bill_To__c)
               { outmessage += 'The Bill to Site on the Quote Line does not have active Bill Site usage.</br>';
                testFlipper = false;
                AllGood = false;
               }
             
               
                if(!line.Shipto_Site__r.Active__c)
               { outmessage += 'The Ship to Site on the Quote Line is not active.</br>';
                testFlipper = false;
                AllGood = false;
               }
              
               
               
                 if(!line.Shipto_Site__r.Ship_To__c)
               { outmessage += 'The Ship to Site on the Quote Line does not have active Ship Site usage.</br>';
                testFlipper = false;
                AllGood = false;
               }
               
                 if((!line.Deliverto_Site__r.Active__c)   && (line.DeliverTo_Site__c !=null))
               { outmessage += 'The Deliver to Site on the Quote Line is not active.</br>';
                testFlipper = false;
                AllGood = false;
               }
              
               
               
                 if ((!line.Deliverto_Site__r.Deliver_To__c)  && (line.DeliverTo_Site__c !=null))
               { outmessage += 'The Deliver to Site the Quote Line does not have active Deliver Site Usage.</br>';
                testFlipper = false;
                AllGood = false;
               }
               
               
           
                        
               
               
               

            //tempIncludeInOrder = line.Include_In_Order__c;

            //add to the wrapper list
            //QuoteLineWrapperList.add(new QuoteLineWrapper(line,testFlipper,outmessage,tempIncludeInOrder));
            //paginationQuoteLineWrapperList.add(new QuoteLineWrapper(line,testFlipper,outmessage,tempIncludeInOrder));
            System.debug('QL #:'+line);
            paginationQuoteLineWrapperSet.put(line.Name,new QuoteLineWrapper(line,testFlipper,outmessage,tempIncludeInOrder));
            System.debug('yo yo:'+paginationQuoteLineWrapperSet);
            
            qlProductsMap.put(line.Id, new QuoteLineWrapper(line,testFlipper,outmessage,tempIncludeInOrder));
            System.debug('prevDuplicate:'+dupeCount);
                      
        }        
        //alert user there are issues with Quote Lines
        if (AllGood == false) errors.add('Please review the Quote Line Status Message(s) below.');
        
        
    }
    
    //if (AllGood == false) errors.add('Please review the Quote Line Status Message(s).');

    public List<QuoteWrapper> getQuoteWrapper() {
        return QuoteWrapperList;
    }

    public List<QuoteLineWrapper> getQuoteLineWrapper() {
    
        List<QuoteLineWrapper> tempQuoteLW = new List<QuoteLineWrapper>();
        pageNumbers = new List<Integer>();
        Set<QuoteLineWrapper> QLWList = new Set<QuoteLineWrapper>();
        //string sortFullExp = sortExpression  + ' ' + sortDirection +',SBQQ__Number__c';
        
        //QLWSet.addAll(qlProductsMap.values());
        system.debug('map values:'+qlProductsMap.values());
        if(tempQuoteLWList == null || tempQuoteLWList.size() > 0)
            paginationQuoteLineWrapperList = tempQuoteLWList;
        else
            paginationQuoteLineWrapperList = qlProductsMap.values();    
        //System.debug('QLWSet:'+qlProductsMap.values());
        
        /*for(SBQQ__QuoteLine__c ql : paginationQuoteLineWrapperSet){
            for(QuoteLineWrapper qlw : qlProductsMap.values()){
            if(ql.SBQQ__Number__c == qlw.relatedQuoteLine.SBQQ__Number__c)    
                paginationQuoteLineWrapperList.add(qlw);    
            }
        }*/
        
        CountTotalRecords = paginationQuoteLineWrapperList.size();
        
        if(CountTotalRecords > 0)
        totalPage = (Decimal.valueOf(CountTotalRecords)/Decimal.valueOf(initialQueryLimit)).round(System.RoundingMode.CEILING);
        
        for(Integer i = 1; i <= Math.round(totalPage) ;i++)
            pageNumbers.add(i);
            //QuoteLineWrapperList.clear();
        
        System.debug('TotalPage:'+totalPage);
        //System.debug('QuoteLineWrapper size:'+QuoteLineWrapperList.size());    
        System.debug('pagination size:'+paginationQuoteLineWrapperList.size());
        System.debug('OffsetSize:'+OffsetSize);
        System.debug('QueryLimit:'+QueryLimit);
        System.debug('CountTotalRecords:'+CountTotalRecords);
        System.debug('pageNumbers:'+pageNumbers);
        System.debug('totalPage:'+totalPage.round(System.RoundingMode.CEILING));
        
        if(paginationQuoteLineWrapperList.size() > 0){
            if(CountTotalRecords < QueryLimit){
                QueryLimit = CountTotalRecords;
                initialQueryLimit =  CountTotalRecords;
            }
            
            if(QueryLimit > paginationQuoteLineWrapperList.size())
                QueryLimit = paginationQuoteLineWrapperList.size();
            
            for(Integer i=OffsetSize; i<QueryLimit; i++){
                System.debug('paginationQuoteLineWrapperList:'+paginationQuoteLineWrapperList[i]);
                //System.debug('0 size:'+paginationQuoteLineWrapperList[i]);
                tempQuoteLW.add(paginationQuoteLineWrapperList[i]);    
            }
        }
        
        
        
        
        QuoteLineWrapperList = new List<QuoteLineWrapper>();
        QuoteLineWrapperList = tempQuoteLW;
        System.debug('final size:'+tempQuoteLW.size());         
    
        return QuoteLineWrapperList;
    }
        
    public List<Schema.FieldSetMember> getQuoteFields() {
        return SObjectType.SBQQ__Quote__c.FieldSets.OrderConfirmation.getFields();
    }
    
    public List<Schema.FieldSetMember> getQuoteInputFields() {
        return SObjectType.SBQQ__Quote__c.FieldSets.Order_Confirmation_Input.getFields();
    }
    
    
    
    private SBQQ__Quote__c getQuote(String quoteid) {
        String query = 'SELECT ';
        for(Schema.FieldSetMember f : this.getQuoteFields()) {
            query += f.getFieldPath() + ', ';
        }
        for(Schema.FieldSetMember f : this.getQuoteInputFields()) {
            query += f.getFieldPath() + ', ';
        }
         
        
        
        
        /* Rich Varga Apps Associates */
        /* added oracle customer number */
        /* added billto, shipto, deliverto fields */
        /* HD-4288 */
        query += 'Id,SBQQ__Account__r.Oracle_Party_Id__c,Bill_To_Account__c,SBQQ__Account__r.Oracle_Customer_Number__c,BillTo_Site__r.Active__c,BillTo_Site__r.Bill_To__c,ShipTo_Site__r.Active__c,ShipTo_Site__r.Ship_To__c, DeliverTo_Site__r.Active__c, Deliverto_Site__r.Deliver_To__c,Ship_To_Account__c,Deliver_To_Account__c,Order_Type__c FROM SBQQ__Quote__c where id = :quoteid LIMIT 1';
        return Database.query(query);
    }   

    public List<Schema.FieldSetMember> getQuoteLineFields() {
        return SObjectType.SBQQ__QuoteLine__c.FieldSets.OrderConfirmation.getFields();
    }
    
    private List<SBQQ__QuoteLine__c> getQuoteLines(String qID) {
    
        string sortFullExp = sortExpression  + ' ' + sortDirection+',SBQQ__Number__c';
        
        String query = 'SELECT ';
        for(Schema.FieldSetMember f : this.getQuoteLineFields()) {
            query += f.getFieldPath() + ', ';
        }
        /* Rich Varga Apps Asspciates */
        /* HD-4288 */
        /* Updated by Krishna Prasad to --  Update Quote Order Form (US-0003896)
        Added logic to retrieve 'Quantity_to_Ship__c' field data from Object */
        if(sortExpression == null || sortExpression == '')
        query += 'Quantity_to_Ship__c,Ready_for_Integration__c, Processed_By_Integration__c, Requested_Date__c, Deliverto_Site__c, Deliverto_Site__r.Name ,ShipTo_Site__r.Name ,ShipTo_Site__c, BillTo_Site__c, BillTo_Site__r.Name, BillTo_Site__r.Active__c,BillTo_Site__r.Bill_To__c,ShipTo_Site__r.Active__c,ShipTo_Site__r.Ship_To__c, DeliverTo_Site__r.Active__c, Deliverto_Site__r.Deliver_To__c, id, Name, Quotable__c,SBQQ__Quote__r.ShipTo_Site__c,SBQQ__Quote__r.DeliverTo_Site__c,SBQQ__Quote__r.BillTo_Site__c,Ship_To_Account__c,SBQQ__Quote__r.Ship_To_Account__c,Deliver_To_Account__c,SBQQ__Quote__r.Deliver_To_Account__c,Bill_To_Account__c,SBQQ__Quote__r.Bill_To_Account__c,SBQQ__Quote__r.FOB__c,SBQQ__Quote__r.Ship_Date__c,SBQQ__Quote__r.SBQQ__Account__c,SBQQ__Quote__r.Requested_Date__c,SBQQ__Quote__r.Payment_Terms_Freight__c,SBQQ__Quote__r.Shipping_Method_Code__c,Sales_Rep__c, SBQQ__Quote__r.SBQQ__SalesRep__c,Payment_Terms__c,SBQQ__Quote__r.SBQQ__PaymentTerms__c,SBQQ__Quote__c,SBQQ__RequiredBy__c,Include_In_Order__c,Received_By_Integration__c, Order_Line_Type__c, Order_Type__c, FOB__c, Ship_Date__c FROM SBQQ__QuoteLine__c where Received_by_Integration__c = false AND SBQQ__Quote__c = \'' + qID + '\'' + ' ORDER BY SBQQ__Number__c';        
        else if(sortExpression != null || sortExpression != '')
        query += 'Quantity_to_Ship__c,Ready_for_Integration__c, Processed_By_Integration__c, Requested_Date__c, Deliverto_Site__c, Deliverto_Site__r.Name ,ShipTo_Site__r.Name ,ShipTo_Site__c, BillTo_Site__c, BillTo_Site__r.Name, BillTo_Site__r.Active__c,BillTo_Site__r.Bill_To__c,ShipTo_Site__r.Active__c,ShipTo_Site__r.Ship_To__c, DeliverTo_Site__r.Active__c, Deliverto_Site__r.Deliver_To__c, id, Name, Quotable__c,SBQQ__Quote__r.ShipTo_Site__c,SBQQ__Quote__r.DeliverTo_Site__c,SBQQ__Quote__r.BillTo_Site__c,Ship_To_Account__c,SBQQ__Quote__r.Ship_To_Account__c,Deliver_To_Account__c,SBQQ__Quote__r.Deliver_To_Account__c,Bill_To_Account__c,SBQQ__Quote__r.Bill_To_Account__c,SBQQ__Quote__r.FOB__c,SBQQ__Quote__r.Ship_Date__c,SBQQ__Quote__r.SBQQ__Account__c,SBQQ__Quote__r.Requested_Date__c,SBQQ__Quote__r.Payment_Terms_Freight__c,SBQQ__Quote__r.Shipping_Method_Code__c,Sales_Rep__c, SBQQ__Quote__r.SBQQ__SalesRep__c,Payment_Terms__c,SBQQ__Quote__r.SBQQ__PaymentTerms__c,SBQQ__Quote__c,SBQQ__RequiredBy__c,Include_In_Order__c,Received_By_Integration__c, Order_Line_Type__c, Order_Type__c, FOB__c, Ship_Date__c FROM SBQQ__QuoteLine__c where Received_by_Integration__c = false AND SBQQ__Quote__c = \'' + qID + '\'' + ' ORDER BY '+sortFullExp;        
        //String soql='Select ' + richTextField + ' FROM ' + objectname + ' where id=\'' + parId +'\'';
        
        System.debug('Final Query:'+query);
        
        //Prevent successive Order creation
        dupeCount = [SELECT Count() FROM SBQQ__QuoteLine__c where Received_by_Integration__c = True AND Processed_By_Integration__c = False AND Include_In_Order__c = True AND SBQQ__Product__r.CPQ_Bundle__c = false AND SBQQ__Quote__c = :qID];
        
        if(dupeCount > 0)
            prevDuplicate = true;
            
        System.debug('dupe:'+ prevDuplicate);    
        
        return Database.query(query);
    }   

   public PageReference CreateOrder() {
        //commit the Quote Line updats and return the user back to the Quote...
       
        //future call to avoid timeout error

        List<SBQQ__QuoteLine__c> upsertQLList = new List<SBQQ__QuoteLine__c>();      
       
        for (QuoteLineWrapper qlw : qlProductsMap.values()) {
            //only update Quote Line where the Include in Order Checkbox has been changed by the user
            if (qlw.tempIncludeInOrder != qlw.relatedQuoteLine.Include_In_Order__c) {
                qlw.relatedQuoteLine.Include_In_Order__c = qlw.tempIncludeInOrder;
                upsertQLList.add(qlw.relatedQuoteLine);
            }
            /*Updated by Krishna Prasad to -- Update Quote Order Form (US-0003896)
             Update Quoteline to save Quantity_to_ship__c when changed */
            else{
                upsertQLList.add(qlw.relatedQuoteLine);
            }
        }
        system.debug('$$$$$$$$$$ upsertQLList' + upsertQLList);
        try{
            upsert upsertQLList;
        }catch(DmlException d){
             ApexPages.addMessages(d);//new ApexPages.message(ApexPages.severity.ERROR,d.getMessage()));
             return null;
        }

        //update the Create Order Flag on the quote
        List<SBQQ__Quote__c> upsertQList = new List<SBQQ__Quote__c>();      
       
        for (QuoteWrapper ql : QuoteWrapperList) {
            ql.RelatedQuote.Order_Created_By__c=UserInfo.getUserId();
            ql.RelatedQuote.Create_Order__c  = true;
            ql.RelatedQuote.Operating_Unit__c = quote.Operating_Unit__c;
            ql.RelatedQuote.Order_Type__c = quote.Order_Type__c;
            ql.RelatedQuote.PO_Number__c = quote.PO_Number__c;
            ql.RelatedQuote.Shipping_Method_Code__c = quote.Shipping_Method_Code__c;
            upsertQList.add(ql.relatedQuote);
        }
        system.debug('$$$$$$$$$$ upsertQList' + upsertQList);
        try{
            upsert upsertQList;
            PageReference pr = new PageReference('/'+quote.id);
            pr.setRedirect(true); 
            return pr; 
        }catch(DmlException d){
             ApexPages.addMessages(d);//(new ApexPages.message(ApexPages.severity.ERROR,d.getMessage()));
             return null;
        }
    }

   public PageReference SaveAndCancel() {

        //commit the Quote Line updats and return the user back to the Quote...
       
        List<SBQQ__QuoteLine__c> upsertList = new List<SBQQ__QuoteLine__c>();      
       
        for (QuoteLineWrapper qlw : qlProductsMap.values()) {
            //only update Quote Line where the Include in Order Checkbox has been changed by the user
            /*  if (qlw.tempIncludeInOrder != qlw.relatedQuoteLine.Include_In_Order__c) {
                qlw.relatedQuoteLine.Include_In_Order__c = qlw.tempIncludeInOrder;
                upsertList.add(qlw.relatedQuoteLine);                    
            }*/
            /*Updated by Krishna Prasad to -- Update Quote Order Form (US-0003896)
            update Quoteline object to reflect changes after 'save'*/
            if (qlw.tempIncludeInOrder != qlw.relatedQuoteLine.Include_In_Order__c) {
                qlw.relatedQuoteLine.Include_In_Order__c = qlw.tempIncludeInOrder;
                               
            }
             upsertList.add(qlw.relatedQuoteLine);    
            
        }
        system.debug('$$$$$$$$$$ upsertList' + upsertList);
        
        List<SBQQ__Quote__c> upsertQList = new List<SBQQ__Quote__c>();      
       
        for (QuoteWrapper ql : QuoteWrapperList) {
            ql.RelatedQuote.Operating_Unit__c = quote.Operating_Unit__c;
            ql.RelatedQuote.Order_Type__c = quote.Order_Type__c;
            ql.RelatedQuote.PO_Number__c = quote.PO_Number__c;
            ql.RelatedQuote.Shipping_Method_Code__c = quote.Shipping_Method_Code__c;
            upsertQList.add(ql.relatedQuote);
        }
        
        try{
            upsert upsertQList;
            upsert upsertList;
            
            PageReference pr = new PageReference('/'+quote.id);
            pr.setRedirect(true); 
            return pr; 
        }catch(DmlException d){
             ApexPages.addMessages(d);//(new ApexPages.message(ApexPages.severity.ERROR,d.getMessage()));
             return null;
        }
        
    }
   public PageReference CancelAndClose() {
        PageReference pr = new PageReference('/'+quote.id);
        pr.setRedirect(true); 
        return pr;
    }
    
    //Test Method
    public PageReference testSorting(){
    
        List<SBQQ__QuoteLine__c> testQL = new List<SBQQ__QuoteLine__c>();
        List<QuoteLineWrapper> tempQuoteLW = new List<QuoteLineWrapper>();
        
        testQL = getQuoteLines(quote.id);
        System.debug('Hwllo WOrld:'+testQL);
        
        for(SBQQ__QuoteLine__c ql : testQL)
        {
            System.debug('yummy:'+ql.Name);
            tempQuoteLW.add(qlProductsMap.get(ql.Id));    
        }
        
        tempQuoteLWList = tempQuoteLW;
        
        System.debug('tempQuoteLW:'+tempQuoteLW);
    
        return null;
    }
    
    //Method for maintaining the state of the checkbox in VF page
    public void setSelected(){
    
        Id oi = (Id)System.currentPagereference().getParameters().get('QuoteLine');
        String selected = System.currentPagereference().getParameters().get('Selected');
        
        if(QuoteLineWrapperList != null)
        for(QuoteLineWrapper qlw : QuoteLineWrapperList)
            if(qlw.relatedQuoteLine.Id == oi)
                qlProductsMap.get(oi).tempIncludeInOrder = qlw.tempIncludeInOrder;
            
    }
    
    //Pagination methods for Next Link
    public PageReference Next() {
        
        Integer tempOffsetSize = OffsetSize;
        Integer tempQueryLimit = QueryLimit;
      
        OffsetSize = tempOffsetSize + initialQueryLimit;
        
        if(OffsetSize == CountTotalRecords || OffsetSize > CountTotalRecords)
            OffsetSize = CountTotalRecords - tempOffsetSize;
        
        QueryLimit += initialQueryLimit;
       
        if(QueryLimit > CountTotalRecords)
            QueryLimit = CountTotalRecords;
        
        System.debug('OffsetSize:'+OffsetSize);
        System.debug('QueryLimit:'+QueryLimit);
              
        return null;
    }
    
    //Pagination method for Previous Link
    public PageReference Previous() {
        
        Integer tempOffsetSize = OffsetSize;
        Integer tempQueryLimit = QueryLimit;
        
        OffsetSize = tempOffsetSize - initialQueryLimit;
        
        if(QueryLimit == CountTotalRecords)
            QueryLimit = OffsetSize + initialQueryLimit;
        else
            QueryLimit -= initialQueryLimit;
        
        if(QueryLimit < initialQueryLimit)
            QueryLimit = initialQueryLimit;
        
        if(OffsetSize < initialOffsetSize)
            OffsetSize = initialOffsetSize; 
        
        
                
        System.debug('OffsetSize:'+OffsetSize);
        System.debug('QueryLimit:'+QueryLimit);
        System.debug('CountTotalRecords:'+CountTotalRecords); 
              
        return null;
        
    }
    
    //Number Pagination
    public PageReference noPagination(){
        Integer pgNo = 0;
        
        if(System.currentPagereference().getParameters().get('PageNumber') != null)
            pgNo = Integer.valueOf(System.currentPagereference().getParameters().get('PageNumber'));
        
        System.debug('pageNumber:'+pgNo);
        
        Integer tempOffsetSize = OffsetSize;
        Integer tempQueryLimit = QueryLimit;
        
        
        QueryLimit = initialQueryLimit * pgNo;
        OffsetSize = QueryLimit - initialQueryLimit;
        
        if(QueryLimit > CountTotalRecords)
            QueryLimit = CountTotalRecords;
        
        System.debug('QueryLimit:'+QueryLimit);
        System.debug('OffsetSize:'+OffsetSize); 
        
        
        return null;
    }
    
     //Method for rendering Previous Link
    public Boolean getDisablePrevious(){
        if(OffsetSize>0){
            return true;
        }
        else return false;
    }

    //Method for rendering Next Link
    public Boolean getDisableNext() {
        if (QueryLimit == countTotalRecords){
            return false;
        }
        else return true;
    } 
    
    //Sorting methods
    public String sortExpression
       {
         get
         {
            return sortExp;
         }
         set
         {
           //if the column is clicked on then switch between Ascending and Descending modes
           sortExp = apexpages.currentpage().getparameters().get('sortExp');
           if (value == sortExp)
             sortDirection = (sortDirection == 'ASC')? 'DESC' : 'ASC';
           else
             sortDirection = 'ASC';
           sortExp = value;
         }
       }

     public String getSortDirection()
     {
        //if not column is selected 
        if (sortExpression == null || sortExpression == '')
          return 'ASC';
        else
         return sortDirection;
     }
    
     public void setSortDirection(String value)
     {  
       sortDirection = value;
     }
     //RMendoza - Created new method to set Quote Line Order Type from Quote header
     public void setOrderType() {     
        //List<SBQQ__QuoteLine__c> upsertList = new List<SBQQ__QuoteLine__c>();      

        for (QuoteLineWrapper qlw : qlProductsMap.values()) {
            if (quote.Order_Type__c != null){
                qlw.relatedQuoteLine.Order_Type__c = quote.Order_Type__c;
                //upsertList.add(qlw.relatedQuoteLine);
            }                 
        }
        /*try{
            upsert upsertList;
            return null;
        }
        catch(DmlException d){
            ApexPages.addMessages(d);//(new ApexPages.message(ApexPages.severity.ERROR,d.getMessage()));
            return null;
        }*/
        
    }          
        
}