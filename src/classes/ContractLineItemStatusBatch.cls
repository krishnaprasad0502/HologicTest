global class ContractLineItemStatusBatch implements Database.Batchable<sObject> {
	
	global Database.QueryLocator start(Database.BatchableContext bc){
		String formattedToday = String.valueOf(Date.today());
		String query =
			'SELECT Id, AssetId FROM ContractLineItem'
		  + ' WHERE (StartDate = ' + formattedToday
		  			+ ' OR EndDate = ' + formattedToday
		  			+ ' OR Asset.Contract_Line_Processing_Completed__c = false'
				 + ')'
		  + ' AND (Asset.AccountId != null OR Asset.ContactId != null)';
		return Database.getQueryLocator(query);
	}
	
	global void execute(Database.BatchableContext bc, List<sObject> scope){
		Set<Id> assetIds = new Set<Id>();
		for(sObject ent : scope){
			Id assetId = (Id)ent.get('AssetId');
			if(assetId != null){
				assetIds.add(assetId);
			}
		}
		if(assetIds.size() > 0){
			ContractLineItemTriggerActions.updateParentAssets(assetIds);
		}
	}
	
	global void finish(Database.BatchableContext bc){}

}