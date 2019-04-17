/*------------------------------------------------------------
  Author:         John Christy
  Company:        Apps Associates
  Description:    Updates the MA Territory to reflect the Site Location Territory 
  Runs every 12 hours at 01:00 AM/PM
  Inputs:         N/A
  Returns:        N/A
 
  History:
  <Date>          <Authors Name>      <Brief Description of Change>
  11/27/2018      John Christy        Initial Creation (US-0005566)
  ------------------------------------------------------------*/
global class AccountBatch implements Schedulable {

	global void execute(SchedulableContext sc) {

		// create map of all accounts and territories
		Map<Id, String> otaMap = new Map<Id, String> ();
		for (ObjectTerritory2Association ota :[select ObjectId, Territory2.Name
		     from ObjectTerritory2Association
		     where LastModifiedDate = LAST_N_DAYS : 1
		     and Territory2.ParentTerritory2.ParentTerritory2.ParentTerritory2.DeveloperName = 'Medical_Aesthetics_Sales_US']) {
			otaMap.put(ota.ObjectId, ota.Territory2.Name);
		}

		if (otaMap.size() > 0) {
			// create list of accounts to update
			List<Account> accountUpdates = new List<Account> ();
			// create list of all accounts in otaMap
			List<Account> accountList = [select Id, Name from Account where Id in :otaMap.keySet()];

			// update each account with the territory
			for (Account a : accountList) {
				a.Medical_Aesthetics_Marketing_Territory__c = otamap.get(a.Id);
				accountUpdates.add(a);
			}

			update accountUpdates;
		}
	}
}