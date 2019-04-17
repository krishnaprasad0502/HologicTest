/*------------------------------------------------------------
Author:     Mani Sundaresan
Description:  Trigger framework for the AccountContactRelation object

History:
<Date>         <Author Name>      <Brief Description of Change>     <Copa.do US#>
07/05/2018  Mani Sundaresan   Initial Creation (US-4409)
11/13/2018   Nikhil Mutyam    Updated sharing logic US-0006062, US-0006075
11/19/2018  Niraj Wani        addError when case exists             US-0006167
------------------------------------------------------------*/
trigger AccountContactRelationTrigger on AccountContactRelation (before insert, before update, before delete, after insert, after update, after undelete) {

    private static Boolean isActive = GlobalUtility.isTriggerActive('AccountContactRelationTrigger');
    map<Id,User> ContactUserMap = new map<Id,User>();
    set<Id> ContactIds = new set<Id>();
    set<Id> AccountIds = new set<Id>();
    map<Id,Id> DestructMap = new map<Id,Id>();
    Id cntId;
    Id actId;
    //map<Id,AccountContactRelation> ACRMap = new map<Id,AccountContactRelation>();
    
    if(Trigger.isBefore && isActive){
        if(Trigger.isInsert){
            AccountContactRelationTriggerActions.setParentContact(Trigger.New, null);    
        }
        if(Trigger.isUpdate){}
        if(Trigger.isDelete){
            for(AccountContactRelation ACR : trigger.old){
                ContactIds.add(ACR.ContactId);
                AccountIds.add(ACR.AccountId);
            }
            
            AggregateResult[] groupedResults = [SELECT ContactId,AccountId, Count(Id)
                                              FROM Case
                                              WHERE ContactId IN: ContactIds AND AccountId IN: AccountIds
                                              GROUP BY ContactId,AccountId];
            for (AggregateResult ar : groupedResults)  {
                for(AccountContactRelation ACR : trigger.old){
                    if (ACR.ContactId == ar.get('ContactId') && ACR.AccountId== ar.get('AccountId'))
                        ACR.addError(System.Label.RelationshipDeleteValidation);
                } 
            }
            
            if(ContactIds != Null && ContactIds.size() > 0){
                for(User usr : [SELECT Id,ContactId FROM User WHERE ContactId IN: ContactIds]){
                    ContactUserMap.put(usr.ContactId,usr);
                }
            }
            if(ContactUserMap != Null && ContactUserMap.size() > 0){ 
                for(AccountContactRelation ACR : trigger.old){
                    DestructMap.put(ACR.AccountId,ContactUserMap.get(ACR.ContactId).Id);
                    //ACRMap.put(ACR.AccountId, ACR);
                }
            }
            
            if(DestructMap != Null && DestructMap.size() > 0){
                    AccountContactRelationTriggerActions.deleteAccountShareRecords(DestructMap);
            }
        }
    }
    if(Trigger.isAfter && isActive){
        system.debug('You are here');
        if(Trigger.isInsert || Trigger.isUpdate){
            //After Insert
            if(Trigger.isInsert){
                for(AccountContactRelation ACR : trigger.new){
                    //if(ACR.Community_View_All_Cases__c == 'Yes'){
                        ContactIds.add(ACR.ContactId);
                    //}    
                }
            }
            
            //After Update
            if(Trigger.isUpdate){
                for(AccountContactRelation ACR : trigger.new){
                    if(trigger.oldmap.get(ACR.Id).Community_View_All_Cases__c != ACR.Community_View_All_Cases__c){
                        ContactIds.add(ACR.ContactId);
                    }    
                }
            }
            system.debug('The contact Ids are: '+ContactIds);
            
            if(ContactIds != Null && ContactIds.size() > 0){
                for(User usr : [SELECT Id,ContactId FROM User WHERE ContactId IN: ContactIds]){
                    ContactUserMap.put(usr.ContactId,usr);
                }
            }
            system.debug('The contact user map contains: '+ContactUserMap);
            if(trigger.isInsert){
                AccountContactRelationTriggerActions.upsertAccountShareRecords(trigger.new,ContactUserMap,null,'Insert');
            }else if(trigger.isUpdate){
                AccountContactRelationTriggerActions.upsertAccountShareRecords(trigger.new,ContactUserMap,trigger.oldMap,'Update');
            }    
        }
        if(Trigger.isUndelete){}
    }
}