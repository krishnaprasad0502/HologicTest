/*------------------------------------------------------------
Author:			Denise Bacher
Company:		Salesforce.com
Description:	Data_Quality__c Trigger functions
Test Class:		DataQualityTrigger_Test

History:
<Date>			<Authors Name>		<Brief Description of Change>
05/25/2016		Denise Bacher		Initial Creation (US1070)
------------------------------------------------------------*/
public with sharing class DataQualityTriggerActions {

	/*------------------------------------------------------------
	Author:			Denise Bacher
	Company:		Salesforce.com
	Description:	Auto generate a Site Location for DQ records that meet the criteria: 
					RT = Site, Type = New Site Location, Status = Verified, Site Locaiton = null
					Runs before insert, before update
	Inputs:			dqList - The list of Data Quality records
					oldDQMap - Map of pervious Data Quality values
	Returns:		N/A
	
	History:
	<Date>			<Authors Name>		<Brief Description of Change>
	05/25/2016		Denise Bacher		Initial Creation (US1070)
	------------------------------------------------------------*/
	public static void autoGenerateNewSiteLocation(List<Data_Quality__c> dqList, Map<Id, Data_Quality__c> oldDQMap){
		Id siteLocationDQRecordTypeId = GlobalUtility.getRecordTypeId('Data_Quality__c', 'Site_Location');
		List<Data_Quality__c> dqNeedNewSite = new List<Data_Quality__c>();
		List<Site_Location__c> newSiteLocations = new List<Site_Location__c>();
		
		// loop through and determine which DQ records need a site location
		for(Data_Quality__c dq: dqList){
			Data_Quality__c oldDQ = oldDQMap.get(dq.Id);
			
			if(oldDQ != null && dq.RecordTypeId == siteLocationDQRecordTypeId && dq.Type__c == 'New Site Location' && dq.Site_Location__c == null
				&& oldDQ.CDQ_Status__c != dq.CDQ_Status__c && dq.CDQ_Status__c == 'Verified')
			{
				dqNeedNewSite.add(dq);
				
				// create the new site location
				Site_Location__c sl = new Site_Location__c(
					Name = dq.Address_Line_1__c
					, Address_Line_1__c = dq.Address_Line_1__c
					, Address_Line_2__c = dq.Address_Line_2__c
					, Address_Line_3__c = dq.Address_Line_3__c
					, Address_Line_4__c = dq.Address_Line_4__c
					, City__c = dq.City__c
					, State__c = dq.State_Code__c
					, Zip_Code__c = dq.Zip_Code__c
					, Country__c = dq.Country_Code__c
					, Parent_Oracle_Party_ID__c = dq.Oracle_Party_Id__c
					, Account__c = dq.Account__c
					, Installed_At__c = dq.Installed_At__c
					, Bill_To__c = dq.Bill_To__c
					, Ship_To__c = dq.Ship_To__c
				);
				newSiteLocations.add(sl);
			}
		}
		
		// insert the new site locations
		Database.SaveResult[] srList = Database.insert(newSiteLocations, false);
		for(Integer i = 0; i < srList.size(); i++){
			Database.SaveResult sr = srList[i];
			Site_Location__c sl = newSiteLocations[i];
			Data_Quality__c dq = dqNeedNewSite[i];
			
			if(sr.isSuccess()){
				// set the site location on the data quality record
				dq.Site_Location__c = sl.Id;
			}
			else{
				// compile errors
				String errors = 'Unable to create a new Site Location. ';
				for(Database.Error err : sr.getErrors()){
					System.debug('*** '+ err.getMessage());
					System.debug('*** '+ err.getFields());
					System.debug('*** '+ err.getStatusCode());
					
					errors += err.getMessage() + ' ';
				}
				
				// add the errors to the data quality record
				dq.addError(errors);
			}
		}
	}
}