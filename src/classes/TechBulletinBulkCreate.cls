/*------------------------------------------------------------
Author:		 	John Christy
Company:		Apps Associates
Description:	Used to create many records of cases and asset tech bulletins for a tech bulletin
Test Class:	 	TechBulletinBulkCreate_Test

History:
<Date>			<Authors Name>	  <Brief Description of Change>
10/02/2017		John Christy		Initial Creation (US-0002058)
05/24/2018		Dave Mansell		Modified and cleaned up (US-0004157)
------------------------------------------------------------*/

public class TechBulletinBulkCreate {
	public static final Integer BATCH_COUNT = 100;
	
	public Id tbId					{get;set;}
	public String createType		{get;set;}
	public Integer remainingCount	{get;set;}
	
	public TechBulletinBulkCreate(){
		tbId = ApexPages.currentPage().getParameters().get('id');
		createType = ApexPages.currentPage().getParameters().get('createType');
		remainingCount = 0;
	}
	
	//Determine which method to run and assign tech bulletin
	public void determineCreateType(){
		//Call method depending on createType: WorkOrder or Asset
		if(createType == 'workorder'){
			createWorkOrders();
		} else if (createType == 'asset'){
			createAssetTechBulletins();
		}
	}
	
	//Create WorkOrders for all tech bulletins that do not have a current Work Order assigned
	private void createWorkOrders(){
		//Query for ATBs without WO assigned
		Map<Id, Asset_Tech_Bulletin__c> atbsById = new Map<Id, Asset_Tech_Bulletin__c>([
			SELECT Id
				  ,Asset__c
				  ,Asset__r.AccountId
				  ,Asset__r.Ship_To_Location__c
				  ,Asset__r.Status
				  ,Tech_Bulletin__c
				  ,Tech_Bulletin__r.Subject__c
			  FROM Asset_Tech_Bulletin__c 
			 WHERE Tech_Bulletin__c = :tbId
			   AND Work_Order__c = null
			 LIMIT :BATCH_COUNT
		]);
		
		if(atbsById.isEmpty()){
		    //Display success message
			ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.WARNING, 'All needed work order records have already been created.');
			ApexPages.addMessage(myMsg);
		} else {
			//Create list of WorkOrders to be inserted
			Map<Id, WorkOrder> wosByATBId = new Map<Id, WorkOrder>();
			
			//Create WO for each ATB
			Id techBulletinRTId = GlobalUtility.getRecordTypeId('WorkOrder', 'Tech_Bulletin');
			List<WorkType> workTypes = [SELECT Id FROM WorkType WHERE Name = 'Tech Bulletin'];
			for(Asset_Tech_Bulletin__c atb : atbsById.values()){
				WorkOrder wo = new WorkOrder();
				
				wo.Asset_Tech_Bulletin__c		= atb.Id;
				wo.AccountId 					= atb.Asset__r.AccountId;
				wo.AssetId						= atb.Asset__c;
				wo.Description					= 'Tech Bulletin - ' + atb.Tech_Bulletin__r.Subject__c;
				wo.New_Install_Location__c		= atb.Asset__r.Ship_To_Location__c;
				wo.Priority						= 'Sev 3';
				wo.RecordTypeId					= techBulletinRTId;
				wo.Status						= 'New';
				wo.Subject						= 'Tech Bulletin - ' + atb.Tech_Bulletin__r.Subject__c;
				wo.Type__c						= 'Upgrade';
				if(workTypes.size() > 0){
					wo.WorkTypeId = workTypes[0].Id;
				}
				
				wosByATBId.put(atb.Id, wo);
			}
			
			try {
				insert wosByATBId.values();
			
				//Update AssetTechBulletins with new WorkOrder Ids
				for(Id atbId : atbsById.keySet()){
					Asset_Tech_Bulletin__c atb = atbsById.get(atbId);
					WorkOrder wo = wosByATBId.get(atbId);
					
					atb.Work_Order__c = wo.Id;
				}
				update atbsById.values();
				
				remainingCount = [
					SELECT COUNT()
					  FROM Asset_Tech_Bulletin__c
					 WHERE Tech_Bulletin__c = :tbId
					   AND Work_Order__c = null
				];
				if(remainingCount > 0){
					ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.WARNING, BATCH_COUNT + ' work orders were created. ' + remainingCount + ' must still be created. Please click "Create More" below to continue.');
					ApexPages.addMessage(myMsg);
				} else {
					ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.CONFIRM, 'Work Order Creation Successful');
					ApexPages.addMessage(myMsg);
					
				}
			}
			catch(Exception ex){
				ApexPages.addMessages(ex);
			}
		}
	}
	
	//Creates asset tech bulletins for all assets of current tech bulletin product
	private void createAssetTechBulletins(){
		Tech_Bulletin__c tb = [
			SELECT Id
				  ,Product__c
				  ,Serial_Number_Start__c
				  ,Serial_Number_End__c
			  FROM Tech_Bulletin__c
			 WHERE Id = :tbId
		];
		
		//Build list of all assets based on product
		List<Asset> assets;
		if(tb.Serial_Number_Start__c != null && tb.Serial_Number_End__c != null){
			assets = [
				SELECT Id
				  FROM Asset
				 WHERE Product2Id = :tb.Product__c
				   AND SerialNumber >= :tb.Serial_Number_Start__c
				   AND SerialNumber <= :tb.Serial_Number_End__c
				   AND Id NOT IN (SELECT Asset__c
				   					FROM Asset_Tech_Bulletin__c
				   				   WHERE Tech_Bulletin__c = :tbId)
				   AND (Status = 'Installed' OR Status = 'SAN-ASSET' OR Status = 'MAR-ASSET')
			];
		} else {
			assets = [
				SELECT Id
				  FROM Asset
				 WHERE Product2Id = :tb.Product__c
				   AND Id NOT IN (SELECT Asset__c
				   					FROM Asset_Tech_Bulletin__c
				   				   WHERE Tech_Bulletin__c = :tbId)
				   AND (Status = 'Installed' OR Status = 'SAN-ASSET' OR Status = 'MAR-ASSET')
			];
		}
		
		//Create a new asset tech bulletin for each asset if one doesn't exist
		List<Asset_Tech_Bulletin__c> atbs = new List<Asset_Tech_Bulletin__c>();
		for(Asset asst : assets){
			Asset_Tech_Bulletin__c atb = new Asset_Tech_Bulletin__c();
			atb.Tech_Bulletin__c = tbId;
			atb.Asset__c = asst.Id;
			atb.Status__c = 'Open';
			atbs.add(atb);
		}
		
		try{
			insert atbs;
			
			//Display success message
			ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.CONFIRM, 'Asset Tech Bulletins Creation Successful');
			ApexPages.addMessage(myMsg);
		}
		catch(Exception ex){
			ApexPages.addMessages(ex);
		}
	}
	
	//Return user to tech bulletin
	public PageReference redirect(){
		PageReference pageRef = new PageReference('/' + tbId);
		return pageRef.setRedirect(true);
	}
}