/*------------------------------------------------------------
Author:         Yogi
Company:        Salesforce.com
Description:    Temporary schedulable job to clear teh REcord_job record from 
SBQQ__JobStatus__c object when calculation has completed 
but status has not been updated by Heroku service
Test Class:     Non

History:
<Date>          <Authors Name>      <Brief Description of Change>
06/09/2017      Yogi       Initial Creation 

------------------------------------------------------------*/
global class Temp_QuoteJobRecordClearanceJobScheduler implements Schedulable{
    
    
    
    global void execute(SchedulableContext sc) {
        
        Map<Id, SBQQ__RecordJob__c> queuedJobsMap = new Map<Id, SBQQ__RecordJob__c>([Select Id, name, SBQQ__IsRead__c, SBQQ__JobId__c, SBQQ__RecordId__c, SBQQ__JobDetails__c, SBQQ__JobStatus__c, createddate, owner.name 
                                                                                     FROM SBQQ__RecordJob__c 
                                                                                     where SBQQ__JobStatus__c = 'Queued']);
        
        Map<Id, SBQQ__RecordJob__c> quoteIDToRecordJobMap = new Map<Id, SBQQ__RecordJob__c>();
        
        //get quote Id's from record job recs
        //Sameple SBQQ__RecordId__c = 005V000000466yBIAQ::a0v61000002lhIKAAY::QuoteCalculator
        for (SBQQ__RecordJob__c qj: queuedJobsMap.values()){
            Id quoteID = qj.SBQQ__RecordId__c.substringAfter('::').substringBefore('::');
            quoteIDToRecordJobMap.put(quoteID, qj);
            system.debug ('quoteID: ' + quoteID);
        }
        
        //Retrieve the quotes
        //If they have been modified by the Oauth user, then we can set job status to completed
        //remove ones that are not modified by Oauth user from list
        if (quoteIDToRecordJobMap.size()>0){
            List<SBQQ__Quote__c> quoteList = [SELECT Id,LastModifiedBy.name FROM SBQQ__Quote__c where Id in :quoteIDToRecordJobMap.keyset()];
            
            Map<Id, SBQQ__RecordJob__c> quoteIDToRecordJobMapQL = new Map<Id, SBQQ__RecordJob__c>(); // for secondary evaluation
            for (SBQQ__Quote__c q: quoteList){
                if (q.LastModifiedBy.name != 'Salesforce Administrator'){
                    //add it for evaluation at quote line level
                    quoteIDToRecordJobMapQL.put(q.id, quoteIDToRecordJobMap.get(q.id));
                    quoteIDToRecordJobMap.remove(q.Id);
                    
                }
                
            }
            //the remaining record job recs can be set to completed
            for (SBQQ__RecordJob__c rj: quoteIDToRecordJobMap.values()){
                rj.SBQQ__JobStatus__c = 'Completed';
            }    
            
            //for the QL Eval set, check if quote lines were last updated by SF admin (can remove these as well in case quote header was already updated by someone else)
            String quoteForEval = 'List of Quotes that did not get picked up by job. Needs manual review \n' ;
            Boolean quoteNeedManualReview = false;
            if (quoteIDToRecordJobMapQL.size() > 0){
                List<SBQQ__QuoteLine__c> quoteLines = [select ID, LastModifiedBy.name, SBQQ__Quote__c from SBQQ__QuoteLine__c where SBQQ__Quote__c = :quoteIDToRecordJobMapQL.keyset()];
                for (SBQQ__QuoteLine__c ql: quoteLines){
                    system.debug('quote line Id: ' + ql.id + ' LastModifiedBy ' + ql.LastModifiedBy.name);
                    if (ql.LastModifiedBy.name != 'Salesforce Administrator'){
                        if (quoteIDToRecordJobMapQL.containsKey(ql.SBQQ__Quote__c)){
                            quoteIDToRecordJobMapQL.remove(ql.SBQQ__Quote__c); //not updated by oauth user...remove from update consideration set
                            quoteNeedManualReview = true;
                            quoteForEval = quoteForEval + ql.SBQQ__Quote__c + '\n';
                        }   
                    }
                }
                for (SBQQ__RecordJob__c rj: quoteIDToRecordJobMapQL.values()){
                    rj.SBQQ__JobStatus__c = 'Completed';
                }   
                
            }
            
            
            
            
            system.debug ('recordJobToquoteIds.values(): ' + quoteIDToRecordJobMap.values());
            Update quoteIDToRecordJobMap.values();
            system.debug ('recordJobToquoteIdsQL.values(): ' + quoteIDToRecordJobMapQL.values());
            Update quoteIDToRecordJobMapQL.values();
            
            System.debug('quoteForEval: ' + quoteForEval);
            if (quoteNeedManualReview){
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                String[] toAddresses = new String[] {'myogaratnam@salesforce.com', 'josh.fleury@hologic.com', 'Jennifer.O\'Reilly@hologic.com'};
                mail.setToAddresses(toAddresses);
                mail.setSubject('Quotes Job Record Job: Quotes needing manual review ');
                mail.setPlainTextBody(quoteForEval);
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
            }
        }
    }
}