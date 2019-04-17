/*------------------------------------------------------------------------------------------------------
  Author: John Christy
  Company: Apps Associates    
  Description:  Batch class to remove large data volume records on Contract_Agreed_Price__c object
  Test Class:   Test_ContractAgreedPrice
  History:
  <Date>      <Authors Name>    <Brief Description of Change>
  09/19/2018  John Christy       Logic to remove duplicate records via batch apex on the Contract_Agreed_Price__c junction object
  ---------------------------------------------------------------------------------------------------------*/
global class ContractAgreedPriceBatchDelete implements Database.Batchable<SObject> {

    // constructor to pass list of Contracts and if delete all records
    private Set<Id> newContracts;
    private String objectType;

    global ContractAgreedPriceBatchDelete(Set<Id> listContracts, String thisObjectType) {
        newContracts = listContracts;
        objectType = thisObjectType;
    }

    // query all CAP records for deletion based on objectType
    global Database.QueryLocator start(Database.BatchableContext context) {
        System.debug('Begin Batch Delete ' + objectType);
        System.debug('newContracts: ' + newContracts);

        if (objectType == 'Contract') {
            objectType = 'Customer_Eligible_Contract__r.Contract__c';
        }

        String dbQuery = 'SELECT Id FROM Contract_Agreed_Price__c WHERE ' + objectType + ' IN :newContracts OR ' + objectType + ' = null';
        System.debug('dbQuery: ' + dbQuery);

        return Database.getQueryLocator(dbQuery);
    }

    global void execute(Database.BatchableContext context, List<Contract_Agreed_Price__c> scope) {
        System.debug('Execute');
        System.debug('ContractAgreedPriceBatchDelete Scope Size: ' + scope.size());
        System.debug('ContractAgreedPriceBatchDelete : ' + scope);
        if (!scope.isEmpty()) {
            System.debug('Delete All');
            delete scope;
        }
    }

    global void finish(Database.BatchableContext context) {

    }
}