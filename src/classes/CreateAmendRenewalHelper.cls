/*---------------------------------------------------------------------------------------------------------------------------------------------
Author:     N/A
Description:  Helper class used for Amendments/Renewals

Test Class:

History:
<Date>      <Authors Name>    <Brief Description of Change>
02/16/2017   Ronald Mendoza   US-0002197 - Update Contract Amendment Logic
03/09/2017   Ronald Mendoza   US-0002196 - Update Contract Renewal Logic
07/26/2017   Kent Smith       Updating 'Committed_Quantity__c' spelling
07/28/2017   Ronald Mendoza   US-0003142 - Added Logic to Include Required By Agreed Price/Quote Line Mapping
08/15/2017   Ronald Mendoza   US-0003269 - Updated code to set the correct end date
9/5/2017     Ronald Mendoza   US-0003343 Added Original Number of Tests and Original Price Per Test
------------------------------------------------------------------------------------------------------------------------------------------------*/
public with sharing class CreateAmendRenewalHelper {

    public static Id opptyRecordTypeId;

    public CreateAmendRenewalHelper() {
        
    }
    public static Map<String, Opportunity> FindOpp(List<Contract> cons){
        //search opp based on SBQQ__RenewedContract__c
        Set<string> conIds = new Set<string>();
        Map<String, Opportunity> map_returnOppConId = new Map<String, Opportunity>();
        for(Contract lp_cons : cons)
        {
            conIds.add(lp_cons.Id);
        }
        for(Opportunity lst_Opp : [SELECT Id, SBQQ__RenewedContract__c FROM Opportunity WHERE SBQQ__RenewedContract__c IN : conIds])
        {
            map_returnOppConId.put(lst_Opp.SBQQ__RenewedContract__c, lst_Opp);
        }
        return map_returnOppConId;
    }
    public static Opportunity CreateOpp(Contract contract, String opptype){

        Contract currentContract = contract;
        Opportunity newOpp = new Opportunity();
        newOpp.Name = opptype+'_'+currentContract.ContractNumber +'_'+currentContract.Account.Name;
        //Initialize BSH and Surgical Record Types from Custom Settings
        BSH_Opportunity_Record_Type_IDs__c bshRecordTypes = BSH_Opportunity_Record_Type_IDs__c.getOrgDefaults();
        Surgical_Opportunity_Record_Type_IDs__c surgicalRecordTypes = Surgical_Opportunity_Record_Type_IDs__c.getOrgDefaults();
        Diagnostic_Opportunity_Record_Type_IDs__c diagnosticRecordTypes = Diagnostic_Opportunity_Record_Type_IDs__c.getOrgDefaults();
        newOpp.StageName = 'Action';

        //US-0002197 - Adding record type id based on the contract's previous oppty
        if (currentContract.SBQQ__Opportunity__r.Opportunity_RecordType__c != NULL){
            Id recordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get(currentContract.SBQQ__Opportunity__r.Opportunity_RecordType__c).getRecordTypeId();
            Id finalOpptyRecordType = recordTypeId;
            //If Previous Opportunity has a BSH Record Type revert the Record Type back to Open Opportunity
            if(recordTypeId == bshRecordTypes.Read_Only_Opportunity_B_SH_Sales__c)
                finalOpptyRecordType = bshRecordTypes.Opportunity_BSH_Sales_Oppty__c;
            else if(recordTypeId == bshRecordTypes.Read_Only_Opportunity_B_SH_Mammopad__c)
                finalOpptyRecordType = bshRecordTypes.Opportunity_B_SH_Mammopad_Oppty__c;
            else if(recordTypeId == bshRecordTypes.Read_Only_Opportunity_B_SH_Service__c)
                finalOpptyRecordType = bshRecordTypes.Opportunity_B_SH_Service_Oppty__c;
            else if(recordTypeId == diagnosticRecordTypes.Diagnostic_Lab_Open_Opportunity__c)
                newOpp.StageName = 'Negotiate';

            newOpp.RecordTypeId = finalOpptyRecordType;
        }
        else{
            //If no Opportunity is associated with the Contract then Set the Record Type based on User Profile
            IF(currentContract.Owner.Profile.Name.Contains('B&SH Sales'))
                newOpp.RecordTypeId = bshRecordTypes.Opportunity_BSH_Sales_Oppty__c;
            ELSE IF(currentContract.Owner.Profile.Name.Contains('B&SH Service'))
                newOpp.RecordTypeId = bshRecordTypes.Opportunity_B_SH_Service_Oppty__c;
            ELSE IF(currentContract.Owner.Profile.Name.Contains('B&SH'))
                newOpp.RecordTypeId = bshRecordTypes.Opportunity_BSH_Sales_Oppty__c;
            ELSE IF(currentContract.Owner.Profile.Name.Contains('Surgical'))
                newOpp.RecordTypeId = surgicalRecordTypes.Surgical_Open_Opportunity__c;
            ELSE IF(currentContract.Owner.Profile.Name.Contains('Diagnostics Lab Sales User')){
                newOpp.RecordTypeId = diagnosticRecordTypes.Diagnostic_Lab_Open_Opportunity__c;
                newOpp.StageName = 'Negotiate';
            }
            ELSE IF(currentContract.Owner.Profile.Name.Contains('Diagnostics Perinatal Sales User'))
                newOpp.RecordTypeId = diagnosticRecordTypes.Diagnostic_Perinatal_Open_Opportunity__c;
            ELSE IF(currentContract.Owner.Profile.Name.Contains('Diagnostics Physician Sales User'))
                newOpp.RecordTypeId = diagnosticRecordTypes.Diagnostic_Physician_Open_Opportunity__c;
        }

        if(opptype == 'Amendment')
        {
            newOpp.SBQQ__AmendedContract__c = currentContract.Id;
        }
        else if(opptype == 'Renewal')
        {
            newOpp.SBQQ__RenewedContract__c = currentContract.Id;
            newOpp.Renewal_Contract_End_Date__c = currentContract.Contract_End_Date__c;
            
            if(newOpp.RecordTypeId == diagnosticRecordTypes.Diagnostic_Lab_Open_Opportunity__c)
                newOpp.Revenue_Class__c = 'Contract Renewal'; //Set Revenue Class to renewal DE 398
        }
       
        newOpp.Type = 'Existing Business';
        newOpp.Sales_Opp_Type__c = opptype;
        newOpp.AccountId = contract.AccountId;
        newOpp.Pricebook2Id = currentContract.SBQQ__Opportunity__r.Pricebook2Id;
        
        //newOpp.StageName = 'Action';
        newOpp.ForecastCategoryName = 'Expected';
        newOpp.Probability = 75;
        newOpp.CloseDate = System.today().addDays(5);
        
        opptyRecordTypeId = newOpp.RecordTypeId;
        
        System.debug('OpptyRecordTypeId:'+opptyRecordTypeId);
        insert newOpp; 
        return newOpp;
    }
    public static String CreateQuote(Opportunity opp)
    {
        SBQQ__Quote__c quote=new SBQQ__Quote__c();
        Contract amendedContract = new Contract();
        Contract renewedContract = new Contract();
        quote.SBQQ__Account__c=opp.AccountId;
        quote.SBQQ__Opportunity2__c=opp.Id;
        quote.SBQQ__PriceBook__c=opp.Pricebook2Id; //?? where do i get the price book from??
        quote.SBQQ__Primary__c = true;
        quote.Show_Tax__c = false;
        quote.SBQQ__StartDate__c = opp.Renewal_Contract_End_Date__c==null?system.today():opp.Renewal_Contract_End_Date__c.addDays(1);
        quote.SBQQ__SubscriptionTerm__c = 12;
        List<Customer_Eligible_Contract__c> newQuoteCECsList = new List<Customer_Eligible_Contract__c>();
        Diagnostic_Opportunity_Record_Type_IDs__c diagnosticRecordTypes = Diagnostic_Opportunity_Record_Type_IDs__c.getOrgDefaults();
        //DE 393 - Updated code to set primary to false if Diagnostic Quote
        if (opp.RecordTypeId == diagnosticRecordTypes.Diagnostic_Lab_Open_Opportunity__c || opp.RecordTypeId == diagnosticRecordTypes.Diagnostic_Perinatal_Open_Opportunity__c)
            quote.SBQQ__Primary__c = false;
        
        //US-0002197 - Update Amendment Quote to have Price Agreement from the opportunity populated
        if (opp.SBQQ__AmendedContract__c != null){
            //Set Quote Type to Amendment
            quote.SBQQ__Type__c = 'Amendment';
            //Use SOQL Query to Fetch Amended Contract ID to set Price Agreement
            List<Contract> amendedContractList = [Select Id, Marketing_Program__c,Quote_Type__c, SBQQ__Quote__c, StartDate, OwnerId From Contract WHERE Id = :opp.SBQQ__AmendedContract__c];
            //Set Price Agreement field on the new quote with the current contract so that contracted prices come over
            for(Contract ac : amendedContractList){
                if(ac.Id != null)
                    quote.Price_Agreement__c = ac.Id;
                    quote.Amended_Contract_Start_Date__c = ac.StartDate;
                    //Setting Contract Owner to Sales Rep
                    if (ac.OwnerId != null)
                        quote.SBQQ__SalesRep__c = ac.OwnerId;
                    //Setting Marketing Program from contract onto Amendment Quote
                    if(ac.Marketing_Program__c != null)
                        quote.Marketing_Program__c = ac.Marketing_Program__c;
                    amendedContract = ac;
                    //Set End Date if Marketing Program  = Non-Contracted Pricing
                    if(ac.Marketing_Program__c == 'Non-Contracted Pricing')
                        quote.SBQQ__EndDate__c = quote.SBQQ__StartDate__c.addYears(1).addDays(-1); //US-0003269 - updated to use the correct start date
            }
            //Use SOQL Query to Fetch CEC from Amended Contract
            List<Customer_Eligible_Contract__c> cecList = [SELECT Id FROM Customer_Eligible_Contract__c where Customer_Account__c = :opp.AccountId AND Contract__c = :amendedContract.Id AND Selected__c = TRUE];
            //Set CEC field on the new quote with any existing CECs that are on the contract with the same account
            for(Customer_Eligible_Contract__c cec : cecList){
                if(cec.Id != null)
                    quote.Customer_Eligible_Contract__c = cec.Id;
            }
            //Fetch CECs that are only related accounts (not the actual account)
            List<Customer_Eligible_Contract__c> cecsFromContractList = [SELECT Id, Customer_Account__c, Precedence_Value__c, Tier__c  FROM Customer_Eligible_Contract__c where Customer_Account__c !=:opp.AccountId AND Contract__c = :amendedContract.Id AND Selected__c = TRUE];
            //Create CECs with Related Accounts from Original Contract on new Amended Quote
            for(Customer_Eligible_Contract__c relatedCEC : cecsFromContractList){
                Customer_Eligible_Contract__c newCEC = new Customer_Eligible_Contract__c();
                newCEC.Customer_Account__c = relatedCEC.Customer_Account__c;
                newCEC.Precedence_Value__c = relatedCEC.Precedence_Value__c;
                newCEC.Tier__c = relatedCEC.Tier__c;
                newCEC.Selected__c = TRUE;
                newQuoteCECsList.add(newCEC);
            }

            List<SBQQ__Quote__c> quoteList = [SELECT Id, Marketing_Program__c, Quote_Type__c, recordTypeId FROM SBQQ__Quote__c where Id = :amendedContract.SBQQ__Quote__c];
            //Set Set Marketing Program and Quote Type based on the Amended Quote
            for(SBQQ__Quote__c q : quoteList){
                if(q.Id != null && q.recordTypeId != null)
                    quote.recordTypeId = q.recordTypeId;
                if(q.Id != null && q.Marketing_Program__c != null)
                    quote.Marketing_Program__c = q.Marketing_Program__c;
                if(q.Id != null && q.Quote_Type__c != null)
                    quote.Quote_Type__c = q.Quote_Type__c;
            }
        }
        //US-002196 - Update Renewal Quote to map previous contract, CEC, and previous quote information onto renewal quote
        if (opp.SBQQ__RenewedContract__c != null){
            //Set Quote Type to Renewal
            quote.SBQQ__Type__c = 'Renewal';
            //Use SOQL Query to Fetch Amended Contract ID to set Price Agreement
            List<Contract> renewedContractList = [Select Id, Marketing_Program__c,Quote_Type__c, SBQQ__Quote__c, OwnerId, StartDate From Contract WHERE Id = :opp.SBQQ__RenewedContract__c];
            //Set Price Agreement field on the new quote with the current contract so that contracted prices come over
            for(Contract rc : renewedContractList){
                if(rc.Id != null)
                    quote.Amended_Contract_Start_Date__c = rc.StartDate;
                    quote.Price_Agreement__c = rc.Id;
                    //Setting Contract Owner to Sales Rep
                    if (rc.OwnerId != null)
                        quote.SBQQ__SalesRep__c = rc.OwnerId;
                    renewedContract = rc;
                    //Set End Date if Marketing Program  = Non-Contracted Pricing
                    if(rc.Marketing_Program__c == 'Non-Contracted Pricing')
                        quote.SBQQ__EndDate__c = rc.StartDate.addYears(1).addDays(-1);
            }
            //Use SOQL Query to Fetch CEC from Amended Contract
            List<Customer_Eligible_Contract__c> cecList = [SELECT Id FROM Customer_Eligible_Contract__c where Customer_Account__c = :opp.AccountId AND Contract__c = :renewedContract.Id];
            //Set CEC field on the new quote with any existing CECs that are on the contract with the same account
            for(Customer_Eligible_Contract__c cec : cecList){
                if(cec.Id != null)
                    quote.Customer_Eligible_Contract__c = cec.Id;
            }
            //Fetch CECs that are only related accounts (not the actual account)
            List<Customer_Eligible_Contract__c> cecsFromContractList = [SELECT Id, Customer_Account__c, Precedence_Value__c, Tier__c  FROM Customer_Eligible_Contract__c where Customer_Account__c !=:opp.AccountId AND Contract__c =:renewedContract.Id];
            //Create CECs with Related Accounts from Original Contract on new Renewed Quote
            for(Customer_Eligible_Contract__c relatedCEC : cecsFromContractList){
                Customer_Eligible_Contract__c newCEC = new Customer_Eligible_Contract__c();
                newCEC.Customer_Account__c = relatedCEC.Customer_Account__c;
                newCEC.Precedence_Value__c = relatedCEC.Precedence_Value__c;
                newCEC.Tier__c = relatedCEC.Tier__c;
                newCEC.Selected__c = TRUE;
                newQuoteCECsList.add(newCEC);
            }

            List<SBQQ__Quote__c> quoteList = [SELECT Id, Marketing_Program__c, Quote_Type__c, recordTypeId FROM SBQQ__Quote__c where Id = :renewedContract.SBQQ__Quote__c];
            //Set Set Marketing Program and Quote Type based on the Renewed Quote
            for(SBQQ__Quote__c q : quoteList){
                if(q.Id != null && q.recordTypeId != null)
                    quote.recordTypeId = q.recordTypeId;
                if(q.Id != null && q.Marketing_Program__c != null)
                    quote.Marketing_Program__c = q.Marketing_Program__c;
                if(q.Id != null && q.Quote_Type__c != null)
                    quote.Quote_Type__c = q.Quote_Type__c;
            }
            /*SBQQ__Quote__c previousQuote = [SELECT Id, Marketing_Program__c, Quote_Type__c, recordTypeId FROM SBQQ__Quote__c where Id = :renewedContract.SBQQ__Quote__c LIMIT 1];
            //Set Set Marketing Program and Quote Type based on the Renewed Quote
            if(previousQuote.Id != null){
                if(previousQuote.recordTypeId != null)
                    quote.recordTypeId = previousQuote.recordTypeId;
                if(previousQuote.Marketing_Program__c != null)
                    quote.Marketing_Program__c = previousQuote.Marketing_Program__c;
                if(previousQuote.Quote_Type__c != null)
                    quote.Quote_Type__c = previousQuote.Quote_Type__c;
            }*/
            //take marketing program from contract if quote doesn't exist
            if(quote.Marketing_Program__c == null && renewedContract.Marketing_Program__c != null)
                quote.Marketing_Program__c = renewedContract.Marketing_Program__c;
            else if(quote.Marketing_Program__c == null && amendedContract.Marketing_Program__c != null)
                quote.Marketing_Program__c = amendedContract.Marketing_Program__c;
        }

        insert quote;
        
        //Associate CECs to the new quote and upsert CEC records
        if(newQuoteCECsList.size() > 0){
            for (Customer_Eligible_Contract__c eachCEC : newQuoteCECsList){
                eachCEC.Quote__c = quote.Id;
            }
            upsert newQuoteCECsList;
        }
        return quote.Id;
    }
    //Creates Quote Lines from Agreed Prices for Amendments and Renewals
    //public static Boolean CreateQL(Contract oldContract, String quoteId, String oppType){
    @future
    public static void CreateQL(String oldContract, String quoteId, String oppType){
        //Creating Map to Store Newly Created Quote Line Groups to associate to new Quote Lines and Fetch Agreed Price Groups to be used to create Quote Line Groups on new Quote
        Map<String,SBQQ__QuoteLineGroup__c> quoteLineGroupMap = new Map<String,SBQQ__QuoteLineGroup__c>();        
        List<Agreed_Price_Group__c> agreedPriceGroupList = [SELECT Id, Group_Name__c, of_Boxes__c, Shipment_Period__c, number_of_Tests__c, Spend__c, Start_Date__c, number_of_Months__c, Tier__c, Price_per_Test__c FROM Agreed_Price_Group__c WHERE Contract__c =:oldContract];
        List<SBQQ__QuoteLineGroup__c> newQuoteLineGroupList  = new List<SBQQ__QuoteLineGroup__c>();
        SBQQ__Quote__c  tempQuote = [Select Id, Opportunity_Record_Type__c FROM SBQQ__Quote__c WHERE SBQQ__Quote__c.Id =:quoteId LIMIT 1];
        integer groupCount = 1; //Used to set the Group Number on the new quote
        

        for(Agreed_Price_Group__c quoteLineGroup : agreedPriceGroupList)
        {
            SBQQ__QuoteLineGroup__c newQLG = new SBQQ__QuoteLineGroup__c();
            newQLG.Name = quoteLineGroup.Group_Name__c;
            newQLG.SBQQ__Quote__c = quoteId;
            newQLG.of_Boxes__c = quoteLineGroup.of_Boxes__c;
            newQLG.Shipment_Period__c = quoteLineGroup.Shipment_Period__c;
            newQLG.number_of_Tests__c = quoteLineGroup.number_of_Tests__c;
            newQLG.Spend__c = quoteLineGroup.Spend__c;
            newQLG.SBQQ__StartDate__c = quoteLineGroup.Start_Date__c;
            newQLG.number_of_Months__c = quoteLineGroup.number_of_Months__c;            
            newQLG.Tier__c = quoteLineGroup.Tier__c;
            newQLG.SBQQ__Number__c = groupCount;
            newQLG.Price_per_Test__c = quoteLineGroup.Price_per_Test__c; //US-0002768 - Added price per test for diagnostics
            newQLG.Contract_Agreed_Price_Group__c = quoteLineGroup.Id; //Adding lookup to original Agreed Price Group
            newQLG.Enable_Price_Calculation__c = false; //US-0003178 - setting to false for amendments/renewals
            //US-0003343 Added Original Number of Tests and Original Price Per Test
            newQLG.Original_number_of_Tests__c = quoteLineGroup.number_of_Tests__c;
            newQLG.Original_Price_Per_Test__c = quoteLineGroup.Price_per_Test__c;
            newQuoteLineGroupList.add(newQLG);
            quoteLineGroupMap.put(quoteLineGroup.Id, newQLG);
            groupCount++;
        }
        //Insert Quote Line Groups
        if(newQuoteLineGroupList.size() > 0){
            insert newQuoteLineGroupList;
            if(tempQuote != null){
                tempQuote.SBQQ__LineItemsGrouped__c = true;
                update tempQuote; //Setting Line Items Groups Checkbox to true on new quote so that groups appear in Quote Line Editor
            }
        }

        Map<Id,Id> quoteLineRequiredByMap = new Map<Id,Id>();
        List<SBQQ__QuoteLine__c> lst_QL = new List<SBQQ__QuoteLine__c>();
        List<Agreed_Price__c> lst_AP = [SELECT Id, Discount__c, Commitment_Quantity__c, Tier__c, End_Date__c, Price__c, Start_Date__c, Product__c,Agreed_Price_Group__r.Id, Product__r.Description, Product__r.Test_Count__c, Product__r.Name, Agreed_Price_Required_By__r.Id, Number__c, Product_Option__c, Active__c FROM Agreed_Price__c WHERE Contract__c =: oldContract];
        Set<Id> prodId = new Set<Id>();
        
        for(Agreed_Price__c lp_AP : lst_AP)
        {
            if(lp_AP.Active__c && oppType == 'Amendment' || opptype == 'Renewal'){
                SBQQ__QuoteLine__c newQL = new SBQQ__QuoteLine__c();
                newQL.SBQQ__Product__c = lp_AP.Product__c ;
                newQL.SBQQ__Quote__c = quoteId;
                newQL.SBQQ__SpecialPrice__c = lp_AP.Price__c;
                newQL.SBQQ__SpecialPriceType__c = 'Agreed Pricing';
                newQL.SBQQ__StartDate__c = lp_AP.Start_Date__c;
                newQL.SBQQ__EndDate__c = lp_AP.End_Date__c;
                newQL.Agreed_Price_Line__c = lp_AP.Id;
                newQL.Tier__c = lp_AP.Tier__c;
                newQL.Committed_Quantity__c = lp_AP.Commitment_Quantity__c; //ks updated Committed_Quantity__c spelling
                newQL.SBQQ__Quantity__c = 1;
                newQL.Amendment_Line__c = true;
                newQL.SBQQ__Description__c = lp_AP.Product__r.Description;
                newQL.Test_Count__c = lp_AP.Product__r.Test_Count__c; // Adding Test Count when creating new QL

                if (lp_AP.Number__c != NULL)
                    newQL.SBQQ__Number__c = lp_AP.Number__c; //Set the Order Number from Agreed Price

                if (lp_AP.Product_Option__c != NULL)  //Set Product Option from Agreed Price
                    newQL.SBQQ__ProductOption__c = lp_AP.Product_Option__c;

                //Check Quote Line Group Map if Agreed Price Group matches
                if(quoteLineGroupMap.get(lp_AP.Agreed_Price_Group__r.Id) != NULL)
                        newQL.SBQQ__Group__c = quoteLineGroupMap.get(lp_AP.Agreed_Price_Group__r.Id).Id;

                //Mark all quote lines as optional for Diagnostic Renewal Quotes
                if(tempQuote.Opportunity_Record_Type__c != NULL && oppType == 'Renewal'){
                    if(tempQuote.Opportunity_Record_Type__c.Contains('Diagnostic') )
                        newQl.SBQQ__Optional__c = true;
                }

                lst_QL.add(newQL);

                //US-0003142 - Creating Map to Store Agreed Price Required By key value pairs
                if (lp_AP.Agreed_Price_Required_By__c != NULL && quoteLineRequiredByMap.containsKey(lp_AP.Id) == FALSE)
                    quoteLineRequiredByMap.put(lp_AP.Id, lp_AP.Agreed_Price_Required_By__r.Id);
            }
        }

        //insert lst_QL;
        if(lst_QL.size() > 0){
            Database.SaveResult[] lsr = Database.insert(lst_QL, false); 
            
            for(Integer index = 0; index < lsr.size(); index++){
                if(!lsr[index].isSuccess() && lsr[index].getErrors()[0].getMessage().contains('One or more of the quote lines is no longer quotable.')){
                    prodId.add(lst_QL.get(index).SBQQ__Product__c);
                }
            }
            
            System.debug('prodId:'+prodId);
            List<Product2> prodList = [Select Id, Name from Product2 where Id IN :prodId];
            String prodName = '';
            for(Product2 p : prodList){
                if(prodName == '')
                    prodName += p.Name + '';
                else
                    prodName += ', '+p.Name+'';
            }
                
            System.debug('prodName:'+prodName);
                
            for(Integer index = 0; index < lsr.size(); index++){
                if(!lsr[index].isSuccess() && lsr[index].getErrors()[0].getMessage().contains('One or more of the quote lines is no longer quotable.')){
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 'Quote Lines were not created for '+prodName+' as the items are no longer quotable.'));
                }
            }
            
            
            
             
        }
        
        //If required quote lines exist then call method to populate required by
        if(quoteLineRequiredByMap.size() > 0)
            UpdateRequiredQL(quoteLineRequiredByMap, quoteId);

        //return !lst_QL.isEmpty();
    }

    public static void UpdateRequiredQL(Map<Id,Id> quoteLineRequiredByMap, String quoteId){
        //Use SOQL to fetch quote lines that need to be updated with Required by
        List<SBQQ__QuoteLine__c> updatedQuoteLines = [Select Id, Agreed_Price_Line__c FROM SBQQ__QuoteLine__c WHERE Agreed_Price_Line__c IN : quoteLineRequiredByMap.keySet() AND SBQQ__Quote__c =:quoteId];
        //Initialize required by map and returned quote line list
        Map<SBQQ__QuoteLine__c, Id> requiredAPIdMAP = new Map<SBQQ__QuoteLine__c, Id>();
        //List<SBQQ__QuoteLine__c> returnedQuoteLines = new List<SBQQ__QuoteLine__c>();
        Set<SBQQ__QuoteLine__c> returnedQuoteLines = new Set<SBQQ__QuoteLine__c>();

        //Iterate through each quote line to populate map with quote lines to be updated and the required agreed price
        for(SBQQ__QuoteLine__c quoteLine : updatedQuoteLines){
            requiredAPIdMAP.put(quoteLine, quoteLineRequiredByMap.get(quoteLine.Agreed_Price_Line__c));
        }
        //Use SOQL to Fetch the Required Quote Lines
        List<SBQQ__QuoteLine__c> requiredQuoteLines = [Select Id, Agreed_Price_Line__c FROM SBQQ__QuoteLine__c WHERE Agreed_Price_Line__c IN : quoteLineRequiredByMap.values() AND SBQQ__Quote__c =:quoteId];
        Integer sequenceCount = 1;
        //Loop through Map and required quote lines to check if required quote line matches if so then update Quote Line and add to Return List
        for (SBQQ__QuoteLine__c quoteLine : requiredAPIdMAP.keySet()){
            for (SBQQ__QuoteLine__c requiredQuoteLine : requiredQuoteLines)
            {
                if(requiredAPIdMAP.get(quoteLine) == requiredQuoteLine.Agreed_Price_Line__c){
                    quoteLine.SBQQ__RequiredBy__c = requiredQuoteLine.Id;
                    
                    if(returnedQuoteLines.contains(requiredQuoteLine) == false){
                        requiredQuoteLine.SBQQ__Number__c = sequenceCount;
                        sequenceCount++;
                        returnedQuoteLines.add(requiredQuoteLine);
                    }
                    
                    quoteLine.SBQQ__Number__c = sequenceCount;
                    returnedQuoteLines.add(quoteLine);
                    sequenceCount++;
                }
            }
        }

        if(returnedQuoteLines.size() > 0)
        {
            List<SBQQ__QuoteLine__c> returnedQuoteLinesFinal = new List<SBQQ__QuoteLine__c>();
            returnedQuoteLinesFinal.addAll(returnedQuoteLines);
            update returnedQuoteLinesFinal;
        }
    }
   
}