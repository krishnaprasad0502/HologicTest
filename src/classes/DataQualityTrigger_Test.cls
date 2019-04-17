/*------------------------------------------------------------
Author:			Denise Bacher
Company:		Salesforce.com
Description:	Test class to validate DataQualityTrigger
				Tests Excecuted:
				
				autoGenerateNewSiteLocation_Success - bulk verify data quality records to create new site locations
				
				autoGenerateNewSiteLocation_Errors - bulk verify data quality records and ensure errors are handled gracefully
History:
<Date>			<Authors Name>		<Brief Description of Change>
05/25/2016		Denise Bacher		Initial Creation (US1070)
------------------------------------------------------------*/
@isTest
private class DataQualityTrigger_Test {
	private final static Id assetSystemRecordTypeId = GlobalUtility.getRecordTypeId('Asset', 'System');
	
	private static Configuration_Settings__c orgDefaults;
	private static Account customerAccount;
	private static Account siteAccount;
	private static Account siteAccount2;
	private static List<Asset> assets = new List<Asset>();
	
	static{
		orgDefaults = TestUtility.setupConfigurationSettings();
		TestUtility.insertCustSetting('sitelocTrigger');
		customerAccount = TestUtility.newAccount('Customer Account Test', 'unitTest');
		insert customerAccount;
		
		siteAccount = TestUtility.newAccount('Site Account Test', null, customerAccount.Id);
		siteAccount.RecordTypeId = GlobalUtility.getRecordTypeId('Account', 'Site');
		siteAccount2 = TestUtility.newAccount('Site Account Test2', null, customerAccount.Id);
		siteAccount2.RecordTypeId = GlobalUtility.getRecordTypeId('Account', 'Site');
		insert new List<Account>{siteAccount, siteAccount2};
		
		for(Integer i = 0; i < 100; i++){
			assets.add(TestUtility.newAsset(siteAccount.Id, customerAccount.Id, null, assetSystemRecordTypeId, 'B&SH '+i, 'B&SH', 'XXXX'+i));
			assets.add(TestUtility.newAsset(siteAccount2.Id, customerAccount.Id, null, assetSystemRecordTypeId, 'B&SH '+i, 'B&SH', 'XXXX'+i));
		}
		insert assets;
	}
	
	static testMethod void autoGenerateNewSiteLocation_Success() {
		List<Data_Quality__c> newInstallLocationRequests = new List<Data_Quality__c>();
		for(Integer i = 0; i < assets.size(); i++){
			newInstallLocationRequests.add(TestUtility.newDataQuality_NewSiteLocation(
				i+' Some Street'
				, 'Floor '+i
				, 'Suite '+i
				, 'Room '+i
				, 'Some City'
				, 'NY'
				, '55555'
				, 'US'
				, customerAccount.Id
				, customerAccount.Oracle_Party_Id__c
				, assets[i].Id
			));
		}
		insert newInstallLocationRequests;
		
		Test.startTest();
			for(Data_Quality__c dq : newInstallLocationRequests){
				dq.CDQ_Status__c = 'Verified';
			}
			update newInstallLocationRequests;
		Test.stopTest();
		
		List<Site_Location__c> siteLocations = [Select Id, Installed_At__c From Site_Location__c];
		System.assertEquals(200, siteLocations.size());
		
		for(Data_Quality__c dq : [Select Id, Site_Location__c From Data_Quality__c Where Id IN: newInstallLocationRequests]){
			System.assertNotEquals(null, dq.Site_Location__c);
		}
	}
	
	static testMethod void autoGenerateNewSiteLocation_Errors() {
		List<Data_Quality__c> newInstallLocationRequests = new List<Data_Quality__c>();
		for(Integer i = 0; i < assets.size(); i++){
			newInstallLocationRequests.add(TestUtility.newDataQuality_NewSiteLocation(
				i+' Some Street'
				, 'Floor '+i
				, 'Suite '+i
				, 'Room '+i
				, 'Some City'
				, 'NY'
				, '55555'
				, 'US'
				, customerAccount.Id
				, customerAccount.Oracle_Party_Id__c
				, assets[i].Id
			));
		}
		insert newInstallLocationRequests;
		
		Test.startTest();
			for(Data_Quality__c dq : newInstallLocationRequests){
				dq.CDQ_Status__c = 'Verified';
				dq.State_Code__c = 'MN';
				dq.Country_Code__c = 'CA';
			}
			
			Database.SaveResult[] srList = Database.update(newInstallLocationRequests, false);
			for(Database.SaveResult sr : srList){
				if(sr.isSuccess()){
					System.assert(false, 'There should have been no successes.');
				}
				else{
					String errors = '';
					for(Database.Error err : sr.getErrors()){
						errors += err.getMessage() + ' ';
					}
					System.assert(errors.contains('Unable to create a new Site Location.'), errors);
				}
			}
		Test.stopTest();
	}
}