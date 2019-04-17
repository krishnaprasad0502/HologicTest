/*------------------------------------------------------------
Author:			Sumit Gupta
Company:		Salesforce.com
Description:	Invocable Method to copy Account skills from Account to Service as Service skills on Service creation
Test Class:		ServiceResourceBuilder_Invocable_Test

History:
<Date>			<Authors Name>		<Brief Description of Change>
07/01/2016		Sumit Gupta			Initial Creation (US798)
------------------------------------------------------------*/
public with sharing class VendorCredentialTracking_Invocable {

	// Global variable to store supported account skill type
	public static String ACCOUNT_SKILL_TYPE = 'Vendor Credential'; 

	/*------------------------------------------------------------
	Author:			Sumit Gupta
	Company:		Salesforce.com
	Description:	Invocable Method to copy Account skills from Account to Service as Service skills on Service creation
	Inputs:			requests - list of ServiceRequestWrapper (represents the service record)
	Returns:		N/A
	
	History:
	<Date>			<Authors Name>		<Brief Description of Change>
	07/01/2016		Sumit Gupta			Initial Creation (US798)
	------------------------------------------------------------*/
	@InvocableMethod(label='Add Service Skills' description='Copy Account Skills from Account to Service as Service Skills on Service creation')
	public static void AddServiceSkills(List<ServiceRequestWrapper> requests){
		List<Id> accountIds = new List<Id>();
		Map<Id, List<Id>> accountSkillIdsMap = new Map<Id, List<Id>>();
		List<CKSW_BASE__Service_Skill__c> serviceSkills = new List<CKSW_BASE__Service_Skill__c>();
		
		// collect the account IDs
		for(ServiceRequestWrapper r : requests){
			if(r.accountId != null && r.serviceId != null){
				accountIds.add(r.accountId);
			}
		}
		
		// fetch the active account skills of type Vendor Credential from accounts
		List<Account_Skill__c> accountSkills = [SELECT Id, Account__c, Skill__c
			FROM Account_Skill__c 
			WHERE IsActive__c = true 
			AND Type__c =: ACCOUNT_SKILL_TYPE 
			AND Account__c IN: accountIds ];

		// prepare a map of account id to skill ids
		for(integer i = 0; i < accountSkills.size(); i++){
			Account_Skill__c accountSkill = accountSkills.get(i);
			List<Id> skillIds = accountSkillIdsMap.get(accountSkill.Account__c);

			if(skillIds == null){
				skillIds = new List<Id>();
			}
			skillIds.add(accountSkill.Skill__c);
			accountSkillIdsMap.put(accountSkill.Account__c, skillIds);
		}
		
		// create the service skills
		for(ServiceRequestWrapper r : requests){
			List<Id> skillIds = accountSkillIdsMap.get(r.accountId);
			
			if(skillIds != null){
				for(integer i = 0; i < skillIds.size(); i++){
					serviceSkills.add(new CKSW_BASE__Service_Skill__c(CKSW_BASE__Service__c = r.serviceId, CKSW_BASE__Skill__c = skillIds.get(i)));
				}
			}
		}

		if(serviceSkills.size() > 0){
			insert serviceSkills;
		}
	}
		
	public class ServiceRequestWrapper {
		@InvocableVariable(required=true)
		public Id serviceId;
		
		@InvocableVariable(required=true)
		public Id accountId;
		
		public ServiceRequestWrapper(){}
		
		public ServiceRequestWrapper(Id serviceId, Id accountId){
			this.serviceId = serviceId;
			this.accountId = accountId;
		}
	}
}