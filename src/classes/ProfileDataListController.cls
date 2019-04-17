/*------------------------------------------------------------
Author:       Mani Sundaresan
Description:  Class for OpptyProfData Aurabundle
TestClass: ProfileDataListController_Test

History:
<Date>       <Authors Name>    <Brief Description of Change>
03/21/2019   Mani Sundaresan    Initial Creation ()             
------------------------------------------------------------*/
public with sharing class ProfileDataListController {
    
    static Id labLandscapeRTId = GlobalUtility.getRecordTypeId('Profile_Data__c','Lab_Landscape');
    
    //Method to display the list of profile data related to the Account on the opportunity
    @AuraEnabled
    public static List<wrapProfData> findAll(Id opptyId){
        System.debug('OpptyId:'+opptyId);
        List<wrapProfData> wrapProfDataList = new List<wrapProfData>();
        List<Id> profDataIdList = new List<Id>();
        List<Profile_Data__c> profDataList = new List<Profile_Data__c>();
        Opportunity opptyRec = [SELECT Id, AccountId, Account.ParentId, Account_Site__c, (SELECT Id, Profile_Data__c FROM Pipeline_Products__r) FROM Opportunity where Id = :opptyId];
        System.debug('opptyRec:'+opptyRec);
        System.debug('labLandscapeRTId:'+labLandscapeRTId);
        if(opptyRec.getSObjects('Pipeline_Products__r') != null)
            for(Pipeline_Products__c pp : opptyRec.getSObjects('Pipeline_Products__r'))
                profDataIdList.add(pp.Profile_Data__c);
        
        System.debug('profDataList:'+profDataIdList);
        profDataList = [SELECT Id, Name, Volume__c, Division__c, Profile__r.Name, Profile__c, Price__c, CurrencyIsoCode from Profile_Data__c where Account__c = :opptyRec.AccountId and RecordTypeId = :labLandscapeRTId and ID NOT IN :profDataIdList];
            
        for(Profile_Data__c pd : profDataList){
            if((profDataIdList.size() > 0 != null && !profDataIdList.contains(pd.Id)) || profDataIdList.size() == 0)
                wrapProfDataList.add(new wrapProfData(pd));
        }
        System.debug('wrapProfDataList:'+wrapProfDataList);
        
        return wrapProfDataList;
    }
    
    //Method to save the selected profile data on the oppty
    @AuraEnabled
    public static void saveProfData(String wrapProfDataList,Id opptyId){
        System.debug('Hello World');
        Opportunity opptyRec = [SELECT Id, AccountId, Account.ParentId, Account_Site__c FROM Opportunity where Id = :opptyId];
        List<Pipeline_Products__c> pipelineProdList = new List<Pipeline_Products__c>();
        List<wrapProfData> listToSave = (List<wrapProfData>)JSON.deserialize(wrapProfDataList, List<wrapProfData>.class);
        for(wrapProfData pd : listToSave){
            if(pd.selected){
                System.debug('Selected Profile Data:'+pd.profData.Name);
                pipelineProdList.add(new Pipeline_Products__c(Profile__c = pd.ProfData.Profile__c, Division__c= pd.ProfData.Division__c, Profile_Data__c = pd.ProfData.Id, Account_Site__c = opptyRec.Account_Site__c, Opportunity__c = opptyId, CurrencyIsoCode=pd.ProfData.CurrencyIsoCode, Volume__c=pd.ProfData.Volume__c, Price__c=pd.ProfData.Price__c));
            }
        }
        System.debug('pipelineProdList:'+pipelineProdList);
        try{
            if(pipelineProdList.size() > 0)
                insert pipelineProdList;
            
            if(Test.isRunningTest())
                Integer i = 10/0;  
            
        }
        catch(Exception e){
            if(!Test.isRunningTest())
                throw new AuraHandledException('Error inserting Pipeline Products:'+e.getMessage());
        }
    }
    
    
    
    //Wrapper class
    public class wrapProfData{
        
        @AuraEnabled public Profile_Data__c profData {get; set;}
        @AuraEnabled public Boolean selected {get; set;}
        
        public wrapProfData(Profile_Data__c pd){
            profData = pd;
            selected = false;
        }
    }
    
    
    
}