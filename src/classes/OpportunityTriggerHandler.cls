/*---------------------------------------------------------------------------------------------------------------------------------------------
Author:     Buan Consulting
Description:

Test Class:

History:
<Date>      <Authors Name>    <Brief Description of Change>
02/02/2017   Ronald Mendoza     US-0001741 - Need ability to associate multiple accounts to a contract when creating a quote
02/02/2017   Ronald Mendoza     US-0002463 - Update Agreed Price Code to Filter Out Surgical Agreed Prices based on checkbox
03/23/2017   Ronald Mendoza     US-0002196 - Added Logic to Create Agreed Price Groups from Quote Line Groups in createAgreementPrices method
07/26/2017   Kent Smith                      Updating 'Committed_Quantity__c' spelling
07/27/2017   Ronald Mendoza     US-0003142 - Added Logic to Retain Contract Bundle Structure for Diagnostic Usage Fees
------------------------------------------------------------------------------------------------------------------------------------------------*/
public with sharing class OpportunityTriggerHandler 
{
    //Constructor
    public OpportunityTriggerHandler(boolean isExecuting, integer size)
    {
    }
    
    public static Map<String,String> createContract(List<Opportunity> lst_Opp)
    {
        List<Contract> lst_Contract = new List<Contract>();
        Map<String,String> opp_contract_map=new Map<String,String>();

        Set<Id> ContractIds = new Set<Id>();

        //loop through Qoute for fields
        //map quote and Opp
        Map<String, SBQQ__Quote__c> map_str_quote = new Map<String, SBQQ__Quote__c>();
        for(Opportunity lp_Opp : lst_Opp)
        {
            SBQQ__Quote__c blankQuote = new SBQQ__Quote__c();
            blankQuote.SBQQ__StartDate__c=system.today();
            blankQuote.SBQQ__SubscriptionTerm__c=12;
            blankQuote.SBQQ__EndDate__c=system.today().addMonths(12).addDays(-1);
            map_str_quote.put(lp_Opp.SBQQ__PrimaryQuote__c, blankQuote);
        }
        for(SBQQ__Quote__c lp_Quote : [SELECT Id,SBQQ__SubscriptionTerm__c,SBQQ__EndDate__c,SBQQ__StartDate__c,FOB__c,SBQQ__SalesRep__c,Operating_Unit__c,Marketing_Program__c,SBQQ__PaymentTerms__c,Payment_Terms_Freight__c,Quote_Name__c,Name, Opportunity_Record_Type__c FROM SBQQ__Quote__c WHERE Id IN: map_str_quote.keySet() ])
        {
            map_str_quote.put(lp_Quote.Id, lp_Quote);
        }

        /*
        Quote   Contract
        FOB__c  FOB__c
        SBQQ__EndDate__c    Contract_End_Date__c
        SBQQ__SalesRep__c   Owner
        Operating_Unit__c   Operating_Unit__c
        Marketing_Program__c    Marketing_Program__c
        SBQQ__PaymentTerms__c   Payment_Terms_AR__c
        Payment_Terms_Freight__c    Payment_Terms_Freight__c
        SBQQ__SubscriptionTerm__c   ContractTerm

*/
        for(Opportunity lp_Opp : lst_Opp)
        {
            SBQQ__Quote__c quote = map_str_quote.get(lp_Opp.SBQQ__PrimaryQuote__c);
            Contract newContract = new Contract();
            newContract.AccountId = lp_Opp.AccountId;
            newContract.Status = 'Draft';
            //newContract.CurrencyIsoCode = 'U.S. Dollar';
            newContract.StartDate = quote.SBQQ__StartDate__c;
           
            if(quote.SBQQ__StartDate__c == null || (quote.SBQQ__EndDate__c == null && quote.SBQQ__SubscriptionTerm__c == null)) {
                lp_Opp.addError('Primary Quote must have a Start Date and either an End Date or Contract Term, Please update before continuing');
                continue;
            }
            //if end date is null, use subscription term and calulcate end date of contract addMonths,
            if(quote.SBQQ__EndDate__c==null) {
              newContract.Contract_End_Date__c = quote.SBQQ__StartDate__c.addMonths(Integer.valueOf(quote.SBQQ__SubscriptionTerm__c)).addDays(-1);
                newContract.ContractTerm = Integer.valueOf(quote.SBQQ__SubscriptionTerm__c);
            } 
            else {
                newContract.ContractTerm = quote.SBQQ__StartDate__c.monthsBetween(quote.SBQQ__EndDate__c);
                newContract.Contract_End_Date__c = quote.SBQQ__EndDate__c;
            }
            //If end date is not null, use Monthsbetween method to calculate subscription term
            //newContract.Contract_End_Date__c = quote.SBQQ__EndDate__c;
            if(quote.SBQQ__SalesRep__c != null)
                newContract.OwnerId = quote.SBQQ__SalesRep__c;
            newContract.Operating_Unit__c = quote.Operating_Unit__c;
            newContract.Marketing_Program__c = quote.Marketing_Program__c;
            newContract.Payment_Terms_AR__c = quote.SBQQ__PaymentTerms__c;
            newContract.Payment_Terms_Freight__c = quote.Payment_Terms_Freight__c;
            newContract.ContractTerm = Integer.valueOf(quote.SBQQ__SubscriptionTerm__c);
            newContract.FOB__c=quote.FOB__c;
            newContract.SBQQ__Quote__c = lp_Opp.SBQQ__PrimaryQuote__c;
            newContract.SBQQ__Opportunity__c = lp_Opp.Id;
            newContract.Name = String.IsBlank(quote.Quote_Name__c)?quote.Name:quote.Quote_Name__c;
            newContract.Renewed_Contract__c = lp_Opp.SBQQ__RenewedContract__c;
            newContract.Amended_Contract__c = lp_Opp.SBQQ__AmendedContract__c;

            if(quote.Opportunity_Record_Type__c == 'Diagnostic Lab Open Opportunity' || quote.Opportunity_Record_Type__c == 'Diagnostic Perinatal Open Opportunity'){
                lp_Opp.CloseDate = date.today();
            }

            lst_Contract.add(newContract);
        }
        insert lst_Contract; 
        System.debug('Start ');
        createAgreementPrices(lst_Contract);
        System.debug('Stop ');

        for(Contract con:lst_Contract){
            opp_contract_map.put(con.SBQQ__Opportunity__c, con.id);
            ContractIds.add(con.Id);
        }

        //Create CEC with a Precedence of 260 linked to the contract and the account Effective_Date__c and Expiration_Date__c= dates from Contract, Selected__c=true
        createCECs(ContractIds);

        return opp_contract_map;
        
    }

    //Method to Create a CEC and Agreed Prices from the primary quote when Price Agreement Created is checked on the Opportunity - Existing CECs related to primary quote will be backfilled with data
    //US-0001741 - Updated Logic to Associate Existing CECs to Contract when Price Agreement Created is Checked
    public static void createCECs(Set<Id> ContractIds){
        
        //Create List to store CECs to be updated and Contracts to be used for update logic
        List<Customer_Eligible_Contract__c> CEClist = new List<Customer_Eligible_Contract__c>();
        List<String> quoteList = new List<String>();
        //Create map for contracts 
        Map<Id, Contract> contractMap = new Map<Id, Contract> ([Select Id, Name, AccountId, StartDate, Contract_End_Date__c,ContractNumber,Default_Precedence__c,SBQQ__Quote__c,(SELECT Id,Tier__c FROM Agreed_Price__r)
                                      from Contract where Id IN :ContractIds]);
        Decimal tier;
        
        //Loop through Contract Map to pull the quote number from Contract record
        for(Id key : contractMap.keySet()){
            Contract c = contractMap.get(key);
            //Add Quote Number from the contract to the quote list
            if(c.SBQQ__Quote__c != null){
                quoteList.add(c.SBQQ__Quote__c);
            }
        }
        //Create a Map for existing CECs that are related to the Primary Quote
        Map<Id, Customer_Eligible_Contract__c> cecMap = new Map<Id, Customer_Eligible_Contract__c> ([SELECT Id FROM Customer_Eligible_Contract__c where Quote__c IN :quoteList]);

        if(contractMap.size() > 0){
            //Loop through contracts map to check for existing CECs to be updated with Contract Data and/or to create new CEC
            for(Id key : contractMap.keySet()){
                Contract c = contractMap.get(key);
                //Updating Existing CECs tied to primary quote with Contract Info
                for (Id cecKey: cecMap.keySet()){
                    Customer_Eligible_Contract__c existingCEC = cecMap.get(cecKey);
                    existingCEC.Contract__c = c.Id;
                    existingCEC.Effective_Date__c = c.StartDate;
                    existingCEC.Expiration_Date__c = c.Contract_End_Date__c;
                    existingCEC.Precedence_Value__c = c.Default_Precedence__c;
                    existingCEC.Selected__c = true;
                    CEClist.add(existingCEC);
                }
                //Create new CEC with Contract Info to be added
                Customer_Eligible_Contract__c newCEC = new Customer_Eligible_Contract__c();
                newCEC.Contract__c = c.Id;
                newCEC.Customer_Account__c = c.AccountId;
                newCEC.Effective_Date__c = c.StartDate;
                newCEC.Expiration_Date__c = c.Contract_End_Date__c;
                newCEC.Precedence_Value__c = c.Default_Precedence__c;
                newCEC.Selected__c = true;
                //Add Agreed Prices to newly created CEC using data from the Primary Quote
                if(c.getSObjects('Agreed_Price__r') != null)
                    for(Agreed_Price__c ap : (List<Agreed_Price__c>)c.getSObjects('Agreed_Price__r')){
                        if(ap.Tier__c != null && ap.Tier__c > 0 && tier == null)
                            tier = ap.Tier__c;
                        else if(ap.Tier__c != null && ap.Tier__c > 0 && ap.Tier__c < tier)
                            tier = ap.Tier__c; 
                    }
                newCEC.Tier__c = tier;
                //Update and/or Add new CEC data to CEC List
                CEClist.add(newCEC);
            }
        }
        //Insert or Update CEC Data
        upsert CEClist;
    }
    public static void createAgreementPrices(List<Contract> lst_Contract)
    {   System.debug('InsideOppty Trigger Handler ' + lst_Contract);
        List<SBQQ__QuoteLine__c> lst_QLI = new List<SBQQ__QuoteLine__c>();
        //US-0002196 - Created Lists to store Quote Line Groups and Agreed Price Groups
        List<SBQQ__QuoteLineGroup__c> lst_QLG = new List<SBQQ__QuoteLineGroup__c>();
        List<Agreed_Price_Group__c> lst_APG = new List<Agreed_Price_Group__c>();
        List<Agreed_Price__c> lst_AP = new List<Agreed_Price__c>();
        Map<Id, Id> map_contract_Quote = new Map<Id, Id>();
        Map<String,Contract> QuoteToContractMap = new Map<String,Contract>();
        //US-0002196 - Create Map to store newly created Agreed Price Groups
        Map<String,Agreed_Price_Group__c> agreedPriceGroupMap = new Map<String,Agreed_Price_Group__c>();
        //DE-530 Adding Map for Required by Relationships
        //Map<String,Agreed_Price__c> agreedPriceRequiredByMap = new Map<String,Agreed_Price__c>();
        Map<SBQQ__QuoteLine__c,Agreed_Price__c> agreedPriceRequiredByMap = new Map<SBQQ__QuoteLine__c,Agreed_Price__c>();
        //Use Custom Org Settings to check if Surgical Record Type
        Surgical_Opportunity_Record_Type_IDs__c recordTypes = Surgical_Opportunity_Record_Type_IDs__c.getOrgDefaults();
        Diagnostic_Opportunity_Record_Type_IDs__c diagRecordTypes = Diagnostic_Opportunity_Record_Type_IDs__c.getOrgDefaults();

        for(Contract lp_contracts : lst_Contract)
        {
            map_contract_Quote.put(lp_contracts.SBQQ__Quote__c, lp_contracts.Id);
            QuoteToContractMap.put(lp_contracts.SBQQ__Quote__c,lp_contracts);
        }
        //Use SOQL to Fetch Quote Line Groups from Quote and use info to create Agreed Price Groups with Group Level Filds to be passed to the contract
        lst_QLG = [SELECT Id, of_Boxes__c, Name, SBQQ__Number__c, Shipment_Period__c,SBQQ__Quote__c, number_of_Tests__c,  Spend__c, SBQQ__StartDate__c, number_of_Months__c, Tier__c, Price_per_Test__c, SBQQ__Quote__r.SBQQ__StartDate__c FROM SBQQ__QuoteLineGroup__c WHERE SBQQ__Quote__c IN: map_contract_Quote.keySet()];
        for(SBQQ__QuoteLineGroup__c lp_QLG : lst_QLG){
            Agreed_Price_Group__c newAPGroup = new Agreed_Price_Group__c();
            newAPGroup.Group_Name__c = lp_QLG.Name;
            newAPGroup.Shipment_Period__c = lp_QLG.Shipment_Period__c;
            newAPGroup.Contract__c = map_contract_Quote.get(lp_QLG.SBQQ__Quote__c);
            newAPGroup.of_Boxes__c = lp_QLG.of_Boxes__c;
            newAPGroup.number_of_Tests__c = lp_QLG.number_of_Tests__c;
            newAPGroup.Spend__c = lp_QLG.Spend__c;
            newAPGroup.Start_Date__c = lp_QLG.SBQQ__Quote__r.SBQQ__StartDate__c; //lp_QLG.SBQQ__StartDate__c; updated to SBQQ__StartDate__c
            newAPGroup.number_of_Months__c = lp_QLG.number_of_Months__c;
            newAPGroup.Tier__c = lp_QLG.Tier__c;
            newAPGroup.Price_per_Test__c = lp_QLG.Price_per_Test__c; //US-0002768 - Added Price Per Test for Diagnostics
            lst_APG.add(newAPGroup);
            //Add Agreed Price Group Info to Map to be used later when tying Agreed Price to Agreed Price Group
            //agreedPriceGroupMap.put(lp_QLG.Name, newAPGroup);
            agreedPriceGroupMap.put(lp_QLG.Id, newAPGroup);
        }
        //Inserting Agreed Price Groups to Contract
        insert lst_APG;

        //US-0002463 - Update Agreed Price Logic to Check for Surgical and if Create Agreed Price flag is true if not then go to previous logic
        lst_QLI = [SELECT Id, SBQQ__Discount__c, PAProductKey__c,Tier__c,Committed_Quantity__c, SBQQ__EndDate__c, SBQQ__Quote__c, SBQQ__Quote__r.SBQQ__StartDate__c, SBQQ__Quote__r.SBQQ__EndDate__c, SBQQ__NetPrice__c, SBQQ__StartDate__c, SBQQ__Product__c,SBQQ__Group__c,SBQQ__Group__r.Id, SBQQ__Group__r.Name, Create_Agreed_Price__c, SBQQ__Quote__r.SBQQ__Opportunity2__r.RecordType.Id, SBQQ__RequiredBy__r.Id, Usage_Fee__c, SBQQ__Number__c, SBQQ__ProductOption__c FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c IN: map_contract_Quote.keySet()]; //ks updated Committed_Quantity__c spelling
        for(SBQQ__QuoteLine__c lp_QLI : lst_QLI){ 
            System.debug('Oppty Trigger Handler ' + lp_QLI.SBQQ__Quote__r.SBQQ__Opportunity2__r.RecordType.Id + ' ' + recordTypes.Surgical_Open_Opportunity__c);
            //Check if Surgical Open Oppty and Create Agreed Price is True if so create agreed price
            if((lp_QLI.SBQQ__Quote__r.SBQQ__Opportunity2__r.RecordType.Id == recordTypes.Surgical_Open_Opportunity__c 
                || lp_QLI.SBQQ__Quote__r.SBQQ__Opportunity2__r.RecordType.Id == diagRecordTypes.Diagnostic_Lab_Open_Opportunity__c
                || lp_QLI.SBQQ__Quote__r.SBQQ__Opportunity2__r.RecordType.Id == diagRecordTypes.Diagnostic_Perinatal_Open_Opportunity__c)
                 &&  lp_QLI.Create_Agreed_Price__c){
                Agreed_Price__c newAP = new Agreed_Price__c();
                newAP.Product__c =  lp_QLI.SBQQ__Product__c;
                newAP.Contract__c = map_contract_Quote.get(lp_QLI.SBQQ__Quote__c);
                newAP.Discount__c = lp_QLI.SBQQ__Discount__c;
                newAP.Price__c = lp_QLI.SBQQ__NetPrice__c;
                newAP.Start_Date__c = lp_QLI.SBQQ__Quote__r.SBQQ__StartDate__c;
                newAP.End_Date__c = QuoteToContractMap.get(lp_QLI.SBQQ__Quote__c).Contract_End_Date__c;
                newAP.Active__c = true;
                newAP.Commitment_Quantity__c = lp_QLI.Committed_Quantity__c; //ks updated Committed_Quantity__c spelling
                newAP.PAProductKey__c = lp_QLI.PAProductKey__c;
                newAP.Tier__c = lp_QLI.Tier__c;
                newAP.Quote_Line__c = lp_QLI.Id;
                newAP.Number__c = lp_QLI.SBQQ__Number__c;  //Added Quote Line Order Number for Agreed Prices
                newAP.Product_Option__c = lp_QLI.SBQQ__ProductOption__c;

                //Check if Quote Line has Group and tie Agreed Price to the Agreed Price Group
                if(agreedPriceGroupMap.get(lp_QLI.SBQQ__Group__r.Id) != NULL)
                    newAP.Agreed_Price_Group__c = agreedPriceGroupMap.get(lp_QLI.SBQQ__Group__r.Id).Id;

                //Check if Required By is populated if so then add to Required By Map US-0003142
                if(lp_QLI.SBQQ__RequiredBy__c != NULL && lp_QLI.Usage_Fee__c)
                    agreedPriceRequiredByMap.put(lp_QLI, newAP);

                lst_AP.add(newAP);
            }//Agreed Price creation for BSH Quote Lines - Added Condition to Check for Create Agreed Price
            else if(((lp_QLI.SBQQ__Group__c != null && lp_QLI.SBQQ__Group__r.Name != 'Equipment') || lp_QLI.SBQQ__Group__c == null)  
                && lp_QLI.SBQQ__Quote__r.SBQQ__Opportunity2__r.RecordType.Id != recordTypes.Surgical_Open_Opportunity__c 
                && lp_QLI.SBQQ__Quote__r.SBQQ__Opportunity2__r.RecordType.Id != diagRecordTypes.Diagnostic_Lab_Open_Opportunity__c
                && lp_QLI.SBQQ__Quote__r.SBQQ__Opportunity2__r.RecordType.Id != diagRecordTypes.Diagnostic_Perinatal_Open_Opportunity__c){
                Agreed_Price__c newAP = new Agreed_Price__c();
                newAP.Product__c =  lp_QLI.SBQQ__Product__c;
                newAP.Contract__c = map_contract_Quote.get(lp_QLI.SBQQ__Quote__c);
                newAP.Discount__c = lp_QLI.SBQQ__Discount__c;
                newAP.Price__c = lp_QLI.SBQQ__NetPrice__c;
                newAP.Start_Date__c = lp_QLI.SBQQ__Quote__r.SBQQ__StartDate__c;
                //newAP.End_Date__c = lp_QLI.SBQQ__Quote__r.SBQQ__EndDate__c;
                newAP.End_Date__c = QuoteToContractMap.get(lp_QLI.SBQQ__Quote__c).Contract_End_Date__c;
                newAP.Active__c = true;
                newAP.Commitment_Quantity__c = lp_QLI.Committed_Quantity__c; //ks updated Committed_Quantity__c spelling
                newAP.PAProductKey__c = lp_QLI.PAProductKey__c;
                newAP.Tier__c = lp_QLI.Tier__c;//(lp_QLI.Tier__c==NULL) ? 1 : lp_QLI.Tier__c; 
                newAP.Quote_Line__c = lp_QLI.Id;
                newAP.Number__c = lp_QLI.SBQQ__Number__c;  //Added Quote Line Order Number for Agreed Prices
                newAP.Product_Option__c = lp_QLI.SBQQ__ProductOption__c;

                //Check if Quote Line has Group and tie Agreed Price to the Agreed Price Group
                if(agreedPriceGroupMap.get(lp_QLI.SBQQ__Group__r.Id) != NULL)
                    newAP.Agreed_Price_Group__c = agreedPriceGroupMap.get(lp_QLI.SBQQ__Group__r.Id).Id;

                //Check if Required By is populated if so then add to Required By Map US-0003142
                if(lp_QLI.SBQQ__RequiredBy__c != NULL && lp_QLI.Usage_Fee__c)
                    agreedPriceRequiredByMap.put(lp_QLI, newAP);

                lst_AP.add(newAP);
            }
        }

        insert lst_AP;

        List<Agreed_Price__c> updatedAgreedPrices = new List<Agreed_Price__c>();
        //Loop through Agreed Prices and Add Required By Reference US-0003142
        
        if(agreedPriceRequiredByMap.size() > 0){
            for (SBQQ__QuoteLine__c quoteLine : agreedPriceRequiredByMap.keySet()){             
                Agreed_Price__c updatedAP = agreedPriceRequiredByMap.get(quoteLine);

                if(quoteLine.SBQQ__RequiredBy__c != NULL && quoteLine.SBQQ__Quote__c != NULL){
                    Id contractId = map_contract_Quote.get(quoteLine.SBQQ__Quote__c);
                    Agreed_Price__c tempAP = [Select Id FROM Agreed_Price__c WHERE Quote_Line__c =:quoteLine.SBQQ__RequiredBy__c AND Contract__c =: contractId];
                    updatedAP.Agreed_Price_Required_By__c = tempAP.Id;
                    updatedAgreedPrices.add(updatedAP);
                }
            }
            if (updatedAgreedPrices.size() > 0)
                update updatedAgreedPrices;
        }
    }
}