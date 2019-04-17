trigger FSREmailtoFE on FeedItem (after insert) {

    Set<Id> relatedRecordIdSet = new Set<Id>();
    Set<Id> parentIdSet = new Set<Id>();
    Set<Id> userIdSet = new Set<Id>();
    List<ContentVersion> contentVersionList = new List<ContentVersion>();
    List<Messaging.SingleEmailMessage> email = new List<Messaging.SingleEmailMessage>();
    Map<Id, WorkOrder> woMap = new Map<Id, WorkOrder>(); 
    Map<Id,Id> woCVMap = new Map<Id,Id>();
    List<ContentVersion> updateContentVersionList = new List<ContentVersion>();
    List<WorkOrder> woList = new List<WorkOrder>();
    
    for(FeedItem fi : Trigger.New){
        System.debug('HW0');
        if(String.valueOf(fi.ParentId).startsWithIgnoreCase('0WO')){
            relatedRecordIdSet.add(fi.RelatedRecordId);
            parentIdSet.add(fi.ParentId);
            woCVMap.put(fi.ParentId,fi.RelatedRecordId);
            System.debug('HW1'+fi.Parent.Name);
            
        }
        System.debug('HW2'+relatedRecordIdSet);
        System.debug('Hawa1'+parentIdSet);
    }
    
    if(parentIdSet.size() > 0){
        for(WorkOrder wo : [SELECT WorkOrderNumber, Owner.Name, Id, Customer_Name__c, isFSRSent__c, Account.Name, Asset.Name, Asset.SerialNumber, Case.CaseNumber, Entitlement.Name, Owner.Email, Contact.Email from WorkOrder where Id IN :parentIdSet AND Status = 'Closed' AND isFSRSent__c = False])
            woMap.put(wo.Id, wo);
    }
    
    if(relatedRecordIdSet.size() > 0 && woMap.size() > 0){
        contentVersionList = [SELECT Id, Title, VersionData, Owner.Email, OwnerId, FileType from ContentVersion where Id IN :relatedRecordIdSet and Title = 'ServiceReport'];    
        System.debug('HW3');
        
    }
    
    if(contentVersionList.size() > 0){
        System.debug('HW4'+contentVersionList);
        for(FeedItem fi : Trigger.New){
            System.debug('Yoy o:'+fi.Parent.Name);
            for(WorkOrder wo : woMap.values()){
                for(ContentVersion cv : contentVersionList){
                    if(fi.RelatedRecordId == cv.Id){
                    
                        String subject = String.valueOf('Hologic Case#'+ wo.Case.CaseNumber + ' ' +wo.Customer_Name__c + ' ' +'SN '+ wo.Asset.SerialNumber);
                        
                        
                        String emailBody = '<html><body>Your Service Report for '+wo.WorkOrderNumber+' is attached.' + '</BR></BR>' +
                                        'Customer Name: '+ (wo.Customer_Name__c != null ? wo.Customer_Name__c : '') + '</BR>' +
                                        'Account Name: '+(wo.Account.Name != null ? wo.Account.Name : '') + '</BR>' +
                                        'Asset Name: '+(wo.Asset.Name != null ? wo.Asset.Name : '')+ '</BR>' +
                                        'Case: '+ (wo.Case.CaseNumber != null ? wo.Case.CaseNumber : '' ) + '</BR>' +
                                        'Entitlement: '+(wo.Entitlement.Name != null ? wo.Entitlement.Name : '')+'</body></html>'; 
                    
                    
                        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                        mail.setToAddresses(new String[] {cv.Owner.Email});
                        mail.setSaveAsActivity(false);
                        mail.setSubject(subject);
                        mail.setEntityAttachments(new String[] {cv.Id});
                        //mail.setPlainTextBody('Your Service Report for '+woMap.get(fi.ParentId)+' is attached.');
                        mail.setHtmlBody(emailBody);
                        mail.setSenderDisplayName(String.valueOf(wo.Owner.Name));
                        mail.setReplyTo(String.valueOf(wo.Owner.Email));
                        email.add(mail);
                        System.debug('HW5');
                        
                         wo.isFSRSent__c = true;
                         woList.add(wo);
                         
                         cv.Title = 'Hologic Service Report Case#:' + wo.Case.CaseNumber + ' | ' +wo.Customer_Name__c + ' | '+wo.Asset.Name;
                         updateContentVersionList.add(cv);
                         
                    }
                }
            }
        }
        
        if(woList.size() > 0)
            update woList;
        if(updateContentVersionList.size() > 0)
            update updateContentVersionList;
        
        if(email != null ) {
            System.debug('HW6');
            if(!Test.isRunningTest())
            Messaging.sendEmail(email);
        }
    }
}