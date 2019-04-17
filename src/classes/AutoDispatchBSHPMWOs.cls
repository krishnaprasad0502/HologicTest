/*---------------------------------------------------------------------------------------------------------------------------------------------
Author:     Kasmoor Reddy
Description:  Schedulable Batch job that will auto dispatch the B&SH PM work orders through FSL schedule service class.

Execute:    System.schedule('AutoDispatchBSHPMWOs', '0 0 0 * * ?', new AutoDispatchBSHPMWOs());

Test Class:   AutoDispatchBSHPMWOs_test 

History:
<Date>      <Authors Name>    <Brief Description of Change>
04/10/2019   Kasmoor Reddy    Initial Creation(US-0005544)
------------------------------------------------------------------------------------------------------------------------------------------------*/
global class AutoDispatchBSHPMWOs implements Database.Batchable<sObject>, Schedulable,Database.AllowsCallouts,Database.Stateful{ 
    
    
    //Schedulable Interface to make it run at specific times from the UI with batch size 1
    global void execute(SchedulableContext sc){
        Database.executeBatch(new AutoDispatchBSHPMWOs(),1);    
    }
    global String query;
    global string owneremail;
    global Date terminatedDate = System.today()+30;
    global DateTime dateconv = DateTime.newInstance(terminatedDate.year(), terminatedDate.month(), terminatedDate.day(),0-1,0,0);
    
    global list<Exception> exceptionList = new List<Exception>();
    global string Error;
    //Constructor to fetch all service appointments satisfying the criteria.
    global AutoDispatchBSHPMWOs(){
        //system.debug('dateconv----'+dateconv);
        //query = 'SELECT id,FSL__Scheduling_Policy_Used__c,FSL__Related_Service__c from ServiceAppointment where id= \'08p4N000000TPXh\' and Status=\'None\' and Related_Work_Order__r.WorkType.Division__c = \'BSH\' and Related_Work_Order__r.WorkType.Name like \'PM Auto%\' and DAY_ONLY(dueDate)=:terminatedDate limit 1';
        query = 'SELECT id,FSL__Scheduling_Policy_Used__c,FSL__Related_Service__c,Owner.Email from ServiceAppointment where Status=\'None\' and Related_Work_Order__r.WorkType.Division__c = \'BSH\' and Related_Work_Order__r.WorkType.Name like \'PM Auto%\' and DAY_ONLY(dueDate)=:terminatedDate';
    }
    global Database.QueryLocator start(Database.BatchableContext BC) {
        // collect the batches of records or objects to be passed to execute
        return Database.getQueryLocator(query);
    }     
    global void execute(Database.BatchableContext BC, List<ServiceAppointment> sAList) {
        // process each batch of records
       system.debug(sAList);
        for(ServiceAppointment saDetails : sAList)
        {        
            //Invoke the ScheduleService Class from the FSL package to auto dispatch the ServiceAppointment records fetched in the Start Method
            // FSL.ScheduleService class
            // The Schedule method returns a ScheduleResult result
            FSL.ScheduleResult myResult = new FSL.ScheduleResult();
            // static FSL.ScheduleResult Schedule(Scheduling Policy ID, Service Appointment ID)
            if(saDetails.Owner.Email!=null)
                owneremail = saDetails.Owner.Email;
            system.debug('FSL__Scheduling_Policy_Used__c'+saDetails.FSL__Scheduling_Policy_Used__c);
                myResult = FSL.ScheduleService.schedule(saDetails.FSL__Scheduling_Policy_Used__c,saDetails.id);
                system.debug('myResult:::'+myResult);
                 system.debug('owneremail:::'+owneremail);
                
            
            
        }
        
        
    }   
    
    global void finish(Database.BatchableContext BC){
        String errorMessage='';
        AsyncApexJob a = [Select Id, Status,ExtendedStatus,NumberOfErrors,CompletedDate,JobItemsProcessed,TotalJobItems, CreatedBy.Email,JobType from AsyncApexJob where Id =:BC.getJobId()];
        User u = [Select id,Name,Email from User where Name = 'Salesforce Administrator'];
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        if(owneremail!=null)
        {
        String[] toAddresses = new String[] {owneremail};
       
        String[] ccAddresses = new String[] {u.Email};    
            mail.setToAddresses(toAddresses);
            mail.setccAddresses(ccAddresses);
        mail.setSubject('AutoDispatchBSHPMWOs Batch Completed ' + a.Status);
        if(exceptionList==null||exceptionList.isEmpty())
        {
            mail.setPlainTextBody('Records processed ' + a.TotalJobItems +  ' with '+ a.NumberOfErrors + ' failures.');
        }
        system.debug(toAddresses);
        system.debug(mail);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });   
        }
        
    }
}