/*------------------------------------------------------------
Author:     Mani Sundaresan
Description:  Preventing Users from removing themselves from Surgical Marketing Chatter group
Test Class:   CollaborationGroupMemberTrigger_Test 

History:
<Date>      <Authors Name>    <Brief Description of Change>
08/28/2017  Mani Sundaresan    Initial Creation (US3322)

------------------------------------------------------------*/
public with sharing class CollaborationGroupMemberTriggerActions{

    /*------------------------------------------------------------
    Author:      Mani Sundaresan
    Description:  Prevent Surgical Marketing Chatter group members from being removed.
           Runs before delete
    Inputs:      collabGrpMembers - The list of old CollaborationGroupMembers records
                 oldcollabGrpMembers - Map of pervious CollaborationGroupMembers values
    Returns:    N/A
  
    History:
    <Date>      <Authors Name>    <Brief Description of Change>
    08/28/2017  Mani Sundaresan    Initial Creation (US3322)
  ------------------------------------------------------------*/
    public static void preventUserRemoval(List<CollaborationGroupMember> collabGrpMembers, Map<Id, CollaborationGroupMember> oldcollabGrpMembers){
    
        CollaborationGroup collabGroup = [SELECT Id, OwnerId from CollaborationGroup where CollaborationType='Public' AND Name LIKE 'Surgical Marketing%' LIMIT 1];
        Integer sysAdminCount = [SELECT Count() from User where Id = :userInfo.getUserId() AND Profile.Name LIKE 'System Administrator%'];
        
        for(CollaborationGroupMember member : collabGrpMembers){
            if(collabGroup.Id == member.CollaborationGroupId && member.CollaborationRole == 'Standard' && collabGroup.OwnerId != UserInfo.getUserId() && sysAdminCount == 0)
                member.addError('We are unable to process your request, please contact your Group Owner.');
        }
    }
}