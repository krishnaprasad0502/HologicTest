/*------------------------------------------------------------
Author:         Denise Bacher
Company:        Salesforce.com
Description:    Test class to validate OppTerrAssignDefaultLogicFilter
                Tests Excecuted:
                
                viewHierarchyFromParent - view account hierarchy from the top account, verfiy hierarchy details and 'lazy load' additional accounts
                
                viewHierarchyFromChild - view account hierarchy from bottom most account in the hierarchy, should not be able to see top level
                
                viewHierarchy4LevelsDeep - view account hierarchy that is only 4 levels deep from top node, this is checking that the loop that queries
                    child records breaks before max depth is reached
                    
                loadInitialHierarchyBadInputs - call AccountHierarchy_ControllerX.loadInitialHierarchy with null inputs
                
                lazyLoadChildAccountsBadInputs - call AccountHierarchy_ControllerX.lazyLoadChildAccounts with null inputs
                
                noErrorsOnNullConfigurationSetting - verify no errors occur if the org defaults for Configuration_Settings__c have not been set up

History:
<Date>          <Authors Name>      <Brief Description of Change>
06/21/2016      Denise Bacher       Initial Creation (US1294)
------------------------------------------------------------*/
@isTest
private class OppTerrAssignDefaultLogicFilter_Test {
    private static Territory2Model model;
    private static List<Territory2> territories;
    private static List<User> users;
    private static List<Account> accounts;
    private static List<ObjectTerritory2Association> accountTerritories;
    private static List<UserTerritory2Association> userTerritories;
    
    private static Map<Id, Set<Id>> territoryToAccount;
    private static Map<Id, Set<Id>> userToTerritory;
    private static Map<Id, Map<Id, Set<Id>>> userToAccountToTerritory;
    
    static{
        TestUtility.setupConfigurationSettings();        
         
        Trigger_Switch__c tsop= new Trigger_Switch__c();
        tsop.Name = 'OpportunityTrigger';
        tsop.Active__c = true;        
        insert tsop;
        
        try{
            model = [Select Id From Territory2Model Where State = 'Active' Limit 1];
        }
        catch(Exception e){}
        System.assertNotEquals(null, model, 'SETUP ERROR: test cannot proceed, no Territory Models were found.');
        
        try{
            territories = [Select Id, Name From Territory2 Where Territory2ModelId =: model.Id Limit 10];
        }
        catch(Exception e){}
        System.assertNotEquals(null, territories, 'SETUP ERROR: test cannot proceed, no Territories were found.');
        
        users = new List<User>();
        accounts = new List<Account>();
        System.runAs(new User(Id = UserInfo.getUserId())) {
            for(Integer i = 0; i < territories.size(); i++){
                users.add(TestUtility.newUser(UserInfo.getProfileId(), 'tu'+i));
            }
            insert users;
        
            for(Integer i = 0; i < 50; i++){
                accounts.add(TestUtility.newAccount('Account '+i, 'xxTest' + i, 'address ' + i, null, GlobalUtility.getRecordTypeId('Account', 'Customer')));
            }
            insert accounts;
        }
        
        territoryToAccount = new Map<Id, Set<Id>>();
        accountTerritories = new List<ObjectTerritory2Association>();
        for(integer i = 0; i < accounts.size(); i++){
            accountTerritories.add(new ObjectTerritory2Association(AssociationCause = 'Territory2Manual', ObjectId = accounts[i].Id, Territory2Id = territories[math.mod(i, territories.size())].Id));
            accountTerritories.add(new ObjectTerritory2Association(AssociationCause = 'Territory2Manual', ObjectId = accounts[i].Id, Territory2Id = territories[math.mod(i+1, territories.size())].Id));
            accountTerritories.add(new ObjectTerritory2Association(AssociationCause = 'Territory2Manual', ObjectId = accounts[i].Id, Territory2Id = territories[math.mod(i+2, territories.size())].Id));
            
            if(!territoryToAccount.containsKey(territories[math.mod(i, territories.size())].Id)){
                territoryToAccount.put(territories[math.mod(i, territories.size())].Id, new Set<Id>());
            }
            if(!territoryToAccount.containsKey(territories[math.mod(i+1, territories.size())].Id)){
                territoryToAccount.put(territories[math.mod(i+1, territories.size())].Id, new Set<Id>());
            }
            if(!territoryToAccount.containsKey(territories[math.mod(i+2, territories.size())].Id)){
                territoryToAccount.put(territories[math.mod(i+2, territories.size())].Id, new Set<Id>());
            }
            
            territoryToAccount.get(territories[math.mod(i, territories.size())].Id).add(accounts[i].Id);
            territoryToAccount.get(territories[math.mod(i+1, territories.size())].Id).add(accounts[i].Id);
            territoryToAccount.get(territories[math.mod(i+2, territories.size())].Id).add(accounts[i].Id);
        }
        insert accountTerritories; 
        
        userToTerritory = new Map<Id, Set<Id>>();
        userTerritories = new List<UserTerritory2Association>();
        System.runAs(new User(Id = UserInfo.getUserId())) {
            for(Integer i = 0; i < territories.size(); i++){
                userTerritories.add(new UserTerritory2Association(UserId = users[i].Id, Territory2Id = territories[i].Id));
                userTerritories.add(new UserTerritory2Association(UserId = users[i].Id, Territory2Id = territories[math.mod(i+5, territories.size())].Id));
                
                userToTerritory.put(users[i].Id, new Set<Id>());
                userToTerritory.get(users[i].Id).add(territories[i].Id);
                userToTerritory.get(users[i].Id).add(territories[math.mod(i+5, territories.size())].Id);
            }
            insert userTerritories;
        }
        
        userToAccountToTerritory = new Map<Id, Map<Id, Set<Id>>>();
        for(Id uId : userToTerritory.keySet()){
            userToAccountToTerritory.put(uId, new Map<Id, Set<Id>>());
            for(Id tId : userToTerritory.get(uId)){
                for(Id aId : territoryToAccount.get(tId)){
                    if(!userToAccountToTerritory.get(uId).containsKey(aId)){
                        userToAccountToTerritory.get(uId).put(aId, new Set<Id>());
                    }
                    userToAccountToTerritory.get(uId).get(aId).add(tId);
                }
            }
        }
        System.debug(Json.serialize(userToAccountToTerritory));
    }
    
    static testMethod void getOpportunityTerritory2Assignments() {
        List<Opportunity> opportunities = new List<Opportunity>();
        for(Integer i = 0; i < accounts.size(); i++){
            opportunities.add(TestUtility.newOpportunity('Test Opp '+i, accounts[i].Id, System.today(), 'Prospecting', 'Pipeline', users[math.mod(i, users.size())].Id));
        }
        insert opportunities;
        
        List<Id> oppIds = new List<Id>();
        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>();
        for(Opportunity o : opportunities){
            oppIds.add(o.Id);
            oppMap.put(o.Id, o);
        }
        
        Test.startTest();
            OppTerrAssignDefaultLogicFilter filter = new OppTerrAssignDefaultLogicFilter();
            Map<Id, Id> oppToTerritory = filter.getOpportunityTerritory2Assignments(oppIds);
            
            for(Id oppId : oppToTerritory.keySet()){
                Opportunity o = oppMap.get(oppId);
                Set<Id> territoryIds = userToAccountToTerritory.get(o.OwnerId).get(o.AccountId);
                System.assert(territoryIds.contains(oppToTerritory.get(oppId)));
            }
        Test.stopTest();
    }
}