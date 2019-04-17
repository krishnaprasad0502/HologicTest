trigger CreateContractAgreePrice on Opportunity (before update, after update) 
{
    Boolean isActive=false;
    try{
        isActive=[SELECT Name, Active__c FROM Trigger_Switch__C WHERE Name = 'CreateContractAgreePrice'].Active__c;  
    }catch(QueryException q){

    }
    
    if(isActive || test.IsRunningTest())
    {
        List<Contract> newContract = new List<Contract>();
        List<QuoteLineItem> QLI = new List<QuoteLineItem>();
        List<Opportunity> lst_Opp = new List<Opportunity>();
        List<Opportunity> lst_Amd = new List<Opportunity>();
        List<Opportunity> lst_Renew = new List<Opportunity>();
        Map<String,String> opp_con_map=new Map<String,String>();
        List<Opportunity> lst_BulkRenew = new List<Opportunity>();
        

        if(Trigger.isBefore && Trigger.isUpdate)
        {
            for(Opportunity newOpp : Trigger.new)
            {
                if(newOpp.Pricing_Agreement_Created__c && Trigger.oldMap.get(newOpp.Id).Pricing_Agreement_Created__c == false && newOpp.SBQQ__AmendedContract__c == null && newOpp.SBQQ__RenewedContract__c == null)
                {
                   lst_Opp.add(newOpp);
                }
                else if(newOpp.Pricing_Agreement_Created__c && Trigger.oldMap.get(newOpp.Id).Pricing_Agreement_Created__c == false && newOpp.SBQQ__AmendedContract__c != null && newOpp.SBQQ__RenewedContract__c == null)
                {
                    lst_Amd.add(newOpp);
                    //not creating a contract
                }
                else if(newOpp.Renewal_Quote_Creation__c == false && newOpp.Pricing_Agreement_Created__c && Trigger.oldMap.get(newOpp.Id).Pricing_Agreement_Created__c == false && newOpp.SBQQ__AmendedContract__c == null && newOpp.SBQQ__RenewedContract__c != null)
                {
                    lst_Renew.add(newOpp);
                    //Create contract
                }
                else if(newOpp.Renew_Contract_Option__c != 'Don\'t Renew Contract' && newOpp.Renewal_Quote_Creation__c && !trigger.oldMap.get(newOpp.Id).Renewal_Quote_Creation__c && newOpp.SBQQ__RenewedContract__c != null)
                {
                    if(newOpp.Renew_Contract_Option__c == null)
                    {
                        newOpp.Renew_Contract_Option__c = 'No Change to Existing Price';
                        newOpp.Justification__c = 'Auto Generated';
                    }
                }
                
            }
            if(!lst_Opp.isEmpty())
            {
             opp_con_map.putAll(OpportunityTriggerHandler.createContract(lst_Opp));  
            }
            if(!lst_Amd.isEmpty())
            {
                opp_con_map.putAll(OpportunityTriggerHandler.createContract(lst_Amd));
            }
            /*if(!lst_Amd.isEmpty())
            {
                opp_con_map.putAll(OpportunityTriggerHandler.amendAgreementPrices(lst_Amd));
            }*/
            if(!lst_Renew.isEmpty())
            {
                opp_con_map.putAll(OpportunityTriggerHandler.createContract(lst_Renew));
                //create contract
            }
            
            system.debug(opp_con_map);
            for(Opportunity newOpp : Trigger.new)
            {
                if(opp_con_map.containsKey(newOpp.id)){
                    newOpp.Price_Agreement_Contract__c=opp_con_map.get(newOpp.id);
                }
            }
        }
        if(Trigger.isAfter && Trigger.isUpdate)
        {
            for(Opportunity newOpp : Trigger.new)
            {
                if(newOpp.Renew_Contract_Option__c != 'Don\'t Renew Contract' && newOpp.Renewal_Quote_Creation__c && !trigger.oldMap.get(newOpp.Id).Renewal_Quote_Creation__c && newOpp.SBQQ__RenewedContract__c != null)
                {
                    //// new list of renewel quote list
                    lst_BulkRenew.add(newOpp);
                }
            }
            /*if(!lst_BulkRenew.isEmpty())
            {
                CreateAmendRenewalHelper.CreateBulkQuotes(lst_BulkRenew);
                //creating a renewal quote
            } */  
        }
    }
}