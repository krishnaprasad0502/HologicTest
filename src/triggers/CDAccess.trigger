trigger CDAccess on ContentDocumentLink (after insert) {
    List<Id> cdIdList = new List<Id>();
/*
    List<ContentDocument> cdList = new List<ContentDocument>();
    List<ContentDocumentLink> cdlList = new List<ContentDocumentLink>();
    Set<ContentDocumentLink> cdlSet = new Set<ContentDocumentLink>();
    Set<Id> duplicateCheck = new Set<Id>();
        
    //Group WorkOrderApprovers = [SELECT Id from Group where Name='WorkOrder Approvers'];
    CollaborationGroup WorkOrderApprovers = new CollaborationGroup();
    for(CollaborationGroup cg : [SELECT Id,Name From CollaborationGroup WHERE Name LIKE 'WorkOrder Approvers%' limit 1]){
        WorkOrderApprovers = cg;
    }
    if(GlobalUtility.runOnceOnAfter()){
    
    for(ContentDocumentLink cdl : Trigger.new){
        cdIdList.add(cdl.ContentDocumentId);
    }
    
    if(cdIdList.size()>0)
        cdList = [SELECT Id, Title from ContentDocument where Id in :cdIdList];
        
    List<ContentDocumentLink> cdllink = [select Id, ContentDocumentId, ContentDocument.Title, LinkedEntityId, ShareType, Visibility from ContentDocumentLink where ContentDocumentId in:cdIdList];
    
 
    
    if(cdllink.size() > 0){
        for(ContentDocumentLink cdl : cdllink){
            if(!duplicateCheck.contains(WorkOrderApprovers.Id) && cdl.LinkedEntityId != WorkOrderApprovers.Id && (cdl.ContentDocument.Title == 'ServiceReport' || cdl.ContentDocument.Title == 'Service Report')){
                ContentDocumentLink cdl1 = new ContentDocumentLink();
                cdl1.LinkedEntityId = WorkOrderApprovers.Id;
                cdl1.ShareType = 'C';
                //cdl1.Visibility = 'AllUsers';    
                cdl1.ContentDocumentId = cdl.ContentDocumentId;  
                
                cdlSet.add(cdl1); 
                duplicateCheck.add(WorkOrderApprovers.Id);
                System.debug('Method2'); 
            }
             
        }
    }
    
    //WorkOrderTriggerActions.firstRun = false;
    system.debug('cdl:'+cdlSet);
    if(cdlSet.size() > 0){
        cdlList.addAll(cdlSet);
        upsert cdlList;
        }
    }*/
}