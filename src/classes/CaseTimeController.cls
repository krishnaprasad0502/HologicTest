Global with sharing class CaseTimeController {
    
   
    public String recordId {get;set;}
    public String duration {get;set;} 
    public String comments {get;set;}
    
    /* *****************Updated by Mani Sundaresan for US-3657***************/
    public String userId {get;set;}
    public String ownerId {get;set;}
    public String secondLevelOwnerId {get;set;}
    /*************************************************************/
 
    public Decimal cumulativeTime {
        get {
             if(recordId != null){
                 Case currentCase = [select Id, Cumulative_Time__c from Case where Id =:recordId limit 1];
                 return currentCase.Cumulative_Time__c;
             }
             else
                 return null;
        }
        set;
    }
    
    public List<Session_Time__c> sessions {
        get{
            if(recordId != null){
                sessions = [select Id, Agent__r.Name, Date__c, Duration__c from Session_Time__c where Case__r.Id=:recordId and Type__c = 'Automatic' order by Date__c desc];
                return sessions;
            }
            else
                return null;      
        }
        set;      
    }
    
    public List<Session_Time__c> manualSessions {
        get{
           if(recordId != null){
               manualSessions = [select Id, Agent__r.Name, Date__c, Duration__c from Session_Time__c where Case__r.Id=:recordId and Type__c = 'Manual' order by Date__c desc];
               return manualSessions;
           }
           else
               return null;  
        }
        set;
        
    }
    
    public CaseTimeController(ApexPages.StandardController stdController){
        recordId = (String)stdController.getRecord().Id;
         /*******************Updated by Mani for US-3657***************/
        userId = Userinfo.getUserId();
        Case queryCaseVal = [SELECT Id, OwnerId, Escalated_2nd_Level_Owner__c from Case where Id = :recordId];
        ownerId = queryCaseVal.OwnerId;
        secondLevelOwnerId = queryCaseVal.Escalated_2nd_Level_Owner__c;
        System.debug('userId:'+userId);
        System.debug('ownerId:'+ownerId);
        System.debug('secondLevelOwnerId:'+secondLevelOwnerId);
        /**************************************************************/
    }
    
    @RemoteAction
    Global static String recordSession(String caseId, String duration) {
        
        System.debug('caseId: ' + caseId);
        System.debug('duration: ' + duration);
        
        Session_Time__c session = new Session_Time__c();
        session.Case__c = caseId;
        session.Date__c = System.now();
        session.Duration__c = Integer.valueOf(duration);
        session.Agent__c = UserINFO.getUserId();
        session.Type__c = 'Automatic';
        
        insert session;
     //   System.debug('sessionId: ' + session.Id);
        return session.Id;

    }
 
    
    public PageReference recordManualSession() {
        
        Session_Time__c session = new Session_Time__c();
        session.Case__c = recordId;
        session.Date__c = System.now();
        session.Duration__c = Integer.valueOf(duration);
        session.Agent__c = UserINFO.getUserId();
        session.Type__c = 'Manual';
        session.Comments__c = comments;
        
        insert session;
     //   System.debug('sessionId: ' + session.Id);

        return null;
    }
    
}