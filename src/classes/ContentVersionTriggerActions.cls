/*------------------------------------------------------------
Author:		 	Dave Mansell
Company:		Salesforce.com
Description:	ContentVersion Trigger functions
Test Class:	 	ContentVersionTriggerActions_Test

History:
<Date>		  <Authors Name>	  	<Brief Description of Change>
06/20/2018	  Dave Mansell			Initial Creation (US-0004287)
------------------------------------------------------------*/
public class ContentVersionTriggerActions {
	
	private static final Integer EDIT_WINDOW_MS = 1000 * 60 * 60; //1 hour
	
	/*------------------------------------------------------------
	Author:         	Dave Mansell, Salesforce
	Description:    	Checks if parent record is case, if so, updates case summaries
	Inputs:         	List of records, Map of old records
	Returns:        	N/A
	Test Class(es):		ContentDocumentLinkTriggerActions_Test.testUpdateParentIfCase
	------------------------------------------------------------*/
	public static void updateParentIfCase(List<ContentVersion> cvs, Map<Id, ContentVersion> oldMap){
		List<ContentVersion> validCVs = new List<ContentVersion>();
		for(ContentVersion cv : cvs){
			ContentVersion old = oldMap.get(cv.Id);
			if(Datetime.now().getTime() - old.LastModifiedDate.getTime() > EDIT_WINDOW_MS){
				cv.addError('This note is too old to edit. Please create a new note.');
			} else {
				validCVs.add(cv);
			}
		}
		
		if(validCVs.size() > 0){
			updateParentIfCase(validCVs);
		}
	}
	
	/*------------------------------------------------------------
	Author:         	Dave Mansell, Salesforce
	Description:    	Checks if parent record is case, if so, updates case summaries
	Inputs:         	List of records
	Returns:        	N/A
	Test Class(es):		ContentDocumentLinkTriggerActions_Test.testUpdateParentIfCase
	------------------------------------------------------------*/
	public static void updateParentIfCase(List<ContentVersion> cvs){
		Map<Id, ContentVersion> cvsByCDId = new Map<Id, ContentVersion>();
		for(ContentVersion cv : cvs){
			cvsByCDId.put(cv.ContentDocumentId, cv);
		}
		
		Map<Id, ContentDocument> cdsById = new Map<Id, ContentDocument>([
			SELECT Id
				  ,(SELECT Id
				  		  ,LastModifiedDate
				  	  FROM ContentVersions
				  	 ORDER BY LastModifiedDate ASC
				  	 LIMIT 1
				   )
			  FROM ContentDocument
			 WHERE Id IN :cvsByCDId.keySet()
		]);
		
		Set<Id> validCDIds = new Set<Id>();
		for(ContentVersion cv : cvs){
			ContentVersion prev = cdsById.get(cv.ContentDocumentId).ContentVersions[0];
			if(Datetime.now().getTime() - prev.LastModifiedDate.getTime() > EDIT_WINDOW_MS){
				cv.addError('This note is too old to edit. Please create a new note.');
			} else {
				validCDIds.add(cv.ContentDocumentId);
			}
		}
		
		if(validCDIds.size() > 0){
			List<ContentDocumentLink> links = [
				SELECT Id
					  ,LinkedEntityId
				  FROM ContentDocumentLink
				 WHERE ContentDocumentId IN :validCDIds
			];
			
			ContentDocumentLinkTriggerActions.updateParentIfCase(links);
		}
	}
}