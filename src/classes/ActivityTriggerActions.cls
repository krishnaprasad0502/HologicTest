/*------------------------------------------------------------
Author:     Kasmoor Reddy
Description:  Trigger framework for Activities.
Test Class:   ActivityTriggerActions_Test

History:
<Date>      <Authors Name>    <Brief Description of Change>
10/26/2017   Kasmoor Reddy    Initial Creation(US3490)
------------------------------------------------------------*/
public with sharing class ActivityTriggerActions {
	 //Map declarations
	public static Map<id,Case> mapcases = new Map<id,Case>();
    public static Map<id,Opportunity> mapoppty = new Map<id,Opportunity>();
    public static Map<id,WorkOrder> mapwrkoderes = new Map<id,WorkOrder>();
	/*-----------------------------------------------------------------------------
    Author:      Kasmoor Reddy
    Company:     Apps Associates
    Description: Method in which we are getting all the variables from event and task to create
                 procedure.
    Returns:     N/A
      
    History:
    <Date>         <Authors Name>      <Brief Description of Change>
    10/26/2017     Kasmoor Reddy       Initial Creation(US3490)
-----------------------------------------------------------------------------------*/
    public static void createProcedureFromActivity(List<Sobject> newList){
    //Variable declarations	
    List<id> Caseids= new List<id>();
    List<id> Oppids= new List<id>();
    List<id> woids= new List<id>();
    List<Procedure__c> Insrtactivityprocedures = new List<Procedure__c>();
    system.debug('newList-----'+newList);
     
     for(Sobject sobj: newList){
     	//While creating the event to create procedure
    	if(sobj.getSobjectType()==Event.Sobjecttype)
    	{
    		 Event e=(Event)sobj;
    		 if(e.Whatid != null && e.Create_Procedure_From_Event__c == true){
	    		 //Event creation from case
	    		 if(string.valueof(e.Whatid).startsWith('500')){
	    		 	Caseids.add(e.Whatid);
	    		 }
	    		 //Event creation from opportunity
	    		 if(string.valueof(e.Whatid).startsWith('006')){
	    		 	Oppids.add(e.Whatid);
	    		 }
	    		 //Event creation from workorder
	    		 if(string.valueof(e.Whatid).startsWith('0WO')){
	    		 	woids.add(e.Whatid);
	    		 }
    	    }	 
    		 //while creating the task to create procedure
    	}else if(sobj.getSobjectType()==Task.Sobjecttype){
    		 Task t=(Task)sobj;
    		 if(t.Whatid != null && t.Create_Procedure_from_Task__c == true){
	    		 //Task creation from case
	    		 if(string.valueof(t.Whatid).startsWith('500')){
	    		 	Caseids.add(t.Whatid);
	    		 }
	    		 //Task creation from opportunity
	    		 if(string.valueof(t.Whatid).startsWith('006')){
	    		 	Oppids.add(t.Whatid);
	    		 }
	    		 //Task creation from workorder
	    		 if(string.valueof(t.Whatid).startsWith('0WO')){
	    		 	woids.add(t.Whatid);
	    		 }
    		 }	 
    		
    	}
     } 	
    	//getting related values object-wise in map variables
    	if(Caseids.size()>0){
    	   mapcases = new Map<id,Case>([Select id,Accountid from Case where id IN:Caseids]);
    	}
    	if(Oppids.size()>0){
    	   mapoppty = new Map<id,Opportunity>([Select id,Accountid from Opportunity where id IN:Oppids]);
    	}
    	if(woids.size()>0){
    	   mapwrkoderes = new Map<id,WorkOrder>([Select id,Accountid from WorkOrder where id IN:woids]);
    	}
    	
    	for(Sobject sobj: newList){
    		//While creating the event to create procedure
    		
	    	if(sobj.getSobjectType()==Event.Sobjecttype)
	    	{
	    		 Event e=(Event)sobj;
	    		 //Checking conditions while creating the new event
	    		 if(e.Create_Procedure_From_Event__c == true && e.Whatid != null && e.Whoid != null && (mapcases.size()>0 || mapoppty.size()>0 || mapwrkoderes.size()>0)){
	    		 	Insrtactivityprocedures.add(createProcedure(e.Whatid,e.Subject,e.Whoid,e.StartDateTime,e.Description,'Event'));
	    	  }
	    	     //While creating the Task to create procedure 
	    	}else if(sobj.getSobjectType()==Task.Sobjecttype){
	    		 Task t=(Task)sobj;
	    		 //Checking conditions while creating the new task
	    		 if(t.Create_Procedure_from_Task__c == true && t.Whatid != null && t.Whoid != null && (mapcases.size()>0 || mapoppty.size()>0 || mapwrkoderes.size()>0)){
	    		 	Insrtactivityprocedures.add(createProcedure(t.Whatid,t.Subject,t.Whoid,t.ActivityDate,t.Description,'task'));
	    		 }
	    		
	    	}
    	
     }
     //inserting the procedures from event/task
     system.debug('Insrtactivityprocedures'+Insrtactivityprocedures);
     if(Insrtactivityprocedures.size()>0){
         Database.SaveResult[] lcr = Database.Insert(Insrtactivityprocedures,false);
        for(Integer index = 0; index < lcr.size(); index++){
            if(!lcr[index].isSuccess()){
            Insrtactivityprocedures[index].addError('Failed to Insert Procedure records: '+lcr[index].getErrors()[0].getMessage());
                
            }
        }
    } 	 
    	     
    	
    	
 }
    /*-----------------------------------------------------------------------------
    Author:      Kasmoor Reddy
    Company:     Apps Associates
    Description: Method which will create the procedure from task and event when checkbox is checked.
    Returns:     N/A
      
    History:
    <Date>         <Authors Name>      <Brief Description of Change>
    10/26/2017     Kasmoor Reddy       Initial Creation(US3490)
   -----------------------------------------------------------------------------------*/
     public static Procedure__c createProcedure(string Whatid,string Subject,string Whoid,datetime ActivityDate,string Description,string type){
     	        //creating procedure from event or task when the checkbox is checked.
                Procedure__c evntprocdre = new Procedure__c();
    		 	
    		 	if(string.valueof(Whatid).startsWith('001')){
		    	 evntprocdre.Account__c = Whatid;
    		 	}else if(string.valueof(Whatid).startsWith('500')){
    		 	  evntprocdre.Account__c = mapcases.get(Whatid).Accountid;
    		    }
    		    else if(string.valueof(Whatid).startsWith('006')){
    		 	  evntprocdre.Account__c = mapoppty.get(Whatid).Accountid;
    		    }else if(string.valueof(Whatid).startsWith('0WO')){
    		 	  evntprocdre.Account__c = mapwrkoderes.get(Whatid).Accountid;
    		    }
    		    evntprocdre.Name = Subject;
		    	evntprocdre.Practicing_Physician__c = Whoid;
		    	evntprocdre.Procedure_Date__c = Date.newInstance(ActivityDate.year(),ActivityDate.month(),ActivityDate.day());
		    	evntprocdre.Procedure_Notes__c = Description;
		    	evntprocdre.Procedure_Status__c = 'Completed';
		    	return evntprocdre;
     }
   
  }