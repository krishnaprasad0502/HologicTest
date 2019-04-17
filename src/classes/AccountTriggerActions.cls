/*------------------------------------------------------------
  Author:            Denise Bacher
  Company:        Salesforce.com
  Description:    Account Trigger functions
  Test Class:        AccountTrigger_Test
 
  History:
  <Date>            <Authors Name>        <Brief Description of Change>
  04/08/2016        Denise Bacher        Initial Creation (US538)
  08/11/2016        Denise Bacher        Remove ShippingStreet_LineX__c fields (US1450)
  03/06/2019        Mani Sundaresan      International Territory Management (US6875)
  ------------------------------------------------------------*/
public with sharing class AccountTriggerActions {

    //Variable to access recordtypeids from Custom Setting
    private static Record_Type_IDs__c recordTypeIds = Record_Type_IDs__c.getOrgDefaults();

    /*------------------------------------------------------------
      Author:            Denise Bacher
      Company:        Salesforce.com
      Description:    Split the BillingStreet and ShippingStreet into seperate fields by line 
      Runs before insert, before update
      Inputs:            accounts - The list of Accounts to modify
      Returns:        N/A
     
      History:
      <Date>            <Authors Name>        <Brief Description of Change>
      04/08/2016        Denise Bacher        Initial Creation (US538)
      ------------------------------------------------------------*/
    public static void splitStreetFields(List<Account> accounts) {
        for (Account a : accounts) {
            List<String> billingSplit = String.isNotBlank(a.BillingStreet) ? a.BillingStreet.split('\n') : new List<String> ();

            a.BillingStreet_Line1__c = billingSplit.size() >= 1 ? billingSplit[0] : '';
            a.BillingStreet_Line2__c = billingSplit.size() >= 2 ? billingSplit[1] : '';
            a.BillingStreet_Line3__c = billingSplit.size() >= 3 ? billingSplit[2] : '';
            a.BillingStreet_Line4__c = billingSplit.size() >= 4 ? billingSplit[3] : '';
        }
    }


    public static void checkToCreateInitiatingTasks(List<Account> accounts, Map<Id, Account> oldMap) {
        //Filter for valid accounts
        List<Account> validAccounts = new List<Account> ();
        for (Account acct : accounts) {
            Account old = oldMap.get(acct.Id);
            if (acct.AMPS_Track__c != null && acct.AMPS_Track__c != old.AMPS_Track__c) {
                validAccounts.add(acct);
            }
        }

        if (validAccounts.size() > 0) {
            createInitiatingTasks(validAccounts);
        }
    }


    public static void createInitiatingTasks(List<Account> accounts) {

        map<id, id> territoryUserforAccount = new map<id, id> ();

        for (AccountUserTerritory2View actUsr :[select id, AccountId, UserId
             from AccountUserTerritory2View
             where RoleInTerritory2 = 'AMPS Representative'
             and AccountId IN :accounts]) {
            territoryUserforAccount.put(actUsr.AccountId, actUsr.UserId);
        }

        Map<String, AMPS_Marketing_Activity_Flow__c> flowsByType = new Map<String, AMPS_Marketing_Activity_Flow__c> ();
        for (AMPS_Marketing_Activity_Flow__c flow :[
             SELECT Id
             , Initiating_Task_Type__c
             , Name
             , Number_of_days_to_be_added__c
             FROM AMPS_Marketing_Activity_Flow__c
             WHERE Name != NULL
             AND Initiating_Task_Type__c != NULL
             ]) {
            flowsByType.put(flow.Initiating_Task_Type__c, flow);
        }

        List<Task> tasksToInsert = new List<Task> ();
        for (Account acct : accounts) {
            AMPS_Marketing_Activity_Flow__c flow = flowsByType.get(acct.AMPS_Track__c);
            if (flow != null && territoryUserforAccount.containsKey(acct.id)) {
                Task tsk = new Task();
                tsk.Priority = 'Normal';
                tsk.Status = 'Not Started';
                tsk.OwnerId = territoryUserforAccount.get(acct.id);
                if (flow.Number_of_days_to_be_added__c != null) {
                    tsk.ActivityDate = System.today().addDays(Integer.valueOf(flow.Number_of_days_to_be_added__c));
                }
                tsk.Subject = flow.Name;
                tsk.WhatID = acct.ID;
                tasksToInsert.add(tsk);
            }
        }

        insert tasksToInsert;
    }

    /*------------------------------------------------------------
      Author:         Mani Sundaresan
      Company:        Hologic
      Description:    International Territory Assignment Automation 
      Runs after insert, after update
      Inputs:            accounts - The list of Accounts to modify
      oldMap - Map of accounts with old data
      Returns:        N/A
     
      History:
      <Date>            <Authors Name>        <Brief Description of Change>
      03/06/2019        Mani Sundaresan        Initial Creation (US6875)
      ------------------------------------------------------------*/
    public static void internationalTerritoryAssignments(List<Account> accounts, Map<Id, Account> oldMap) {

        //Variable Declarations
        List<Account> accountList = new List<Account> ();
        Set<Id> accIdSet = new Set<Id> ();
        Set<Id> parentIdSet = new Set<Id> ();
        List<Account> accList = new List<Account> ();
        Set<Territory_Assignment_Rule__c> terrAssignmentRuleSet = new Set<Territory_Assignment_Rule__c> ();
        Map<Account, String> terrAssignmentCodeMap = new Map<Account, String> ();
        Map<Account, String> terrCountryMap = new Map<Account, String> ();
        Map<Account, String> terrParentAccMap = new Map<Account, String> ();
        Map<Account, String> terrStateMap = new Map<Account, String> ();
        Map<Account, String> terrAccMap = new Map<Account, String> ();
        Map<Id, List<Id>> accTerrMap = new Map<Id, List<Id>> ();
        List<Id> terrIdList = new List<Id> ();
        List<ObjectTerritory2Association> deleteot2aList = new List<ObjectTerritory2Association> ();
        List<ObjectTerritory2Association> ot2aList = new List<ObjectTerritory2Association> ();

        for (Account acc : accounts) {
            Account oldAcc = null;
            if (oldMap != null)
                oldAcc = oldMap.get(acc.Id);
            if (acc.RecordTypeId == recordTypeIds.Account_Site_Recordtype__c && acc.Run_Territory_Assignment__c && !acc.IsExcludedFromRealign && acc.BillingCountryCode != 'US' && (oldAcc == null || (oldAcc != null && acc.BillingCountryCode != oldAcc.BillingCountryCode) || (oldAcc != null && acc.BillingStateCode != oldAcc.BillingStateCode) || (oldAcc != null && acc.Run_Territory_Assignment__c != oldAcc.Run_Territory_Assignment__c))) {
                accIdSet.add(acc.Id);
            }
        }

        System.debug('accIdSet****:' + accIdSet);

        if (accIdSet.size() > 0)
            for (Account acc :[SELECT Id, ParentId, Parent.AccountNumber, AccountNumber, BillingState, BillingStateCode, BillingCountry, BillingCountryCode, Territory_Assignment_Code__c FROM Account WHERE Id IN :accIdSet]) {
                if (acc.BillingCountryCode != null)
                terrCountryMap.put(acc, acc.BillingCountryCode);
                if (acc.Territory_Assignment_Code__c != null)
                terrAssignmentCodeMap.put(acc, acc.Territory_Assignment_Code__c);
                if (acc.Parent.AccountNumber != null)
                terrParentAccMap.put(acc, acc.Parent.AccountNumber);
                if (acc.BillingStateCode != null)
                terrStateMap.put(acc, acc.BillingStateCode);
                if (acc.AccountNumber != null)
                terrAccMap.put(acc, acc.AccountNumber);

                accList.add(acc);
            }

        System.debug('terrCountryMap*****:' + terrCountryMap);
        System.debug('terrAssignmentCodeMap*****:' + terrAssignmentCodeMap);
        System.debug('terrParentAccMap*****:' + terrParentAccMap);
        System.debug('terrStateMap*****:' + terrStateMap);
        System.debug('terrAccMap*****:' + terrAccMap);

        for (Territory_Assignment_Rule__c tar :[SELECT Id, Territory_Assignment__r.Name, Territory_Assignment__r.Territory_ID__c, Assignment_Code__c FROM Territory_Assignment_Rule__c WHERE(Assignment_Code__c IN :terrCountryMap.values() AND Assignment_Type__c = 'Country') OR (Assignment_Code__c IN :terrAssignmentCodeMap.values() AND Assignment_Type__c = 'Postal Code') 
                                                OR (Assignment_Code__c IN :terrParentAccMap.values() AND Assignment_Type__c = 'Account Number') OR (Assignment_Code__c IN :terrStateMap.values() AND Assignment_Type__c = 'State') OR (Assignment_Code__c IN :terrAccMap.values() AND Assignment_Type__c = 'Site Number')]) {
            terrAssignmentRuleSet.add(tar);
        }

        System.debug('terrAssignmentRuleSet***:' + terrAssignmentRuleSet);

        if(accList.size() > 0)
            for (Account acc : accList) {
                terrIdList.clear();
                for (Territory_Assignment_Rule__c tar : terrAssignmentRuleSet){
                    if ((terrCountryMap.containsKey(acc) && terrCountryMap.get(acc) == tar.Assignment_Code__c) || (terrAssignmentCodeMap.containsKey(acc) && terrAssignmentCodeMap.get(acc) == tar.Assignment_Code__c) || (terrParentAccMap.containsKey(acc) && terrParentAccMap.get(acc) == tar.Assignment_Code__c) ||
                    (terrStateMap.containsKey(acc) && terrStateMap.get(acc) == tar.Assignment_Code__c) || (terrAccMap.containsKey(acc) && terrAccMap.get(acc) == tar.Assignment_Code__c))

                    terrIdList.add(tar.Territory_Assignment__r.Territory_ID__c);
                }
                System.debug('terrIdList*****:' + terrIdList);

                if (terrIdList.size() > 0){
                    parentIdSet.add(acc.ParentId);
                    accTerrMap.put(acc.Id, terrIdList);
                }
            }

        System.debug('parentIdSet*****:' + parentIdSet);
        System.debug('accTerrMap*****:' + accTerrMap);
        
        if (accTerrMap.size() > 0){
            //Delete the existing Territories from the Site account
            deleteot2aList = [SELECT Id FROM ObjectTerritory2Association WHERE ObjectId IN :accTerrMap.keySet()];
            System.debug('deleteot2aList***:' + deleteot2aList);
            delete deleteot2aList;

            //Creating the new Territories on the Site accounts
            for (Id acc : accTerrMap.keySet()) {
                for (Id terrId : accTerrMap.get(acc)) {
                    if (terrId != null) {
                        ObjectTerritory2Association ota = new ObjectTerritory2Association(Territory2Id = terrId, ObjectId = acc, AssociationCause = 'Territory2Manual');
                        ot2aList.add(ota);
                    }
                }
                Account acc1 = new Account(Id=acc, Run_Territory_Assignment__c = false);
                accountList.add(acc1);
            }
            System.debug('Insert territory records***:' + ot2aList);
            System.debug('Update account records***:' + accountList);
            
            if (ot2aList.size() > 0){
                Database.SaveResult[] srList = Database.insert(ot2aList, false);
                //insert ot2aList;
            
            
                for(Database.SaveResult sr : srList){
                    if(!sr.isSuccess()){
                        for(Database.Error err : sr.getErrors()){
                            System.debug('The following error has occured:'+err.getStatusCode() + ' '+ err.getMessage() + 'Fields that affected this error:' +err.getFields());
                        }
                    }
                }
            
            }
                
            
            if(accountList.size() > 0)
                update accountList;
                
            
        }
        System.debug('parentIdSet:' + parentIdSet);

        //Delete the exisiting territories and add the new ones on the parent account
        List<Account> childAccList = [SELECT Id, ParentId, (SELECT Id, Territory2Id, ObjectId FROM ObjectTerritory2Associations) FROM Account WHERE ParentId IN :parentIdSet];

        List<ObjectTerritory2Association> parentot2aList = new List<ObjectTerritory2Association> ();

        for (Account acc : childAccList) {
            System.debug('childAccId:' + acc.Id);
            System.debug('childTerr:' + acc.getSObjects('ObjectTerritory2Associations'));
            if (acc.getSObjects('ObjectTerritory2Associations') != null) {
                for (ObjectTerritory2Association ot2a : acc.getSObjects('ObjectTerritory2Associations')) {
                    ObjectTerritory2Association ota = new ObjectTerritory2Association(Territory2Id = ot2a.Territory2Id, ObjectId = acc.ParentId, AssociationCause = 'Territory2Manual');
                    parentot2aList.add(ota);
                }
            }
        }

        if(parentot2aList.size() > 0){
            Database.SaveResult[] srList = Database.insert(parentot2aList, false);
        
            for(Database.SaveResult sr : srList){
                if(!sr.isSuccess()){
                    for(Database.Error err : sr.getErrors()){
                        System.debug('The following error has occured:'+err.getStatusCode() + ' '+ err.getMessage() + 'Fields that affected this error:' +err.getFields());
                    }
                }
            }
        }
    }
}