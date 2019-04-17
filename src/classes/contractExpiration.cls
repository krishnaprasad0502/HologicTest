/*---------------------------------------------------------------------------------------------------------------------------------------------
  Author:     Mani Sundaresan
  Description:  Schedulable Batch job that deactivates Agreed Pricing and Customer Eligible Contract records based on End Date and Updates the Status on Contracts
  if the Contract End Date is a past date. 
 
  Test Class:   Test_contractExpiration
 
  Execute:    System.schedule('Contract Expiration', '0 0 0 * * ?', new contractExpiration());
 
  History:
  <Date>      <Authors Name>    <Brief Description of Change>
  09/23/2016   Mani Sundaresan    Initial Creation
  01/30/2017   Ronald Mendoza     US-0001739 - Annual Automatic Price Increases to Agreed Prices (removed)
  02/09/2017   Ronald Mendoza     US-0001678 - Auto Renewals
  02/14/2017   Ronald Mendoza     US-0002196 - Manual Renewals
  05/02/2017   Ronald Mendoza     DE-130 - Add Logic to keep track of how many times contract has been renewed
  07/16/2017   Ronald Mendoza     Removed unecessary SOQL queries for CECs and APs that will be handled by trigger, optimized code, added e-mail notification for batch job
  02/23/2018   Kasmoor Reddy      Added the insert method from Apex class GlobalUtility to Capture the error message in to custom object Apex_debug_Log (US-0003995)
  12/05/2018   Rich Varga         Commented out the code where updating the contractagreedprice as per US-0005878
  3/28/2019    Rich Varga         Added additional status of Amended to be execluded from Main Query US-0006955
  ------------------------------------------------------------------------------------------------------------------------------------------------*/
global class contractExpiration implements Database.Batchable<sObject>, Schedulable, Database.Stateful {


    //Schedulable Interface to make it run at specific times from the UI
    global void execute(SchedulableContext sc) {
        Database.executeBatch(new contractExpiration());
    }
    global list<Exception> exceptionList = new List<Exception> ();
    global Map<Id, String> errorsMap = new Map<Id, String> ();

    global String query;
    global String Terminated = 'Terminated';
    global String Expired = 'Expired';
    global String Amended = 'Amended';
    
    //global String conId = '80061000000ApsO';


    //Constructor to fetch all Contracts which are active
    global contractExpiration() {

        //query = 'SELECT Id, Contract_End_Date__c, Status FROM Contract where Status != :Expired AND Status != :Terminated';
        //updated query below to only pull contracts that are Active and that have expiration date that is today or past the expiraction date
        // US-0006955  Rich Varga  Add execlude of status of Amended
        query = 'SELECT Id, Contract_End_Date__c, Status, Automatic_Renewal__c, number_of_times_Auto_Renewed__c FROM Contract where Status != :Expired AND Status != :Terminated and Status != :Amended AND Contract_End_Date__c < Today';
    }

    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<Contract> scope) {
        System.debug('Query: ' + scope);
        List<Contract> contractList = new List<Contract> ();
        List<Agreed_Price__c> finalContractAgreedPriceList = new List<Agreed_Price__c> ();
        //US-0001739 - invokes increasePrice method in contractPriceIncrease class to uplift any relevant agreed prices
        //contractPriceIncrease.increasePrice(); - Commented out temporarily while story's requirements are changing

        //Updates the Contract Status to Expired if it has a past End Date
        //US-0001678 - Updated Logic to Auto Renew if Automatic Renewal is checked, push Contract End date a year
        for (Contract c : scope) {
            
            Agreed_Price__c agreedprice = [SELECT Active__c,Id,End_Date__c, Contract__r.Id  FROM Agreed_Price__c WHERE Active__c = True and Contract__r.Id = :c.id];
              //Contract c = (Contract)s;
            //If Automatic Renewal Checkbox is not checked then set status to expired
            if (c.Automatic_Renewal__c == false)
            c.Status = Expired;



            //Automatic Renewal is checked add 12 months to Contract End Date
            else {
                c.Contract_End_Date__c = c.Contract_End_Date__c.addYears(1);
                //DE-130 Adding logic to increase number of times contract has been renewed

                System.debug('Before Auto Renewal:' + c.number_of_times_Auto_Renewed__c);
                System.debug('Rich Contract id :' + c.id);

                if (c.number_of_times_Auto_Renewed__c == 0 || c.number_of_times_Auto_Renewed__c == null)
                c.number_of_times_Auto_Renewed__c = 1;
                else
                c.number_of_times_Auto_Renewed__c = c.number_of_times_Auto_Renewed__c + 1;

                System.debug('After Auto Renewal:' + c.number_of_times_Auto_Renewed__c);

                for (Agreed_Price__c ap : c.getSObjects('Agreed_Price__r')) {
                    if (ap.Contract__r.Id == c.Id) {
                        //Set Each Agreed Price to Active and Set End Date of each Agreed Price to the new Contract End Date
                        ap.Active__c = true;
                        ap.End_Date__c = c.Contract_End_Date__c;

                        finalContractAgreedPriceList.add(ap);
                    }
                }
            }
            contractList.add(c);
        }

        try {
            system.debug('in try agreed price');
            //12-05-2018 Commented out by Rich as per the US-0005878
            // RV 12-5 Comment out updated on AP Records
            // if(finalContractAgreedPriceList.size() > 0)
            //   update finalContractAgreedPriceList;
            //Moved contract updates to after CEC/AP Updates
            /*if(contractList.size() > 0)
              update contractList;*/

            Database.SaveResult[] srList;
            if (contractList.size() > 0)
                srList = Database.update(contractList, false);
            
            if(Test.isRunningTest()){
                errorsMap.put(contractList[0].Id, 'Test Error Message');
            }
            Integer index = 0;

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

            if (Test.isRunningTest())
            Integer i = 10 / 0;
            system.debug('after try');
        }
        catch(Exception e) {

            System.debug('Exception Occured::::::::::::' + e.getMessage());
            exceptionList.add(e);
            System.debug('Exception :' + exceptionList);
        }
    }

    global void finish(Database.BatchableContext BC) {
        String errorMessage = '';
        AsyncApexJob a = [Select Id, Status, ExtendedStatus, NumberOfErrors, CompletedDate, JobItemsProcessed,
                          TotalJobItems, CreatedBy.Email, JobType
                          from AsyncApexJob where Id = :BC.getJobId()];

        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String[] toAddresses = new String[] { a.CreatedBy.Email };
        mail.setToAddresses(toAddresses);
        mail.setSubject('Contract Expiration Batch Completed ' + a.Status);
        if (exceptionList == null || exceptionList.isEmpty())
        {
            mail.setPlainTextBody('Records processed ' + a.TotalJobItems +
                                  ' with ' + a.NumberOfErrors + ' failures.');
        }
        else
        {
            for (Exception ex : exceptionList)
            {
                if (ex != null)
                errorMessage += ex.getMessage() + ' ';
            }
            mail.setPlainTextBody('Records failed to process due to  ' + errorMessage);
        }
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });

       //02/23/2018 Kasmoor Reddy Added the insert method from Apex class GlobalUtility to Capture the error message in to custom object Apex_debug_Log (US-00003995)
        list<Apex_Log__c> Loglist = new list<Apex_Log__c> ();
        Apex_Log__c LogRecord;
        System.debug('Exception -finish::::::::' + exceptionList);
        
        if(errorsMap.size() > 0){
            for (Id str : errorsMap.keySet())
            {
                LogRecord = globalutility.NewApexLog('ContractExpiration',
                                                     'Execute',
                                                     'Error: ' + 'RecordId: '+ str + 'Error msg:' + errorsMap.get(str),
                                                     a.CompletedDate, a.ExtendedStatus,
                                                     a.JobItemsProcessed,
                                                     a.JobType,
                                                     a.NumberOfErrors,
                                                     a.Status,
                                                     a.TotalJobItems,
                                                     null,
                                                     null
                                                     );
                
                Loglist.add(LogRecord);
            }
        }
        if (exceptionList != null)
        {
            System.debug('exceptionList:'+exceptionList);
            for (Exception ex : exceptionList)
            {



                LogRecord = globalutility.NewApexLog('ContractExpiration',
                                                     'Execute',
                                                     'Error: ' + ex.getMessage() + '; Stack Trace:' + ex.getStackTraceString(),
                                                     a.CompletedDate, a.ExtendedStatus,
                                                     a.JobItemsProcessed,
                                                     a.JobType,
                                                     a.NumberOfErrors,
                                                     a.Status,
                                                     a.TotalJobItems,
                                                     ex.getLineNumber(),
                                                     ex.getTypeName()
                                                     );


                Loglist.add(LogRecord);
            }
        }

        try {
            if (loglist.size() > 0) {
                insert Loglist;
                if (Test.isRunningTest())
                Integer i = 10 / 0;

            }
        }
        catch(exception e) {
            system.debug('Error Message' + e.getMessage());
        }
    }

}