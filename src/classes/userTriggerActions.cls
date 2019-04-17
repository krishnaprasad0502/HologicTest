/*------------------------------------------------------------------------------------------------------------
Author:     Mani Sundaresan
Description:  Trigger framework for User object
Test Class:    Test_UserTrigger

History:
<Date>      <Authors Name>    <Brief Description of Change>
02/10/2017  Mani Sundaresan    Initial Creation
------------------------------------------------------------------------------------------------------------*/
public with sharing class userTriggerActions{

    //Updates the delegates field on Work Order when the Owner is changed
    public static void updateDelegateOnWorkOrders(List<User> newUserList, Map<Id, User> oldUserMap){
        //Variable Declaration Section
        List<WorkOrder> woList = new List<WorkOrder>();
        Map<Id,Id> delegateIds = new Map<Id,Id>();
        List<WorkOrder> updateWOList = new List<WorkOrder>();
        
        //Collects the new delegate userId
        for(User u : newUserList){
            if(u.DelegatedApproverId != oldUserMap.get(u.Id).DelegatedApproverId){
                delegateIds.put(u.Id,u.DelegatedApproverId);
            }
        }
        
        System.debug('DelegatesId:'+delegateIds);
        System.debug('woList query:'+[SELECT Id, Status, Submitted_for_Approval__c from WorkOrder where District_Service_Manager__c IN :delegateIds.keySet()]);
        
        //SOQL to get the Work Order field values based on the new Owner Id
        if(delegateIds != null){
            woList = [SELECT Id, DSM_Delegate__c, Zone_Director_Delegate__c, Zone_Director__c, District_Service_Manager__c from WorkOrder where (District_Service_Manager__c IN :delegateIds.keySet() OR Zone_Director__c IN :delegateIds.keySet()) AND Status != 'Closed' AND Status != 'Cancelled' AND Status != 'Deferred' AND Submitted_for_Approval__c = False];    
        }
        
        System.debug('woList:'+woList);
        System.debug('woList size:'+woList.size());
        
        //Logic to assign the delegate based on the new DSM/Zone Director
        if(woList.size() > 0){
            for(WorkOrder wo : woList){
                for(Id userId : delegateIds.keySet()){
                    if(wo.District_Service_Manager__c == userId)
                            wo.DSM_Delegate__c = delegateIds.get(userId);
                        if(wo.Zone_Director__c == userId)
                            wo.Zone_Director_Delegate__c = delegateIds.get(userId);
                        
                        updateWOList.add(wo);
                }
            }
            
            System.debug('updateWOList:'+updateWOList);
            System.debug('updateWOList size:'+updateWOList.size());
            
            try{
            if(updateWOList.size() > 0)
                update updateWOList;
            }
            catch(Exception e){
                System.debug('Unable to update the Work Order:'+e.getMessage());
            }
        }
    }    
}