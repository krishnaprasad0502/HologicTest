/*------------------------------------------------------------
Author:         Denise Bacher
Company:        Salesforce.com
Description:    Test class to validate SiteLocationTrigger
                Tests Excecuted:
                
                setAccountLookup_ByOraclePartyIdSuccess - insert new site locations with a valid oracle party id and no account,
                    verify that an account lookup is created, and the account's parent is the account with the corresponding oracle party id
                    
                setAccountLookup_ByOraclePartyIdFailure - insert new site locations with invalid oracle party id and no account,
                    verify that no site locations are inserted
                    
                setSiteAccount_insertForNewExistingSiteAccount - insert new site locations for both new and existing site accounts. For locations requireing
                    new site accounts, accounts should be created; for locations requiring existing site accounts, they should be reparented to the appropriate account
                
                setSiteAccount_insertManyNewSameSiteAccount - insert multiple new site locations for the same new site account (same street address),
                    verify that only a single new site account is created
                    
                setSiteAccount_insertLookupSiteAccount - insert new site locations with a lookup to the site account, verify no new accounts are created
                
                setSiteAccount_updateReParentSiteAccount - verify that on update, when a site location's account is changed, it is reset to the correct account
                
                setSiteAccount_updateNewAddressLine1 - verify that on update, when a site location's address line one is changed, a new site account is created
                
                setSiteAccount_errorHandlingSiteAccount - verify that failures on insert of site accounts are handled
                
                updateCustomerAccountAddress_insertIdentifying - verify that on insert of a new identifying site location, the related customer account's billing address
                    is updated to match the identifying site location address
                
                updateCustomerAccountAddress_updateIdentifying - verify that on update of a site location's identifying to false, the related customer account's billing address
                    is updated to be blank as there is no indentifying address
                    
                updateCustomerAccountAddress_updateAddress - verify that on update of a site location's address, the related customer account's billing address
                    is updated to match
                    
                updateCustomerAccountAddress_errorHandlingAccountUpdate - verify that errors updating the customer account are handled gracefully
                
                updateCustomerAccountAddress_insertBulk - verify bulk insert works as expected
                
                updateCustomerAccountAddress_updateBulk - verify bulk update works as expected
History:
<Date>          <Authors Name>      <Brief Description of Change>
03/29/2016      Denise Bacher       Initial Creation
04/08/2016      Denise Bacher       Add call to create Configuration_Settings__c to get around validation rule that prevents
                                    Account creation from anything but a Lead
04/14/2016      Denise Bacher       Update to ensure billing address is populated correctly on new Site Accounts (US555)
04/15/2016      Denise Bacher       Update to test updating custoer account addresses if site location is primary and bill to and/or ship to (US610)
04/27/2016      Denise Bacher       Update updateCustomerAccountAddress tests (US745)
06/08/2016      Denise Bacher       Update setSiteAccount to handle updates to Site_Location__c.Address_Line_1__c (US1217)
------------------------------------------------------------*/
@isTest
private class SiteLocationTrigger_Test {
    
    public static Id accountCustomerRecordTypeId = GlobalUtility.getRecordTypeId('Account', 'Customer');
    public static Id accountSiteRecordTypeId = GlobalUtility.getRecordTypeId('Account', 'Site');
    public static List<Account> customerAccounts = new List<Account>();
    public static List<Account> siteAccounts = new List<Account>();
    public static Map<Id, Account> customerAccountMap = new Map<Id, Account>();
    public static Map<Id, Account> siteAccountMap = new Map<Id, Account>();
    
    static{
        TestUtility.setupConfigurationSettings();
        
        TestUtility.insertCustSetting('sitelocTrigger');
        
        for(Integer i = 0; i < 10; i++){
            customerAccounts.add(TestUtility.newAccount('CustAccount-'+i, 'custParty'+i, null, null, accountCustomerRecordTypeId));
            customerAccounts[i].CDM_Record_Id__c='record'+i;
        }
        insert customerAccounts;
        for(Account a : customerAccounts){
            customerAccountMap.put(a.Id, a);
        }
        
        for(Account a : customerAccounts){
            siteAccounts.add(TestUtility.newAccount('123 A Street', null, '123 A Street\nSuite A\nRoom 1', a.Id, accountSiteRecordTypeId));
            
        }
        insert siteAccounts;
        for(Account a : siteAccounts){
            siteAccountMap.put(a.Id, a);
        }
    }
    
    static testMethod void setAccountLookup_ByOraclePartyIdSuccess() {
        List<Site_Location__c> locations = new List<Site_Location__c>();
        
        
        for(Account a : customerAccounts){
            locations.add(TestUtility.newSiteLocation('123 A Street Suite 1', '123 A Street', 'Suite 1', null, null,
                'Some City', 'MA', '11111', 'US',
                a.Oracle_Party_Id__c, null, true));
        
           
        }
        
        Test.startTest();
            insert locations;
            
        Test.stopTest();
        
        List<Site_Location__c> insertedLocations = [Select Id, Name, Account__c, Account__r.ParentId, Account__r.Parent.Oracle_Party_Id__c, Parent_Oracle_Party_ID__c From Site_Location__c];
        //System.assertEquals(200, insertedLocations.size());
        for(Site_Location__c l : insertedLocations){
            System.assertEquals(l.Account__r.Parent.Oracle_Party_Id__c, l.Parent_Oracle_Party_ID__c);
            System.assertNotEquals(null, l.Account__c);
            System.assertNotEquals(l.Account__c, l.Account__r.ParentId);
            System.assert(!siteAccountMap.containsKey(l.Account__c));
            System.assert(customerAccountMap.containsKey(l.Account__r.ParentId));
        }
        
        // assert no additial site accounts were added
      //  System.assertEquals(400, [Select Id From Account Where RecordTypeId =: accountSiteRecordTypeId].size());
    }
    
    static testMethod void testNullSiteName(){
    
        Site_Location__c nullLocationName = new Site_Location__c();
        
        nullLocationName = TestUtility.newSiteLocation(null, '123 A Street', 'Suite 1', null, null,
                'Some City', 'MA', '11111', 'US',
                customerAccounts[0].Oracle_Party_Id__c, null, true);
        
        
        Test.startTest();
            insert nullLocationName;
        Test.stopTest();
        
        
                
    }
    
    static testMethod void setAccountLookup_ByOraclePartyIdFailure() {
        List<Site_Location__c> locations = new List<Site_Location__c>();
        
        for(Integer i = 0; i < 10; i++){
            locations.add(TestUtility.newSiteLocation('123 A Street Suite 1', '123 A Street', 'Suite 1', null, null,
                'Some City', 'MA', '11111', 'US',
                'oops-'+i, null, true));
            locations[i].Parent_CDM_Record_Id__c='Some city';
            
        }
        
        Test.startTest();
            try{
                insert locations;
                //System.assert(false, 'Site Location insert should have failed');
            }
            catch(Exception e){
                System.assert(e.getMessage().containsIgnoreCase('REQUIRED_FIELD_MISSING'));
            }
        Test.stopTest();
        
        List<Site_Location__c> insertedLocations = [Select Id, Name From Site_Location__c];
        System.assertEquals(0, insertedLocations.size());
        
        // assert no additial site accounts were added
        //System.assertEquals(200, [Select Id From Account Where RecordTypeId =: accountSiteRecordTypeId].size());
    }
    
    static testMethod void setSiteAccount_insertForNewExistingSiteAccount(){
        List<Site_Location__c> locationsNewSite = new List<Site_Location__c>();
        List<Site_Location__c> locationsExistingSite = new List<Site_Location__c>();
        
        Integer i = 0;
        for(Account a : customerAccounts){
            locationsNewSite.add(TestUtility.newSiteLocation('123 B Street Suite '+i, '123 B STREET', 'Suite '+i, 'Floor '+i, 'Room '+i,
                'Some City', 'MA', '11111', 'US',
                a.Oracle_Party_Id__c, a.Id, true));
             locationsNewSite[i].Parent_CDM_Record_Id__c=a.CDM_Record_Id__c;  
            locationsExistingSite.add(TestUtility.newSiteLocation('123 A Street Suite '+i, '123 A STREET', 'Suite '+i, 'Floor '+i, 'Room '+i,
                'Some City', 'MA', '11111', 'US',
                a.Oracle_Party_Id__c, a.Id, true));
                
            i++;
        }
        
        Test.startTest();
            List<Site_Location__c> temp = new List<Site_Location__c>();
            temp.addAll(locationsNewSite);
            temp.addAll(locationsExistingSite);
            insert temp;
        Test.stopTest();
        
        List<Site_Location__c> insertedLocationsNewSite = [Select Id, Account__c, Account__r.ParentId From Site_Location__c Where Id IN: locationsNewSite];
        Set<Id> newSiteAccountIds = new Set<Id>();
       // System.assertEquals(200, insertedLocationsNewSite.size());
        for(Site_Location__c l : insertedLocationsNewSite){
            System.assert(!siteAccountMap.containsKey(l.Account__c));
            System.assert(customerAccountMap.containsKey(l.Account__r.ParentId));
            
            newSiteAccountIds.add(l.Account__c);
        }
        
        List<Site_Location__c> insertedLocationsExistingSite = [Select Id, Account__c, Account__r.ParentId From Site_Location__c Where Id IN: locationsExistingSite];
       // System.assertEquals(200, insertedLocationsExistingSite.size());
        for(Site_Location__c l : insertedLocationsExistingSite){
            System.assert(!siteAccountMap.containsKey(l.Account__c));
            System.assert(customerAccountMap.containsKey(l.Account__r.ParentId));
        }
        
        // assert additional sites were created
       // System.assertEquals(600, [Select Id From Account Where RecordTypeId =: accountSiteRecordTypeId].size());
        
        // verify the billing address was fully filled out for the site account
        for(Account a : [Select Id, Name, BillingStreet, BillingStreet_Line1__c, BillingStreet_Line2__c, BillingStreet_Line3__c, BillingStreet_Line4__c,
                        BillingCity, BillingStateCode, BillingPostalCode, BillingCountryCode, CDQ_Status__c
                        From Account
                        Where Id IN: newSiteAccountIds])
        {
            System.assert(String.isNotBlank(a.BillingStreet), a.BillingStreet);
            System.assert(String.isNotBlank(a.BillingStreet_Line1__c), a.BillingStreet_Line1__c);
            System.assert(String.isBlank(a.BillingStreet_Line2__c), a.BillingStreet_Line2__c);
            System.assert(String.isBlank(a.BillingStreet_Line3__c), a.BillingStreet_Line3__c);
            System.assert(String.isBlank(a.BillingStreet_Line4__c), a.BillingStreet_Line4__c);
            System.assert(String.isNotBlank(a.BillingCity), a.BillingCity);
            System.assert(String.isNotBlank(a.BillingStateCode), a.BillingStateCode);
            System.assert(String.isNotBlank(a.BillingPostalCode), a.BillingPostalCode);
            System.assert(String.isNotBlank(a.BillingCountryCode), a.BillingCountryCode);
            
            System.assertEquals('Closed', a.CDQ_Status__c);
        }
    }
    
    static testMethod void setSiteAccount_insertManyNewSameSiteAccount(){
        List<Site_Location__c> locationsNewSite1 = new List<Site_Location__c>();
        List<Site_Location__c> locationsNewSite2 = new List<Site_Location__c>();
        List<Site_Location__c> locationsNewSite3 = new List<Site_Location__c>();
        
        for(Account a : customerAccounts){
            locationsNewSite1.add(TestUtility.newSiteLocation('456 B Street Suite 1', '456 B STREET', 'Suite 1', 'Floor 1', 'Room 1',
                'Some City', 'MA', '11111', 'US',
                a.Oracle_Party_Id__c, a.Id, true));
                
            locationsNewSite2.add(TestUtility.newSiteLocation('456 B Street Suite 2', '456 B Street', 'Suite 2', 'Floor 2', 'Room 2',
                'Some City', 'MA', '11111', 'US',
                a.Oracle_Party_Id__c, a.Id, true));
                
            locationsNewSite3.add(TestUtility.newSiteLocation('456 B Street Suite 2', '456 B STrEEt', 'Suite 3', 'Floor 3', 'Room 3',
                'Some City', 'MA', '11111', 'US',
                a.Oracle_Party_Id__c, a.Id, true));
        }
        
        Test.startTest();
            insert locationsNewSite1;
            insert locationsNewSite2;
            insert locationsNewSite3;
        Test.stopTest();
        
        // verify new site accounts
        List<Account> newSiteAccounts = [Select Id, Name, BillingStreet, BillingStreet_Line1__c, BillingStreet_Line2__c, BillingStreet_Line3__c, BillingStreet_Line4__c,
                                        BillingCity, BillingStateCode, BillingPostalCode, BillingCountryCode
                                        From Account
                                        Where Id NOT IN: siteAccounts
                                        And RecordTypeId =: accountSiteRecordTypeId];
       // System.assertEquals(400, newSiteAccounts.size());
        
        // verify the billing address was fully filled out for the site account
        for(Account a : newSiteAccounts){
            System.assert(String.isNotBlank(a.BillingStreet), a.BillingStreet);
            System.assert(String.isNotBlank(a.BillingStreet_Line1__c), a.BillingStreet_Line1__c);
            System.assert(String.isBlank(a.BillingStreet_Line2__c), a.BillingStreet_Line2__c);
            System.assert(String.isBlank(a.BillingStreet_Line3__c), a.BillingStreet_Line3__c);
            System.assert(String.isBlank(a.BillingStreet_Line4__c), a.BillingStreet_Line4__c);
            System.assert(String.isNotBlank(a.BillingCity), a.BillingCity);
            System.assert(String.isNotBlank(a.BillingStateCode), a.BillingStateCode);
            System.assert(String.isNotBlank(a.BillingPostalCode), a.BillingPostalCode);
            System.assert(String.isNotBlank(a.BillingCountryCode), a.BillingCountryCode);
        }
    }
    
    static testMethod void setSiteAccount_insertLookupSiteAccount(){
        List<Site_Location__c> locations1 = new List<Site_Location__c>();
        List<Site_Location__c> locations2 = new List<Site_Location__c>();
        List<Site_Location__c> locations3 = new List<Site_Location__c>();
        
        for(Account a : siteAccounts){
            locations1.add(TestUtility.newSiteLocation('123 A Street Suite 1', '123 a STREET', customerAccountMap.get(a.ParentId).Oracle_Party_Id__c, a.Id));
            locations2.add(TestUtility.newSiteLocation('123 A Street Suite 2', '123 A Street', customerAccountMap.get(a.ParentId).Oracle_Party_Id__c, a.Id));
            locations3.add(TestUtility.newSiteLocation('123 A Street Suite 3', '123 A STrEEt', customerAccountMap.get(a.ParentId).Oracle_Party_Id__c, a.Id));
        }
        
        Test.startTest();
            insert locations1;
            insert locations2;
            insert locations3;
        Test.stopTest();
        
       // System.assertEquals(600, [Select Id From Account Where Id NOT IN: siteAccounts And RecordTypeId =: accountSiteRecordTypeId].size());
    }
    
    static testMethod void setSiteAccount_updateReParentSiteAccount(){
        List<Site_Location__c> locations = new List<Site_Location__c>();
        
        for(Account a : siteAccounts){
            locations.add(TestUtility.newSiteLocation('123 A Street Suite 1', '123 A Street', customerAccountMap.get(a.ParentId).Oracle_Party_Id__c, a.Id));
        }
        insert locations;
        
        Test.startTest();
            // set the site locations account to the customer account
            for(Site_Location__c l : locations){
                l.Account__c = siteAccountMap.get(l.Account__c).ParentId;
            }
            
            update locations;
        Test.stopTest();
        
        List<Site_Location__c> updatedLocations = [Select Id, Account__c, Account__r.Name, Account__r.ParentId, Account__r.Parent.Name From Site_Location__c];
       // System.assertEquals(200, updatedLocations.size());
        for(Site_Location__c l : updatedLocations){
            System.assert(!siteAccountMap.containsKey(l.Account__c));
            System.assert(customerAccountMap.containsKey(l.Account__r.ParentId));
        }
    }
    
    static testMethod void setSiteAccount_updateNewAddressLine1(){
        List<Site_Location__c> locations = new List<Site_Location__c>();
        
        for(Account a : siteAccounts){
            locations.add(TestUtility.newSiteLocation('123 A Street Suite 1', '123 A Street', customerAccountMap.get(a.ParentId).Oracle_Party_Id__c, a.Id));
        }
        insert locations;
        
        Test.startTest();
            // set the new address line 1
            for(Site_Location__c l : locations){
                l.Address_Line_1__c = '123 B Street';
                l.Name = '123 B Street Suite 1';
            }
            
            update locations;
        Test.stopTest();
        
        List<Site_Location__c> updatedLocations = [Select Id, Account__c, Account__r.Name, Account__r.ParentId, Account__r.Parent.Name From Site_Location__c];
      //  System.assertEquals(200, updatedLocations.size());
        for(Site_Location__c l : updatedLocations){
            System.assert(!siteAccountMap.containsKey(l.Account__c));
            System.assert(customerAccountMap.containsKey(l.Account__r.ParentId));
        }
    }
    
    static testMethod void setSiteAccount_errorHandlingSiteAccount(){
        List<Site_Location__c> locations = new List<Site_Location__c>();
        
        for(Account a : customerAccounts){
            locations.add(TestUtility.newSiteLocation('456 B Street Suite 1', null, a.Oracle_Party_Id__c, a.Id));
        }
        
        Test.startTest();
            Database.SaveResult[] srList = Database.insert(locations, false);
            for(Database.SaveResult sr : srList){
                if(sr.isSuccess()){
                    System.assert(false, 'There should have been no successes.');
                }
                else{
                    String errors = '';
                    for(Database.Error err : sr.getErrors()){
                        errors += err.getMessage() + ' ';
                    }
                    //System.assert(errors.contains('Unable to create a new Site Account.'), errors);
                    System.assert(String.isNotBlank(errors));
                }
            }
        Test.stopTest();
    }
    
    static testMethod void updateCustomerAccountAddress_insertIdentifying(){
        Site_Location__c idLocation = TestUtility.newSiteLocation('Bill To', '123 B Street', 'Floor A', 'Suite B', 'Room C',
            'Some City', 'MA', '00000', 'US',
            customerAccounts[0].Oracle_Party_Id__c, customerAccounts[0].Id, true);
        idLocation.Identifying_Address__c = true;
        
        Test.startTest();
            insert new List<Site_Location__c> {idLocation};
        Test.stopTest();
        
        Account updatedAccount = [Select Id, Name, BillingStreet, BillingCity, BillingStateCode, BillingPostalCode, BillingCountryCode
                                    From Account
                                    Where Id =: customerAccounts[0].Id];

        String idLocationStreet = idLocation.Address_Line_1__c + '\n' + idLocation.Address_Line_2__c + '\n' + idLocation.Address_Line_3__c + '\n' + idLocation.Address_Line_4__c;
                                            
        System.assertEquals(idLocationStreet, updatedAccount.BillingStreet);
        System.assertEquals(idLocation.City__c, updatedAccount.BillingCity);
        System.assertEquals(idLocation.State__c, updatedAccount.BillingStateCode);
        System.assertEquals(idLocation.Zip_Code__c, updatedAccount.BillingPostalCode);
        System.assertEquals(idLocation.Country__c, updatedAccount.BillingCountryCode);
    }
    
    static testMethod void updateCustomerAccountAddress_updateIdentifying(){
        Site_Location__c idLocation = TestUtility.newSiteLocation('Bill To', '123 B Street', 'Floor A', 'Suite B', 'Room C',
            'Some City', 'MA', '00000', 'US',
            customerAccounts[0].Oracle_Party_Id__c, customerAccounts[0].Id, true);
        idLocation.Identifying_Address__c = true;
        
        insert new List<Site_Location__c> {idLocation};
        
        Account updatedAccount = [Select Id, Name, BillingStreet, BillingCity, BillingStateCode, BillingPostalCode, BillingCountryCode
                                    From Account
                                    Where Id =: customerAccounts[0].Id];

        String idLocationStreet = idLocation.Address_Line_1__c + '\n' + idLocation.Address_Line_2__c + '\n' + idLocation.Address_Line_3__c + '\n' + idLocation.Address_Line_4__c;
                                            
        System.assertEquals(idLocationStreet, updatedAccount.BillingStreet);
        System.assertEquals(idLocation.City__c, updatedAccount.BillingCity);
        System.assertEquals(idLocation.State__c, updatedAccount.BillingStateCode);
        System.assertEquals(idLocation.Zip_Code__c, updatedAccount.BillingPostalCode);
        System.assertEquals(idLocation.Country__c, updatedAccount.BillingCountryCode);
        
        Test.startTest();
            // mark the locations as no longer primary
            idLocation.Identifying_Address__c = false;
            
            update new List<Site_Location__c> {idLocation};
        Test.stopTest();
        
        // verify that the customer account addresses are blanked out
        updatedAccount = [Select Id, Name, BillingStreet, BillingCity, BillingStateCode, BillingPostalCode, BillingCountryCode,
                                    ShippingStreet, ShippingCity, ShippingStateCode, ShippingPostalCode, ShippingCountryCode
                                    From Account
                                    Where Id =: customerAccounts[0].Id];
        
        System.assertEquals(null, updatedAccount.BillingStreet);
        System.assertEquals(null, updatedAccount.BillingCity);
        System.assertEquals(null, updatedAccount.BillingStateCode);
        System.assertEquals(null, updatedAccount.BillingPostalCode);
        System.assertEquals(null, updatedAccount.BillingCountryCode);
    }
    
    static testMethod void updateCustomerAccountAddress_updateAddress(){
        Site_Location__c idLocation = TestUtility.newSiteLocation('Bill To', '123 B Street', 'Floor A', 'Suite B', 'Room C',
            'Some City', 'MA', '00000', 'US',
            customerAccounts[0].Oracle_Party_Id__c, customerAccounts[0].Id, true);
        idLocation.Identifying_Address__c = true;
        
        insert new List<Site_Location__c> {idLocation};
        
        Account updatedAccount = [Select Id, Name, BillingStreet, BillingCity, BillingStateCode, BillingPostalCode, BillingCountryCode
                                    From Account
                                    Where Id =: customerAccounts[0].Id];

        String idLocationStreet = idLocation.Address_Line_1__c + '\n' + idLocation.Address_Line_2__c + '\n' + idLocation.Address_Line_3__c + '\n' + idLocation.Address_Line_4__c;
                                            
        System.assertEquals(idLocationStreet, updatedAccount.BillingStreet);
        System.assertEquals(idLocation.City__c, updatedAccount.BillingCity);
        System.assertEquals(idLocation.State__c, updatedAccount.BillingStateCode);
        System.assertEquals(idLocation.Zip_Code__c, updatedAccount.BillingPostalCode);
        System.assertEquals(idLocation.Country__c, updatedAccount.BillingCountryCode);
        
        Test.startTest();
            // update the addresses
            idLocation.Address_Line_2__c = 'Floor 5';
            idLocation.Address_Line_3__c = 'Suite 1';
            idLocation.Address_Line_3__c = 'Room 2';
            idLocation.City__c = 'New City';
            idLocation.Zip_Code__c = '11111';
            update new List<Site_Location__c> {idLocation};
            
            // update just the country
            idLocation.State__c = 'IL';
            idLocation.Country__c = 'US';
            update new List<Site_Location__c> {idLocation};
        Test.stopTest();
        
        // verify addresses on customer account match what the site location addresses were updated to
        updatedAccount = [Select Id, Name, BillingStreet, BillingCity, BillingStateCode, BillingPostalCode, BillingCountryCode
                                    From Account
                                    Where Id =: customerAccounts[0].Id];
                                    
        idLocationStreet = idLocation.Address_Line_1__c + '\n' + idLocation.Address_Line_2__c + '\n' + idLocation.Address_Line_3__c + '\n' + idLocation.Address_Line_4__c;
        
        System.assertEquals(idLocationStreet, updatedAccount.BillingStreet);
        System.assertEquals(idLocation.City__c, updatedAccount.BillingCity);
        System.assertEquals(idLocation.State__c, updatedAccount.BillingStateCode);
        System.assertEquals(idLocation.Zip_Code__c, updatedAccount.BillingPostalCode);
        System.assertEquals(idLocation.Country__c, updatedAccount.BillingCountryCode);
    }
    
    static testMethod void updateCustomerAccountAddress_errorHandlingAccountUpdate(){
        Site_Location__c idLocation = TestUtility.newSiteLocation('Bill To', '123 B Street', 'Floor A', 'Suite B', 'Room C',
            'Some City', 'MA', '00000', 'US',
            customerAccounts[0].Oracle_Party_Id__c, customerAccounts[0].Id, true);
        idLocation.Identifying_Address__c = true;
        
        insert new List<Site_Location__c> {idLocation}; 
        
        Test.startTest();
            // set bad state and country codes
            idLocation.State__c = 'XX';
            idLocation.Country__c = 'XX';
            
            Database.SaveResult[] srList = Database.update(new List<Site_Location__c> {idLocation}, false);
            for(Database.SaveResult sr : srList){
                if(sr.isSuccess()){
                    System.assert(false, 'There should have been no successes.');
                }
                else{
                    String errors = '';
                    for(Database.Error err : sr.getErrors()){
                        errors += err.getMessage() + ' ';
                    }
                    //System.assert(errors.contains('Unable to update Account address.'), errors);
                }
            }
        Test.stopTest();
    }
    
    static testMethod void updateCustomerAccountAddress_insertBulk(){
        List<Site_Location__c> locations = new List<Site_Location__c>();
        for(Account a : siteAccounts){
            Site_Location__c idLocation = TestUtility.newSiteLocation('Bill To', '123 A Street', 'Floor A', 'Suite B', 'Room C',
                'Some City', 'MA', '00000', 'US',
                customerAccountMap.get(a.ParentId).Oracle_Party_Id__c, a.Id, true);
            idLocation.Identifying_Address__c = true;
            
            locations.add(idLocation);
        }
        
        Test.startTest();
            insert locations;
        Test.stopTest();

        String idLocationStreet = '123 A Street\nFloor A\nSuite B\nRoom C';
        
        List<Account> updatedAccounts = [Select Id, Name, BillingStreet, BillingCity, BillingStateCode, BillingPostalCode, BillingCountryCode
                                    From Account
                                    Where Id IN: customerAccounts];
        for(Account a : updatedAccounts){
            System.assertEquals(idLocationStreet, a.BillingStreet);
            System.assertEquals('Some City', a.BillingCity);
            System.assertEquals('MA', a.BillingStateCode);
            System.assertEquals('00000', a.BillingPostalCode);
            System.assertEquals('US', a.BillingCountryCode);
        }
        
        /*List<Account> updatedSiteAccounts = [Select Id, Name, BillingStreet, BillingCity, BillingStateCode, BillingPostalCode, BillingCountryCode
                                    From Account
                                    Where Id IN: siteAccounts];  
        for(Account a : updatedSiteAccounts){
            System.assertNotEquals(idLocationStreet, a.BillingStreet);
            System.assertEquals('Some City', a.BillingCity);
            System.assertEquals('MA', a.BillingStateCode);
            System.assertEquals('00000', a.BillingPostalCode);
            System.assertEquals('US', a.BillingCountryCode);
        }*/
    }
    
    static testMethod void updateCustomerAccountAddress_updateBulk(){
        List<Site_Location__c> locations = new List<Site_Location__c>();
        for(Account a : siteAccounts){
            Site_Location__c idLocation = TestUtility.newSiteLocation('Bill To', '123 A Street', 'Floor A', 'Suite B', 'Room C',
                'Some City', 'MA', '00000', 'US',
                customerAccountMap.get(a.ParentId).Oracle_Party_Id__c, a.Id, true);
            idLocation.Identifying_Address__c = true;
            
            locations.add(idLocation);
        }
        insert locations;
        
        Test.startTest();
            for(Site_Location__c l : locations){
                l.Address_Line_1__c = '123 A Street';
                l.State__c = 'VIC';
                l.Country__c = 'AU';
            }
            
            update locations;
        Test.stopTest();
        
        String idLocationStreet = '123 A Street\nFloor A\nSuite B\nRoom C';
        
        List<Account> updatedAccounts = [Select Id, Name, BillingStreet, BillingCity, BillingStateCode, BillingPostalCode, BillingCountryCode
                                    From Account
                                    Where Id IN: customerAccounts];  
        for(Account a : updatedAccounts){
            System.assertEquals(idLocationStreet, a.BillingStreet);
            System.assertEquals('Some City', a.BillingCity);
            System.assertEquals('VIC', a.BillingStateCode);
            System.assertEquals('00000', a.BillingPostalCode);
            System.assertEquals('AU', a.BillingCountryCode);
        }
        
        /*List<Account> updatedSiteAccounts = [Select Id, Name, BillingStreet, BillingCity, BillingStateCode, BillingPostalCode, BillingCountryCode
                                    From Account
                                    Where Id IN: siteAccounts];  
        for(Account a : updatedSiteAccounts){
            System.assertNotEquals(idLocationStreet, a.BillingStreet);
            System.assertEquals('Some City', a.BillingCity);
            System.assertEquals('VIC', a.BillingStateCode);
            System.assertEquals('00000', a.BillingPostalCode);
            System.assertEquals('AU', a.BillingCountryCode);
        }*/
    }
}