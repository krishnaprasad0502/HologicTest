global class PopulateContractAgreedPrice implements Database.Batchable<sObject>, Schedulable{

    global void execute(SchedulableContext sc){
        Database.executeBatch(new PopulateContractAgreedPrice());    
    }
    
    global String query;
    
    global PopulateContractAgreedPrice(){
    
        query = 'SELECT Id, Contract__c from Customer_Eligible_Contract__c where Selected__c = true and Contract__r.Status = \'Activated\' and Contract__r.Division__c INCLUDES (\'BSH\')';
        
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<Customer_Eligible_Contract__c> scope) {
    
        
         Set<Id> contractId = new Set<Id>();
         Integer count = 0;
         List<Contract_Agreed_Price__c> capList = new List<Contract_Agreed_Price__c>();
         List<Contract_Agreed_Price__c> capList1 = new List<Contract_Agreed_Price__c>();
         for(Customer_Eligible_Contract__c cec : scope)
             contractId.add(cec.Contract__c);
         
         System.debug('scope:'+scope.size());
         System.debug('contractId size:'+contractId);
        
        List<Agreed_Price__c> apList = [SELECT Id from Agreed_Price__c where Active__c = True and Contract__c IN :contractId];
        
        for(Customer_Eligible_Contract__c cec : scope){
            for(Agreed_Price__c ap : apList){
                Contract_Agreed_Price__c cap = new Contract_Agreed_Price__c(Customer_Eligible_Contract__c = cec.Id, Agreed_Price__c = ap.Id);
                capList.add(cap);
            }
        }
        
        if(capList.size() > 0 && capList.size() < 10001)
            upsert capList;
        else if(capList.size() > 0 && capList.size() > 10000){
            for(Contract_Agreed_Price__c cap : capList){
               
                count++;
                if(count < 10000){
                    capList1.add(cap);
                }
                else if(count == 10000){
                    count = 0;
                    System.enqueueJob(new AsyncExecutionCECAPPopulation(capList1));
                    capList1.clear();
                    capList1.add(cap);
                }
                
                
            }
            System.debug('capList1:'+capList1.size());
            if(capList1.size() > 0)
                upsert capList1;
        }
        
    }

    global void finish(Database.BatchableContext bc) {

    }


}