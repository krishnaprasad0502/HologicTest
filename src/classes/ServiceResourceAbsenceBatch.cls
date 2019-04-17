global without sharing class ServiceResourceAbsenceBatch implements Database.Batchable<sObject> {
    
    global static void createHourlySchedule(){
        System.schedule('Service Resource Absence Batch Scheduler 0', '0 0 * * * ?', new ServiceResourceAbsenceBatchScheduler());
        System.schedule('Service Resource Absence Batch Scheduler 30', '0 30 * * * ?', new ServiceResourceAbsenceBatchScheduler());
    }
    
    global static final Integer WINDOW_MINUTES = 30;
    global static Datetime startOfWindow {get;set;}//= DateTime.newInstance(Date.today(), Time.newInstance(DateTime.now().hour(), 0, 0, 0));
    global static Datetime endOfWindow {get;set;}//= startOfWindow.addMinutes(WINDOW_MINUTES);
    global static Datetime twentyFourAgo = DateTime.now().addDays(-1);
    
    global Database.QueryLocator start(Database.BatchableContext bc){
        Integer thisMinute = DateTime.now().minute();
        for(Integer i = 0; i < 60; i += WINDOW_MINUTES){
            if(thisMinute >= i && thisMinute < (i + WINDOW_MINUTES)){
                startOfWindow = DateTime.newInstance(Date.today(), Time.newInstance(DateTime.now().hour(), i, 0, 0));
                endOfWindow = startOfWindow.addMinutes(WINDOW_MINUTES);
                System.debug('***[0] ' + startOfWindow + ' / ' + endOfWindow);
            }
        }
        
        String query =
            'SELECT Id, ResourceId, Start, End, AbsenceNumber FROM ResourceAbsence'
          + ' WHERE ((Start >= :startOfWindow AND Start < :endOfWindow AND Resource.Absent__c = false)'
          + ' OR (End >= :twentyFourAgo AND End <= :startOfWindow AND Resource.Absent__c = true)'
          + ' OR (Start <= :startOfWindow AND End >= :endOfWindow AND Resource.Absent__c = false))'
          + ' AND FSL__Approved__c = true'
          + ' AND Resource.IsActive = true'
          + ' ORDER BY End ASC';
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext bc, List<sObject> scope){
        Integer thisMinute = DateTime.now().minute();
        for(Integer i = 0; i < 60; i += WINDOW_MINUTES){
            if(thisMinute >= i && thisMinute < (i + WINDOW_MINUTES)){
                startOfWindow = DateTime.newInstance(Date.today(), Time.newInstance(DateTime.now().hour(), i, 0, 0));
                endOfWindow = startOfWindow.addMinutes(WINDOW_MINUTES);
                System.debug('***[0] ' + startOfWindow + ' / ' + endOfWindow);
            }
        }
        
        List<ResourceAbsence> ras = new List<ResourceAbsence>();
        for(sObject ra : scope){
            ras.add((ResourceAbsence)ra);
        }
        
        Map<Id, ServiceResource> srsById = new Map<Id, ServiceResource>();
        for(ResourceAbsence ra : ras){
            srsById.put(ra.ResourceId, null);
        }
        
        srsById = new Map<Id, ServiceResource>([
            SELECT Id, Name, Absent__c
              FROM ServiceResource
             WHERE Id IN :srsById.keySet()
        ]);
        
        System.debug('***[00] ' + ras);
        for(ResourceAbsence ra : ras){
            System.debug('***[000] ' + ra);
            ServiceResource sr = srsById.get(ra.ResourceId);
            System.debug('***[a] ' + sr);
            System.debug('***[b] ' + ra.Start);
            System.debug('***[c] ' + ra.End);
            System.debug('***[d] ' + startOfWindow);
            System.debug('***[e] ' + endOfWindow);
            if(ra.Start >= startOfWindow && ra.Start < endOfWindow && sr.Absent__c == false){
                System.debug('***[1] setting to true for ' + sr.Name + ' based on RA ' + ra.AbsenceNumber + ' / ' + ra.Id);
                sr.Absent__c = true;
            } else if(ra.End >= twentyFourAgo && ra.End <= startOfWindow && sr.Absent__c == true){
                System.debug('***[2] setting to false for ' + sr.Name + ' based on RA ' + ra.AbsenceNumber + ' / ' + ra.Id);
                sr.Absent__c = false;
            } else if(ra.Start <= startOfWindow && ra.End >= endOfWindow && sr.Absent__c == false){
                System.debug('***[3] setting to true for ' + sr.Name + ' based on RA ' + ra.AbsenceNumber + ' / ' + ra.Id);
                sr.Absent__c = true;
                System.debug('***[3b] ' + sr);
            }
        }
        update srsById.values();
    }
    
    global void finish(Database.BatchableContext bc){}

}