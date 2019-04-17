/*------------------------------------------------------------
Author:         Denise Bacher
Company:        Salesforce.com
Description:    Test class to validate AccountHierarchy page and AccountHierarchy_ControllerX
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
03/25/2016      Denise Bacher       Initial Creation
03/30/2016      Denise Bacher       Add new unit test for defect fix (DE35)
05/11/2016      Denise Bacher       Update to popover information (US959)
09/06/2016      Mani                Update to include pagination (DE011)
------------------------------------------------------------*/
@isTest
private class AccountHierarchy_ControllerX_Test {
    private static Configuration_Settings__c orgDefaults;
    private static Account parent;
    private static List<Account> level1;
    private static List<Account> level2;
    private static List<Account> level3;
    private static List<Account> level4;
    private static List<Account> level5;
    private static List<Account> level6;
    private static List<Account> level7;
    private static List<Account> level8;
    private static List<Account> level9;
    
    static{
        // defaults to hierarchy depth of 5
        orgDefaults = TestUtility.setupConfigurationSettings();
        
        
    }
    
    private static void setupAccountHierarchy10Levels(){
        parent = TestUtility.newAccount('Account0', 'Account0');
        insert parent;
        
        level1 = createChildAccounts(new List<Account>{parent}, 5);
        level2 = createChildAccounts(level1, 5);
        level3 = createChildAccounts(level2, 3);
        level4 = createChildAccounts(level3, 2);
        level5 = createChildAccounts(level4, 2);
        //level6 = createChildAccounts(level5, 1);
        //level7 = createChildAccounts(level6, 1);
        //level8 = createChildAccounts(level7, 1);
        //level9 = createChildAccounts(level8, 1);
    }
    
    private static void setupAccountHierarchy4Levels(){
        parent = TestUtility.newAccount('Account0', 'Account0');
        insert parent;
        
        level1 = createChildAccounts(new List<Account>{parent}, 5);
        level2 = createChildAccounts(level1, 5);
        level3 = createChildAccounts(level2, 5);
    }
    
    private static List<Account> createChildAccounts(List<Account> parents, Integer numberChildren){
        List<Account> children = new List<Account>();
        for(Account pLevel : parents){
            for(Integer i = 0; i < numberChildren; i++){
                String nodeName = pLevel.Name+'-'+i;
                children.add(TestUtility.newAccount(nodeName, null, pLevel.Id));
            }
        }
        insert children;
        return children;
    }
    
    static testMethod void viewHierarchyFromParent() {
        PageReference pageRef = Page.AccountHierarchy;
        Test.setCurrentPage(pageRef);
        
        setupAccountHierarchy10Levels();
        pageRef.getParameters().put('Id',parent.Id);
        AccountHierarchy_ControllerX ctrl = new AccountHierarchy_ControllerX(new ApexPages.StandardController(parent));
        Integer counter = ctrl.counter;
        Integer list_size = ctrl.list_size;
        Integer total_size;
        
        Test.startTest();
            AccountHierarchy_ControllerX.ReturnPayload returned = AccountHierarchy_ControllerX.loadInitialHierarchy(parent.Id, counter, list_size, 0);
            List<ObjectNode> objectNodes = returned.nodes;
            
            ApexPages.currentPage().getParameters().put('accounts', JSON.serialize(returned.accounts));
            ctrl.updatePopover();
            System.assertEquals(256, ctrl.accounts.size());
            
            // verify account hierarchy loaded
            System.assertEquals(1, objectNodes.size());
            System.assertEquals(parent.Id, objectNodes[0].nodeId);
            System.assertEquals(parent.Name, objectNodes[0].nodeName);
            System.assertEquals(0, objectNodes[0].nodeLevel);
            System.assertEquals(true, objectNodes[0].isSelectedObject);
            System.assertEquals(true, objectNodes[0].isTopNode);
            System.assertEquals(false, objectNodes[0].hasMissingParent);
            System.assertEquals(false, objectNodes[0].hasMissingChildren);
            
            System.assertEquals(5, objectNodes[0].nodeChildren.size()); // level 1
            System.assertEquals(5, objectNodes[0].nodeChildren[0].nodeChildren.size()); // level 2
            System.assertEquals(3, objectNodes[0].nodeChildren[0].nodeChildren[0].nodeChildren.size()); // level 3
            System.assertEquals(2, objectNodes[0].nodeChildren[0].nodeChildren[0].nodeChildren[0].nodeChildren.size()); // level 4
            
            // check last level loaded has missing children (level 4)
            List<ObjectNode> level4ChildNodes = objectNodes[0].nodeChildren[0].nodeChildren[0].nodeChildren[0].nodeChildren;
            System.assertEquals(true, level4ChildNodes[0].hasMissingChildren);
            
            // lazy load the missing children
            AccountHierarchy_ControllerX.ReturnPayload lazyLoadReturned = AccountHierarchy_ControllerX.lazyLoadChildAccounts(level4ChildNodes[0].nodeLevel, level4ChildNodes[0].nodeId, parent.Id,counter, list_size, total_size);
            List<ObjectNode> missingChildNodes = lazyLoadReturned.nodes;
            
            ApexPages.currentPage().getParameters().put('accounts', JSON.serialize(lazyLoadReturned.accounts));
            ctrl.updatePopover();
            System.assertEquals(3, ctrl.accounts.size());
            
            // verify missing hierarchy loaded
            System.assertEquals(1, missingChildNodes.size());
            System.assertEquals(2, missingChildNodes[0].nodeChildren.size(), missingChildNodes[0].nodeChildren); // level 5
            //System.assertEquals(1, missingChildNodes[0].nodeChildren[0].nodeChildren.size()); // level 6
            //System.assertEquals(1, missingChildNodes[0].nodeChildren[0].nodeChildren[0].nodeChildren.size()); // level 7
            //System.assertEquals(1, missingChildNodes[0].nodeChildren[0].nodeChildren[0].nodeChildren[0].nodeChildren.size()); // level 8
            //System.assertEquals(true, missingChildNodes[0].nodeChildren[0].nodeChildren[0].nodeChildren[0].nodeChildren[0].hasMissingChildren); // level 8 has missing children
        Test.stopTest();
    }
    
    static testMethod void viewHierarchyFromChild(){
        PageReference pageRef = Page.AccountHierarchy;
        Test.setCurrentPage(pageRef);
        
        setupAccountHierarchy10Levels();
        pageRef.getParameters().put('Id',parent.Id);
        AccountHierarchy_ControllerX ctrl = new AccountHierarchy_ControllerX(new ApexPages.StandardController(level5[0]));
        
        Integer counter = ctrl.counter;
        Integer list_size = ctrl.list_size;
        Integer total_size = ctrl.total_size;
        
        Test.startTest();
            // verify account hierarchy loaded
            AccountHierarchy_ControllerX.ReturnPayload returned = AccountHierarchy_ControllerX.loadInitialHierarchy(level5[0].Id, counter, list_size, total_size);
            List<ObjectNode> objectNodes = returned.nodes;
            
            ApexPages.currentPage().getParameters().put('accounts', JSON.serialize(returned.accounts));
            ctrl.updatePopover();
            System.assertEquals(111, ctrl.accounts.size());
            
            System.assertEquals(1, objectNodes.size());
            System.assertEquals(level1[0].Id, objectNodes[0].nodeId);
            System.assertEquals(level1[0].Name, objectNodes[0].nodeName);
            System.assertEquals(0, objectNodes[0].nodeLevel);
            System.assertEquals(false, objectNodes[0].isSelectedObject);
            System.assertEquals(false, objectNodes[0].isTopNode);
            System.assertEquals(true, objectNodes[0].hasMissingParent);
            
            //System.assertEquals(1, objectNodes[0].nodeChildren.size()); // level 6
            //System.assertEquals(1, objectNodes[0].nodeChildren[0].nodeChildren.size()); // level 7
            //System.assertEquals(1, objectNodes[0].nodeChildren[0].nodeChildren[0].nodeChildren.size()); // level 8
            //System.assertEquals(1, objectNodes[0].nodeChildren[0].nodeChildren[0].nodeChildren[0].nodeChildren.size()); // level 9
            //System.assertEquals(true, objectNodes[0].nodeChildren[0].nodeChildren[0].nodeChildren[0].nodeChildren[0].isSelectedObject);
            //System.assertEquals(false, objectNodes[0].nodeChildren[0].nodeChildren[0].nodeChildren[0].nodeChildren[0].isTopNode);
            //System.assertEquals(false, objectNodes[0].nodeChildren[0].nodeChildren[0].nodeChildren[0].nodeChildren[0].hasMissingParent);
            //System.assertEquals(false, objectNodes[0].nodeChildren[0].nodeChildren[0].nodeChildren[0].nodeChildren[0].hasMissingChildren);
            
            ctrl.getDisablePrevious();
            ctrl.getDisableNext();
            ctrl.Next();
            ctrl.Previous();
            
        Test.stopTest();
    }
    
    static testMethod void viewHierarchy4LevelsDeep(){
        PageReference pageRef = Page.AccountHierarchy;
        Test.setCurrentPage(pageRef);
        
        setupAccountHierarchy4Levels();
        pageRef.getParameters().put('Id',parent.Id);
        AccountHierarchy_ControllerX ctrl = new AccountHierarchy_ControllerX(new ApexPages.StandardController(parent));
        
        Integer counter = ctrl.counter;
        Integer list_size = ctrl.list_size;
        Integer total_size = ctrl.total_size;
        
        Test.startTest();
            // verify account hierarchy loaded
            AccountHierarchy_ControllerX.ReturnPayload returned = AccountHierarchy_ControllerX.loadInitialHierarchy(parent.Id, counter, list_size, total_size);
            List<ObjectNode> objectNodes = returned.nodes;
            
            ApexPages.currentPage().getParameters().put('accounts', JSON.serialize(returned.accounts));
            ctrl.updatePopover();
            System.assertEquals(156, ctrl.accounts.size());
            
            System.assertEquals(1, objectNodes.size());
            System.assertEquals(parent.Id, objectNodes[0].nodeId);
            System.assertEquals(parent.Name, objectNodes[0].nodeName);
            System.assertEquals(0, objectNodes[0].nodeLevel);
            System.assertEquals(true, objectNodes[0].isSelectedObject);
            System.assertEquals(true, objectNodes[0].isTopNode);
            System.assertEquals(false, objectNodes[0].hasMissingParent);
            System.assertEquals(false, objectNodes[0].hasMissingChildren);
            
            System.assertEquals(5, objectNodes[0].nodeChildren.size()); // level 1
            System.assertEquals(5, objectNodes[0].nodeChildren[0].nodeChildren.size()); // level 2
            System.assertEquals(5, objectNodes[0].nodeChildren[0].nodeChildren[0].nodeChildren.size()); // level 3
            
            ctrl.Next();
            ctrl.Previous();
            ctrl.counter = 0;
            ctrl.list_size = 500;
            ctrl.total_size = 611;
            ctrl.getDisablePrevious();
            ctrl.getDisableNext();
            
            ctrl.counter = 500;
            ctrl.list_size = 1000;
            ctrl.getDisablePrevious();
            ctrl.getDisableNext();
            
            
            for(ObjectNode o : objectNodes[0].nodeChildren[0].nodeChildren[0].nodeChildren){
                System.assertEquals(false, o.hasMissingChildren);
            }
        Test.stopTest();
    }
    
    static testMethod void loadInitialHierarchyBadInputs(){
        Integer counter = 0;
        Integer list_size = 500;
        Integer total_size = 0;
        
        Test.startTest();
            try{
                AccountHierarchy_ControllerX.ReturnPayload returned = AccountHierarchy_ControllerX.loadInitialHierarchy(null, counter, list_size, total_size);
                List<ObjectNode> objectNodes = returned.nodes;
                System.assert(false, 'loadInitialHierarchy with null params should have thrown an error');
            }
            catch(Exception e){
                System.assert(e.getTypeName().contains('GenericException'));
            }
        Test.stopTest();
    }
    
    static testMethod void lazyLoadChildAccountsBadInputs(){
        Integer counter = 0;
        Integer list_size = 500;
        Integer total_size = 0;
        
        Test.startTest();
            try{
                AccountHierarchy_ControllerX.ReturnPayload returned = AccountHierarchy_ControllerX.lazyLoadChildAccounts(null, null, null, counter, list_size, total_size);
                List<ObjectNode> objectNodes = returned.nodes;
                System.assert(false, 'lazyLoadChildAccounts with null params should have thrown an error');
            }
            catch(Exception e){
                System.assert(e.getTypeName().contains('GenericException'));
            }
        Test.stopTest();
    }
    
    static testMethod void noErrorsOnNullConfigurationSetting(){
        PageReference pageRef = Page.AccountHierarchy;
        Test.setCurrentPage(pageRef);
        
        setupAccountHierarchy10Levels();
        pageRef.getParameters().put('Id',parent.Id);
        delete orgDefaults;
        AccountHierarchy_ControllerX ctrl = new AccountHierarchy_ControllerX(new ApexPages.StandardController(parent));
        Integer counter = ctrl.counter;
        Integer list_size = ctrl.list_size;
        Integer total_size = ctrl.total_size;
        
        Test.startTest();
            // verify account hierarchy loaded
            AccountHierarchy_ControllerX.ReturnPayload returned = AccountHierarchy_ControllerX.loadInitialHierarchy(parent.Id, counter, list_size, total_size);
            List<ObjectNode> objectNodes = returned.nodes;
            
            ApexPages.currentPage().getParameters().put('accounts', JSON.serialize(returned.accounts));
            ctrl.updatePopover();
            System.assertEquals(256, ctrl.accounts.size());
            
            System.assertEquals(1, objectNodes.size());
            System.assertEquals(parent.Id, objectNodes[0].nodeId);
            System.assertEquals(parent.Name, objectNodes[0].nodeName);
            System.assertEquals(0, objectNodes[0].nodeLevel);
            System.assertEquals(true, objectNodes[0].isSelectedObject);
            System.assertEquals(true, objectNodes[0].isTopNode);
            System.assertEquals(false, objectNodes[0].hasMissingParent);
            System.assertEquals(false, objectNodes[0].hasMissingChildren);
            
            System.assertEquals(5, objectNodes[0].nodeChildren.size()); // level 1
            System.assertEquals(5, objectNodes[0].nodeChildren[0].nodeChildren.size()); // level 2
            System.assertEquals(3, objectNodes[0].nodeChildren[0].nodeChildren[0].nodeChildren.size()); // level 3
            System.assertEquals(2, objectNodes[0].nodeChildren[0].nodeChildren[0].nodeChildren[0].nodeChildren.size()); // level 4
            
            // check last level loaded has missing children (level 4)
            System.assertEquals(true, objectNodes[0].nodeChildren[0].nodeChildren[0].nodeChildren[0].nodeChildren[0].hasMissingChildren);
        Test.stopTest();
    }
}