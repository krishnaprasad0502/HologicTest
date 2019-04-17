trigger ContractRenewalTrigger on Contract (before update, after update) 
{
    Boolean isActive=false;
    try{
        isActive=[SELECT Name, Active__c FROM Trigger_Switch__C WHERE Name = 'ContractRenewalTrigger'].Active__c;  
    }catch(QueryException q){
        
    }
    
    if(isActive || test.IsRunningTest())
    {
        Map<String, Opportunity> map_ConOpp = new Map<String, Opportunity>();
        Map<String, Opportunity> map_newConOpp = new Map<String, Opportunity>();
        List<Contract> lst_cons = new List<Contract>();
        map_ConOpp = CreateAmendRenewalHelper.FindOpp(Trigger.new);
        List<Contract> contractList = [SELECT Id, Automatic_Renewal__c, SBQQ__RenewalOpportunity__c,Status,Contract_End_Date__c,Termination_Date__c, Amended_Contract__c, (SELECT Id, Tier__c,End_Date__c,Header_Update__c,Active__c  FROM Agreed_Price__r), (SELECT Id, Tier__c, Expiration_Date__c, Header_Update__c, Selected__c from Customer_Eligible_Contracts__r ) from Contract where Id in :Trigger.new];
        
        //List<Contract> activeContractList = [SELECT Id, StartDate, Contract_End_Date__c,Status, (SELECT Id, Header_Update__c FROM Agreed_Price__r where  Active__c = True ), (SELECT Id, Header_Update__c from Customer_Eligible_Contracts__r where Selected__c = True) from Contract where Id in :Trigger.new];
        //List<Agreed_Price__c> agreedPriceList = new List<Agreed_Price__c>();
        //List<Customer_Eligible_Contract__c> cecList = new List<Customer_Eligible_Contract__c>();
        List<Agreed_Price__c> agreedPriceList = [SELECT Id, Agreed_Price_Group__c, Contract__c from Agreed_Price__c where Contract__c IN: contractList];
        List<Agreed_Price_Group__c> agreedPriceGroupList = [SELECT Id, Contract__c from Agreed_Price_Group__c where Contract__c IN: contractList];
        
        //Boolean isTier = false;
        //Boolean noTier = false;
        
        if(Trigger.isBefore){
            //SBQQ__RenewalOpportunity__c
            for(Contract con : Trigger.new)
            {   
                //Updating Amendmended Contracts once activated
                //ContractTriggerActions.updateAmendedContract(con);
                if(con.Amended_Contract__c != NULL){
                    Contract amendedContract = [SELECT Id, Contract_End_Date__c, StartDate, Status FROM Contract where Id =:con.Amended_Contract__c];
                    //amendedContract.Contract_End_Date__c = con.StartDate.addDays(-1);
                    if(amendedContract.Status != 'Expired'){
                        amendedContract.Status = 'Expired';
                        update amendedContract;
                        //update end date to terminate amended contract
                        if(con.StartDate.addDays(-1) > amendedContract.StartDate){
                            amendedContract.Contract_End_Date__c = con.StartDate.addDays(-1);
                            amendedContract.Automatic_Renewal__c = false;
                            update amendedContract;
                        }
                    }
                }

                //Updating Contract Validations to check for Agreed Price Groups if groups are used on the contract
                boolean agreedPriceGroupsExist = false;
                //Checking if Groups are on the Contract
                for (Agreed_Price_Group__c agreedPriceGroup : agreedPriceGroupList){
                    if(agreedPriceGroup.Contract__c == con.Id){
                        agreedPriceGroupsExist = true;
                    }
                }

                for(Agreed_Price__c ap : agreedPriceList){                         
                    //If Groups are on the Contract and Agreed Prices aren't associated to a group then throw an error
                    if(ap.Agreed_Price_Group__c == null && agreedPriceGroupsExist && ap.Contract__c == con.Id){
                        con.addError('All Agreed Prices must be associated to an Agreed Price Group if groups are used');
                    }
                }
                System.debug('agreedPriceGroupList'+agreedPriceGroupList);
                System.debug('agreedPriceList'+agreedPriceList);
            }
        }




               /* if(con.Automatic_Renewal__c && !Trigger.oldMap.get(con.Id).Automatic_Renewal__c)
                {
                    Opportunity opp;
                    if(map_ConOpp.containsKey(con.Id))
                    {
                        opp = map_ConOpp.get(con.Id);
                        con.SBQQ__RenewalOpportunity__c = opp.Id;
                    }
                    else
                    {
                        map_newConOpp.put(con.Id, null);
                    }
                }
                
                //System.debug('Contract status:'+con.Status);
                //System.debug('Old status:'+Trigger.oldMap.get(con.Id).Status);
                
                if(con.Status == 'Activated'){
                    
                    for(Contract con1 : contractList){
                        Contract updatedCon = Trigger.oldMap.get(con1.Id);
                        System.debug('UpdatedCon:'+updatedCon);
                        //System.debug('Yo yo:'+con1.Contract_End_Date__c == updatedCon.Contract_End_Date__c);
                        System.debug('HW1:'+con1.getSObjects('Customer_Eligible_Contracts__r'));
                        for(Customer_Eligible_Contract__c cec : con1.getSObjects('Customer_Eligible_Contracts__r')){
                            if(cec.Selected__c == true){
                                if(cec.Tier__c != null || cec.Tier__c > 0)
                                    isTier = true;
                                else if(cec.Tier__c < 1 || cec.Tier__c == null)
                                    noTier = true;
                            }
                            
                        }
                        System.debug('HW2:'+con1.getSObjects('Agreed_Price__r'));
                        for(Agreed_Price__c ap : con1.getSObjects('Agreed_Price__r')){
                            if(ap.Active__c == True){
                                if(ap.Tier__c != null || ap.Tier__c > 0)
                                    isTier = true;
                                else if(ap.Tier__c < 1 || ap.Tier__c == null)
                                    noTier = true;
                            }
                        }
                        
                        System.debug('IsTier:'+isTier);
                        System.debug('noTier:'+noTier);
                        
                        if(isTier && noTier)
                            con.addError('Kindly ensure that Tier is populated on all Customer Eligible Contract and Agreed Price records associated with this Contract.');
                        else if(isTier && !noTier)
                            con.Tier_Included__c = true;

                        if(con.Amended_Contract__c != NULL){
                            Contract amendedContract = [SELECT Id, Contract_End_Date__c, StartDate, Status FROM Contract where Id =:con.Amended_Contract__c];
                            //amendedContract.Contract_End_Date__c = con.StartDate.addDays(-1);
                            if(amendedContract.Status != 'Expired'){
                                amendedContract.Status = 'Expired';
                                update amendedContract;
                                //update end date to terminate amended contract
                                if(con.StartDate.addDays(-1) > amendedContract.StartDate){
                                    amendedContract.Contract_End_Date__c = con.StartDate.addDays(-1);
                                    amendedContract.Automatic_Renewal__c = false;
                                    update amendedContract;
                                }
                            }
                        }
                    }
                }
            }
            if(!map_newConOpp.isEmpty())
            {
                map_newConOpp = CreateAmendRenewalHelper.CreateBulkOpp(map_newConOpp, 'Renewal');
                for(Contract con : Trigger.new)
                {
                    Opportunity opp;
                    if(map_newConOpp.containsKey(con.Id))
                    {
                        opp = map_newConOpp.get(con.Id);
                        con.SBQQ__RenewalOpportunity__c = opp.Id;
                    }
                }
            }
        }*/
        
        /*if(Trigger.isAfter){
            //if(GlobalUtility.runOnce()){
                for(Contract con1 : contractList){
                    Contract updatedCon = Trigger.oldMap.get(con1.Id);
                    System.debug('UpdatedCon:'+updatedCon);
                    System.debug('HW1:'+con1.getSObjects('Customer_Eligible_Contracts__r')); 
                    if(con1.Status == 'Activated' && con1.Status == updatedCon.Status){
                        for(Customer_Eligible_Contract__c cec : con1.getSObjects('Customer_Eligible_Contracts__r')){
                            if(con1.Contract_End_Date__c != updatedCon.Contract_End_Date__c && cec.Selected__c == True){
                                System.debug('Yuppy1');
                                cec.Expiration_Date__c = con1.Contract_End_Date__c;
                                if(cec.Header_Update__c)
                                    cec.Header_Update__c = false;
                                else
                                    cec.Header_Update__c = true;
                                //if((updatedCon.Status == 'Expired' || updatedCon.Status == 'Terminated') && cec.Expiration_Date__c >= updatedCon.LastModifiedDate)
                                //cec.Selected__c = true;
                                
                                
                                cecList.add(cec);
                            }    
                        } 
                        System.debug('HW2:'+con1.getSObjects('Agreed_Price__r'));
                        for(Agreed_Price__c ap : con1.getSObjects('Agreed_Price__r')){
                            if(con1.Contract_End_Date__c != updatedCon.Contract_End_Date__c && ap.Active__c == True){
                                System.debug('Yuppy2');
                                ap.End_Date__c = con1.Contract_End_Date__c;
                                
                                if(ap.Header_Update__c)
                                    ap.Header_Update__c = false;
                                else
                                    ap.Header_Update__c = true;
                                
                                agreedPriceList.add(ap);
                                
                                
                            } 
                        }      
                        
                    }
                    
                    if(con1.Status == 'Activated' && (updatedCon.Status == 'Terminated' || updatedCon.Status == 'Expired')){
                        for(Customer_Eligible_Contract__c cec : con1.getSObjects('Customer_Eligible_Contracts__r')){
                            if(cec.Expiration_Date__c >= con1.Termination_Date__c){
                                cec.Selected__c = True;
                                if(con1.Contract_End_Date__c != updatedCon.Contract_End_Date__c)
                                    cec.Expiration_Date__c = con1.Contract_End_Date__c;
                                if(cec.Header_Update__c)
                                    cec.Header_Update__c = false;
                                else
                                    cec.Header_Update__c = true;
                                
                                cecList.add(cec);
                            }
                        }
                        for(Agreed_Price__c ap : con1.getSObjects('Agreed_Price__r')){
                            if(ap.End_Date__c >= con1.Termination_Date__c){
                                ap.Active__c = True;
                                if(con1.Contract_End_Date__c != updatedCon.Contract_End_Date__c)
                                    ap.End_Date__c = con1.Contract_End_Date__c;
                                if(ap.Header_Update__c)
                                    ap.Header_Update__c = false;
                                else
                                    ap.Header_Update__c = true;
                                agreedPriceList.add(ap);
                            }
                        }
                        
                        con1.Termination_Date__c = null;
                        lst_cons.add(con1);    
                    }  
                    
                    
                    if((con1.Status == 'Expired' || con1.Status == 'Terminated') && updatedCon.Status == 'Activated'){
                        for(Customer_Eligible_Contract__c cec : con1.getSObjects('Customer_Eligible_Contracts__r')){
                            cec.Selected__c = False;
                            if(cec.Header_Update__c)
                                cec.Header_Update__c = false;
                            else
                                cec.Header_Update__c = true;
                            
                            cecList.add(cec);
                        }
                        for(Agreed_Price__c ap : con1.getSObjects('Agreed_Price__r')){
                            ap.Active__c = False;
                            if(ap.Header_Update__c)
                                ap.Header_Update__c = false;
                            else
                                ap.Header_Update__c = true;
                            agreedPriceList.add(ap);
                        }   
                    }
                }
                
            //}
            System.debug('CECList:'+cecList);
            System.debug('AP List:'+agreedPriceList);
        }
        
        if(agreedPriceList.size()> 0)
            update agreedPriceList;
        if(cecList.size()>0)
            update cecList;
        if(lst_cons.size()>0)
            update lst_cons;*/
    }
}