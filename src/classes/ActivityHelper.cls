/*------------------------------------------------------------
Author:     Kasmoor Reddy
Description:  Trigger framework for Activities.
Test Class:   ActivityTriggerActions_Test

History:
<Date>      <Authors Name>    <Brief Description of Change>
10/26/2017   Kasmoor Reddy    Initial Creation(US3490)
10/23/2018		Dave Mansell	Refactored code
04/09/2019   Alex Powning      Added Swarm Waypoint Actions Func
------------------------------------------------------------*/
public with sharing class ActivityHelper {

	public static void createProcedureFromActivity(List<SObject> recs){
		Map<Id, Case> casesById = new Map<Id, Case>();
		Map<Id, Opportunity> oppsById = new Map<Id, Opportunity>();
		Map<Id, WorkOrder> wosById = new Map<Id, WorkOrder>();
		
		List<SObject> validRecs = new List<SObject>();
		for(SObject rec : recs){
			if(rec.get('WhatId') != null
				&& rec.get('WhoId') != null
				&& (
					   (rec.getSObjectType() == Event.SObjectType && rec.get('Create_Procedure_From_Event__c') == true)
					|| (rec.getSObjectType() == Task.SObjectType && rec.get('Create_Procedure_From_Task__c') == true)
				   )
			){
				validRecs.add(rec);
				
				Id whatId = (Id)rec.get('WhatId');
				if(whatId.getSObjectType() == Case.SObjectType){
					casesById.put(whatId, null);
				} else if(whatId.getSObjectType() == Opportunity.SObjectType){
					oppsById.put(whatId, null);
				} else if(whatId.getSObjectType() == WorkOrder.SObjectType){
					wosById.put(whatId, null);
				}
			}
		}
		
		if(validRecs.isEmpty() || (casesById.isEmpty() && oppsById.isEmpty() && wosById.isEmpty())){
			return;
		}
		
		if(casesById.size() > 0){
			casesById = new Map<Id, Case>([
				SELECT Id
					  ,AccountId
				  FROM Case
				 WHERE Id IN :casesById.keySet()
			]);
		}
		if(oppsById.size() > 0){
			oppsById = new Map<Id, Opportunity>([
				SELECT Id
					  ,AccountId
				  FROM Opportunity
				 WHERE Id IN :oppsById.keySet()
			]);
		}
		if(wosById.size() > 0){
			wosById = new Map<Id, WorkOrder>([
				SELECT Id
					  ,AccountId
				  FROM WorkOrder
				 WHERE Id IN :wosById.keySet()
			]);
		}
		
		List<Procedure__c> procsToInsert = new List<Procedure__c>();
		for(SObject rec : validRecs){
			Procedure__c proc = new Procedure__c();
			Id whatId = (Id)rec.get('WhatId');
			
			if(whatId.getSObjectType() == Case.SObjectType){
				proc.Account__c 			= casesById.get(whatId).AccountId;
			} else if(whatId.getSObjectType() == Opportunity.SObjectType){
				proc.Account__c 			= oppsById.get(whatId).AccountId;
			} else if(whatId.getSObjectType() == WorkOrder.SObjectType){
				proc.Account__c 			= wosById.get(whatId).AccountId;
			}
			proc.Name 						= (String)rec.get('Subject');
			proc.Practicing_Physician__c 	= (Id)rec.get('WhoId');
			proc.Procedure_Date__c 			= (Date)rec.get('ActivityDate');
			proc.Procedure_Notes__c 		= (String)rec.get('Description');
			proc.Procedure_Status__c 		= 'Completed';
			
			procsToInsert.add(proc);
		}
		insert procsToInsert;
	}
    
    public static void swarmWaypointActivityActions(List<Event> events){
        //get swarm waypoint related activities
        List<Event> validRecs = new List<Event>();
        List<id> validRecWhatIds = new List<id>();
        for (Event rec : events){
            if (string.valueof(rec.whatid.getsobjecttype()) == 'Swarm_Waypoint__c'){
                validRecs.add(rec);
                validRecWhatIds.add(rec.whatid);
            }
        }
        
        //return if validrec list empty
        if (validRecs.isEmpty()) {
            return;
        }
        
        //get lead or contact id for swarm waypoint given activity whatid
        map<id, id> swarmToLeadContact = new map<id,id>();
        for (Swarm_Waypoint__c swarm : [select id, Lead__c, Contact__c from Swarm_Waypoint__c where id = :validRecWhatIds]) {
            if (swarm.Lead__c != null){
            	swarmToLeadContact.put(swarm.id, swarm.Lead__c);
            } else {
                swarmToLeadContact.put(swarm.id, swarm.Contact__c);
            }
        }
        
        //replace activity whatid with lead or contact whoid, post message to chatter for swarm waypoint
        for (Event rec : validRecs){
            id whoid = swarmToLeadContact.get(rec.whatid);
            rec.whatid = null;
            rec.whoid = whoid;
        }
    }
}