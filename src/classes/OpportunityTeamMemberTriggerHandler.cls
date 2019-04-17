/*------------------------------------------------------------
Author:     Dinesh Mummidi
Description:  Trigger framework for Opportunity Memeber to Opportunity split
Test Class:    OpportunityTeamMemberTriggerHandler_Test

06/16/2018  Dinesh Mummidi   Initial Creation (US-4457)
06/16/2018  Dinesh Mummidi   For only RecordType 'Medical Aesthetics Capital Sales Opportunity' this functionality works
06/16/2018  Dinesh Mummidi   List of OpportunityTeamMember user is selected for Record type 'Medical Aesthetics Capital Sales Opportunity'
06/16/2018  Dinesh Mummidi   Add OpportunityTeamMember than OpportunitySplit added 
07/01/2018  Dinesh Mummidi   Based on the result of insert, update DML Operation returned by a Database Method.

---------------------------------------------------------------*/

public class OpportunityTeamMemberTriggerHandler {


    public static void createOpportunitySplit(List<OpportunityTeamMember> opptyTMList, Map<Id, OpportunityTeamMember> oldOpptyTMMap){
    
        Id medAesOpptyRT = GlobalUtility.getRecordTypeId('Opportunity', 'Medical_Aesthetics_Capital_Sales_Opportunity');
        List<Id> opptyIdList = new List<Id>();
        List<OpportunitySplit> opptySplitList = new List<OpportunitySplit>();
        OpportunitySplitType opptySplitType = [SELECT Id, DeveloperName, MasterLabel, IsActive FROM OpportunitySplitType where MasterLabel = 'Revenue' and isActive = true limit 1];
        Map<Id,Opportunity> opptyMap; 
        
        for(OpportunityTeamMember otm : opptyTMList)
            opptyIdList.add(otm.OpportunityId);
        
        if(opptyIdList.size() > 0)
            opptyMap = new Map<Id, Opportunity>([SELECT Id, RecordTypeId from Opportunity where Id IN :opptyIdList and RecordTypeId = :medAesOpptyRT]);
            
        if(opptyMap.size() > 0){
            for(OpportunityTeamMember otm : opptyTMList){
                if(opptyMap.get(otm.OpportunityId) != null){
                    OpportunitySplit rec = new OpportunitySplit();
                    rec.SplitOwnerId = otm.UserId;
                    rec.OpportunityId = opptyMap.get(otm.OpportunityId).Id;
                    rec.SplitPercentage = 0;
                    if(opptySplitType != null){
                        rec.SplitTypeId = opptySplitType.Id;
                    }
                    opptySplitList.add(rec);
                }
            }
        }
        
        if(opptySplitList.size() > 0){
            Database.SaveResult[] srList = Database.insert(opptySplitList);

                for (Database.SaveResult sr : srList) {
                    if (!sr.isSuccess()) {
                        for(Database.Error err : sr.getErrors()) {
                            string errorMsg = 'The following error has occurred.'+err.getStatusCode() + ': ' + err.getMessage();
                        }
                    }
                }
        }
    }
}