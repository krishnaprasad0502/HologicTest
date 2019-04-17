/*--------------------------------------------------------------------
Author:     Mani Sundaresan
Description:  Trigger framework for User object
Test Class:   Test_UserTrigger

History:
<Date>         <Author Name>   <Brief Description of Change>     							<Copa.do US#>
02/10/2017  Mani Sundaresan    Initial Creation
22/10/2018  Nikhil Mutyam      This modification to after trigger should help L3 Contact/User 
							   to access L2 Account related Assets 
11/15/2018      Niraj Wani     Change to make future call to avoid mixed DML operations      US-0006167
-------------------------------------------------------------------------*/
trigger userTrigger on User (before insert, before update, after insert, after update, before delete, after delete) {
	
    private static Boolean isActive = GlobalUtility.isTriggerActive('UserTrigger');
    
    if(isActive){
        if(Trigger.isBefore){
            if(Trigger.isInsert){
            }
            if(Trigger.isUpdate){
                //Updates the delegates field on WO whenever the Owner is changed
                userTriggerActions.updateDelegateOnWorkOrders((List<User>) Trigger.New, Trigger.oldMap);
            }
        }
        if(Trigger.isAfter){
            if(Trigger.isInsert){
                system.debug('You are in after insert');
                system.debug(trigger.new);
                //Prepare list of Ids
                List<Id> userIds = new List<Id>();
                for (User usr: trigger.new){
                    userIds.add(usr.Id);
                }
                UpdateSharingController.CreateSharingforL2(userIds);
                
               // UpdateSharingController.CreateSharingforL2(trigger.new);
            }
            if(Trigger.isUpdate){
                
            }
        }
    } 
}