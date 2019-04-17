/*------------------------------------------------------------
Author:         Kasmoor Reddy
Company:        Apps Associates
Description:    Trigger framework for the Event object
Test Class:     ActivityTriggerActions_Test

History:
<Date>          <Authors Name>      <Brief Description of Change>
10/26/2017      Kasmoor Reddy       Initial Creation <US3490>
10/23/2018		Dave Mansell		Refactored code
04/09/2019   Alex Powning      Added Swarm Waypoint Actions Func
------------------------------------------------------------*/
trigger EventTrigger on Event (before insert, before update, before delete, after insert, after update, after delete) {
	
	private static Boolean isActive = GlobalUtility.isTriggerActive('EventTrigger');
	
	if(isActive){
	    if(Trigger.isBefore){
	        if(Trigger.isInsert){
                ActivityHelper.swarmWaypointActivityActions(trigger.new);
            }
	        if(Trigger.isUpdate){}
	        if(Trigger.isDelete){}
	        
	    }
	    if(Trigger.isAfter){
            if(Trigger.isInsert){
            	ActivityHelper.createProcedureFromActivity(trigger.new);
            }
            if(Trigger.isUpdate){}
            if(Trigger.isDelete){}
        }
    }
}