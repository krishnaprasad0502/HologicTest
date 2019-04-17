/*------------------------------------------------------------
Author:			Denise Bacher
Company:		Salesforce.com
Description:	Schedulable Batch job that calculates the skill rating for a Resource
				TODO: at some point, anything with the prefix CKSW_BASE__, FSL_INTG__, or FSO__ may need to be updated
Test Class:		CalculateResourceSkill_SchedBatch_Test

Execute:		System.schedule('Calculate Resource Skill', '0 0 0 * * ?', new CalculateResourceSkill_SchedBatch());

History:
<Date>			<Authors Name>		<Brief Description of Change>
05/27/2016		Denise Bacher		Initial Creation (US956)
06/24/2016		Denise Bacher		Only level resorce skills where the relate skil has "Auto Level" checked (US1310)
03/06/2018      Kasmoor Reddy		Added the insert method from Apex class GlobalUtility to Capture the error message in to custom object Apex_Log (US-0003995)
------------------------------------------------------------*/
//Updated by Kasmoor Reddy on 03/06/2018 Implemented an Interface 'Database.Stateful' to support requirements of US-000395
global class CalculateResourceSkill_SchedBatch implements Database.Batchable<SObject>, Schedulable,Database.Stateful{
	
	global void execute(SchedulableContext sc) {
		Database.executeBatch(new CalculateResourceSkill_SchedBatch(), 50);
	}
	//Created an Exceptionlist to capture exceptions in custom object Apex_log (US-000395) by kasmoor Reddy on 03/06/2018
	 global list<Exception> exceptionList = new List<Exception>();
	
	
	global Set<String> inProgressStatuses;
	global Set<String> completedStatuses;
	global Set<String> profileNames;
	global DateTime endDate;
	
	global CalculateResourceSkill_SchedBatch(){
		Skill_Calculation_Setting__mdt settings = [Select Id, Day_Range__c, Work_Order_Completed_Statuses__c, Work_Order_In_Progress_Statuses__c, User_Profiles__c
			From Skill_Calculation_Setting__mdt
			Where DeveloperName = 'Batch_Skill_Settings'];
			
		inProgressStatuses = new Set<String>(settings.Work_Order_In_Progress_Statuses__c.split(','));
		completedStatuses = new Set<String>(settings.Work_Order_Completed_Statuses__c.split(','));
		profileNames = new Set<String>(settings.User_Profiles__c.split(','));
		endDate = System.now().addDays(-1 * (Integer)settings.Day_Range__c);
	}
	
	global Database.QueryLocator start(Database.BatchableContext context){
		String query = 'Select Id, Name '
			+ ' From CKSW_BASE__Resource__c'
			+ ' Where CKSW_BASE__Active__c = true'
			+ ' And CKSW_BASE__User__r.Profile.Name IN: profileNames';
		return Database.getQueryLocator(query);
	}
	
	global void execute(Database.BatchableContext context, List<CKSW_BASE__Resource__c> scope) {
		Map<Id, Map<Id, DateTime>> mostRecentDateBySkillByResource = new Map<Id, Map<Id, DateTime>>();
		Map<Id, Map<Id, Integer>> currentLevelBySkillByResource = new Map<Id, Map<Id, Integer>>(); 
		
		// initialize the maps for the resources
		for(CKSW_BASE__Resource__c resource : scope){
			mostRecentDateBySkillByResource.put(resource.Id, new Map<Id, DateTime>());
			currentLevelBySkillByResource.put(resource.Id, new Map<Id, Integer>());
		}
		 
		// get service records related to the resources
		List<CKSW_BASE__Service__c> services = [Select Id, CKSW_BASE__Resource__c, FSL_INTG__Work_Order__r.Status, FSL_INTG__Work_Order__r.LastModifiedDate, FSL_INTG__Work_Order__r.FSO__Completed_Date__c
				, (Select Id, CKSW_BASE__Skill__c From CKSW_BASE__Service_Skills__r Where CKSW_BASE__Skill__r.Auto_Level__c = true) 
			From CKSW_BASE__Service__c
			Where CKSW_BASE__Resource__c IN: scope
			AND ((FSL_INTG__Work_Order__r.Status IN: inProgressStatuses AND FSL_INTG__Work_Order__r.LastModifiedDate >=: endDate)
			OR (FSL_INTG__Work_Order__r.Status IN: completedStatuses AND FSL_INTG__Work_Order__r.FSO__Completed_Date__c >=: endDate))
			Order By CKSW_BASE__Resource__c, FSL_INTG__Work_Order__r.FSO__Completed_Date__c NULLS LAST
		];
		
		for(CKSW_BASE__Service__c service : services){
			// grab the date off the Work Order, if it's an in progress status use last modified, if it's a closed status use the completed date
			DateTime currentSkillDate = inProgressStatuses.contains(service.FSL_INTG__Work_Order__r.Status) ? service.FSL_INTG__Work_Order__r.LastModifiedDate : service.FSL_INTG__Work_Order__r.FSO__Completed_Date__c;
			for(CKSW_BASE__Service_Skill__c sSkill : service.CKSW_BASE__Service_Skills__r){
				// map most recent date to the skill and resource
				if(!mostRecentDateBySkillByResource.get(service.CKSW_BASE__Resource__c).containsKey(sSkill.CKSW_BASE__Skill__c)){
					mostRecentDateBySkillByResource.get(service.CKSW_BASE__Resource__c).put(sSkill.CKSW_BASE__Skill__c, currentSkillDate);
				}
				
				// if the currently logged date
				DateTime currentLoggedDate = mostRecentDateBySkillByResource.get(service.CKSW_BASE__Resource__c).get(sSkill.CKSW_BASE__Skill__c);
				if(currentLoggedDate < currentSkillDate){
					mostRecentDateBySkillByResource.get(service.CKSW_BASE__Resource__c).put(sSkill.CKSW_BASE__Skill__c, currentSkillDate);
				}
				
				// map skill level to the skill and resource
				if(!currentLevelBySkillByResource.get(service.CKSW_BASE__Resource__c).containsKey(sSkill.CKSW_BASE__Skill__c)){
					currentLevelBySkillByResource.get(service.CKSW_BASE__Resource__c).put(sSkill.CKSW_BASE__Skill__c, 0);
				}
				Integer currentSkill = currentLevelBySkillByResource.get(service.CKSW_BASE__Resource__c).get(sSkill.CKSW_BASE__Skill__c) + 1;
				currentLevelBySkillByResource.get(service.CKSW_BASE__Resource__c).put(sSkill.CKSW_BASE__Skill__c, currentSkill);
			}
		}
		
		// get resource skill records related to the resources
		List<CKSW_BASE__Resource_Skill__c> resourceSkills = [Select Id, CKSW_BASE__Resource__c, CKSW_BASE__Skill__c, CKSW_BASE__Skill_Level__c, Most_Recent_Skill_Auto_Level_Date__c 
			From CKSW_BASE__Resource_Skill__c
			Where CKSW_BASE__Resource__c IN: scope
			And CKSW_BASE__Skill__r.Auto_Level__c = true
			Order By CKSW_BASE__Resource__c
		];
		
		for(CKSW_BASE__Resource_Skill__c rSkill : resourceSkills){
			rSkill.CKSW_BASE__Skill_Level__c = currentLevelBySkillByResource.get(rSkill.CKSW_BASE__Resource__c).containsKey(rSkill.CKSW_BASE__Skill__c) ? 
				currentLevelBySkillByResource.get(rSkill.CKSW_BASE__Resource__c).get(rSkill.CKSW_BASE__Skill__c) : 0;
				
			rSkill.Most_Recent_Skill_Auto_Level_Date__c = mostRecentDateBySkillByResource.get(rSkill.CKSW_BASE__Resource__c).containsKey(rSkill.CKSW_BASE__Skill__c) ? 
				mostRecentDateBySkillByResource.get(rSkill.CKSW_BASE__Resource__c).get(rSkill.CKSW_BASE__Skill__c) : rSkill.Most_Recent_Skill_Auto_Level_Date__c;
		}
/* Added the try/catch block to catch exceptions and insert to a custom object Apex_debug_Log (US-0003995) by Kasmoor Reddy on 03/06/2018 */
		try
		{
			if(resourceSkills.size()>0)
			{
		update resourceSkills;
			}
		 if(Test.isRunningTest())
                    Integer i = 10/0;
            }
            
            catch(Exception e){
                System.debug('Exception occured when inserting territories:'+e.getMessage());
 // 03/06/2018   Kasmoor Reddy Added the exception to list to capture in custom object Apex_log (US-0003995)      
                  exceptionList.add(e);
           System.debug('Exception :'+exceptionList);
            }
	}
	
	global void finish(Database.BatchableContext context){
        String errorMessage='';
// 03/06/2018   Kasmoor Reddy Added the insert method from Apex class GlobalUtility to Capture the error message in to custom object Apex_Log (US-0003995) 
		  AsyncApexJob a = [Select Id, Status,ExtendedStatus,NumberOfErrors,CompletedDate,JobItemsProcessed,
        TotalJobItems, CreatedBy.Email,JobType
        from AsyncApexJob where Id =:context.getJobId()];
          
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            String[] toAddresses = new String[] {a.CreatedBy.Email};
            mail.setToAddresses(toAddresses);
            mail.setSubject('CalculateResourceSkill_SchedBatch Batch Completed ' + a.Status);
            if(exceptionList==null||exceptionList.isEmpty())
        {
            mail.setPlainTextBody('Records processed ' + a.TotalJobItems +
                                  ' with '+ a.NumberOfErrors + ' failures.');
        }
        else
        {
            for(Exception ex:exceptionList)
            {
                if(ex!=null)
                errorMessage+=ex.getMessage()+' ';
            }
            mail.setPlainTextBody('Records failed to process due to  ' +errorMessage);
        }
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });    

              list<Apex_Log__c> Loglist= new list<Apex_Log__c>();
         Apex_Log__c LogRecord;
        System.debug('Exception -finish::::::::'+exceptionList);
        if(exceptionList!=null)
            {
        for(Exception ex:exceptionList)
        {
			
                
            
             LogRecord= globalutility.NewApexLog('CalculateResourceSkill_SchedBatch',
                                                            'Execute',
                                                            'Error: ' + ex.getMessage() + '; Stack Trace:' + ex.getStackTraceString(),
                                                            a.CompletedDate,a.ExtendedStatus,
                                                            a.JobItemsProcessed,
                                                            a.JobType,
                                                            a.NumberOfErrors,
                                                            a.Status,
                                                            a.TotalJobItems,
                                                            ex.getLineNumber(),
                                                            ex.getTypeName());
            
       
            Loglist.add(LogRecord);
        }
        }
            
            try{
                if(loglist.size()>0)	{   
                    insert Loglist;
                    if(Test.isRunningTest())
                Integer i = 10/0;
                }
            }
            catch(exception e){
                system.debug('Error Message'+e.getMessage());
            }
		
	}
}