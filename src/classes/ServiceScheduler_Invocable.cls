/*------------------------------------------------------------
Author:			Chad Barbour
Company:		Salesforce.com
Description:	Invocable Method to schedule service appointments
Test Class:		ServiceScheduler_Invocable_Test

History:
<Date>			<Authors Name>		<Brief Description of Change>
08/11/2016		Chad Barbour		Initial Creation (US1451)
------------------------------------------------------------*/
public class ServiceScheduler_Invocable {

	@InvocableMethod(label='Schedule Service Appointment' description='Schedule a service appointment using a specific scheduling policy.')
	public static void scheduleServices(List<ServiceAppointment> appointments){
        
        //Check to see if the appointments have been provided
        if(appointments != null && !appointments.isEmpty()){

            //Build a map of scheduling policies for reference
            Map<String,String> policyMap = new Map<String,String>();
            for(CKSW_BASE__Scheduling_Policy__c p : [SELECT Id, Name FROM CKSW_BASE__Scheduling_Policy__c]){
                
                policyMap.put(p.Name,p.Id);
                
            }
            
            //Schedule each appointment
            if(policyMap != null && !policyMap.isEmpty()){
                
               for(ServiceAppointment sa : appointments){
               
                   if(sa.autoschedule){
                       
                       String serviceApptId = sa.serviceId;
                   	   String policyId = policyMap.get(sa.schedulingPolicyName);
                
                       CKSW_SRVC.ScheduleResult result = CKSW_SRVC.ScheduleService.Schedule(policyId,serviceApptId);
                   
                	   //The result cannot be used by the process builder, set the result to null to clear from heap   	
                	   result = null;
                       
                   }
            		
            	} 
                
    		}
            
        }   

	}
    
	
	public class ServiceAppointment {
		@InvocableVariable(required=true)
		public Id serviceId;
		
		@InvocableVariable(required=true)
		public String schedulingPolicyName;
        
        @InvocableVariable(required=true)
        public Boolean autoSchedule;
	}
}