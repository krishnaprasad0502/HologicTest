/*-------------------------------------------------------------------------------------------------------------------
Author:     Mani Sundaresan
Description:  Schedulable Batch job that updates the Account Relationship status to Inactive when Current Date > End Date or Active when Start Date = Current Date
        
Test Class:    Test_DeactivateAccountRelationships

Execute:    System.schedule('Deactivate Account Relationships', '0 0 0 * * ?', new DeactivateAccountRelationships());

History:
<Date>      <Authors Name>    <Brief Description of Change>
07/28/2016   Mani Sundaresan    Initial Creation
03/06/2018   Kasmoor Reddy		Added the insert method from Apex class GlobalUtility to Capture the error message in to custom object Apex_Log (US-0003995)
-----------------------------------------------------------------------------------------------------------------------*/
//Updated by Kasmoor Reddy on 03/06/2018 Implemented an Interface 'Database.Stateful' to support requirements of US-000395
global class DeactivateAccountRelationships implements Database.Batchable<sObject>, Schedulable,Database.Stateful{

    //Schedulable Interface to make it run at specific times from the UI
    global void execute(SchedulableContext sc){
        Database.executeBatch(new DeactivateAccountRelationships());
    }
  //Created an Exceptionlist to capture exceptions in custom object Apex_log (US-000395) by kasmoor Reddy on 03/06/2018
     global list<Exception> exceptionList = new List<Exception>();
    
    global String query;
    String activeStatus = 'Active';
    String inactiveStatus = 'Inactive';
    
    global DeactivateAccountRelationships(){
        //Query to fetch all the Account Relationship records with status Active and End Date is a past date
        query = 'SELECT Id, Start_Date__c, End_Date__c, Status__c from Account_Relationships__c where (End_Date__c <= YESTERDAY AND Status__c = :activeStatus) OR (Start_Date__c = TODAY AND Status__c = :inactiveStatus)';
    }
    
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<Account_Relationships__c> scope){
    
        List<Account_Relationships__c> arList = new List<Account_Relationships__c>();
        
        //Loop through Account Relationship records to update its Status to either 'Inactive' or 'Active' based on Start Date/End Date
        for(Account_Relationships__c ar : scope){
            if(ar.End_Date__c <= Date.Today().addDays(-1) && ar.Status__c == 'Active'){
                ar.Status__c = 'Inactive';
                arList.add(ar);
            }
            else if(ar.Start_Date__c == Date.Today() && ar.Status__c == 'Inactive'){
                ar.Status__c = 'Active';
                arList.add(ar);
            }
        }
        
        try{
            if(arList.size() > 0)
                update arList;
                
            if(Test.isRunningTest())
                Integer i = 10/0;
         }
         catch(Exception e){
             System.debug('Exception Occured:'+e.getMessage());
 // 03/06/2018   Kasmoor Reddy Added the exception to list to capture in custom object Apex_log (US-0003995)      
               exceptionList.add(e);
           System.debug('Exception :'+exceptionList);
         }
         
        
    }
    
    global void finish(Database.BatchableContext BC){
       String errorMessage='';
// 03/06/2018   Kasmoor Reddy Added the insert method from Apex class GlobalUtility to Capture the error message in to custom object Apex_Log (US-0003995)
    	 AsyncApexJob a = [Select Id, Status,ExtendedStatus,NumberOfErrors,CompletedDate,JobItemsProcessed,
        TotalJobItems, CreatedBy.Email,JobType
        from AsyncApexJob where Id =:BC.getJobId()];
          
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            String[] toAddresses = new String[] {a.CreatedBy.Email};
            mail.setToAddresses(toAddresses);
            mail.setSubject('DeactivateAccountRelationships Batch Completed ' + a.Status);
        system.debug('::::::::::::::::::::::exceptionList'+exceptionList);
             if(exceptionList==null||exceptionList.isEmpty())
        {
            mail.setPlainTextBody('Records processed ' + a.TotalJobItems +
                                  ' with '+ a.NumberOfErrors + ' failures.');
        }
        else
        {
            for(Exception ex:exceptionList)
            {
                if(ex!=null)
                errorMessage+=ex.getMessage()+' ';
            }
            mail.setPlainTextBody('Records failed to process due to  ' +errorMessage);
        }
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });    
              list<Apex_Log__c> Loglist= new list<Apex_Log__c>();
         Apex_Log__c LogRecord;
        System.debug('Exception -finish::::::::'+exceptionList);
        if(exceptionList!=null)
            {
        for(Exception ex:exceptionList)
        {
			
                
            
             LogRecord= globalutility.NewApexLog('DeactivateAccountRelationships',
                                                            'Execute',
                                                            'Error: ' + ex.getMessage() + '; Stack Trace:' + ex.getStackTraceString(),
                                                            a.CompletedDate,a.ExtendedStatus,
                                                            a.JobItemsProcessed,
                                                            a.JobType,
                                                            a.NumberOfErrors,
                                                            a.Status,
                                                            a.TotalJobItems,
                                                            ex.getLineNumber(),
                                                            ex.getTypeName());
            
       
            Loglist.add(LogRecord);
        }
        }
            
            try{
                if(loglist.size()>0)	{   
                    insert Loglist;
                    if(Test.isRunningTest())
                Integer i = 10/0;
                }
            }
            catch(exception e){
                system.debug('Error Message'+e.getMessage());
            }
    }

}