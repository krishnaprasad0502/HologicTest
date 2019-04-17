/*******************************************************************************************
    Author       : Nikhil Mutyam
    Company      : Hexaware Technologies
    Created Date : 11/1/2018 4:06 AM
    Description  : Create Account Share records
    Test Class   : Test_UserTriggerActions    
    Coverage     : 100% 

    History:
    <Date>          <Author Name>           <Brief Description of Change>   <Copa.do US#>
    8/28/2018       Nikhil Mutyam           Initial Creation                US-0006043 
    11/13/2018       Niraj Wani           updated code for defect fix        US-0006075
    11/15/2018      Niraj Wani              Change to make future call to 
                                            avoid mixed DML operations      US-0006167
*******************************************************************************************/

public without sharing class UpdateSharingController {
    /*
     * Method Name: CreateSharingforL2()
     * Input Param: List of users to be inserted
     * Return: void 
     * Description: Helps in creating Account share records, The mapping is done between L3 Contact's User and L2 Account.
     */
    
    /*
    public static void CreateSharingforL2(list<User> usersToBeInserted){
        system.debug('The users to be inserted are: '+usersToBeInserted);
        list<AccountShare> shareListToBeInserted = new list<AccountShare>();
        set<Id> ContactIds = new set<Id>();
        list<Contact> associatedContacts = new list<Contact>();
        map<Id,Id> contactL2AccountMap = new map<Id,Id>();
        
        for(User usr : usersToBeInserted){
            system.debug('The user type is: '+usr.UserType);
            if(usr.ContactId != Null && usr.UserType == Label.Community_User_Type){
                ContactIds.add(usr.ContactId);
            }
        }
        system.debug('The Contact Ids are: '+ContactIds);
        
        if(ContactIds != Null && ContactIds.size() > 0){
            associatedContacts = [SELECT Id, AccountId, Account.ParentId FROM Contact WHERE Id IN: ContactIds];
        }
        system.debug('The associatedContacts are: '+ContactIds);
        
        if(associatedContacts != Null && associatedContacts.size() > 0){
            for(Contact cnt : associatedContacts){
                if(cnt.AccountId != Null && cnt.Account.ParentId != Null){
                    contactL2AccountMap.put(cnt.Id,cnt.Account.ParentId);
                }    
            }
        }
        system.debug('The contactL2AccountMap are: '+contactL2AccountMap);
        
        if(contactL2AccountMap != Null && contactL2AccountMap.size() > 0){
            system.debug('The contactL2AccountMap are2: '+contactL2AccountMap);
            for(User usr : usersToBeInserted){
                system.debug('The user is: '+usr);
                system.debug('The user type is: '+Label.Community_User_Type);
                if(usr.ContactId != Null && usr.UserType == Label.Community_User_Type && contactL2AccountMap.get(usr.ContactId) != Null){
                    AccountShare aShare = new AccountShare();
                    aShare.AccountId = contactL2AccountMap.get(usr.ContactId);
                    aShare.UserOrGroupId = usr.Id;
                    aShare.AccountAccessLevel = 'Read';
                    aShare.CaseAccessLevel = 'None';
                    aShare.OpportunityAccessLevel = 'None';
                    shareListToBeInserted.add(aShare);
                }
            }
        }
        system.debug('The shareListToBeInserted are: '+shareListToBeInserted);
        if(shareListToBeInserted != Null && shareListToBeInserted.size() > 0){
            insert shareListToBeInserted;
        }
        system.debug('The inserted Share List: '+shareListToBeInserted);
    } */ 
    
    @future
    public static void CreateSharingforL2(List<Id> usersIds){
        List<User> usersToBeInserted = new List<User>();
        usersToBeInserted = [SELECT Id,ContactId,UserType FROM User WHERE Id IN :usersIds ];
        system.debug('The users to be inserted are: '+usersToBeInserted);
        list<AccountShare> shareListToBeInserted = new list<AccountShare>();
        set<Id> ContactIds = new set<Id>();
        list<Contact> associatedContacts = new list<Contact>();
        map<Id,Id> contactL2AccountMap = new map<Id,Id>();
        
        for(User usr : usersToBeInserted){
            system.debug('The user type is: '+usr.UserType);
            if(usr.ContactId != Null && usr.UserType == Label.Community_User_Type){
                ContactIds.add(usr.ContactId);
            }
        }
        system.debug('The Contact Ids are: '+ContactIds);
        
        if(ContactIds != Null && ContactIds.size() > 0){
            associatedContacts = [SELECT Id, AccountId, Account.ParentId FROM Contact WHERE Id IN: ContactIds];
        }
        system.debug('The associatedContacts are: '+ContactIds);
        
        if(associatedContacts != Null && associatedContacts.size() > 0){
            for(Contact cnt : associatedContacts){
                if(cnt.AccountId != Null && cnt.Account.ParentId != Null){
                    contactL2AccountMap.put(cnt.Id,cnt.Account.ParentId);
                }    
            }
        }
        system.debug('The contactL2AccountMap are: '+contactL2AccountMap);
        
        if(contactL2AccountMap != Null && contactL2AccountMap.size() > 0){
            system.debug('The contactL2AccountMap are2: '+contactL2AccountMap);
            for(User usr : usersToBeInserted){
                system.debug('The user is: '+usr);
                system.debug('The user type is: '+Label.Community_User_Type);
                if(usr.ContactId != Null && usr.UserType == Label.Community_User_Type && contactL2AccountMap.get(usr.ContactId) != Null){
                    AccountShare aShare = new AccountShare();
                    aShare.AccountId = contactL2AccountMap.get(usr.ContactId);
                    aShare.UserOrGroupId = usr.Id;
                    aShare.AccountAccessLevel = 'Read';
                    aShare.CaseAccessLevel = 'None';
                    aShare.OpportunityAccessLevel = 'None';
                    shareListToBeInserted.add(aShare);
                }
            }
        }
        system.debug('The shareListToBeInserted are: '+shareListToBeInserted);
        if(shareListToBeInserted != Null && shareListToBeInserted.size() > 0){
            insert shareListToBeInserted;
        }
        system.debug('The inserted Share List: '+shareListToBeInserted);
    }  
}