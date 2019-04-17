/*------------------------------------------------------------
Author:         Denise Bacher
Company:        Salesforce.com
Description:    Site_Location__c Trigger functions
Test Class:     SiteLocationTrigger_Test

History:
<Date>          <Authors Name>      <Brief Description of Change>
03/28/2016      Denise Bacher       Initial Creation (US460)
04/13/2016      Denise Bacher       Updated to use Account.BillingStreet_Line1__c to match, and populate more fields on billing street (US555)
04/15/2016      Denise Bacher       New functionlaty to update associated Customer Account billing/shipping address when location is primary (US610)
04/27/2016      Denise Bacher       Update updateCustomerAccountAddress for new Identifying field (US745)
06/08/2016      Denise Bacher       Update setSiteAccount to handle updates to Site_Location__c.Address_Line_1__c (US1217)
06/20/2016      Denise Bacher       Update setSiteAccount to default new site account's CDQ Status to 'Closed' (DE212)
03/02/2018      Mani Sundaresan     Update setAccountLookup to handle updates from Customer Data Management system (US-4246)
------------------------------------------------------------*/
public with sharing class SiteLocationTriggerActions {

    /*------------------------------------------------------------
    Author:         Denise Bacher
    Company:        Salesforce.com
    Description:    Find and set the account lookup if it is null using the Parent_Oracle_Party_ID__c
                    Specifically, this can occur on records inserted via Webservice API 
                    Runs before insert, before update
    Inputs:         siteLocations - The list of Site Locations to modify
    Returns:        N/A
    
    History:
    <Date>          <Authors Name>      <Brief Description of Change>
    03/29/2016      Denise Bacher       Initial Creation (US460)
    03/02/2018      Mani Sundaresan     Update setAccountLookup to handle updates from Customer Data Management system
    ------------------------------------------------------------*/
    public static void setAccountLookup(List<Site_Location__c> siteLocations){
        Set<String> oraclePartyIds = new Set<String>();
        Set<String> cdmRecordIds = new Set<String>();
        Map<String, Id> oraclePartyIdToAccountId = new Map<String, Id>();
        Map<String, Id> cdmRecordIdToAccountId = new Map<String, Id>();
        
        for(Site_Location__c location : siteLocations){
            // if there is no account, but there is a parent oracle party id, add it to our set for lookup
            if(location.Account__c == null && String.isNotBlank(location.Parent_Oracle_Party_ID__c)){
                oraclePartyIds.add(location.Parent_Oracle_Party_ID__c);
            }
            //if there is no account, but there is a parent cdm record id add it to the collection
            if(location.Account__c == null && String.isNotBlank(location.Parent_CDM_Record_Id__c))
                cdmRecordIds.add(location.Parent_CDM_Record_Id__c);
            
            if(location.Name == null || location.Name == ''){
                if(location.Address_Line_1__c.length() <= 80)
                    location.Name = location.Address_Line_1__c;
                else
                    location.Name = location.Address_Line_1__c.substring(0,80);
            }
        
        }
        
        // lookup accounts by their oracle party id
        if(oraclePartyIds.size() > 0){
            for(Account a : [Select Id, Name, Oracle_Party_Id__c From Account Where Oracle_Party_Id__c IN: oraclePartyIds]){
                oraclePartyIdToAccountId.put(a.Oracle_Party_Id__c, a.Id);
            }
            
            for(Site_Location__c location : siteLocations){
                // if the location's account is null and we found an account by oracle party id, set the accout on the location
                if(location.Account__c == null && oraclePartyIdToAccountId.containsKey(location.Parent_Oracle_Party_ID__c)){
                    location.Account__c = oraclePartyIdToAccountId.get(location.Parent_Oracle_Party_ID__c);
                }
            }
        }
        if(cdmRecordIds.size() > 0){
            for(Account a : [Select Id, Name, CDM_Record_Id__c From Account Where CDM_Record_Id__c IN: cdmRecordIds]){
                 cdmRecordIdToAccountId.put(a.CDM_Record_Id__c, a.Id);       
            }
            
            for(Site_Location__c location : siteLocations){
                // if the location's account is null and we found an account by oracle party id, set the accout on the location
                if(location.Account__c == null && cdmRecordIdToAccountId.containsKey(location.Parent_CDM_Record_Id__c)){
                    location.Account__c = cdmRecordIdToAccountId.get(location.Parent_CDM_Record_Id__c);
                }
            }
        }
        
            
        
    }
    
    /*------------------------------------------------------------
    Author:         Denise Bacher
    Company:        Salesforce.com
    Description:    Set the Site Location account lookup to the correct Site Account 
                    Runs before insert, before update
    Inputs:         siteLocations - The list of Site Locations to modify
    Returns:        N/A
    
    History:
    <Date>          <Authors Name>      <Brief Description of Change>
    03/28/2016      Denise Bacher       Initial Creation (US460)
    04/13/2016      Denise Bacher       Updated to use Account.BillingStreet_Line1__c to match, 
                                        and populate Billing State and Country on Site Account (US555)
    06/08/2016      Denise Bacher       Update setSiteAccount to handle updates to Site_Location__c.Address_Line_1__c (US1217)
    06/20/2016      Denise Bacher       Update setSiteAccount to default new site account's CDQ Status to 'Closed' (DE212)
    04/12/2018      Mani Sundaresan     Update setSiteAccount to use Site Name to determing the correct Site Account (US-4246)
    ------------------------------------------------------------*/
    public static void setSiteAccount(List<Site_Location__c> siteLocations, Map<Id, Site_Location__c> oldLocations){
        Id siteAccountRecordTypeId = GlobalUtility.getRecordTypeId('Account', 'Site');
        Set<Id> accountIds = new Set<Id>();
        Set<String> oraclePartyIds = new Set<String>();
        Set<String> streets = new Set<String>();
        Map<String, Account> accountById = new Map<String, Account>();
        Map<Id, Id> singleSiteAccount = new Map<Id, Id>();
        Boolean cdmParentUpdate = false;
        
        //Collections to store Site Location Name and Parent CDM Record Id
        Set<String> siteLocNameSet = new Set<String>();
        Set<String> parentCDMRecordIdSet = new Set<String>();
        
        List<Account> newSiteAccounts = new List<Account>();
        Map<String, Account> siteAccountBySiteAccountKey = new Map<String, Account>();
        Map<String, List<Site_Location__c>> siteLocationsBySiteAccountKey = new Map<String, List<Site_Location__c>>();
        
        // get all the account ids
        for(Site_Location__c location : siteLocations){
            if(location.Account__c != null){
                accountIds.add(location.Account__c);
            }
            
            if(String.isNotBlank(location.Parent_Oracle_Party_ID__c)){
                oraclePartyIds.add(location.Parent_Oracle_Party_ID__c);
            }
            
            if(String.isNotBlank(location.Address_Line_1__c)){
                streets.add(location.Address_Line_1__c);
            }
            
            if(String.isNotBlank(location.Name))
                siteLocNameSet.add(location.Name);
                
            if(String.isNotBlank(location.Parent_CDM_Record_Id__c))
                parentCDMRecordIdSet.add(location.Parent_CDM_Record_Id__c);
        }
        
        System.debug('parentCDMRecordIdSet:'+parentCDMRecordIdSet);

        // retrieve the account information
        for(Account a : [Select Id, Name, RecordTypeId, BillingStreet_Line1__c, Oracle_Party_Id__c, ParentId, Parent.RecordTypeId, CDM_Record_Id__c, 
                        (Select Id, Name, RecordTypeId, BillingStreet_Line1__c 
                            From ChildAccounts 
                            Where RecordTypeId =: siteAccountRecordTypeId
                            And Name IN: siteLocNameSet),
                        (SELECT Id, Parent_CDM_Record_Id__c FROM Site_Locations__r)
                        From Account 
                        Where Oracle_Party_Id__c IN: oraclePartyIds OR Id IN: accountIds OR CDM_Record_Id__c IN :parentCDMRecordIdSet])
        {
            accountById.put(a.Oracle_Party_Id__c, a);
            System.debug('Oracle Party Id:'+a.Oracle_Party_Id__c);
            accountById.put(a.Id, a);
            System.debug('CDM Record Id:'+a.CDM_Record_Id__c);
            accountById.put(a.CDM_Record_Id__c, a);
            
            //Map to collect all the site accounts with single Site Location record.
            if(a.RecordTypeId == siteAccountRecordTypeId && a.Site_Locations__r.size() == 1){
                singleSiteAccount.put(a.Site_Locations__r[0].Id, a.Id);
            }
        }
                                            
        for(Site_Location__c location : siteLocations){
            Site_Location__c oldLocation = oldLocations != null && oldLocations.containsKey(location.Id) ? oldLocations.get(location.Id) : null;
            System.debug('AccountById:'+accountById);
            System.debug('CDM Record Id:'+location.Parent_CDM_Record_Id__c);
            System.debug('currentOracleAccount:'+location.Parent_Oracle_Party_ID__c);
            System.debug('final chk:'+accountById.get(location.Parent_CDM_Record_Id__c));
            
            Account currentOracleAccount;
            
            if(location.Parent_CDM_Record_Id__c != null)
                currentOracleAccount = accountById.get(location.Parent_CDM_Record_Id__c);
            else
                currentOracleAccount = accountById.get(location.Parent_Oracle_Party_ID__c);
            
            //Account currentOracleAccount = accountById.get(location.Parent_Oracle_Party_ID__c);
            Account currentAccount = accountById.get(location.Account__c);
            Boolean foundMatchingSiteAccount = false;
            String locationAddress = String.isNotBlank(location.Address_Line_1__c) ? location.Address_Line_1__c.toUpperCase() : '';
            String locationName = String.isNotBlank(location.Name) ? location.Name : '';
            
            System.debug('CurrentOracleAccount:'+currentOracleAccount);
            System.debug('currentAccount:'+currentAccount);
            
            // if no account, then continue on. Nothing further can be done without an account
            if(currentOracleAccount == null || currentAccount == null){
                System.debug('Current Site Location Account is null, moving on: '+location.Name);
                System.debug('Oracle Account: ' + location.Parent_Oracle_Party_ID__c + ' -> ' + currentOracleAccount);
                System.debug('Lookup Account: ' + location.Account__c + ' -> ' + currentAccount);
                continue;
            }
            
            String accountLocationAddress = String.isNotBlank(currentAccount.BillingStreet_Line1__c) ? currentAccount.BillingStreet_Line1__c.toUpperCase() : locationAddress;
            String accountLocationName = String.isNotBlank(currentAccount.Name) ? currentAccount.Name : locationName;
            
            System.debug('accountLocationName:'+accountLocationName);
            System.debug('location:'+location);
            
            // if the current account lookup is not a site account, check to see if there is a matching child site account
            if(currentAccount.RecordTypeId != siteAccountRecordTypeId || accountLocationName != locationName){
                for(Account site : currentOracleAccount.ChildAccounts){
                    String siteAddress = String.isNotBlank(site.BillingStreet_Line1__c) ? site.BillingStreet_Line1__c.toUpperCase() : '';
                    String siteName = String.isNotBlank(site.Name) ? site.Name : '';
                    if(locationName == siteName){
                        foundMatchingSiteAccount = true;
                        location.Account__c = site.Id;
                        break;
                    }
                }
            }
            else if(oldLocation != null && currentOracleAccount != null && location.Parent_CDM_Record_Id__c != null && location.Parent_CDM_Record_Id__c != oldLocation.Parent_CDM_Record_Id__c && oldLocation.Parent_CDM_Record_Id__c != null){
                //if(location.Parent_CDM_Record_Id__c != oldLocation.Parent_CDM_Record_Id__c && currentOracleAccount != null && location.Parent_CDM_Record_Id__c != null && oldLocation.Parent_CDM_Record_Id__c != null){
                    Account acc = new Account(Id=location.Account__c, ParentId = currentOracleAccount.Id);
                    newSiteAccounts.add(acc);
                    foundMatchingSiteAccount = true;
                    cdmParentUpdate = true;
                //}
            }
            else{
                foundMatchingSiteAccount = true;
            }
            
            // if no site account was found, create a new one
            if(!foundMatchingSiteAccount){
                // create an identifying key to link locations back to the new site account
                Id accountParentId = currentOracleAccount.Id;
                String siteKey = String.valueOf(accountParentId + locationName).replace(' ', '_');
                
                // create a map of locations by siteKey
                if(!siteLocationsBySiteAccountKey.containsKey(siteKey)){
                    siteLocationsBySiteAccountKey.put(siteKey, new List<Site_Location__c>());
                }
                siteLocationsBySiteAccountKey.get(siteKey).add(location);
                
                //Update the Site Account with the details from Site Account record
                Account newSite = new Account(
                    Name = location.Name
                    , BillingStreet = location.Address_Line_1__c
                    , BillingStreet_Line1__c = location.Address_Line_1__c
                    , BillingCity = location.City__c
                    , BillingStateCode = location.State__c
                    , BillingPostalCode = location.Zip_Code__c
                    , BillingCountryCode = location.Country__c
                    , RecordTypeId = siteAccountRecordTypeId
                    , ParentId = accountParentId
                    , CDQ_Status__c = 'Closed'
                );
                
                if(!siteAccountBySiteAccountKey.containsKey(siteKey) && singleSiteAccount.containsKey(location.Id)){
                    newSite.Id = singleSiteAccount.get(location.Id);
                }
                
                newSiteAccounts.add(newSite);
                siteAccountBySiteAccountKey.put(siteKey, newSite);
            }
        }
        
        // insert the new site accounts
        Database.UpsertResult[] srList = Database.upsert(newSiteAccounts, false);
        for(Integer i = 0; i < srList.size(); i++){
            Database.UpsertResult sr = srList[i];
            Account siteAccount = newSiteAccounts[i];
            String siteAddress = String.isNotBlank(siteAccount.BillingStreet_Line1__c) ? siteAccount.BillingStreet_Line1__c.toUpperCase() : '';
            String siteName = String.isNotBlank(siteAccount.Name) ? siteAccount.Name : '';
            String siteKey = String.valueOf(siteAccount.ParentId + siteName).replace(' ', '_');
            
            if(sr.isSuccess() && !cdmParentUpdate){
                for(Site_Location__c location : siteLocationsBySiteAccountKey.get(siteKey)){
                    location.Account__c = siteAccount.Id;
                }
            }
            else if(!cdmParentUpdate){
                // compile errors
                String errors = 'Unable to create a new Site Account. ';
                for(Database.Error err : sr.getErrors()){
                    System.debug('*** '+ err.getMessage());
                    System.debug('*** '+ err.getFields());
                    System.debug('*** '+ err.getStatusCode());
                    
                    errors += err.getMessage() + ' ';
                }
                
                // add the errors to the location record
                for(Site_Location__c location : siteLocationsBySiteAccountKey.get(siteKey)){
                    location.addError(errors);
                }
            }
        }
    }
    
    /*------------------------------------------------------------
    Author:         Denise Bacher
    Company:        Salesforce.com
    Description:    If the Site Location is the Identifying - update the related Customer Account's Billing Address 
                    If the Site Location was the Identifying - blank the related Customer Account's Billing Address
                    Runs after insert, after update
    Inputs:         siteLocations - The list of Site Locations
                    oldLocations - Map of pervious Site Location values
    Returns:        N/A
    
    History:
    <Date>          <Authors Name>      <Brief Description of Change>
    04/15/2016      Denise Bacher       Initial Creation (US610)
    04/27/2016      Denise Bacher       Update to look at Site Location "Identifiying Address" field to update Account address (US745)
    07/26/2016      Denise Bacher       Updated to update city/state/zip/country on parent Site Account (to remove process builder)
    ------------------------------------------------------------*/
    public static void updateCustomerAccountAddress(List<Site_Location__c> siteLocations, Map<Id, Site_Location__c> oldLocations){
        List<Site_Location__c> identifyingLocations = new List<Site_Location__c>(); // list of locations that are identifying address
        List<Site_Location__c> prevIdentifyingLocations = new List<Site_Location__c>(); // list of locations that were previously identifying address
        Set<String> locParentOraclePartyIds = new Set<String>();
        Set<String> locParentCDMRecordIds = new Set<String>();
        Map<String, Account> mapAccountByOracleId = new Map<String, Account>(); // map of accounts by account external id
        
        List<Site_Location__c> changedLocations = new List<Site_Location__c>(); // list of locations that have changed (to update site account)
        Set<Id> siteAccountParentIds = new Set<Id>(); // (to update site account)
        Map<Id, Account> mapAccountBySFDCId = new Map<Id, Account>(); // map of accounts by account sfdc id (to update site account)
        
        Map<String, List<Site_Location__c>> mapAccountToSiteLocs = new Map<String, List<Site_Location__c>>(); // map of account external ids to their corresponding site locations
        
        for(Site_Location__c location : siteLocations){
            Site_Location__c oldLocation = oldLocations != null && oldLocations.containsKey(location.Id) ? oldLocations.get(location.Id) : null;
            
            // current site location has a customer account (Parent_Oracle_Party_ID__c)
            // new location, is identifying address
            // update location, identifying or address changed
            if((String.isNotBlank(location.Parent_Oracle_Party_ID__c) || String.isNotBlank(location.Parent_CDM_Record_Id__c)) && (
                (oldLocation == null && location.Identifying_Address__c) || 
                (oldLocation != null && (location.Identifying_Address__c != oldLocation.Identifying_Address__c ||
                    location.Address_Line_1__c != oldLocation.Address_Line_1__c || 
                    location.Address_Line_2__c != oldLocation.Address_Line_2__c ||
                    location.Address_Line_3__c != oldLocation.Address_Line_3__c || 
                    location.Address_Line_4__c != oldLocation.Address_Line_4__c || 
                    location.City__c != oldLocation.City__c || 
                    location.State__c != oldLocation.State__c || 
                    location.Zip_Code__c != oldLocation.Zip_Code__c || 
                    location.Country__c != oldLocation.Country__c ) ) ) )
            {    
                if(location.Parent_Oracle_Party_ID__c != null)
                    locParentOraclePartyIds.add(location.Parent_Oracle_Party_ID__c);
                else if(location.Parent_CDM_Record_Id__c != null)
                    locParentCDMRecordIds.add(location.Parent_CDM_Record_Id__c);    
                
                if(location.Identifying_Address__c){
                    identifyingLocations.add(location);
                }
                else{
                    prevIdentifyingLocations.add(location);
                }
                
                if(location.Parent_Oracle_Party_ID__c != null && !mapAccountToSiteLocs.containsKey(location.Parent_Oracle_Party_ID__c)){
                    mapAccountToSiteLocs.put(location.Parent_Oracle_Party_ID__c, new List<Site_Location__c>());
                }
                else if(location.Parent_CDM_Record_Id__c != null && !mapAccountToSiteLocs.containsKey(location.Parent_CDM_Record_Id__c)){
                    mapAccountToSiteLocs.put(location.Parent_CDM_Record_Id__c, new List<Site_Location__c>());
                }
                
                if(location.Parent_Oracle_Party_ID__c != null)
                    mapAccountToSiteLocs.get(location.Parent_Oracle_Party_ID__c).add(location);
                else if(location.Parent_CDM_Record_Id__c != null)
                    mapAccountToSiteLocs.get(location.Parent_CDM_Record_Id__c).add(location);
            }
            
            // current site location has a site account (Account__c)
            // update location and address changed
            if(String.isNotBlank(location.Account__c) && (
                oldLocation == null || 
                (oldLocation != null && 
                    (location.City__c != oldLocation.City__c || 
                    location.State__c != oldLocation.State__c || 
                    location.Zip_Code__c != oldLocation.Zip_Code__c || 
                    location.Country__c != oldLocation.Country__c ) ) ) )
            {
                siteAccountParentIds.add(location.Account__c);
                changedLocations.add(location);
                
                if(!mapAccountToSiteLocs.containsKey(location.Account__c)){
                    mapAccountToSiteLocs.put(location.Account__c, new List<Site_Location__c>());
                }
                mapAccountToSiteLocs.get(location.Account__c).add(location);
            }
        }
        
        System.debug('mapAccountToSiteLocs:'+mapAccountToSiteLocs);
        
        // query the accounts and map them by their oracle ids
        if(locParentOraclePartyIds.size() > 0){
            for(Account a : [Select Id, Oracle_Party_Id__c, RecordTypeId,
                            BillingStreet, BillingStreet_Line1__c, BillingStreet_Line2__c, BillingStreet_Line3__c, BillingStreet_Line4__c, BillingCity, BillingStateCode, BillingPostalCode, BillingCountryCode
                            From Account
                            Where (Oracle_Party_Id__c IN: locParentOraclePartyIds
                            Or Id IN: siteAccountParentIds)])
            {
                if(String.isNotBlank(a.Oracle_Party_Id__c) && mapAccountToSiteLocs.containsKey(a.Oracle_Party_Id__c)){
                    mapAccountByOracleId.put(a.Oracle_Party_Id__c, a);
                }
                
                if(mapAccountToSiteLocs.containsKey(a.Id)){
                    mapAccountBySFDCId.put(a.Id, a);
                }
            }
        }
        if(locParentCDMRecordIds.size() > 0){
            for(Account a : [Select Id, Oracle_Party_Id__c, RecordTypeId, CDM_Record_Id__c,
                            BillingStreet, BillingStreet_Line1__c, BillingStreet_Line2__c, BillingStreet_Line3__c, BillingStreet_Line4__c, BillingCity, BillingStateCode, BillingPostalCode, BillingCountryCode
                            From Account
                            Where (CDM_Record_Id__c IN: locParentCDMRecordIds
                            Or Id IN: siteAccountParentIds)])
            {
                if(String.isNotBlank(a.CDM_Record_Id__c) && mapAccountToSiteLocs.containsKey(a.CDM_Record_Id__c)){
                    mapAccountByOracleId.put(a.CDM_Record_Id__c, a);
                }
                
                if(mapAccountToSiteLocs.containsKey(a.Id)){
                    mapAccountBySFDCId.put(a.Id, a);
                }
            }
        }   
        
        // loop through previously identifying locatons, and null it if they match
        if(prevIdentifyingLocations.size() > 0)
            for(Site_Location__c location : prevIdentifyingLocations){
                
                Account acc = new Account();    
                
                if(location.Parent_Oracle_Party_ID__c != null)
                    acc = mapAccountByOracleId.get(location.Parent_Oracle_Party_ID__c);
                else if(location.Parent_CDM_Record_Id__c != null)
                    acc = mapAccountByOracleId.get(location.Parent_CDM_Record_Id__c);
                
                // check if addresses match
                if(location.Address_Line_1__c == acc.BillingStreet_Line1__c
                    && location.Address_Line_2__c == acc.BillingStreet_Line2__c
                    && location.Address_Line_3__c == acc.BillingStreet_Line3__c
                    && location.Address_Line_4__c == acc.BillingStreet_Line4__c
                    && location.City__c == acc.BillingCity
                    && location.State__c == acc.BillingStateCode
                    && location.Zip_Code__c == acc.BillingPostalCode
                    && location.Country__c == acc.BillingCountryCode )
                {
                    acc.BillingStreet = '';
                    acc.BillingCity = '';
                    acc.BillingStateCode = '';
                    acc.BillingPostalCode = '';
                    acc.BillingCountryCode = '';
                }
            }
        
        // loop through primary locatons, and update the billing and/or shipping address
        if(identifyingLocations.size() > 0)
            for(Site_Location__c location : identifyingLocations){
                Account acc = new Account();    
                
                if(location.Parent_Oracle_Party_ID__c != null)
                    acc = mapAccountByOracleId.get(location.Parent_Oracle_Party_ID__c);
                else if(location.Parent_CDM_Record_Id__c != null)
                    acc = mapAccountByOracleId.get(location.Parent_CDM_Record_Id__c);
                
                
                acc.BillingStreet = location.Address_Line_1__c
                    + (String.isNotBlank(location.Address_Line_2__c) ? '\n' + location.Address_Line_2__c : '')
                    + (String.isNotBlank(location.Address_Line_3__c) ? '\n' + location.Address_Line_3__c : '')
                    + (String.isNotBlank(location.Address_Line_4__c) ? '\n' + location.Address_Line_4__c : '');
                acc.BillingCity = location.City__c;
                acc.BillingStateCode = location.State__c;
                acc.BillingPostalCode = location.Zip_Code__c;
                acc.BillingCountryCode = location.Country__c;
            }
        
        // loop through locations that need to update their site accounts
        if(changedLocations.size() > 0)
            for(Site_Location__c location: changedLocations){
                Account acc = mapAccountBySFDCId.get(location.Account__c);
                if(acc != null){
                    acc.BillingCity = location.City__c;
                    acc.BillingStateCode = location.State__c;
                    acc.BillingPostalCode = location.Zip_Code__c;
                    acc.BillingCountryCode = location.Country__c;
                }
            }
        
        // update the customer/prospect/site accounts
        List<Account> accountsToUpdate = mapAccountByOracleId.values();
        accountsToUpdate.addAll(mapAccountBySFDCId.values());
        Database.SaveResult[] srList = Database.update(accountsToUpdate, false);
        for(Integer i = 0; i < srList.size(); i++){
            Database.SaveResult sr = srList[i];
            Account account = accountsToUpdate[i];
            
            if(!sr.isSuccess()){
                // compile errors
                String errors = 'Unable to update Account address. ';
                for(Database.Error err : sr.getErrors()){
                    errors += err.getMessage() + ' ';
                }
                
                String accountId = String.isNotBlank(account.Oracle_Party_Id__c) ? account.Oracle_Party_Id__c : account.Id;
                
                /*if(mapAccountToSiteLocs != null)
                    for(Site_Location__c location : mapAccountToSiteLocs.get(accountId)){
                        location.addError(errors);
                    }*/
            }
        }
    }
}