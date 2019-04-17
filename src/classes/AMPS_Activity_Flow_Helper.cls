/*------------------------------------------------------------
Author:        Raviraj Reddy
Company:       Cynosure
Description:   AMPS Activity Flow Helper Class used in Task Trigger
Test Class:    TaskTrigger_Test

History:
<Date>        <Authors Name>    <Brief Description of Change>
03/14/2018    Raviraj Reddy     Initial Creation (US3819)
25/02/2019    Alex Powning      Moved from Asset -> Account & Territories
-----------------------------------------------------------*/
public class AMPS_Activity_Flow_Helper{

	//Variable Declaration section
    private Map<Id, Task> oldMapTaskRecs = new Map<Id, Task>();
    private Map<Id, Task> newMapTaskRecs = new Map<Id, Task>();
    private Map<Id,Account> taskIdsWithAccounts = new Map<Id,Account>();   //get a map of task Id's with Laser Onwed records 
    private Map<String, AMPS_Marketing_Activity_Flow__c> mapOfDefaultTaskVals = new Map<String,AMPS_Marketing_Activity_Flow__c>(); //map of the task flows
    private Decimal numberOfDays = null;
    private String priority = 'Normal';
    private String recordType = 'AMPS_Support';
    private Id user = null;
    private String strSubject = '';
    private String status = 'Not Started';
    private String type = ''; 
    private List<Task> lstNewTasksToInsert = new List<Task>(); //list of tasks to create
    private map<id, id> territoryUserforAccount = new map<id, id>();
    
    //Constructor   
    public AMPS_Activity_Flow_Helper(Map<Id, Task> oldMapTaskRecs, Map<Id, Task> newMapTaskRecs){
        this.oldMapTaskRecs = oldMapTaskRecs;
        this.newMapTaskRecs = newMapTaskRecs;
        taskIdsWithAccounts = getAccountTasks();
    }
    
	//Method to return the accounts associated to tasks
    public Map<Id,Account> getAccountTasks(){
        
        String strAccountPrefix = Account.sObjectType.getDescribe().getKeyPrefix();
        Set<Id> accountIds= new Set<Id>();   
        
        for(Task objTask : newMapTaskRecs.values()){
            Task objOldTask = oldMapTaskRecs.get(objTask.Id);
            
            if((objTask.IsClosed == TRUE || objTask.Status == 'Deferred'|| objTask.Status == 'cc') && objTask.whatId != NULL && String.valueOf(objTask.whatId).startsWith(strAccountPrefix) && objTask.Status != objOldTask.Status )
            {
                accountIds.add(objTask.WhatId);
            }
            
         }
         
         List<Task> lstNewTasksToInsert = new List<Task>();
         List<Account> accountsFound = [Select Id  //(select id,IsDeleted,TeamMemberRole,UserId from AccountTeamMembers) 
                                           From Account
                                           Where Id IN : accountIds];
        
         /*List<Account> accountsFound = [Select Id,(select id,Active_User__c,Relationship__c,User__c from Asset_Teams__r) 
                                           From Asset
                                           Where Id IN : assetIds];*/
        
         for(Account acct: accountsFound ){
            for(Task objTask : newMapTaskRecs.values()){
                if(acct.Id == objTask.WhatId){
                    taskIdsWithAccounts.put(objTask.Id,acct);
                }
            }          
         }
		 System.debug('taskIdsWithAccounts:'+taskIdsWithAccounts);
         return taskIdsWithAccounts;
            
     }
     
	 //Method to return a Map of all AMPS Marketing Activity Flow records
     private Map<String, AMPS_Marketing_Activity_Flow__c> returnTaskFlows(){
            for(AMPS_Marketing_Activity_Flow__c objTaskFlow : [ Select Id,Name,Number_of_days_to_be_added__c,
                                                                    AMPS_Track__c,
                                                                    Next_Task__c,Next_Task__r.Name,
                                                                    Cross_object_Asset_Team__c,
                                                                    Sub_Task__c,Sub_Task__r.Name,                                                                    
                                                                    Parent_Task__c,Parent_Task__r.Name,
                                                                    Initiating_Task_Type__c,
                                                                    Type__c,
                                                                    Priority__c 
                                                                    From AMPS_Marketing_Activity_Flow__c
                                                                    WHERE Name != NULL ])
            {   
                mapOfDefaultTaskVals.put(objTaskFlow.Name.toLowerCase(), objTaskFlow);
            }
		System.debug('mapOfDefaultTaskVals:'+mapOfDefaultTaskVals);
        return mapOfDefaultTaskVals;
    }

	//Method to return the next task
    private void setNextTaskValues(AMPS_Marketing_Activity_Flow__c nextTask){
            
            numberOfDays = nextTask.Number_of_days_to_be_added__c;
            strSubject = nextTask.Name;
            type = nextTask.Type__c;
            
            system.debug('numberOfDays :'+numberOfDays );
            system.debug('strSubject :'+strSubject  );
            system.debug('type :'+type);
            
    }
    
	//Method to insert new Task 
    public static Task insertTasks(String strPriority, 
                                   String strStatus,
                                   String strTaskType,
                                   Id ownerId, 
                                   String strSubject, 
                                   Decimal intNumberDays, 
                                   Id whatId){
    system.debug('Number of days =============== ' + IntNumberDays);                                    
        return new Task(
                        Priority = strPriority,
                        Status = strStatus,
                        OwnerId= ownerId,
                        Subject = strSubject,
                        ActivityDate = intNumberDays != NULL ? Date.Today().addDays(intNumberDays.intValue()) : NULL,
                        WhatId = whatId,
                Type = strTaskType);                                                                   
    }
     
     //Method to create next set of activities based on the AMPS Marketing Activity Flow 
     public List<Task> createActivities(){
        
        if(!taskIdsWithAccounts.isEmpty()){
            // get the default task values for the task flow creation tool
            returnTaskFlows();
            System.debug('map of task flows returned======' + mapOfDefaultTaskVals);
            

            //set to hold Ids of parent tasks in case this is a subtask
            Set<String> setofParentTasks = new Set<String>();
            
            List<Task> lstFielteredTasks = newMapTaskRecs.values(); //list of tasks being updated
            Map<Id,Account> mapOfParentAccounts = new Map<Id,Account>([Select Id //(select id,IsDeleted,TeamMemberRole,UserId from AccountTeamMembers) 
                                                                       From Account Where Id IN : taskIdsWithAccounts.values()]); 
                                                                                                    //map of laser Ids with their records
            Map<String,ID> userMap = new Map<String,ID>();
            
            System.debug('here are the tasks======' +  lstFielteredTasks);
            // Iterating over the updated tasks to create new set of Tasks
            
            for (AccountUserTerritory2View actUsr : [select id, AccountId, UserId 
                                                 from AccountUserTerritory2View 
                                                 where RoleInTerritory2 = 'AMPS Representative'
                                                 and AccountId IN :taskIdsWithAccounts.values()]){
        		territoryUserforAccount.put(actUsr.AccountId, actUsr.UserId);
        	}
            
            for(Task objTask : lstFielteredTasks){
                Account acct = mapOfParentAccounts.get(objTask.WhatId);
                system.debug('current due date is ' + objTask.ActivityDate);
                system.debug('iterating over tasks =========' + lstFielteredTasks);
                userMap.put('AMPS Representative', territoryUserforAccount.get(acct.id));
                
                //if any of the task flow records have a name matching the subject and the task is realted to a laser owned
                //added extra condition for submental by Prithvi
                if( mapOfDefaultTaskVals.containsKey(objTask.Subject.toLowerCase()) && 
                    mapOfDefaultTaskVals.get(objTask.Subject.toLowerCase()).Next_Task__c != null &&    
                    mapOfParentAccounts.containsKey(objTask.WhatId) ){
                    
                    AMPS_Marketing_Activity_Flow__c  objTaskFlow = mapOfDefaultTaskVals.get(objTask.Subject.toLowerCase());
                    String strParentTaskId = '';
                    System.debug('Here is the current task flow ====' + objTaskFlow);
                    
                    System.debug('Next task or subtask is not null');
                       
                    if(objTaskFlow.Parent_Task__c != NULL ){ //If the task is a subtask and make sure it has a parent task Id 
                        system.debug('This is a subtask!');
                        if(objTask.IsClosed == TRUE){
                            system.debug('This is a completed subtask!');
                            strParentTaskId = objTask.ParentTask_Id__c;//// get the parent task id for the subtask
                            setNextTaskValues(mapOfDefaultTaskVals.get(objTaskFlow.Next_Task__r.Name.toLowerCase())); //get the next sub task
                        }

                    }else if(objTaskFlow.Parent_Task__c == NULL){  //If the task is a parent task
                        system.debug('This is a parent task!');
                        
                        if( objTask.Status == 'Deferred'){ //if the task is deferred
                            system.debug('This is a deferred parent task!');
                            system.debug('This is a deferred parent task with no subtask');
                            if(objTaskFlow.Sub_Task__c ==null){ //if there's no subtask, do nothing
                                 system.debug('This is a deferred parent task with no subtask');
                                return null;
                            }
                            setNextTaskValues(mapOfDefaultTaskVals.get(objTaskFlow.Sub_Task__r.Name.toLowerCase())); //get the next sub task
                            strParentTaskId = objTask.Id; // get the parent task id for the subtask
                        }else if(objTask.IsClosed == True){ //if the task is completed
                            system.debug('This is a completed parent task!');
                            setNextTaskValues(mapOfDefaultTaskVals.get(objTaskFlow.Next_Task__r.Name.toLowerCase())); //get the next sub task
                           // mapOfNextTasks.get(objTaskFlow);
                            setofParentTasks.add(objTask.Id); //get parent task name
                             
                        }
                        //If the task is a completed parent task
                    }
                        
                        if(objTaskFlow != NULL ){
                            // Created a separate class to create the task record with proper mappings..
                            system.debug('creating new customer tasks.........');
                            ID ownerID ;
                            if(strSubject.contains('QUARTERLY ACTIVITY')){
                                if(userMap.containskey('Practice Support Partner'))
                                ownerID = userMap.get('Practice Support Partner');
                            }else{
                                if(userMap.containskey('AMPS Representative'))
                                ownerID = userMap.get('AMPS Representative');
                            }
                            if(ownerID == null)objTask.addError('You are not Authorised to close this Task.');
                            Task objTaskToInsert = insertTasks( priority,status,
                                                                                  type,
                                                                                  ownerID ,
                                                                                  strSubject,
                                                                                  numberOfDays,
                                                                                  acct.id);

                            // Updating parent Id on newly created Task...
                        
                            if(strParentTaskId != ''){
                                system.debug('Assigning Parent Id to Self ----- Parent Id = ' +strParentTaskId );
                                objTaskToInsert.ParentTask_Id__c = strParentTaskId;
                            }
                            lstNewTasksToInsert.add(objTaskToInsert);
                        } 
                }
                    
                
                   userMap = new Map<String,ID>();
            }
            
            //insert the new taks
            if(!lstNewTasksToInsert.isEmpty()){
                system.debug('lstNewTasksToInsert :'+lstNewTasksToInsert);
                insert lstNewTasksToInsert;
            }
            
           
            
            List<Task> lstTasksToUpdate = new List<Task>(); //list of tasks to update
            
            //close parent tasks if the child task is complete, nad the child task if the parent is complete
            if(!setofParentTasks.isEmpty() ){
                System.debug('set of parent tasks ==============='+ setofParentTasks);
                
                for(Task objTask : [Select Id,ParentTask_Id__c,Status 
                                    From Task 
                                    Where ParentTask_Id__c != ''
                                        AND ParentTask_Id__c != Null
                                        AND ParentTask_Id__c IN :setofParentTasks
                                        AND IsClosed != TRUE
                                        Order By CreatedDate desc
                                        Limit 1000 ]){
                    objTask.Status = 'Completed';
                    lstTasksToUpdate.add(objTask);
                }
            }    
            
            //update tasks
            if(!lstTasksToUpdate.isEmpty()){
                    update lstTasksToUpdate;
            }
            
                    
        }
        return lstNewTasksToInsert; //return the inserted task   
     }
     
}