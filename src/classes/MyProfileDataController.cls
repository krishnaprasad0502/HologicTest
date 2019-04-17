public with sharing class MyProfileDataController {
    
    //Wrapper class
    public class wrapProfData{
        @AuraEnabled public Profile_Data__c profData {get; set;}
        @AuraEnabled public Boolean selected {get; set;}
        
        public wrapProfData(Profile_Data__c pd){
            profData = pd;
            selected = false;
        }
    }
    
    //Query all profile data records owned by the logged-in user
    @AuraEnabled
    public static List<wrapProfData> findAll(){
        List<wrapProfData> profDataWrapperList = new List<wrapProfData>();
        for(Profile_Data__c pd : [SELECT Id, Name, Profile__c, Profile__r.Name, Account_Site__c, Account_Site__r.Name, Account__c, Account__r.Name from Profile_Data__c where OwnerId = :UserInfo.getUserId() and Profile__c != null and 	Profile__r.Active__c = true]){
            profDataWrapperList.add(new wrapProfData(pd));
        }
        System.debug('profDataWrapperList:'+profDataWrapperList);
        return profDataWrapperList;
    }
    
}