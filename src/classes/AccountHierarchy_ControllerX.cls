/*------------------------------------------------------------
Author:         Denise Bacher
Company:        Salesforce.com
Description:    Retrieves the Account Hierarchy for the current account
Test Class:     AccountHierarchy_ControllerX_Test

History:
<Date>          <Authors Name>      <Brief Description of Change>
03/25/2016      Denise Bacher       Initial Creation (US430)
03/30/2016      Denise Bacher       Updated HIERARCHY_DEPTH to check for null Configuration_Settings__c.Account_Hierarchy_Depth__c (DE35)
05/11/2016      Denise Bacher       Update to popover information (US959)
09/06/2016      Mani                        Update to include pagination (DE011)
------------------------------------------------------------*/
global with sharing class AccountHierarchy_ControllerX {
    // how many levels of the hierarchy are queried for
    private static final Integer ORG_DEFAULT_HIERARCHY_DEPTH = (Integer)Configuration_Settings__c.getOrgDefaults().Account_Hierarchy_Depth__c;
    public static final Integer HIERARCHY_DEPTH = ORG_DEFAULT_HIERARCHY_DEPTH != null ? ORG_DEFAULT_HIERARCHY_DEPTH : 5; 
    
    public Map<Id, Account> accountMap;
    
    //Pagination Variables
    public Integer counter {get {if(counter == null) return 0; else return counter;} set;}
    public Integer list_size {get {if(list_size == null) return 500; else return list_size;} set;}
    public Integer total_size {get {if(total_size == null) return 0; else return total_size;} set;}
    
    public List<Account> accounts{
        get {return accountMap.values();}
        private set;
    }
    
    public AccountHierarchy_ControllerX (ApexPages.StandardController ctrl){
        accountMap = new Map<Id, Account>();
        String topLevelId = '';
        String currentId = ApexPages.currentPage().getParameters().get('Id');
        
        if(currentId != null)
            topLevelId = getTopElement(currentId);
        
        if(total_size == 0)
            total_size = [Select Count() FROM Account WHERE ParentId = :topLevelId];
    }
    
    /*------------------------------------------------------------
    Author:         Denise Bacher
    Company:        Salesforce.com
    Description:    Update the accounts currently displayed in the hierarchy so we can show the popover info
    
    History:
    <Date>          <Authors Name>      <Brief Description of Change>
    05/11/2016      Denise Bacher       Initial Creation
    ------------------------------------------------------------*/
    public void updatePopover(){
        String value = ApexPages.currentPage().getParameters().get('accounts');
        List<Account> tempAccounts = String.isNotBlank(value) ? (List<Account>)JSON.deserialize(value, List<Account>.class) : new List<Account>();
        accountMap.clear();
        for(Account a : tempAccounts){
            accountMap.put(a.Id, a);
        }   
    }
    
    /*------------------------------------------------------------
    Author:         Denise Bacher
    Company:        Salesforce.com
    Description:    Remote function to retrieve the initial Account Hierarchy for a given Account 
    Inputs:         currentId - id of an Account
    Returns:        List of ObjectNode
    
    History:
    <Date>          <Authors Name>      <Brief Description of Change>
    03/25/2016      Denise Bacher       Initial Creation
    09/06/2016      Mani                Update to include additional paramaters for Pagination
    ------------------------------------------------------------*/
    @RemoteAction
    global static ReturnPayload loadInitialHierarchy(String currentId, Integer counter, Integer list_size, Integer total_size){
        String topLevelId = getTopElement(currentId);
        return getObjectStructure(0, topLevelId, currentId, counter, list_size, total_size);
    }
    
    /*------------------------------------------------------------
    Author:         Denise Bacher
    Company:        Salesforce.com
    Description:    Remote function to retrieve the additional children in the hierarchy
    Inputs:         currentHierarchyLevel - current hierarchy level of the selected Account
                    currentId - id of an Account
    Returns:        List of ObjectNode
    
    History:
    <Date>          <Authors Name>      <Brief Description of Change>
    03/25/2016      Denise Bacher       Initial Creation
    09/06/2016      Mani                Update to include additional paramaters for Pagination

    ------------------------------------------------------------*/
    @RemoteAction
    global static ReturnPayload lazyLoadChildAccounts(Integer currentHierarchyLevel, String currentId, String selectedId, Integer counter, Integer list_size, Integer total_size){
        return getObjectStructure(currentHierarchyLevel, currentId, selectedId, counter, list_size, total_size);
    }
    
    /*------------------------------------------------------------
    Author:         Denise Bacher
    Company:        Salesforce.com
    Description:    Traverse up the account hierarchy to find the top Account
                    Note: Account depth is unknown, so HIERARCHY_DEPTH is used to limit the number of queries that are performed 
    Inputs:         objId - Account Id to traverse up from
    Returns:        Id of the top most Account
    
    History:
    <Date>          <Authors Name>      <Brief Description of Change>
    03/25/2016      Denise Bacher       Initial Creation
    ------------------------------------------------------------*/
    private static String getTopElement(String objId) {
        Boolean top = false;
        Integer depth = 0;
        try{
            while (!top && depth < HIERARCHY_DEPTH-1) {
                Account a = [Select ID, ParentId From Account Where ID =: objId LIMIT 1];
                
                if (a.ParentID != null) {
                    objId = a.ParentID;
                }
                else {
                    top = true;
                }
                depth++;
            }
        }
        catch(Exception e){
            System.debug(e);
            throw new GlobalUtility.GenericException('There was an error while trying to query for the top of the hierarchy.');
        }
        
        return objId ;
    }
    
    /*------------------------------------------------------------
    Author:         Denise Bacher
    Company:        Salesforce.com
    Description:    Traverse up the account hierarchy to find the top Account
                    Note: Account depth is unknown, so HIERARCHY_DEPTH is used to limit the number of queries that are performed 
    Inputs:         initialLevel - initial hierarchy level starting from
                    currentId - Account Id to begin traversing down the account hierarchy from
                    selectedId - Account Id that we are viewing the hierarchy from
    Returns:        List<ObjectNode> in their tree structure
    
    History:
    <Date>          <Authors Name>      <Brief Description of Change>
    03/25/2016      Denise Bacher       Initial Creation
    09/06/2016      Mani                Update to include additional paramaters for Pagination

    ------------------------------------------------------------*/
    private static ReturnPayload getObjectStructure(Integer initialLevel, String currentId, String selectedId, Integer counter, Integer list_size, Integer total_size){
        if(currentId == null || initialLevel == null){
            throw new GlobalUtility.GenericException('Invalid values, unable to retrieve hierarchy.');
        }
        
        ReturnPayload returnValue = new ReturnPayload();
        Map<String, ObjectNode> nodeMap = new Map<String, ObjectNode>();
        List<Account> currentAccounts = new List<Account>();
        Set<ID> parentIds = new Set<ID>();
        Integer level = initialLevel;
        Integer maxLevel = initialLevel + HIERARCHY_DEPTH;
        Boolean endOfStructure = false;
        
        // Find highest level obejct in the structure
        parentIds.add(currentId);
        
        String selectClause = 'SELECT Id, ParentId, Name';
        for(Schema.FieldSetMember f : SObjectType.Account.FieldSets.Hierarchy_Popover.getFields()){
            selectClause += !selectClause.contains(f.getFieldPath()) ? ', ' + f.getFieldPath() : '';
        }
        
        // Loop though all children
        while (!endOfStructure && level < maxLevel){
            String fromClause = ' FROM Account'
                + ' WHERE ' + (level != initialLevel ? 'ParentId' : 'Id') + ' IN(\'' + String.join(new List<ID>(parentIds), '\',\'')+ '\')'
                + ' ORDER BY Name';
            
            if(level == initialLevel){
                // if we're at the top, get the current account
                currentAccounts = Database.query(selectClause + fromClause);
            }
            else if(level == maxLevel-1){
                // if we're at max depth, add an extra check to the query for additional children so they can be lazy loaded later
                currentAccounts = Database.query(selectClause + ', (Select Id From ChildAccounts) '+ fromClause);
            }
            else {
                if(total_size == 0)
                    total_size = Database.countQuery('Select Count() FROM Account WHERE ' + (level != initialLevel ? 'ParentId' : 'Id') + ' IN(\'' + String.join(new List<ID>(parentIds), '\',\'')+ '\')' );
                
                currentAccounts = Database.query(selectClause + fromClause + ' LIMIT '+list_size  + ' OFFSET '+counter);
            }
            
            if(currentAccounts.size() == 0){
                endOfStructure = true;
            }
            else {
                parentIds.clear();
                for(Account a : currentAccounts){
                    returnValue.accounts.add(a);
                    
                    // add the account ID to the parentIds set for the next loop
                    parentIds.add(a.Id);
                    
                    // create the ObjectNode and add it to the node Map
                    ObjectNode newNode = new ObjectNode(a.Id, a.Name, level, a.ParentId, 
                        level == 0 && String.isNotBlank(a.ParentId), 
                        a.Id == selectedId, 
                        String.isBlank(a.ParentId));
                    nodeMap.put(a.Id, newNode);  
                    
                    // if the nodeMap contains the account's parent, add the current node as a child of the parent node
                    if(nodeMap.containsKey(a.ParentId)){
                        nodeMap.get(a.ParentId).nodeChildren.add(newNode);
                    }
                    
                    // set flag so we know there are additional children to be lazy loaded
                    newNode.hasMissingChildren = a.ChildAccounts != null && a.ChildAccounts.size() > 0;
                    
                    // add all ObjectNodes at the initialLevel to the objectNode list that will be returned
                    if(level == initialLevel){
                        returnValue.nodes.add(newNode);
                    }
                }         
                level++;
            }
        }
        
        return returnValue;
    }
    
    
    //Method invoked by <<-Previous link
    public PageReference Previous() {         
        counter -= list_size;       
        return null;        
    }
    
    //Method invoked by Next->> link     
    public PageReference Next() {       
        counter += list_size;       
       return null;        
    }       
    
    //Method to hide/display <<-Previous link        
    public Boolean getDisablePrevious() {       
        if (counter>0)      
            return false;       
        else        
            return true;        
    } 
    
    //Method to hide/display Next->> link      
    public Boolean getDisableNext() {    
    
        if (counter + list_size < total_size)       
            return false;       
        else        
            return true;        
    }
    
    global class ReturnPayload{
        public List<ObjectNode> nodes;
        public Set<Account> accounts;
        
        public ReturnPayload(){
            nodes = new List<ObjectNode>();
            accounts = new Set<Account>();
        }
        
    }
}