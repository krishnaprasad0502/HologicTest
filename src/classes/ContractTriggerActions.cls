/*------------------------------------------------------------------------------------------------------
Author: Ronald Mendoza
Company: Salesforce    
Description:  Trigger framework for Contract object
Test Class:   Test_GenerateRenewalContract 

History:
<Date>      <Authors Name>    <Brief Description of Change>
11/04/2016  Ronald Mendoza     Initial Creation
02/27/2017  Sheetal Rathod     Restructure & Optimize ContractRenewalTrigger
05/19/2017  Ronald Mendoza     Updated validateTierValue method fixed tier issue
06/14/2017  Kent Smith         Added updates to field Contract_Activated__c on ap and cec (US-0003016)
10/04/2017  Krishna prasad     Update- bug as part of US-0003471
10/25/2017  Mani Sundaresan    Logic updated to prevent the frequent updates on Child records when the contract is updated (US-0003544)
---------------------------------------------------------------------------------------------------------*/

public with sharing class ContractTriggerActions{
    
    
    /*------------------------------------------------------------
Author:         Sheetal Rathod
Company:        Hologic
Description:    To check Tier values when the contract is Activated
Inputs:         newContracts - The list of contracts
oldContracts    Map of pervious contract values
Returns:        N/A

History:
<Date>          <Authors Name>      <Brief Description of Change>
03/06/2017      Sheetal Rathod      Initial Creation
05/15/2017      Ronald Mendoza      Created Contract Validations for Agreed Price Groups
07/17/2017      Ronald Mendoza      Adding Agreed Price Group and Tier Validations
------------------------------------------------------------*/
    public static void validateTierValue(List<Contract> newContracts, Map<Id, Contract> oldContracts){
        
        //Nested SOQL to fetch Contract, Agreed Price, CEC & Agreed Price Group records
        Map<Id,Contract> contractMap = new Map<Id,Contract>([SELECT Id, Automatic_Renewal__c, SBQQ__RenewalOpportunity__c,Status,Contract_End_Date__c,Termination_Date__c, (SELECT Id, Tier__c,End_Date__c,Header_Update__c,Active__c, Agreed_Price_Group__c, Contract__c, Agreed_Price_Group__r.Tier__c FROM Agreed_Price__r), (SELECT Id, Tier__c, Expiration_Date__c, Header_Update__c, Selected__c, Contract__c from Customer_Eligible_Contracts__r ), (SELECT Id from Agreed_Price_Groups__r) from Contract where Id in :newContracts]);    
        
        Boolean isTier = false;
        Boolean noTier = false;
        
        for(Contract con : newContracts){
            //Updating Contract Validations to check for Agreed Price Groups if groups are used on the contract
            boolean agreedPriceGroupsExist = false;
            //Checking if Groups are on the Contract and setting flag on contract to true if groups exist
            if(contractMap.get(con.Id).getSObjects('Agreed_Price_Groups__r') != null && contractMap.get(con.Id).getSObjects('Agreed_Price_Groups__r').size() > 0){
                agreedPriceGroupsExist = true;
                con.Agreed_Price_Groups_Exist__c = true;
            }
            else{
                con.Agreed_Price_Groups_Exist__c = false;
            }
            //Check CEC and AP Tiers if Tier are populated and valid
            if(con.Status == 'Activated' && con.Status != oldContracts.get(con.Id).Status){
                if(contractMap.get(con.Id).getSObjects('Customer_Eligible_Contracts__r') != null){
                    for(Customer_Eligible_Contract__c cec : contractMap.get(con.Id).getSObjects('Customer_Eligible_Contracts__r')){
                        if((cec.Tier__c != null ||cec.Tier__c > 0) && cec.Selected__c == true)
                            isTier = true;
                        else if((cec.Tier__c < 1 || cec.Tier__c == null) && cec.Selected__c == true)
                            noTier = true;
                    }
                }
                //Checking if Groups are on the Contract and setting Agreed Price Group Exists flag to true (to be used for validations)
                if(contractMap.get(con.Id).getSObjects('Agreed_Price_Groups__r') != null && contractMap.get(con.Id).getSObjects('Agreed_Price_Groups__r').size() > 0){
                    agreedPriceGroupsExist = true;
                    con.Agreed_Price_Groups_Exist__c = true;
                }
                //Check Agreed Prices for Valid Tier if Tier matches Agreed Price Group
                for(Agreed_Price__c ap : contractMap.get(con.Id).getSObjects('Agreed_Price__r')){                        
                    if((ap.Tier__c != null ||ap.Tier__c > 0) && ap.Active__c == true)
                        isTier = true;
                    else if((ap.Tier__c < 1 || ap.Tier__c == null) && ap.Active__c == true)
                        noTier = true;
                    //Return Validation Error if Tier does not Match
                    if(ap.Tier__c != ap.Agreed_Price_Group__r.Tier__c && agreedPriceGroupsExist && ap.Contract__c == con.Id)
                        con.addError('Agreed Price Tier must match Agreed Price Group Tier');
                    //Return Validation Error if Agreed Prices does not have an associated Group on a contract that has Groups
                    if(ap.Agreed_Price_Group__c == null && agreedPriceGroupsExist && ap.Contract__c == con.Id){
                        con.addError('All Agreed Prices must be associated to an Agreed Price Group if groups are used');
                    }
                }
                //Return Validation Error if Tiers are not populated on APs or CECs
                if(isTier && noTier)
                    con.addError('Kindly ensure that Tier is populated on all Customer Eligible Contract and Agreed Price records associated with this Contract.');
                else if((!isTier && !noTier) || (!isTier && noTier)){
                    con.Tier_Not_Included__c = true;
                    con.Tier_Included__c = false;
                }
                else{
                    con.Tier_Included__c = true; 
                    con.Tier_Not_Included__c = false;
                }
            }
        }
    } 
    
    /*------------------------------------------------------------
Author:         Ronald Mendoza
Company:        Salesforce
Description:    Moved to Method from ContractRenewal Trigger to Update Amended Contract Dates - RMendoza
Inputs:         newContracts - The list of contracts

Returns:        N/A

History:
<Date>          <Authors Name>      <Brief Description of Change>
05/15/2017      Ronald Mendoza      Initial Creation (US)
09/19/2017      Ronald Mendoza      Updated Amended Contract Status from Expired to Amended
------------------------------------------------------------*/
    
    public static void updateAmendedContract(List<Contract> triggeredContract){
        
        List<Id> amendedContractId = new List<Id>();
        List<Contract> amendedContractList = new List<Contract>();
        List<Contract> updateContractList = new List<Contract>();
        
        for(Contract con : triggeredContract){
            if(con.Amended_Contract__c != NULL)
                amendedContractId.add(con.Amended_Contract__c);
        }
        //fetch amended contracts and populate amended contract list
        if(amendedContractId.size() > 0)
            amendedContractList = [SELECT Id, Contract_End_Date__c, StartDate, Status FROM Contract where Id IN: amendedContractId];
        //find amended contract and if new contract is activated expire the amended contract
        if(amendedContractList.size() > 0)
            for(Contract con : triggeredContract){
                for(Contract acon : amendedContractList){
                    if(con.Amended_Contract__c == acon.Id && acon.Status != 'Amended'){ //Updated from Expired to Amended
                        acon.Status = 'Amended'; // Updated Status from Expired to Amended
                        if(con.StartDate.addDays(-1) > acon.StartDate){
                            acon.Termination_Date__c = con.StartDate.addDays(-1);
                            acon.Automatic_Renewal__c = false;
                        }
                        updateContractList.add(acon);
                    }
                }
            }
        //update amended contracts after being expired
        if(updateContractList.size() > 0){
            Database.SaveResult[] consr = Database.update(updateContractList,false);
            for(Integer index = 0; index < consr.size(); index++){
                if(!consr[index].isSuccess()){
                    triggeredContract[index].addError('Failed to update Contract: '+consr[index].getErrors()[0].getMessage());
                }        
            } 
        }
        
        
    }
    
    /*------------------------------------------------------------
Author:         Sheetal Rathod
Company:        Hologic
Description:    To Activate/Deactivate, Agreed Price & Customer Eligible Contact records based on Contract Status. 
Inputs:         newContracts - The list of contracts
oldContracts-   Map of pervious contract values
Returns:        N/A

History:
<Date>          <Authors Name>      <Brief Description of Change>
03/06/2017      Sheetal Rathod      Initial Creation (US)
6/14/2017       Kent Smith          added updates to Contract_Activated__c and condition to trigger if updatedCon was previously in 'Draft'
6/22/2017       Kent Smith          added functionality to update ExpirationDate on CEC and EndDate on AP when Contract End Date is updated on Active Contracts (US-0002407)
7/16/2017       Ronald Mendoza      Refactored Code to optimize method - Reduced nested for loops and refactored duplicate code
10/04/2017      Krishna prasad      Update- bug as part of US-0003471
10/25/2017      Mani Sundaresan     Logic updated to prevent the frequent updates on child records when the contract is updated (US-0003544)
------------------------------------------------------------*/
    public static void childRecUpdate(List<Contract> newContracts, Map<Id, Contract> oldContracts){
        //Variable Declaration
        List<Agreed_Price__c> agreedPriceList = new List<Agreed_Price__c>();
        List<Customer_Eligible_Contract__c> cecList = new List<Customer_Eligible_Contract__c>();
        List<Contract> lst_cons = new List<Contract>();
        Map<Id,Contract> contractMap = new Map<Id, Contract>([SELECT Id, Automatic_Renewal__c, SBQQ__RenewalOpportunity__c,Status,Contract_End_Date__c,Termination_Date__c, (SELECT Id, Tier__c,End_Date__c,Header_Update__c,Active__c,Contract_Activated__c  FROM Agreed_Price__r), (SELECT Id, Tier__c, Expiration_Date__c, Header_Update__c, Selected__c,Contract_Activated__c from Customer_Eligible_Contracts__r ) from Contract where Id in :newContracts]); 
        
        for(Contract con : newContracts){
            Contract updatedCon = oldContracts.get(con.Id);
            Boolean  updateContract = false;
            
            for(Customer_Eligible_Contract__c cec : contractMap.get(con.Id).getSObjects('Customer_Eligible_Contracts__r')){
                if(con.Status == 'Activated' && cec.Expiration_Date__c >= con.Termination_Date__c && (updatedCon.Status == 'Terminated' || updatedCon.Status == 'Expired' || updatedCon.Status == 'Amended')){
                    cec.Selected__c = true;
                    cec.Contract_Activated__c = true;  //added update to Contract_Activated__c field (ks)
                    
                    if(cec.Header_Update__c)                    
                        cec.Header_Update__c = false;
                    else
                        cec.Header_Update__c = true;
                    
                    cecList.add(cec);
                }
                //On activation (contract status is activated and previous status was draft, set contract_activated__c true and active__c true (ks)
                else if(con.Status == 'Activated' && updatedCon.Status == 'Draft' && cec.Expiration_Date__c >= date.today()){
                    //added condition to only activate CECs with ended datesequal to or after today
                    cec.Selected__c = true;
                    cec.Contract_Activated__c = true;  //added update to Contract_Activated__c field (ks)
                    
                    if(cec.Header_Update__c)                    
                        cec.Header_Update__c = false;
                    else
                        cec.Header_Update__c = true;
                    
                    cecList.add(cec);
                }
                //if contract is active and updated populate end date fields from contract end date (ks, 6/22/2017)
                else if(con.Status == 'Activated' && updatedCon.Status == 'Activated' && con.Contract_End_Date__c != updatedCon.Contract_End_Date__c){
                    //10/04/2017    Krishna prasad   Update- bug as part of US-0003471
                    if(cec.Selected__c) {
                        
                        cec.Expiration_Date__c = con.Contract_End_Date__c;  //added update to populate cec end date with contract end date (ks)
                        
                        if(cec.Header_Update__c)                    
                            cec.Header_Update__c = false;
                        else
                            cec.Header_Update__c = true;
                        
                        cecList.add(cec);
                    }
                    
                }
                //if contract expired or terminated
                else if((con.Status == 'Expired' || con.Status == 'Terminated' || con.Status == 'Amended') && updatedCon.Status == 'Activated'){                    
                    cec.Selected__c = false;
                    cec.Contract_Activated__c = false; //added update to Contract_Activated__c field (ks)          
                    
                    if(cec.Header_Update__c)                    
                        cec.Header_Update__c = false;
                    else
                        cec.Header_Update__c = true;
                    
                    cecList.add(cec);
                }
            }
            
            for(Agreed_Price__c ap : contractMap.get(con.Id).getSObjects('Agreed_Price__r')){
                //When contract is activated after being expired or terminated, activate Agreed Prices and update contract
                if(con.Status == 'Activated' && (updatedCon.Status == 'Terminated' || updatedCon.Status == 'Expired' || updatedCon.Status == 'Amended') && ap.End_Date__c >= con.Termination_Date__c){
                    ap.Active__c = true;
                    ap.Contract_Activated__c = true; //added update to Contract_Activated__c field (ks)  
                    updateContract = true;                                          
                    if(ap.Header_Update__c) 
                        ap.Header_Update__c = false;
                    else
                        ap.Header_Update__c = true;
                    agreedPriceList.add(ap);
                }
                
                
                //On activation (contract status is activated and previous status was draft, set contract_activated__c true and active__c true (ks)
                else if(con.Status == 'Activated' && updatedCon.Status == 'Draft' && ap.End_Date__c >= date.today()){
                    ap.Active__c = true;
                    ap.Contract_Activated__c = true; //added update to Contract_Activated__c field (ks)
                    if(ap.Header_Update__c) 
                        ap.Header_Update__c = false;
                    else
                        ap.Header_Update__c = true;
                    agreedPriceList.add(ap);
                    
                }
                //if contract is active and updated populate end date fields from contract end date (ks, 6/22/2017)
                else if(con.Status == 'Activated' && updatedCon.Status == 'Activated' && con.Contract_End_Date__c != updatedCon.Contract_End_Date__c && ap.Active__c){
                    ap.End_Date__c = con.Contract_End_Date__c; //added update to Contract_Activated__c field (ks)
                    if(ap.Header_Update__c) 
                        ap.Header_Update__c = false;
                    else
                        ap.Header_Update__c = true;
                    agreedPriceList.add(ap);
                    
                }
                //start if contract expired or terminated
                else if((con.Status == 'Expired' || con.Status == 'Terminated' ||con.Status == 'Amended') && updatedCon.Status == 'Activated'){
                    ap.Active__c = false;
                    ap.Contract_Activated__c = false; //added update to Contract_Activated__c field (ks)
                    if(ap.Header_Update__c) 
                        ap.Header_Update__c = false;
                    else
                        ap.Header_Update__c = true;
                    agreedPriceList.add(ap);
                    
                }
            }
            
            if (updateContract){
                con.Termination_Date__c = null;
            }
            
            lst_cons.add(con);
        }
        //Update Agreed Prices
        if(agreedPriceList.size()>0)
            update agreedPriceList;
        //Update CECs
        if(cecList.size()>0)
            update cecList;
    }   
}