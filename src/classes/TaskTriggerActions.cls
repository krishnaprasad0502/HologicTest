/*------------------------------------------------------------
Author:         Yael Perez
Company:        Salesforce.com
Description:    Case Trigger functions
Test Class:     TaskTrigger_Test

History:
<Date>          <Authors Name>      <Brief Description of Change>
08/04/2016      Yael Perez          Initial Creation (US1443)
09/30/2016      Denise Bacher       Allow updates to the Note_Type__c field on complaint cases, and resent to EBS
//27/10/2017      krishna           Update code to only prevent task creation on case record types  as part of  US-0003573
01/16/2018      Mani Sundaresan     Update Task Description on B&SH Service Case when a Task is created/Updated (HD-8082)
10/22/2018      Dave Mansell        Refactored all code
------------------------------------------------------------*/

public class TaskTriggerActions {
    
    public static void checkForComplaintTasks(List<Task> tasks){
        Map<Id, Case> casesById = new Map<Id, Case>();
        for(Task tsk : tasks){
            if(tsk.WhatId != null){
                if(tsk.WhatId.getSObjectType() == Schema.Case.SObjectType){
                    casesById.put(tsk.WhatId, null);
                }
            }
        }
        
        if(casesById.isEmpty()){
            return;
        }
        
        casesById = new Map<Id, Case>([
            SELECT Id
                  ,RecordType.DeveloperName
                  ,Status
              FROM Case
             WHERE Id IN :casesById.keySet()
               AND Complaint__c = 'Yes'
        ]);
        
        for(Task tsk : tasks){
            if(casesById.get(tsk.WhatId) != null){
                Case cas = casesById.get(tsk.WhatId);
                if(tsk.Status != null && tsk.Status != 'Completed' && cas.RecordType.DeveloperName == 'B_SH_Service'){
                    tsk.addError('Tasks of complaint cases must be created in \'Completed\' status.');
                } else if(cas.Status == 'Closed' && (cas.RecordType.DeveloperName == 'Diagnostic_Applications' || cas.RecordType.DeveloperName == 'Diagnostic_Service')){
                    tsk.addError('Tasks cannot be added to a closed complaint case.');
                } else {
                    tsk.Send_Outbound_Message__c = true;
                }
            }
        }
    }
    
    public static void preventEditOfComplaintTasks(List<Task> tasks, Map<Id, Task> oldMap){
        Map<Id, Case> casesById = new Map<Id, Case>();
        for(Task tsk : tasks){
            if(tsk.WhatId != null){
                if(tsk.WhatId.getSObjectType() == Schema.Case.SObjectType){
                    casesById.put(tsk.WhatId, null);
                }
            }
        }
        
        if(casesById.isEmpty()){
            return;
        }
        
        casesById = new Map<Id, Case>([
            SELECT Id
                  ,RecordType.DeveloperName
                  ,Status
              FROM Case
             WHERE Id IN :casesById.keySet()
               AND Complaint__c = 'Yes'
        ]);
        
        for(Task tsk : tasks){
            if(casesById.get(tsk.WhatId) != null){
                Case cas = casesById.get(tsk.WhatId);
                Task old = oldMap.get(tsk.Id);
                
                if(tsk.Note_Type__c != null
                    && tsk.Note_Type__c != old.Note_Type__c
                    && tsk.Description == old.Description
                    && tsk.Status == old.Status
                ){
                    //Allow edit to push to EBS
                    tsk.Send_Outbound_Message__c = true;
                } else if(tsk.Note_Type__c == null){
                    //Allowable edit
                    continue;
                } else if(tsk.Send_Outbound_Message__c == false
                    && tsk.Send_Outbound_Message__c != tsk.Send_Outbound_Message__c
                    && tsk.Description == old.Description
                    && tsk.Status == old.Status
                ){
                    //Allowable edit
                    continue;
                } else {
                    //No other edits allowed
                    tsk.addError('Tasks of complaint cases cannot be edited.');
                }
            }
        }
    }
    
    public static void preventDeletionOfComplaintTasks(List<Task> tasks){
        Map<Id, Case> casesById = new Map<Id, Case>();
        for(Task tsk : tasks){
            if(tsk.WhatId != null){
                if(tsk.WhatId.getSObjectType() == Schema.Case.SObjectType){
                    casesById.put(tsk.WhatId, null);
                }
            }
        }
        
        if(casesById.isEmpty()){
            return;
        }
        
        casesById = new Map<Id, Case>([
            SELECT Id
              FROM Case
             WHERE Id IN :casesById.keySet()
               AND Complaint__c = 'Yes'
        ]);
        
        for(Task tsk : tasks){
            if(casesById.get(tsk.WhatId) != null){
                tsk.addError('Tasks of complaint cases cannot be deleted.');
            }
        }
    }
    
    public static void updateTaskDescriptionOnCase(List<Task> tasks){
        Map<Id, Case> casesById = new Map<Id, Case>();
        for(Task tsk : tasks){
            if(tsk.WhatId != null){
                if(tsk.WhatId.getSObjectType() == Schema.Case.SObjectType
                    && (tsk.Note_Type__c == 'Note to FE' || tsk.Note_Type__c == 'Problem Description')
                ){
                    casesById.put(tsk.WhatId, null);
                }
            }
        }
        
        if(casesById.isEmpty()){
            return;
        }
        
        casesById = new Map<Id, Case>([
            SELECT Id
                  ,(SELECT Id
                          ,Subject
                          ,Note_Type__c
                          ,Owner.Name
                          ,LastModifiedDate
                          ,Description
                      FROM Tasks
                     ORDER BY CreatedDate DESC
                   )
              FROM Case
             WHERE Id IN :casesById.keySet()
               AND RecordType.DeveloperName = 'B_SH_Service'
        ]);
        
        for(Case cas : casesById.values()){
            List<String> toFEArray = new List<String>();
            List<String> probArray = new List<String>();
            for(Task tsk : cas.Tasks){
                String taskString = 
                        'Subject: '             + tsk.Subject                   + '\n'
                      + 'Note Type: '           + tsk.Note_Type__c              + '\n'
                      + 'Assigned To: '         + tsk.Owner.Name                + '\n'
                      + 'Last Modified On: '    + tsk.LastModifiedDate.format() + '\n\n'
                      + 'Comments: '            + tsk.Description               + '\n\n'
                      + '----------------------------------------------------';
                if(tsk.Note_Type__c == 'Note to FE'){
                    toFEArray.add(taskString);
                } else if(tsk.Note_Type__c == 'Problem Description'){
                    probArray.add(taskString);
                }
            }
            cas.Description = '';
            if(toFEArray.size() > 0){
                cas.Task_Description__c += String.join(toFEArray, '\n\n');
            }
            if(toFEArray.size() > 0 && probArray.size() > 0){
                cas.Task_Description__c += '\n\n';
            }
            if(probArray.size() > 0){
                cas.Task_Description__c += String.join(probArray, '\n\n');
            }
        }
        
        update casesById.values();
    }
    
}


















/*------------------------------------------------------------
Author:         Yael Perez
Company:        Salesforce.com
Description:    Case Trigger functions
Test Class:     TaskTrigger_Test

History:
<Date>          <Authors Name>      <Brief Description of Change>
08/04/2016      Yael Perez          Initial Creation (US1443)
09/30/2016      Denise Bacher       Allow updates to the Note_Type__c field on complaint cases, and resent to EBS
//27/10/2017      krishna           Update code to only prevent task creation on case record types  as part of  US-0003573
01/16/2018      Mani Sundaresan     Update Task Description on B&SH Service Case when a Task is created/Updated (HD-8082)
------------------------------------------------------------*
public with sharing class TaskTriggerActions {

  //27/10/2017      krishna             Update code to only prevent task creation on case record types  as part of  US-0003573
   private static Record_Type_IDs__c recordTypeIds = Record_Type_IDs__c.getOrgDefaults();    
   private static final ID RECORD_TYPE_ID_CASE_DIAGNOSTIC_APPLICATIONS =  recordTypeIds.Case_Diagnostic_Applications__c;
   private static final ID RECORD_TYPE_ID_CASE_DIAGNOSTIC_SERVICE = recordTypeIds.Case_Diagnostic_Service__c;
   private static final ID RECORD_TYPE_ID_CASE_B_SH_SERVICE = recordTypeIds.Case_B_SH_Service__c; 

    @TestVisible private static Boolean preventEditFirstRun = true; // only run the preventEditOfComplaintTasks function the first run of the trigger, not again on workflow field update
    
    /*------------------------------------------------------------
    Author:         Yael Perez
    Company:        Salesforce.com
    Description:    Set the "Send_Outbound_Message__c" checkbox to true
                    for new/updated tasks belonging to complaint cases.
                    Workflow rule will then send an outbound message to Agile
                    
    Inputs:         Tasks - The list of Tasks
                    oldTasks - Map of pervious Tasks values
    Returns:        N/A
    
    History:
    <Date>          <Authors Name>      <Brief Description of Change>
    08/04/2016      Yael Perez          Initial Creation (US1443)
    ------------------------------------------------------------*
    public static void checkForComplaintTasks(List<Task> tasks, Map<Id, Task> oldTasks){   
        List<Task> complaintTasks = new List<Task>();
        Map<Id, List<Task>> whatIdtoTaskMap = new Map<Id, List<Task>>();
        List<Task> taskList = new List<Task>();

        for (Task aTask : tasks) {
            // Retrieve all the IDs of the records that the tasks are related to (WhatId)
            if (whatIdtoTaskMap.containsKey(aTask.whatId)) {
                whatIdtoTaskMap.get(aTask.whatId).add(aTask);
            } else {
                whatIdtoTaskMap.put((aTask.whatId), new List<Task> {aTask});
            }   
        }

        // Retreive all tasks that are related to complaint cases
        for (Case aCase : [SELECT Id, Complaint__c FROM Case WHERE Id IN : whatIdtoTaskMap.keySet()]) {
            if (aCase != null && aCase.Complaint__c != null && aCase.Complaint__c.equalsIgnoreCase('Yes')) {
                complaintTasks.addAll(whatIdtoTaskMap.get(aCase.Id));
            }
        }

        // Update the tasks to set the Send_Outbound_Message__c checkbox and trigger the integration to Agile
        for (Task complaintTask : complaintTasks) {
            complaintTask.Send_Outbound_Message__c = true;
        }
    }


    /*------------------------------------------------------------
    Author:         Yael Perez
    Company:        Salesforce.com
    Description:    Prevent edits to tasks that belong to cases with B&SH Service Record Type
    Inputs:         Tasks - The list of Tasks
                    oldTasks - Map of pervious Tasks values
    Returns:        N/A
    
    History:
    <Date>          <Authors Name>      <Brief Description of Change>
    09/13/2016      Yael Perez          Initial Creation (US1443)
    09/30/2016      Denise Bacher       Allow updates to the Note_Type__c field on complaint cases, and resent to EBS
    07/25/2017      Raj Sharan          Remove restriction of Case Record Type (US-0003154).  Keep when Complaint = Yes. 
    ------------------------------------------------------------*
    public static void preventEditOfComplaintTasks(List<Task> tasks, Map<Id, Task> oldTasks) {
        Map<Id, List<Task>> whatIdtoTaskMap = new Map<Id, List<Task>>();
        List<Task> preventEditList = new List<Task>();
        
        if(!preventEditFirstRun ){
            //System.debug('second run, return');
            return;
        }
        
        for (Task aTask : tasks) {
            // Retrieve all the IDs of the records that the tasks are related to (WhatId)
            if (whatIdtoTaskMap.containsKey(aTask.whatId)) {
                whatIdtoTaskMap.get(aTask.whatId).add(aTask);
            } else {
                whatIdtoTaskMap.put((aTask.whatId), new List<Task> {aTask});
            }   
        }

        // Retreive all tasks that are related to Service cases
        for (Case aCase : [SELECT Id, RecordType.DeveloperName, Complaint__c FROM Case WHERE Id IN : whatIdtoTaskMap.keySet()]) {
            if (aCase != null  &&
                aCase.Complaint__c != null && aCase.Complaint__c.equalsIgnoreCase('Yes')) {
                preventEditList.addAll(whatIdtoTaskMap.get(aCase.Id));
            }
        }

        for (Task aTask : preventEditList) {
            Task oldTask = oldTasks.containsKey(aTask.Id) ? oldTasks.get(aTask.Id) : new Task();
           
            system.debug('Note_Type__c = ' + aTask.Note_Type__c);
             
            // if note type has changed, and description has not changed, allow push to ebs
            if(aTask.Note_Type__c != oldTask.Note_Type__c && aTask.Note_Type__c != NULL && aTask.Description == oldTask.Description && aTask.Status == oldTask.Status){
                //System.debug('send outbound message');
                aTask.Send_Outbound_Message__c = true;
            }
            else if((aTask.Send_Outbound_Message__c != oldTask.Send_Outbound_Message__c && aTask.Send_Outbound_Message__c == false && 
                    aTask.Note_Type__c == oldTask.Note_Type__c && aTask.Description == oldTask.Description && aTask.Status == oldTask.Status) || aTask.Note_Type__c == NULL) {
                //System.debug('do nothing');
                continue;
            }
            else{
                aTask.addError('Tasks of Complaint Cases Cannot be Edited');
            }               
        }
        
        preventEditFirstRun  = false;       
    }

    /*------------------------------------------------------------
    Author:         Yael Perez
    Company:        Salesforce.com
    Description:    Prevent deletion to tasks that belong to cases with B&SH Service Record Type
    Inputs:         oldTasks - List of pervious Tasks values        

    Returns:        N/A

    History:
    <Date>          <Authors Name>      <Brief Description of Change>
    09/13/2016      Yael Perez          Initial Creation (US1443)
    07/25/2017      Raj Sharan          Remove restriction of Case Record Type (US-0003154).  Keep when Complaint = Yes. 
    ------------------------------------------------------------*
    public static void preventDeletionOfComplaintTasks(List<Task> oldTasks) {
        Map<Id, List<Task>> whatIdtoTaskMap = new Map<Id, List<Task>>();
        List<Task> preventDeleteList = new List<Task>();
        for (Task aTask : oldTasks) {
            // Retrieve all the IDs of the records that the tasks are related to (WhatId)
            if (whatIdtoTaskMap.containsKey(aTask.whatId)) {
                whatIdtoTaskMap.get(aTask.whatId).add(aTask);
            } else {
                whatIdtoTaskMap.put((aTask.whatId), new List<Task> {aTask});
            }   
        }

        // Retreive all tasks that are related to Service cases
        for (Case aCase : [SELECT Id, RecordType.DeveloperName, Complaint__c FROM Case WHERE Id IN : whatIdtoTaskMap.keySet()]) {
            if (aCase != null && 
                aCase.Complaint__c != null && aCase.Complaint__c.equalsIgnoreCase('Yes')) {
                preventDeleteList.addAll(whatIdtoTaskMap.get(aCase.Id));
            }
        }

        // Add an Error to prevent deletion of the tasks
        for (Task aTask : preventDeleteList) {
            aTask.addError('Tasks of Complaint Cases Cannot be Deleted');                   
        }               
    }

    /*------------------------------------------------------------
    Author:         Yael Perez
    Company:        Salesforce.com
    Description:    Prevent creation of tasks that belong to cases with B&SH Service Record Type
                    and are not in 'Completed' Status (Since edits are not allowed on service cases)
    Inputs:         tasks - The List of tasks        

    Returns:        N/A

    History:
    <Date>          <Authors Name>      <Brief Description of Change>
    09/13/2016      Yael Perez          Initial Creation (US1443)
    ------------------------------------------------------------*
    public static void checkForUncompletedComplaintTasks(List<Task> tasks) {
        Map<Id, List<Task>> whatIdtoTaskMap = new Map<Id, List<Task>>();
        List<Task> uncompletedTaskList = new List<Task>();
        for (Task aTask : tasks) {
            // Retrieve all the IDs of the records that the tasks are related to (WhatId) and are not in 'Completed' status
            if (aTask.Status != null && !aTask.Status.equalsIgnoreCase('Completed')) {
                if (whatIdtoTaskMap.containsKey(aTask.whatId)) {
                    whatIdtoTaskMap.get(aTask.whatId).add(aTask);
                } else {
                    whatIdtoTaskMap.put((aTask.whatId), new List<Task> {aTask});
                }   
            }
        }

        // Retreive all tasks that are related to Service cases
        for (Case aCase : [SELECT Id, RecordType.DeveloperName, Complaint__c FROM Case WHERE Id IN : whatIdtoTaskMap.keySet()]) {
            if (aCase != null && aCase.RecordType.DeveloperName.equalsIgnoreCase('B_SH_Service') && 
                aCase.Complaint__c != null && aCase.Complaint__c.equalsIgnoreCase('Yes')) {
                uncompletedTaskList.addAll(whatIdtoTaskMap.get(aCase.Id));
            }
        }       

        // Add an error to prevent creation of the tasks
        for (Task aTask : uncompletedTaskList) {
            aTask.addError('Tasks of Complaint Cases Must be Created in \'Completed\' Status');                 
        }           
    }    

    /*------------------------------------------------------------
    Author:         Raj Sharan 
    Company:        AppsAssociates 
    Description:    Prevent saving a Task if Case is Closed and Complaint
    Inputs:         Tasks - The list of Tasks
                    oldTasks - Map of pervious Tasks values
    Returns:        N/A
    
    History:
    <Date>          <Authors Name>      <Brief Description of Change>
    10/02/2017      Raj Sharan          Initial Creation
    27/10/2017      krishna             Update code to only prevent task creation on case record types  as part of  US-0003573
    ------------------------------------------------------------*
    public static void preventAddingNotetoClosedCase(List<Task> tasks) {
        Map<Id, List<Task>> whatIdtoTaskMap = new Map<Id, List<Task>>();
        List<Task> preventAddList = new List<Task>();

        for (Task aTask : tasks) {
            // Retrieve all the IDs of the records that the tasks are related to (WhatId)
            if (whatIdtoTaskMap.containsKey(aTask.whatId)) {
                whatIdtoTaskMap.get(aTask.whatId).add(aTask);
            } else {
                whatIdtoTaskMap.put((aTask.whatId), new List<Task> {aTask});
            }   
        }

        // Retreive all tasks that are related to Service cases
        //27/10/2017 krishna  Update code to only prevent task creation on Diagnostics Service and Diagnostics Applications case record types. as part of  US-0003573
        for (Case aCase : [SELECT Id, RecordType.DeveloperName,RecordTypeid, Complaint__c, Status FROM Case WHERE Id IN : whatIdtoTaskMap.keySet()]) {
            if (aCase != null && 
                aCase.Complaint__c != null && aCase.Complaint__c.equalsIgnoreCase('Yes') && aCase.Status == 'Closed'  && (aCase.RecordTypeid == RECORD_TYPE_ID_CASE_DIAGNOSTIC_APPLICATIONS  || aCase.RecordTypeid  == RECORD_TYPE_ID_CASE_DIAGNOSTIC_SERVICE )) {
                preventAddList.addAll(whatIdtoTaskMap.get(aCase.Id));
            }
        }

        // Add an Error to prevent deletion of the tasks
        if(preventAddList.size()>0){
            for (Task aTask : preventAddList) {
                aTask.addError('Tasks of Closed Complaint Cases Cannot be Added');                   
            }   
        }            
    }
    
    /*------------------------------------------------------------
    Author:         Mani Sundaresan
    Description:    Update Task Description on B&SH Service Case when a Task is created/updated.
    Inputs:         Tasks - The list of Tasks
                    oldTasks - Map of pervious Tasks values
    Returns:        N/A
    
    History:
    <Date>          <Authors Name>      <Brief Description of Change>
    01/16/2018      Mani Sundaresan          Initial Creation
    ------------------------------------------------------------*
    public static void updateTaskDescriptionOnCase(List<Task> tasks){
    
        //Variable Declaration Section
        Set<Id> caseIds = new Set<Id>();
        Set<Id> ownerIds = new Set<Id>();
        List<Case> caseList = new List<Case>();
        List<Case> finalCaseList = new List<Case>();
        //List<Task> taskList = new List<Task>();
        Map<Id, User> ownerMap;
        String noteToFE = '';
        String problemDescription = '';
        
        for(Task tsk : tasks){
            if(String.valueOf(tsk.WhatId) != null)
            if(String.valueOf(tsk.WhatId).startsWith('500') && (tsk.Note_Type__c == 'Note To FE' || tsk.Note_Type__c == 'Problem Description'))
                caseIds.add(tsk.WhatId);
                ownerIds.add(tsk.OwnerId);
        }
        
        System.debug('caseIds:'+caseIds);
        
        if(caseIds.size() > 0)
            caseList = [SELECT Id, Task_Description__c, (SELECT Id, Note_Type__c, Subject, OwnerId, Owner.Name, LastModifiedDate, CreatedDate, Description from Tasks ORDER BY CreatedDate DESC) from Case where Id IN :caseIds and RecordTypeId = :RECORD_TYPE_ID_CASE_B_SH_SERVICE];
            
        //if(ownerIds.size() > 0)
            //ownerMap = new Map<Id, User>([SELECT Id, Name from User where Id IN :ownerIds]);
            
        System.debug('caseList:'+caseList);
        System.debug('ownerMap:'+ownerMap);
        
        if(caseList.size() > 0)
            for(Case c : caseList){
                c.Task_Description__c = null;
                for(Task t : c.getSObjects('Tasks')){
                    if(t.Note_Type__c == 'Note To FE' && noteToFE == ''){
                        noteToFE += 'Subject: '+t.Subject +'\n'+
                                    'Note Type: '+t.Note_Type__c + '\n'+
                                    'Assigned To: '+t.Owner.Name + '\n'+
                                    'Last Modified On: '+t.LastModifiedDate.format() +'\n\n'+
                                    'Comments: '+t.Description+'\n\n'+'----------------------------------------------------';   
                    }
                    else if(t.Note_Type__c == 'Note To FE' && noteToFE != ''){
                        noteToFE += '\n\n'+
                                    'Subject: '+t.Subject +'\n'+
                                    'Note Type: '+t.Note_Type__c + '\n'+
                                    'Assigned To: '+t.Owner.Name+ '\n'+
                                    'Last Modified On: '+t.LastModifiedDate.format() +'\n\n'+
                                    'Comments: '+t.Description+'\n\n'+'----------------------------------------------------'; 
                    }
                    else if(t.Note_Type__c == 'Problem Description' && problemDescription != ''){
                        problemDescription += '\n\n'+
                                              'Subject: '+t.Subject +'\n'+
                                              'Note Type: '+t.Note_Type__c + '\n'+
                                              'Assigned To: '+t.Owner.Name + '\n'+
                                              'Last Modified On: '+t.LastModifiedDate.format() +'\n\n'+
                                               'Comments: '+t.Description+'\n\n'+'----------------------------------------------------';    
                    }
                    else if(t.Note_Type__c == 'Problem Description' && problemDescription == ''){
                        problemDescription = 'Subject: '+t.Subject +'\n'+
                                              'Note Type: '+t.Note_Type__c + '\n'+
                                              'Assigned To: '+t.Owner.Name + '\n'+
                                              'Last Modified On: '+t.LastModifiedDate.format() +'\n\n'+
                                               'Comments: '+t.Description+'\n\n'+'----------------------------------------------------';    
                    }
                    
                }
                System.debug('noteToFE:'+noteToFE);
                System.debug('problemDescription:'+problemDescription);
                c.Task_Description__c = noteToFE + '\n'+ problemDescription;
                
            }
            
            
          if(caseList.size() > 0){
              Database.SaveResult[] lsr = Database.update(caseList, false);
                //update installedAssets;

                for (Integer index = 0; index<lsr.size(); index++) {
                    if (!lsr[index].isSuccess()) {
                        tasks[index].addError('Failed to update the related Case record: ' + lsr[index].getErrors() [0].getMessage());
                    } 
                }   
          }
            
    
    }


}*/