/*------------------------------------------------------------
Author:         Dave Mansell
Company:        Salesforce.com
Description:    ContentDocumentLink Trigger functions
Test Class:     ContentDocumentLinkTriggerActions_Test

History:
<Date>        <Authors Name>        <Brief Description of Change>
05/08/2018    Dave Mansell          Initial Creation (US-0004058)
------------------------------------------------------------*/
public class ContentDocumentLinkTriggerActions {
    
    /*------------------------------------------------------------
    Author:             Dave Mansell, Salesforce
    Description:        Checks if parent record is case, if so, updates case summaries
    Inputs:             List of records
    Returns:            N/A
    Test Class(es):     ContentDocumentLinkTriggerActions_Test.testUpdateParentIfCase
    ------------------------------------------------------------*/
    public static void updateParentIfCase(List<ContentDocumentLink> links){
        Set<Id> caseIds = new Set<Id>();
        for(ContentDocumentLink link : links){
            if(link.LinkedEntityId.getSObjectType() == Schema.Case.SObjectType){
                caseIds.add(link.LinkedEntityId);
            }
        }
        
        if(caseIds.size() > 0){
            futureUpdateCases(caseIds);
        }
    }
    
    @future
    private static void futureUpdateCases(Set<Id> caseIds){
        List<Case_Summary__c> summaries = [
            SELECT Id
              FROM Case_Summary__c
             WHERE Case__c IN :caseIds
        ];
        update summaries;
    }
    
    /*------------------------------------------------------------
    Author:             Dave Mansell, Salesforce
    Description:        Checks if parent record is work order, if so, kick off field service report automation
    Inputs:             List of records
    Returns:            N/A
    Test Class(es):     ContentDocumentLinkTriggerActions_Test.testCheckToSendFSREmails
    ------------------------------------------------------------*/
    public static void checkToSendFSREmails(List<ContentDocumentLink> links){
        //Loop through links to find those with User as parent
        //This is step 1 of the OOB report generation
        Set<Id> docIds = new Set<Id>();
        for(ContentDocumentLink link : links){
            if(link.LinkedEntityId.getSObjectType() == Schema.User.SObjectType){
                docIds.add(link.ContentDocumentId);
            }
        }
        
        if(docIds.size() > 0){
            sendFSREmails(docIds);
        }
    }
    
    @future
    private static void sendFSREmails(Set<Id> docIds){
        //Query for all links related to docs
        List<ContentDocumentLink> allLinks = [
            SELECT Id
                  ,ContentDocumentId
                  ,ContentDocument.LatestPublishedVersionId
                  ,ContentDocument.Title
                  ,LinkedEntityId
              FROM ContentDocumentLink
             WHERE ContentDocumentId IN :docIds
        ];
        
        //Filter to make sure they are children of WorkOrders or ServiceAppointments
        List<ContentDocumentLink> woLinks = new List<ContentDocumentLink>();
        List<ContentDocumentLink> saLinks = new List<ContentDocumentLink>();
        for(ContentDocumentLink link : allLinks){
            if(link.ContentDocument.Title.lastIndexOf('_V') != -1){
                if(link.LinkedEntityId.getSObjectType() == Schema.WorkOrder.SObjectType){
                    woLinks.add(link);
                } else if(link.LinkedEntityId.getSObjectType() == Schema.ServiceAppointment.SObjectType){
                    saLinks.add(link);
                }
            }
        }
        
        if(woLinks.size() > 0){
            sendFSREmailsForWOs(woLinks);
        }
        if(saLinks.size() > 0){
            sendFSREmailsForSAs(saLinks);
        }
    }
    
    private static void sendFSREmailsForWOs(List<ContentDocumentLink> links){
        //Gather parent Ids
        Map<Id, ContentDocument> docsById = new Map<Id, ContentDocument>();
        Map<Id, WorkOrder> wosById = new Map<Id, WorkOrder>();
        for(ContentDocumentLink link : links){
            docsById.put(link.ContentDocumentId, null);
            wosById.put(link.LinkedEntityId, null);
        }
        
        //Query for ContentDocument records
        docsById = new Map<Id, ContentDocument>([
            SELECT Id
                  ,LatestPublishedVersionId
              FROM ContentDocument
             WHERE Id IN :docsById.keySet()
        ]);
        
        //Query for WorkOrder records
        wosById = new Map<Id, WorkOrder>([
            SELECT Id
                  ,AccountId
                  ,Account.Name
                  ,AssetId
                  ,Asset.Name
                  ,CaseId
                  ,Case.CaseNumber
                  ,ContactId
                  ,Contact.Email
                  ,Customer_Name__c
                  ,EntitlementId
                  ,Entitlement.Name
                  ,OwnerId
                  ,Owner.Email
                  ,Owner.Name
                  ,WorkOrderNumber
                  ,WorkTypeId
                  ,WorkType.Name
              FROM WorkOrder
             WHERE Id IN :wosById.keySet()
               AND Division__c != 'Medical Aesthetics'
        ]);
        
        //Get FSR recipients to include in email
        Map<Id, Account> accsById = new Map<Id, Account>();
        for(WorkOrder wo : wosById.values()){
            accsById.put(wo.AccountId, null);
        }
        accsById = new Map<Id, Account>([
            SELECT Id
                  ,(SELECT Id
                          ,Contact.Email
                      FROM AccountContactRelations
                     WHERE Roles INCLUDES ('FSR Recipient')
                   )
              FROM Account
             WHERE Id IN :accsById.keySet()
        ]);
        
        //Loop through CDLs
        List<ContentDocument> docsToUpdate = new List<ContentDocument>();
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        for(ContentDocumentLink link : links){
            ContentDocument doc = docsById.get(link.ContentDocumentId);
            WorkOrder wo = wosById.get(link.LinkedEntityId);
            
            if(wo != null){
                wo.IsFSRSent__c = true;
                
                String templateType = 'Service Report';
                if(wo.WorkTypeId != null && wo.WorkType.Name.contains('Estimate')){
                    templateType = 'Estimate';
                }
                
                String caseIdentifier = '';
                if(wo.CaseId != null){
                    caseIdentifier = ' Case #' + wo.Case.CaseNumber;
                }
                
                //Update doc title
                doc.Title = ''
                    + 'Hologic '
                    + templateType
                    + caseIdentifier
                    + ' | ' + wo.Customer_Name__c
                    + ' | ' + wo.Asset.Name
                    + ' | WO# ' + wo.WorkOrderNumber;
                    
                docsToUpdate.add(doc);
                
                //Create and send email
                List<String> toAddresses = new List<String>();
                toAddresses.add(wo.Owner.Email);
                if(wo.ContactId != null){
                    toAddresses.add(wo.Contact.Email);
                }
                for(AccountContactRelation acr : accsById.get(wo.AccountId).AccountContactRelations){
                    toAddresses.add(acr.Contact.Email);
                }
                
                String subject = 'Service Report Generated for WorkOrder #' + wo.WorkOrderNumber;
                
                String emailBody = '<html><body><b>Your Service Report for ' + wo.WorkOrderNumber + ' is attached.</b><br/><br/>' +
                    '<b>Customer Name:</b> '    + (wo.Customer_Name__c != null ? wo.Customer_Name__c : '')  + '<br/>' +
                    '<b>Account Name:</b> '     + (wo.Account.Name != null ? wo.Account.Name : '')          + '<br/>' +
                    '<b>Asset Name:</b> '       + (wo.Asset.Name != null ? wo.Asset.Name : '')              + '<br/>' +
                    '<b>Case:</b> '             + (wo.Case.CaseNumber != null ? wo.Case.CaseNumber : '')    + '<br/>' +
                    '<b>Entitlement:</b> '      + (wo.Entitlement.Name != null ? wo.Entitlement.Name : '') + '</body></html>';
                    
                List<String> attachmentIds = new List<String>();
                attachmentIds.add(doc.LatestPublishedVersionId);
                
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                email.setToAddresses(toAddresses);
                email.setReplyTo(wo.Owner.Email);
                email.setSenderDisplayName(wo.Owner.Name);
                email.setSubject(subject);
                email.setHtmlBody(emailBody);
                email.setEntityAttachments(attachmentIds);
                email.setSaveAsActivity(false);
                
                if(templateType != 'Estimate') {
                    emails.add(email);    
                }
            }
        }
        
        update wosById.values();
        update docsToUpdate;
        if(emails.size() > 0){
            Messaging.sendEmail(emails, false);
        }
    }
    
    private static void sendFSREmailsForSAs(List<ContentDocumentLink> links){
        //Gather parent Ids
        Map<Id, ContentDocument> docsById = new Map<Id, ContentDocument>();
        Map<Id, Id> woIdsBySAId = new Map<Id, Id>();
        for(ContentDocumentLink link : links){
            docsById.put(link.ContentDocumentId, null);
            woIdsBySAId.put(link.LinkedEntityId, null);
        }
        
        for(ServiceAppointment sa : [
            SELECT Id
                  ,Related_Work_Order__c
              FROM ServiceAppointment
             WHERE Id IN :woIdsBySAId.keySet()
        ]){
            woIdsBySAId.put(sa.Id, sa.Related_Work_Order__c);
        }
        
        //Query for ContentDocument records
        docsById = new Map<Id, ContentDocument>([
            SELECT Id
                  ,LatestPublishedVersionId
              FROM ContentDocument
             WHERE Id IN :docsById.keySet()
        ]);
        
        //Query for WorkOrder records
        Map<Id, WorkOrder> wosById = new Map<Id, WorkOrder>([
            SELECT Id
                  ,AccountId
                  ,Account.Name
                  ,AssetId
                  ,Asset.Name
                  ,CaseId
                  ,Case.CaseNumber
                  ,ContactId
                  ,Contact.Email
                  ,Customer_Name__c
                  ,EntitlementId
                  ,Entitlement.Name
                  ,OwnerId
                  ,Owner.Email
                  ,Owner.Name
                  ,WorkOrderNumber
                  ,WorkTypeId
                  ,WorkType.Name
              FROM WorkOrder
             WHERE Id IN (SELECT Related_Work_Order__c FROM ServiceAppointment WHERE Id IN :woIdsBySAId.keySet())
               AND Division__c != 'Medical Aesthetics'
        ]);
        
        //Get FSR recipients to include in email
        Map<Id, Account> accsById = new Map<Id, Account>();
        for(WorkOrder wo : wosById.values()){
            accsById.put(wo.AccountId, null);
        }
        accsById = new Map<Id, Account>([
            SELECT Id
                  ,(SELECT Id
                          ,Contact.Email
                      FROM AccountContactRelations
                     WHERE Roles INCLUDES ('FSR Recipient')
                   )
              FROM Account
             WHERE Id IN :accsById.keySet()
        ]);
        
        //Loop through CDLs
        List<ContentDocument> docsToUpdate = new List<ContentDocument>();
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        for(ContentDocumentLink link : links){
            ContentDocument doc = docsById.get(link.ContentDocumentId);
            WorkOrder wo = wosById.get(woIdsBySAId.get(link.LinkedEntityId));
            
            if(wo != null){
                wo.IsFSRSent__c = true;
                
                String templateType = 'Service Report';
                if(wo.WorkTypeId != null && wo.WorkType.Name.contains('Estimate')){
                    templateType = 'Estimate';
                }
                
                String caseIdentifier = '';
                if(wo.CaseId != null){
                    caseIdentifier = ' Case #' + wo.Case.CaseNumber;
                }
                
                //Update doc title
                doc.Title = ''
                    + 'Hologic '
                    + templateType
                    + caseIdentifier
                    + ' | ' + wo.Customer_Name__c
                    + ' | ' + wo.Asset.Name
                    + ' | WO# ' + wo.WorkOrderNumber;
                docsToUpdate.add(doc);
                
                System.debug('doc Title:'+doc.Title);
                //Create and send email
                List<String> toAddresses = new List<String>();
                toAddresses.add(wo.Owner.Email);
                if(wo.ContactId != null){
                    toAddresses.add(wo.Contact.Email);
                }
                if(wo.AccountId != null && accsById.get(wo.AccountId) != null && accsById.get(wo.AccountId).AccountContactRelations != null){
                    for(AccountContactRelation acr : accsById.get(wo.AccountId).AccountContactRelations){
                        toAddresses.add(acr.Contact.Email);
                    }
                }
                
                String subject = 'Service Report Generated for WorkOrder #' + wo.WorkOrderNumber;
                
                String emailBody = '<html><body><b>Your Service Report for ' + wo.WorkOrderNumber + ' is attached.</b><br/><br/>' +
                    '<b>Customer Name:</b> '    + (wo.Customer_Name__c != null ? wo.Customer_Name__c : '')  + '<br/>' +
                    '<b>Account Name:</b> '     + (wo.Account.Name != null ? wo.Account.Name : '')          + '<br/>' +
                    '<b>Asset Name:</b> '       + (wo.Asset.Name != null ? wo.Asset.Name : '')              + '<br/>' +
                    '<b>Case:</b> '             + (wo.Case.CaseNumber != null ? wo.Case.CaseNumber : '')    + '<br/>' +
                    '<b>Entitlement:</b> '      + (wo.Entitlement.Name != null ? wo.Entitlement.Name : '') + '</body></html>';
                    
                List<String> attachmentIds = new List<String>();
                attachmentIds.add(doc.LatestPublishedVersionId);
                
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                email.setToAddresses(toAddresses);
                email.setReplyTo(wo.Owner.Email);
                email.setSenderDisplayName(wo.Owner.Name);
                email.setSubject(subject);
                email.setHtmlBody(emailBody);
                email.setEntityAttachments(attachmentIds);
                email.setSaveAsActivity(false);
                
                if(templateType != 'Estimate') {
                    emails.add(email);    
                }
            }
        }
        
        update wosById.values();
        update docsToUpdate;
        if(emails.size() > 0){
            Messaging.sendEmail(emails, false);
        }
    }
}