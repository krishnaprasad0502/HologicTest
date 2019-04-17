/*------------------------------------------------------------------------------------------------------
  Author: John Christy
  Company: Apps Associates    
  Description:  Batch class to insert large data volume into Contract_Agreed_Price__c object
  Test Class:   Test_ContractAgreedPrice
  History:
  <Date>      <Authors Name>    <Brief Description of Change>
  09/19/2018  John Christy       Logic to add records via batch apex on the Contract_Agreed_Price__c junction object
  04/09/2019  Mani Sundaresan    Update the logic to handle governor limits while processing larger data (US-7162)
  ---------------------------------------------------------------------------------------------------------*/
global class ContractAgreedPriceBatchInsert implements Database.Batchable<SObject>, Database.Stateful {

    // constructor to pass list of Contracts
    private Set<Id> newContracts;
    private String objectType;
    global ContractAgreedPriceBatchInsert(Set<Id> listContracts, String thisObjectType) {
        newContracts = listContracts;
        objectType = thisObjectType;
    }
    global list<Exception> exceptionList = new List<Exception> ();
    global Map<Id, String> errorsMap = new Map<Id, String> ();
    global list<AggregateResult> capAgg = new List<AggregateResult> ();
    global Boolean isDMLException = false;

    

    global Database.QueryLocator start(Database.BatchableContext context) {

        System.debug('Begin Batch Insert');
        System.debug('newContracts: ' + newContracts);
        System.debug('objectType: ' + objectType);

        String dbId = 'Contract__r.Id';
        if (objectType == 'Customer_Eligible_Contract__c') {
            dbId = 'Id';
        }
        String dbQuery = 'SELECT Id, Contract__r.Id FROM Customer_Eligible_Contract__c WHERE ' + dbId + ' IN :newContracts AND Selected__c = true';
        return Database.getQueryLocator(dbQuery);
    }

    global void execute(Database.BatchableContext context, List<Customer_Eligible_Contract__c> scope) {

        System.debug('Execute');
        if (objectType == 'Customer_Eligible_Contract__c') {
            newContracts.clear();
            for (Customer_Eligible_Contract__c cec : scope) {
                newContracts.add(cec.Contract__c);
            }
        }
        System.debug('newContracts: ' + newContracts);

        // build map of Agreed Prices for assignment to each CEC
        Map<Id, Agreed_Price__c> apMap = new Map<Id, Agreed_Price__c> ([SELECT Id FROM Agreed_Price__c WHERE Contract__r.Id IN :newContracts AND Active__c = true]);

        Map<String, String> checkMap = new Map<String, String> ();
        Map<Id, Contract_Agreed_Price__c> capMap = new Map<Id, Contract_Agreed_Price__c> ([SELECT Id, Customer_Eligible_Contract__c, Agreed_Price__c
                                                                                          FROM Contract_Agreed_Price__c
                                                                                          WHERE Customer_Eligible_Contract__c IN :scope]);

        for (Contract_Agreed_Price__c cap : capMap.values()) {
            checkMap.put(String.valueOf(cap.Customer_Eligible_Contract__c) + String.valueOf(cap.Agreed_Price__c), '');
        }

        // create list to insert cap records
        List<Contract_Agreed_Price__c> insertContractAgreedPrice = new List<Contract_Agreed_Price__c> ();

        List<Contract_Agreed_Price__c> finalContractAgreedPriceList = new List<Contract_Agreed_Price__c> ();

        Database.SaveResult[] srList;

        try {
            // loop through each CEC within scope to assign an AP 
            for (Customer_Eligible_Contract__c cec : scope) {
                for (Agreed_Price__c ap : apMap.values()) {
                    // if checkMap does not contain key, create new CAP record, then add CEC/AP key to checkMap
                    if (!checkMap.containsKey(String.valueOf(cec.Id) + String.valueOf(ap.Id))) {
                        Contract_Agreed_Price__c cap = new Contract_Agreed_Price__c();
                        cap.Customer_Eligible_Contract__c = cec.Id;
                        cap.Agreed_Price__c = ap.Id;
                        insertContractAgreedPrice.add(cap);
                        checkMap.put(String.valueOf(cec.Id) + String.valueOf(ap.Id), '');
                        System.debug('Inserting CEC: ' + cec.Id + ' AP: ' + ap.Id);
                    }
                }

                System.debug('insertContractAgreedPrice Size: ' + insertContractAgreedPrice.size());
                // loop through CAP records and insert
                // batch controls limit of dml statements in loop to avoid governor limit
                if (!insertContractAgreedPrice.isEmpty()) {
                    //System.debug('Heap Size: ' + Limits.getHeapSize());
                    System.debug('List Size: ' + insertContractAgreedPrice.size());
                    //insert insertContractAgreedPrice;
                    //srList = Database.insert(insertContractAgreedPrice, false);
                    for(Contract_Agreed_Price__c cap : insertContractAgreedPrice)
                        finalContractAgreedPriceList.add(cap);    
                    
                }
                insertContractAgreedPrice.clear();
            }

            Integer index = 0;
            if(finalContractAgreedPriceList.size() > 0){
                srList = Database.insert(finalContractAgreedPriceList, false);

                for (Database.SaveResult sr : srList) {
                        if (sr.isSuccess()) {
                            System.debug('Successfully updated the following record:' + sr.getId());
                        }
                        else {
                            for (Database.Error err : sr.getErrors()) {
                                errorsMap.put(srList[index].getId(), err.getMessage());
                            }
                        }
                        index++;
                }
                System.debug('errorMap:' + errorsMap);
            }
            
        }
        catch(DmlException e) {
            // add error to exceptionList in order to log
            isDMLException = true;
            System.debug('Exception occured when inserting ContractAgreedPrice:' + e.getMessage());
            exceptionList.add(e);
            System.debug('Exception :' + exceptionList);
        }
        catch(Exception e) {
            // add error to exceptionList in order to log
            System.debug('Exception occured when inserting ContractAgreedPrice:' + e.getMessage());
            exceptionList.add(e);
            System.debug('Exception :' + exceptionList);
        }
    }

    global void finish(Database.BatchableContext BC) {
        System.debug('Finish');
        System.debug('Exception List: ' + exceptionList);
        System.debug('ExceptionMap: ' + errorsMap);
        
        
        String errorMessage = '';
        AsyncApexJob a = [Select Id, Status, ExtendedStatus, NumberOfErrors, CompletedDate, JobItemsProcessed,
                          TotalJobItems, CreatedBy.Email, JobType
                          from AsyncApexJob where Id = :BC.getJobId()];

        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String[] toAddresses = new String[] { a.CreatedBy.Email };
        mail.setToAddresses(toAddresses);
        mail.setSubject('ContractAgreedPriceBatchInsert Batch ' + a.Status);

        // throw exception if running test class in order to test failure
        if (Test.isRunningTest()) {
           //Exception ex = new GlobalUtility.GenericException();
            DmlException ex = new DmlException();
            exceptionList.add(ex);
            errorsMap.put(null, ex.getMessage());
            
        }
        list<Apex_Log__c> Loglist = new list<Apex_Log__c> ();
        Apex_Log__c LogRecord;
        // capture legit exception and store in log as well as email user notification
         if(errorsMap.size() > 0) {
             
            for (Id str : errorsMap.keySet())
            {
                LogRecord = globalutility.NewApexLog('ContractAgreedPriceBatchInsert',
                                                     'Execute',
                                                      'Error: ' + 'RecordId: '+ str + 'Error msg:' + errorsMap.get(str),
                                                     a.CompletedDate, a.ExtendedStatus,
                                                     a.JobItemsProcessed,
                                                     a.JobType,
                                                     a.NumberOfErrors,
                                                     a.Status,
                                                     a.TotalJobItems,
                                                     null,
                                                     null);

                Loglist.add(LogRecord);
            }
        }
        if (!exceptionList.isEmpty())
        {
            //list<Apex_Log__c> Loglist = new list<Apex_Log__c> ();
            //Apex_Log__c LogRecord;
            Integer count = 0;
            for (Exception ex : exceptionList) {
                
                if(!isDMLException){
                    LogRecord = globalutility.NewApexLog('ContractAgreedPriceBatchInsert',
                                                     'Execute',
                                                     'Error: ' + ex.getMessage() + '; Stack Trace:' + ex.getStackTraceString(),
                                                     a.CompletedDate, a.ExtendedStatus,
                                                     a.JobItemsProcessed,
                                                     a.JobType,
                                                     a.NumberOfErrors,
                                                     a.Status,
                                                     a.TotalJobItems,
                                                     ex.getLineNumber(),
                                                     ex.getTypeName());
                    
                    if(Test.isRunningTest())
                        isDMLException = true;
                }
                if(isDMLException){
                    Id errorId;
                    if(Test.isRunningTest())
                        errorId = null;
                    else
                        errorId = ex.getDmlId(count); 
                    LogRecord = globalutility.NewApexLog('ContractAgreedPriceBatchInsert',
                                                     'Execute',
                                                     'Error: ' + ex.getMessage() + '; Stack Trace:' + ex.getStackTraceString() +'; RecordId: '+errorId,
                                                     a.CompletedDate, a.ExtendedStatus,
                                                     a.JobItemsProcessed,
                                                     a.JobType,
                                                     a.NumberOfErrors,
                                                     a.Status,
                                                     a.TotalJobItems,
                                                     ex.getLineNumber(),
                                                     ex.getTypeName());
                }
                Loglist.add(LogRecord);

                if (ex != null)
                errorMessage += ex.getMessage() + ' ';
                count++;
            }
        }
        
        try {
            if (loglist.size() > 0) {
                insert Loglist;
            }
        }
        catch(exception e) {
            system.debug('Error Message' + e.getMessage());
        }

        //if (!Test.isRunningTest()) {
            if (exceptionList != null && !exceptionList.isEmpty())
            {
                for (Exception ex : exceptionList)
                {
                    if (ex != null)
                    errorMessage += ex.getMessage() + ' ';
                }
                mail.setPlainTextBody('Records failed to process due to  ' + errorMessage);
                
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
            }
            
        //}
    }

}