/*------------------------------------------------------------
Author:         Dave Mansell
Company:        Salesforce.com
Description:    EmailMessage Trigger functions
Test Class:     EmailMessageTriggerActions_Test

History:
<Date>        <Authors Name>      <Brief Description of Change>
05/03/2018    Dave Mansell      Initial Creation (US-0004058)
17/12/2018    Yogitha Malireddy    To display customer emails in community(US-0006345)
9/1/2019      Vinay Nallakadi      To handle special characters in Subject line of a Case Email to avoid error while inserting Content Note at line number 37 (US-0006224)
------------------------------------------------------------*/
public class EmailMessageTriggerActions {
    
    /*------------------------------------------------------------
    Author:             Dave Mansell, Salesforce
    Description:        Checks if parent record is case, if so, updates case summaries
    Inputs:             List of records
    Returns:            N/A
    Test Class(es):     EmailMessageTriggerActions_Test.testCreateNotesForCaseEmails
    ------------------------------------------------------------*/
    public static void createNotesForCaseEmails(List<EmailMessage> emails){
        //Gather parent case IDs and create notes
        Map<Id, List<ContentNote>> notesByCaseId = new Map<Id, List<ContentNote>>();
        List<ContentNote> notesToInsert = new List<ContentNote>();
        for(EmailMessage email : emails){
              if(email.ParentId != null){
            if(email.ParentId.getSObjectType() == Schema.Case.SObjectType && email.Status == '3'){ //Sent emails only
                //Create note
                List<ContentNote> noteList = notesByCaseId.get(email.ParentId);
                if(noteList == null){
                    noteList = new List<ContentNote>();
                }
                
                ContentNote nte = new ContentNote();
                nte.Title = 'Email Sent';
                String content = 'Subject: ' + email.Subject;
                nte.Content = Blob.valueOf(content.escapeHtml4()
);
                
                noteList.add(nte);
                notesByCaseId.put(email.ParentId, noteList);
                notesToInsert.add(nte);
            }
              }
        }
        
        if(notesToInsert.size() > 0){
            insert notesToInsert;
            
            List<ContentDocumentLink> links = new List<ContentDocumentLink>();
            for(Id caseId : notesByCaseId.keySet()){
                for(ContentNote nte : notesByCaseId.get(caseId)){
                    ContentDocumentLink link = new ContentDocumentLink();
                    link.ContentDocumentId = nte.Id;
                    link.LinkedEntityId = caseId;
                    link.ShareType = 'I';
                    links.add(link);
                }
            }
            insert links;
            
            //Update case summaries
            List<Case_Summary__c> summaries = [
                SELECT Id
                  FROM Case_Summary__c
                 WHERE Case__c IN :notesByCaseId.keySet()
            ];
            for(Case_Summary__c summary : summaries){
                summary.Has_Emails__c = true;
            }
            update summaries;
        }
    }
    /*------------------------------------------------------------
    Author:             Yogitha Malireddy, Hexaware
    Description:        Checks if emails received or sent is for customer, if so, stores the emails in Community_Emails__c object
    Inputs:             List of records
    Returns:            N/A
    Test Class(es):     EmailMessageTriggerActions_Test.testtrackCaseEmails
    ------------------------------------------------------------*/
    public static void trackCaseEmails(List<EmailMessage> emailCases){
        Map<Id,List<EmailMessage>> emailMap = new Map<Id,List<EmailMessage>>();
        List<community_emails__c> emailstoinsert = new List<community_emails__c>();
        List<EmailMessage> emailList = new List<EmailMessage>();
        String allAddressesString;
        List<String>toAddress = new List<String>();
        String allccAddressString;
        List<String>ccAddress = new List<String>();
        EmailMessage emMsg = new EmailMessage();
        // get the details from EmailMessage object and store it in a map with caseid
        for(EmailMessage em: emailCases){
                if(em.ParentId != null){
            if(em.ParentId.getSObjectType() == Schema.Case.SObjectType) {
                emMsg.TextBody = em.TextBody;
                emMsg.Subject = em.Subject;
                emMsg.ParentId = em.ParentId;
                emMsg.FromAddress = em.FromAddress;
                emMsg.ToAddress= em.ToAddress;
                emMsg.MessageDate = em.MessageDate;
                emMsg.CcAddress = em.CcAddress;
                emailList.add(emMsg);
                emailMap.put(em.ParentId, emailList);
                System.debug('output of the map' +emailMap +emailList);
            }
                }
        }
        Set<Id> caseIds= emailMap.keySet();
        system.debug('caseIds::' +caseIds);
        //Check if the email contains customer email address and store in the Community_Emails__c object
        Community_Emails__c eminsert = new Community_Emails__c();
        for(case caseem: [Select id, CaseNumber, ContactEmail from case where id In: caseIds]){
            for(EmailMessage em: emailMap.get(caseem.id)){
                allAddressesString = em.ToAddress;
                if(!String.isEmpty(allAddressesString )){
                    toAddress = String.valueOf(allAddressesString).split(';');     
                }    
                //system.debug('toAddress--------' +toAddress);       
                allccAddressString = em.CcAddress;
                if(!String.isEmpty(allccAddressString )){                
                    ccAddress = String.valueOf(allccAddressString).split(';');
                }
                //system.debug('ccAddress------' +ccAddress);
                for(String repAddress: toAddress){
                    //system.debug('repAddress+++++++' +repAddress + 'email0000' +caseem.ContactEmail);
                    if(caseem.ContactEmail == repAddress.trim() || caseem.ContactEmail == em.FromAddress){
                        eminsert.Community_Case__c = em.ParentId;
                        eminsert.Name = em.Subject;
                        eminsert.Community_Email_Body__c = em.TextBody;
                        eminsert.Community_Email_Subject__c = em.Subject;
                        eminsert.Community_Sent_By__c = em.FromAddress;
                        eminsert.Community_Sent_To__c = repAddress;
                        eminsert.Community_Email_Date__c = em.MessageDate;
                        system.debug('eminsert fromadd *** ' +eminsert);
                        emailstoinsert.add(eminsert);
                    }
                }
                if(ccAddress.size() >0){
                    for(String ccAdd: ccAddress){
                        system.debug('ccAdd----' +ccAdd);
                        if(caseem.ContactEmail == ccAdd.trim()){
                            eminsert.Community_Case__c = em.ParentId;
                            eminsert.Name = em.Subject;
                            eminsert.Community_Email_Body__c = em.TextBody;
                            eminsert.Community_Email_Subject__c = em.Subject;
                            eminsert.Community_Sent_By__c = em.FromAddress;
                            eminsert.Community_Sent_To__c = ccAdd;
                            eminsert.Community_Email_Date__c = em.MessageDate;
                            system.debug('eminsert ccAddress***' +eminsert);
                            emailstoinsert.add(eminsert);
                        }
                    }
                }
            }
        }
        system.debug('list to insert****' +emailstoinsert);
        if(emailstoinsert.size() > 0){
            insert emailstoinsert;
        }
    }
}