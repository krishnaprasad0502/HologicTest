/*------------------------------------------------------------
Author:			Denise Bacher
Company:		Salesforce.com
Description:	Sets the default territory for an opportunity from the user inserting the opportunity
Test Class:		OppTerrAssignDefaultLogicFilter_Test

History:
<Date>			<Authors Name>		<Brief Description of Change>
06/21/2016		Denise Bacher		Initial Creation (US1294)
------------------------------------------------------------*/
global class OppTerrAssignDefaultLogicFilter implements TerritoryMgmt.OpportunityTerritory2AssignmentFilter {

	global OppTerrAssignDefaultLogicFilter() {}
	
	/*------------------------------------------------------------
	Author:			Denise Bacher
	Company:		Salesforce.com
	Description:	Get mapping of opportunity to territory2Id. The incoming list of opportunityIds contains only those with IsExcludedFromTerritory2Filter=false.
	
	History:
	<Date>			<Authors Name>		<Brief Description of Change>
	06/21/2016		Denise Bacher		Initial Creation
	------------------------------------------------------------*/
	global Map<Id, Id> getOpportunityTerritory2Assignments(List<Id> opportunityIds) {
		Map<Id, Id> oppToTerritory = new Map<Id, Id>();

		// Get the active territory model Id
		Id activeModelId = getActiveModelId();

		if(activeModelId != null){
			List<Opportunity> opportunities = [Select Id, AccountId, Territory2Id, OwnerId From Opportunity Where Id IN: opportunityIds];
			
			// go through the opportunities and pull out the account ids, and map the owner of the opp to the opp's account
			Map<Id, Map<Id, Id>> ownerToAccountToTerritory = new Map<Id, Map<Id, Id>>();
			Set<Id> accountIds = new Set<Id>();
			for(Opportunity o : opportunities){
				if(o.AccountId != null){
					accountIds.add(o.AccountId);
				}
				
				if(!ownerToAccountToTerritory.containsKey(o.OwnerId)){
					ownerToAccountToTerritory.put(o.OwnerId, new Map<Id, Id>());
				}
				
				if(o.AccountId != null){
					ownerToAccountToTerritory.get(o.OwnerId).put(o.AccountId, null);
				}
			}
			System.debug('PRE ownerToAccountToTerritory '+ownerToAccountToTerritory);
			
			// query for the account's territories, pull out the territory ids, and map the account to its territories
			Map<Id, Set<Id>> accountToTerritory =  new Map<Id, Set<Id>>();
			Set<Id> territoryIds = new Set<Id>();
			for(ObjectTerritory2Association ato : [Select ObjectId, Territory2Id
				From ObjectTerritory2Association 
				Where ObjectId IN: accountIds 
				And Territory2.Territory2ModelId =: activeModelId])
			{
				if(ato.Territory2Id != null){
					territoryIds.add(ato.Territory2Id);
				}
				
				if(!accountToTerritory.containsKey(ato.ObjectId)){
					accountToTerritory.put(ato.ObjectId, new Set<Id>());
				}
				accountToTerritory.get(ato.ObjectId).add(ato.Territory2Id);
			}
			System.debug('accountToTerritory '+accountToTerritory);
			
			// query for opp owners territories, that were also found as territories on the accounts
			for(UserTerritory2Association uta : [Select UserId, Territory2Id
				From UserTerritory2Association
				Where IsActive = true
				And Territory2Id IN: territoryIds
				And UserId IN: ownerToAccountToTerritory.keySet()])
			{
				// get the accounts the user is mapped to
				Map<Id, Id> currUserAccountToTerritory = ownerToAccountToTerritory.get(uta.UserId);
				
				// loop through the accounts
				for(Id accountId : currUserAccountToTerritory.keySet()){
					if(accountToTerritory.containsKey(accountId)){
						// get the territories mapped to the account
						Set<Id> currAccountTerritories = accountToTerritory.get(accountId);
						
						// if the current user territory is also the account's territory, log it
						if(currUserAccountToTerritory.get(accountId) == null && currAccountTerritories.contains(uta.Territory2Id)){
							currUserAccountToTerritory.put(accountId, uta.Territory2Id);
						}
					}
				}
			}
			System.debug('POST ownerToAccountToTerritory '+ownerToAccountToTerritory);
		
			// map the opp to the territory	
			for(Opportunity o : opportunities){
				oppToTerritory.put(o.Id, ownerToAccountToTerritory.get(o.OwnerId).get(o.AccountId));
			}
			
			System.debug('RETURN oppToTerritory '+oppToTerritory);
		}
		
		return oppToTerritory;
	}	
	
	/*------------------------------------------------------------
	Author:			Denise Bacher
	Company:		Salesforce.com
	Description:	Get the Id of the Active Territory Model. If none exists, return null.
	
	History:
	<Date>			<Authors Name>		<Brief Description of Change>
	06/21/2016		Denise Bacher		Initial Creation
	------------------------------------------------------------*/
	private Id getActiveModelId() {
		List<Territory2Model> models = [Select Id From Territory2Model Where State = 'Active'];
		Id activeModelId = null;
		if(models.size() == 1){
			activeModelId = models.get(0).Id;
		}

		return activeModelId;
	}
}