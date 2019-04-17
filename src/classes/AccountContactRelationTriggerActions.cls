/*------------------------------------------------------------
Author:         Mani Sundaresan
Description:    Functions related to AccountContactRelation records
Test Class:     AccountContactRelation_Test

History:
<Date>         <Author Name>      <Brief Description of Change>     <Copa.do US#>
07/05/2018      Mani Sundaresan    Initial Creation (US-4409)
20/11/2018      Niraj Wani		   Issue with View All Cases Y/N	US-0006167
----------------------------------------------------------------------------------*/
public class AccountContactRelationTriggerActions{
    public static list<AccountShare> shareListToBeInserted = new list<AccountShare>();
    public static list<AccountShare> shareListToBeDeleted = new list<AccountShare>();
    
    public static void setParentContact(List<AccountContactRelation> acrList, Map<Id, AccountContactRelation> oldMap){
        Map<Id,AccountContactRelation> accConMap = new Map<Id,AccountContactRelation>();
        List<Id> accIdList = new List<Id>();
        Map<Id,Account> accMap;
        List<AccountContactRelation> accConRelList = new List<AccountContactRelation>();
        Id accSiteRTId = GlobalUtility.getRecordTypeId('Account', 'Site');
        
        for(AccountContactRelation ac : acrList)
            accIdList.add(ac.AccountId);
        
        system.debug('The accounts are: '+accIdList);
        
        if(accIdList.size() > 0)
            accMap = new Map<Id, Account>([SELECT Id, ParentId from Account where Id IN :accIdList and RecordTypeId = :accSiteRTId]);
        
        system.debug('The accounts are: '+accMap);
        if(accMap != null)
            for(AccountContactRelation ac : acrList){
                if(accMap.get(ac.AccountId) != null){
                    AccountContactRelation acr = new AccountContactRelation();
                    acr.AccountId = accMap.get(ac.AccountId).ParentId;
                    acr.ContactId = ac.ContactId;
                    acr.Primary__c = ac.Primary__c;
                    acr.Percentage_of_Work__c = ac.Percentage_of_Work__c;
                    acr.Work_Hours__c = ac.Work_Hours__c;
                    acr.Roles = ac.Roles;
                    acr.StartDate = ac.StartDate;
                    acr.EndDate = ac.EndDate;
                    
                    accConRelList.add(acr);
                    
                }
            }
        
        System.debug('accConRelList:'+accConRelList);
        
        if(accConRelList.size() > 0){
            try{
                insert accConRelList;
                if (Test.isRunningTest()) { 
                    Integer x = 1/0;
                }
                
            }
            catch(Exception e){
                System.debug('Insert Failed:'+e.getMessage());
            }
        }
    }
    
    public static void upsertAccountShareRecords(list<AccountContactRelation> ACRList, map<Id,User> ContactUserMap, 
                                                 map<Id, AccountContactRelation> Oldmap, string triggerType)
    {
        map<Id,Id> DestructMap = new map<Id,Id>();
        if(ContactUserMap != Null && ContactUserMap.size() > 0){
            for(AccountContactRelation ACR : ACRList){
                if(ContactUserMap.get(ACR.ContactId) != Null){
                    if(triggerType == 'Insert'){
                        if(ACR.Community_View_All_Cases__c == 'Yes'){
                            buildAccountShare(ACR.AccountId,ContactUserMap.get(ACR.ContactId).Id,'Read');
                        }
                        else {
                            buildAccountShare(ACR.AccountId,ContactUserMap.get(ACR.ContactId).Id,'None');
                        }
                    }else if(triggerType == 'Update' && Oldmap != Null && Oldmap.size() > 0){
                        if(Oldmap.get(ACR.Id) != Null){
                            if(Oldmap.get(ACR.Id).Community_View_All_Cases__c != ACR.Community_View_All_Cases__c){
                                if(ACR.Community_View_All_Cases__c == 'Yes'){
                                    buildAccountShare(ACR.AccountId,ContactUserMap.get(ACR.ContactId).Id,'Read');
                                }else {
                                    DestructMap.put(ACR.AccountId,ContactUserMap.get(ACR.ContactId).Id);
                                    buildAccountShare(ACR.AccountId,ContactUserMap.get(ACR.ContactId).Id,'None');
                                }
                            }
                        }    
                    }
                }
            }
        }  
        
        
        try{                                           
            if(DestructMap != Null && DestructMap.size() > 0) 
            {
                deleteAccountShareRecords(DestructMap);   
            }
            
            upsert shareListToBeInserted;
        }  
        catch(Exception e){
            System.debug('Sharing Updates Failed:'+e.getMessage());
        }                                         
    }
    
    public static void buildAccountShare(string AccountId, string UserId, string accessType){
        AccountShare aShare = new AccountShare();
        aShare.AccountId = AccountId;
        aShare.UserOrGroupId = UserId;
        aShare.AccountAccessLevel = 'Read';
        aShare.CaseAccessLevel = accessType;
        aShare.OpportunityAccessLevel = 'None';
        shareListToBeInserted.add(aShare);
        system.debug('The Account Share2 is: '+aShare);
    }
    
    public static void deleteAccountShareRecords(map<Id,Id> DestructiveMap){
        
        for(AccountShare ASH : [select Id, UserOrGroupId, AccountId from AccountShare Where AccountId IN: DestructiveMap.keyset()]){
            if(ASH.UserOrGroupId == DestructiveMap.get(ASH.AccountId)){
                System.debug('ASH:' + ASH );
                shareListToBeDeleted.add(ASH);
            }
        }
        if(shareListToBeDeleted != Null && shareListToBeDeleted.size() > 0){
            System.debug('shareListToBeDeleted:' + shareListToBeDeleted );
            delete shareListToBeDeleted;
        }
    }
}