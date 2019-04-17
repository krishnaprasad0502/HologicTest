/*------------------------------------------------------------
Author:    Mani Sundaresan
Description:  Test class to validate CollaborationGroupMemberTrigger
        Tests Excecuted:
        
        removeUser - verify that on removal of a user from Surgical Marketing chatter group, an error message is displayed 
        
History:
<Date>      <Authors Name>    <Brief Description of Change>
08/28/2017   Mani Sundaresan   Initial Creation (US3322)
------------------------------------------------------------*/
@isTest
private class CollaborationGroupMemberTrigger_Test{

    static testMethod void removeUser(){
    
        TestUtility.insertCustSetting('CollaborationGroupMemberTrigger');   
        
        //Create the chatter group
        CollaborationGroup cg = new CollaborationGroup(CollaborationType = 'Public', Description='Test Chatter Group', Name='Surgical Marketing Test', OwnerId=userInfo.getUserId());
        
        insert cg;
        
        //create chatter group members and add it to the above created group
        Profile p = [SELECT Id FROM Profile WHERE Name='Corporate System Administrator'];
        List<User> userList = new List<User>();
        List<CollaborationGroupMember> cgmList = new List<CollaborationGroupMember>();
        
        User testUser1 = TestUtility.newUser(p.Id,'User1');
        insert testUser1;
        
        User testUser2 = TestUtility.newUser(p.Id,'User2');
        insert testUser2;
        
       
        CollaborationGroupMember cgm = new CollaborationGroupMember(CollaborationGroupId = cg.Id, CollaborationRole= 'Standard', MemberId=testUser1.Id);
        cgmList.add(cgm);
        
        CollaborationGroupMember cgm1 = new CollaborationGroupMember(CollaborationGroupId = cg.Id, CollaborationRole= 'Standard', MemberId=testUser2.Id);
        cgmList.add(cgm1);
        
        insert cgmList;
        
        System.runAs(testUser1){
        
            try{
                delete cgm;
            }
            catch(DMLException e){
                System.assert(e.getMessage().contains('We are unable to process your request, please contact your Group Owner'),e.getMessage());
            }
         
        }
      
    }

}