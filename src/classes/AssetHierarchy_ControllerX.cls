/*------------------------------------------------------------
Author:			Denise Bacher
Company:		Salesforce.com
Description:	Displays asset hierarchy for a specific account
Test Class:		AssetHierarchy_ControllerX_Test

History:
<Date>			<Authors Name>		<Brief Description of Change>
03/31/2016		Denise Bacher		Initial Creation (US539)
04/07/2016		Denise Bacher		Add support to work from Asset layout in addition to Account layout
04/27/2016		Denise Bacher		Updated to support both site and customer accounts (US762)
05/10/2016		Denise Bacher		Update popover to provide more detail (US958)
09/02/2016		Denise Bacher		Updated to group by Asset.Produc2.Division__c (REQ168)
------------------------------------------------------------*/
public with sharing class AssetHierarchy_ControllerX {
	private final Id assetSystemRecordTypeId = GlobalUtility.getRecordTypeId('Asset', 'System');
	private final Id assetNonHologicRecordTypeId = GlobalUtility.getRecordTypeId('Asset', 'Non_Hologic');
	
	@TestVisible private final Account accountObj; // account object from standard controller
	@TestVisible private final Asset assetObj;  // asset object from standard controller
	
	// List of ObjectNodes that display the asset hierarchy
	public List<ObjectNode> assetHierarchy{
		get{
			if(assetHierarchy == null){
				if(accountObj != null){
					assetHierarchy = populateAccountAssetHierarchy();
				}
				else if(assetObj != null){
					assetHierarchy = populateAssetHierarchy();
				}
				else{
					assetHierarchy = new List<ObjectNode>();
				}
			}
			return assetHierarchy;
		}
		private set;
	}
	
	// serialized string used on VF page to draw hierarchy
	public String jsonAssetHierarchy {
		get{
			return Json.serialize(assetHierarchy);
		}
		private set;
	}
	
	public List<Schema.FieldSetMember> popoverFields {
		get{
			if(popoverFields == null){
				popoverFields = SObjectType.Asset.FieldSets.Hierarchy_Popover.getFields();
			}
			return popoverFields;
		}
		private set;
	}
	
	public List<Asset> assets {get; private set;}
		
	
	/*------------------------------------------------------------
	Author:			Denise Bacher
	Company:		Salesforce.com
	Description:	Controller Extension constructor
	
	History:
	<Date>			<Authors Name>		<Brief Description of Change>
	03/31/2016		Denise Bacher		Initial Creation
	04/07/2016		Denise Bacher		Determine object currently being run from and set the correct object
	------------------------------------------------------------*/
	public AssetHierarchy_ControllerX(ApexPages.StandardController ctrl){
		Id primaryObjID = ctrl.getId();
       // system.debug(primaryObjID);
		assets = new List<Asset>();
		
		// if the primaryObjID isn't null (a new record is not being created) figure out what type of object we're currently on.
		if(primaryObjID != null){
			if(!Test.isRunningTest() && 'Asset' == String.valueOf(primaryObjID.getSobjectType())){
				ctrl.addFields(new List<String>{'ParentId', 'RecordTypeId'});
			}
			
			accountObj = 'Account' == String.valueOf(primaryObjID.getSobjectType()) ? (Account)ctrl.getRecord() : null;
            //system.debug('accountObj'+accountObj);
			assetObj = 'Asset' == String.valueOf(primaryObjID.getSobjectType()) ? (Asset)ctrl.getRecord() : null;
		}
	}
	
	/*------------------------------------------------------------
	Author:			Denise Bacher
	Company:		Salesforce.com
	Description:	Fetch the System and Component Assets for a given account 
	Returns:		List of ObjectNodes sorted by Asset Hologic Division, and Non-Hologic record type
	
	History:
	<Date>			<Authors Name>		<Brief Description of Change>
	03/31/2016		Denise Bacher		Initial Creation
	04/27/2016		Denise Bacher		Update asset query to look for assets related on either the Account or Customer_Account__c fields
	------------------------------------------------------------*/
	@TestVisible private List<ObjectNode> populateAccountAssetHierarchy(){
		List<ObjectNode> hierarchy = new List<ObjectNode>(); // list of objectNodes that represent the hierarchy
		Map<String, ObjectNode> objectNodeMap = new Map<String, ObjectNode>(); //map of string identifier to the object node so we can build our hierarchy
		Set<Id> systemAssetIds = new Set<Id>(); // set of system asset ids so we can query the child components
		
		try{
			String selectClause = 'Select Id, Name, SerialNumber, Product2.Division__c, ParentId, RecordTypeId ';
			for(Schema.FieldSetMember f : popoverFields){
				selectClause += !selectClause.contains(f.getFieldPath()) ? ', ' + f.getFieldPath() : '';
			}
			
			// query the top level assets
			String queryTop = selectClause + ' From Asset'
				+ ' Where (AccountId = \'' + accountObj.Id + '\' OR Customer_Account__c = \'' + accountObj.Id + '\')'
				+ ' And RecordTypeId IN (\'' + String.join(new List<ID>{assetSystemRecordTypeId, assetNonHologicRecordTypeId}, '\',\'')+ '\')'
				+ ' Order By RecordType.DeveloperName DESC, Product2.Division__c NULLS LAST, Name, SerialNumber'
				+ ' Limit 1000';
			//System.debug(queryTop);
				
			for(Asset a : Database.query(queryTop)){
				// create the new node
				ObjectNode newNode = new ObjectNode(a.Id, a.Name, 1, null, false, false, false);
				newNode.defaultCollapsed = true;
				
				// if this is a Non-Hologic asset, group it in the Non-Hologic category
				if(a.RecordTypeId == assetNonHologicRecordTypeId){
					if(!objectNodeMap.containsKey(assetNonHologicRecordTypeId)){
						ObjectNode nonHologicNode = new ObjectNode(null, GlobalUtility.getRecordTypeName('Asset', assetNonHologicRecordTypeId).toUpperCase(), 0, null, false, false, false);
						nonHologicNode.defaultCollapsed = true;
						objectNodeMap.put(assetNonHologicRecordTypeId, nonHologicNode);
						hierarchy.add(nonHologicNode);
					}
					objectNodeMap.get(assetNonHologicRecordTypeId).nodeChildren.add(newNode);
				}
				else{
					String divisionName = String.isNotBlank(a.Product2.Division__c) ? a.Product2.Division__c.toUpperCase() : 'UNKNOWN';
					
					if(!objectNodeMap.containsKey(divisionName)){
						ObjectNode divisionNode = new ObjectNode(null, divisionName, 0, null, false, false, false);
						divisionNode.defaultCollapsed = true;
						objectNodeMap.put(divisionName, divisionNode);
						hierarchy.add(divisionNode);
					}
					
					objectNodeMap.get(divisionName).nodeChildren.add(newNode);
					objectNodeMap.put(a.Id, newNode);
					systemAssetIds.add(a.Id);
				}
				
				assets.add(a);
			}
			
			// query the secondary level assets
			String querySecondary = selectClause + ' From Asset'
				+ ' Where ParentId IN (\'' + String.join(new List<ID>(systemAssetIds), '\',\'')+ '\')'
				+ ' Order By Name, SerialNumber'
				+ ' Limit 1000';
			//System.debug(querySecondary);
			
			for(Asset a : Database.query(querySecondary)){
				// create the new node
				ObjectNode newNode = new ObjectNode(a.Id, a.Name, 2, null, false, false, false);
				newNode.defaultCollapsed = true;
				objectNodeMap.get(a.ParentId).nodeChildren.add(newNode);
				
				assets.add(a);
			}
		}
		catch(Exception e){
			ApexPages.addMessages(e);
		}
		
		return hierarchy;
	}
	
	/*------------------------------------------------------------
	Author:			Denise Bacher
	Company:		Salesforce.com
	Description:	Fetch the System and Component hierarchy for a given Asset
					Given position in the hierarchy, will locate the System parent, and System's child Components 
	Returns:		List of ObjectNodes
	
	History:
	<Date>			<Authors Name>		<Brief Description of Change>
	04/07/2016		Denise Bacher		Initial Creation
	------------------------------------------------------------*/
	@TestVisible private List<ObjectNode> populateAssetHierarchy(){
		List<ObjectNode> hierarchy = new List<ObjectNode>(); // list of objectNodes that represent the hierarchy
		Map<String, ObjectNode> objectNodeMap = new Map<String, ObjectNode>(); //map of string identifier to the object node so we can build our hierarchy
		
		Id topAssetId;
		Asset topAsset;
		
		try{
			String selectClause = 'Select Id, ParentId, Name, SerialNumber';
			for(Schema.FieldSetMember f : popoverFields){
				selectClause += !selectClause.contains(f.getFieldPath()) ? ', ' + f.getFieldPath() : '';
			}
			
			// query for info on the current node
			String queryTopAsset = selectClause + ' From Asset'
				+ ' Where Id = \'' + (assetObj.ParentId != null ? assetObj.ParentId : assetObj.Id) + '\'';
			//System.debug(queryTopAsset);
			
			Asset initialAsset = Database.query(queryTopAsset);
					
			// create the top node
			ObjectNode topNode = new ObjectNode(initialAsset.Id, initialAsset.Name, 0, null, false, false, false);
			
			hierarchy.add(topNode);
			objectNodeMap.put(initialAsset.Id, topNode);
			assets.add(initialAsset);
			
			// query the secondary level assets
			String queryChildAsset = selectClause + ' From Asset'
				+ ' Where ParentId = \'' + initialAsset.Id + '\''
				+ ' Order By Name, SerialNumber'
				+ ' Limit 1000';
			//System.debug(queryChildAsset);
			
			for(Asset a : Database.query(queryChildAsset)){
				// create the new node
				ObjectNode newNode = new ObjectNode(a.Id, a.Name, 1, null, false, false, false);
				objectNodeMap.get(a.ParentId).nodeChildren.add(newNode);
				assets.add(a);
			}
		}
		catch(Exception e){
			ApexPages.addMessages(e);
		}
		
		return hierarchy;
	}
}