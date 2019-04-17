public class ServiceTerritoryHelper {
	
	public static Id findServiceTerritoryId(String div, String zip, String state, String country, String stType){
		//Concatenate our territory field
		String territoryField = div.replace(' ', '_') + '_' + stType.replace(' ', '_');
		
		if(zip != null && zip.length() > 5 && country != null && country == 'US'){
			zip = zip.substring(0, 5);
		}
		
		String query =
			  'SELECT Id'
			+ ', ' + territoryField + '__c'
			+  ' FROM Service_Geography__c'
			+ ' WHERE ((Type__c = \'Postal Code\' AND PostalCode__c = :zip)'
			+ '    OR (Type__c = \'State\' AND State__c = :state)'
			+ '    OR (Type__c = \'Country\' AND Country__c = :country))'
			+ '    AND ' + territoryField + '__r.TopLevelTerritory.Name = :div'
			+ '    AND ' + territoryField + '__r.Service_Territory_Type__c = :stType'
			+ ' ORDER BY Priority__c ASC'
			+ ' LIMIT 1'
			;
		
		List<Service_Geography__c> geos = Database.query(query);
		if(geos.size() > 0){
			return (Id)geos[0].get(territoryField + '__c');
		}
		
		return null;
	}
	
	public static Map<String, Id> findServiceTerritoryIds(Set<String> divs, Set<String> zips){
		Map<String, Id> geoIdsByKey = new Map<String, Id>();
		for(String div : divs){
			for(String zip : zips){
				String key = div + '|' + zip;
				geoIdsByKey.put(key, findServiceTerritoryId(div, zip, null, null, 'Service'));
			}
		}
		return geoIdsByKey;
	}

}