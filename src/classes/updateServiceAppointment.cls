global class updateServiceAppointment implements Database.Batchable<sObject>, Schedulable, Database.Stateful{

    global void execute(SchedulableContext sc){
        Database.executeBatch(new updateServiceAppointment());    
    }
    
    global String query;
    Map<Id,Id> ServiceReportMap = new Map<Id,Id>();
    global Set<ServiceAppointment> SASet; 
    global List<ServiceAppointment> SAList;
    global Set<Id> failureIdsSet = new Set<Id>();
    global Set<Id> SuccessIdsSet = new Set<Id>();

    
    global updateServiceAppointment(){
        query = 'Select ID, ParentId, createdDate from ServiceReport where ParentId != null ORDER BY ParentId,createdDate ASC';
        
        if(Test.isRunningTest())
            query = 'Select ID, ParentId, createdDate from ServiceReport where ParentId != null ORDER BY ParentId,createdDate DESC LIMIT 200';
    }
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
         return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<ServiceReport> scope) {
    
        SASet = new Set<ServiceAppointment>();
        SAList = new List<ServiceAppointment>();
        
        for(ServiceReport SR: scope){
            ServiceReportMap.put(SR.ParentId,SR.ID);
        }   
        
        System.debug('SRMap:'+ServiceReportMap);
        
        for(ServiceAppointment SA: [SELECT ID,Community_Service_Report_ID__c FROM ServiceAppointment WHERE ID IN: ServiceReportMap.keySet() AND Community_Service_Report_ID__c = '']){
            SA.Community_Service_Report_ID__c = ServiceReportMap.get(SA.ID) ;
            SASet.add(SA);
        }
        
        System.debug('HW:'+SASet);
        
        SAList.addAll(SASet);
        
        Database.SaveResult[] srList = Database.update(SAList, false);
        
        for (Database.SaveResult sr : srList) {
             if (sr.isSuccess()) {
                 SuccessIdsSet.add(sr.getId());    
             }else{
                    for(Database.Error err : sr.getErrors()) {
                        System.debug(err.getStatusCode() + ': ' + err.getMessage());
                        failureIdsSet.add(sr.getId());
                    }
             }
         }
 
    }
    
    global void finish(Database.BatchableContext bc) {
        system.debug('All fails Ids===> ' +failureIdsSet);
        system.debug('All processed Ids ===>'+SuccessIdsSet);
    }
    
}