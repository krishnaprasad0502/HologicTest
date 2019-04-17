/*------------------------------------------------------------
Author:			Denise Bacher
Company:		Salesforce.com
Description:	Invocable Method to build Preferred, Required and Excluded recorces for a Service record
Test Class:		ServiceResourceBuilder_Invocable_Test

History:
<Date>			<Authors Name>		<Brief Description of Change>
05/26/2016		Denise Bacher		Initial Creation (US1059)
06/14/2016		Denise Bacher		Updated generisize creation of roles by boolean values (US1277)
------------------------------------------------------------*/
public with sharing class ServiceResourceBuilder_Invocable {

	/*------------------------------------------------------------
	Author:			Denise Bacher
	Company:		Salesforce.com
	Description:	Invocable Method to create preferred/required/excluded resources for a service record based on the account
					TODO: at some point, anything with the prefix CKSW_BASE__ may need to be updated
	Inputs:			requests - list of ServiceResourceRequest (represents the service record and the resource types that need to be created)
	Returns:		N/A
	
	History:
	<Date>			<Authors Name>		<Brief Description of Change>
	05/26/2016		Denise Bacher		Initial Creation (US1059)
	06/13/2016		Denise Bacher		Updated generisize creation of roles by boolean values (US1277)
	------------------------------------------------------------*/
	@InvocableMethod(label='Create Service Resources' description='Create the preferred, required and excluded resources from the account on the service record.')
	public static void createServiceResources(List<ServiceResourceRequest> requests){
		List<CKSW_BASE__Required_Resource__c> reqdResources = new List<CKSW_BASE__Required_Resource__c>();
		List<CKSW_BASE__Preferred_Resource__c> prefdResources = new List<CKSW_BASE__Preferred_Resource__c>();
		List<CKSW_BASE__Excluded_Resource__c> excldResources = new List<CKSW_BASE__Excluded_Resource__c>();
		Set<Id> accountIDs = new Set<Id>();
		Set<String> resourceRoles = new Set<String>();
		
		// collect the account IDs
		// collect the resource roles
		for(ServiceResourceRequest r : requests){
			if(r.accountId != null){
				accountIds.add(r.accountId);
			}
			if(String.isNotBlank(r.resourceRole)){
				resourceRoles.add(r.resourceRole);
			}
		}
		
		// fetch the account information and the acctive FE account resources
		Map<Id, Account> accountMap = new Map<Id, Account>([Select Id, 
				(Select Resource__c, Resource_Role__c, IsExcluded__c, IsPreferred__c, IsRequired__c
				From Account_Resources__r 
				Where IsActive__c = true 
				And Resource_Role__c IN: resourceRoles) 
			From Account Where Id IN: accountIds]);
		
		// create the service resources
		for(ServiceResourceRequest r : requests){
			Account a = accountMap.get(r.accountId);
			
			if(a != null){
				for(Account_Resource__c ar : a.Account_Resources__r){
					// if the resource role matches, proceed creating the roles
					if(ar.Resource_Role__c == r.resourceRole){
						if(r.createRequiredResources && ar.IsRequired__c){
							reqdResources.add(new CKSW_BASE__Required_Resource__c(CKSW_BASE__Resource__c = ar.Resource__c,
								CKSW_BASE__Service__c = r.serviceId));
						}
						
						if(r.createPreferredResources && ar.IsPreferred__c){
							prefdResources.add(new CKSW_BASE__Preferred_Resource__c(CKSW_BASE__Resource__c = ar.Resource__c,
								CKSW_BASE__Service__c = r.serviceId));
						}
						
						if(r.createExcludedResources && ar.IsExcluded__c){
							excldResources.add(new CKSW_BASE__Excluded_Resource__c(CKSW_BASE__Resource__c = ar.Resource__c,
								CKSW_BASE__Service__c = r.serviceId));
						}
					}
				}
			}
		}
		
		insert reqdResources;
		insert prefdResources; 
		insert excldResources;
	}
	
	public class ServiceResourceRequest {
		@InvocableVariable(required=true)
		public Id serviceId;
		
		@InvocableVariable(required=true)
		public Id accountId;
		
		@InvocableVariable(required=true)
		public String resourceRole;
		
		@InvocableVariable(required=true)
		public Boolean createRequiredResources;
		
		@InvocableVariable(required=true)
		public Boolean createPreferredResources;
		
		@InvocableVariable(required=true)
		public Boolean createExcludedResources;
		
		public ServiceResourceRequest(){}
		
		public ServiceResourceRequest(Id serviceId, Id accountId, String resourceRole, Boolean required, Boolean preferred, Boolean excluded){
			this.serviceId = serviceId;
			this.accountId = accountId;
			this.resourceRole = resourceRole;
			this.createRequiredResources = required;
			this.createPreferredResources = preferred;
			this.createExcludedResources = excluded;
		}
	}
}