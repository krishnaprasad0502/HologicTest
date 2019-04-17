/*-----------------------------------------------------------------------------------------------------------------------------------
Author:       Raviraj Reddy
Description:  Controller class for AccountChildernActivities page
Test Class:   AccountChildrenActivities_Test

History:
<Date>       <Authors Name>    <Brief Description of Change>
03/15/2018    Raviraj Reddy     Initial Creation (US3819)   
                                Pulled Product family value from Asset Sclpusure 
------------------------------------------------------------------------------------------------------------------------------------*/
public without sharing class AccountChildrenActivities {
   
    public string options{get;set;}
    public string sculpSureAssetIds {get;set;}    
    public List<SelectOption> lstLaserOwnedSelect {get{
                                                        List<SelectOption> lstSelectOpts = new List<SelectOption>();
                                                        lstSelectOpts.add(new SelectOption('All' , 'All'));
                                                        lstSelectOpts.add(new SelectOption('None' , 'None'));
                                                        sculpSureAssetIds = '';
                                                        for(Asset asst: [SELECT Id, Name, Product2Id, Product2.family FROM Asset WHERE AccountID=: curRecordID])
                                                        {
                                                            lstSelectOpts.add(new SelectOption(asst.Id , asst.Name));
                                                            if(asst.Product2Id != null && asst.Product2.family != null && asst.Product2.family.containsIgnoreCase('Sculpsure')){
                                                                sculpSureAssetIds = sculpSureAssetIds + ','+asst.Id;
                                                            }
                                                        }
                                                        //lstSelectOpts.add(new SelectOption('All' , 'All')); 
                                                        return lstSelectOpts;
    }}    
    public String strLaserSelect                  {get;set;}
    
    
    public String mapIdToAMPSUser      {get;set;}
    public String mapIdToEmails        {get{
                                                        map<Id , String> mapIdToEMails = new map<Id , String>();
                                                        map<Id , String> mapIdToAMPS = new map<Id , String>();
                                                        for(Asset asst :  [Select id,AccountID,
                                                                                    (Select Id,
                                                                                     User__c,User__r.Email, 
                                                                                     Relationship__c
                                                                                     From Asset_Teams__r)
                                                                                     From Asset
                                                                                     Where AccountID=: curRecordID ])
                                                        {
                                                            if(!asst.Asset_Teams__r.isEmpty()){
                                                                String emails = '';
                                                                for(Asset_Team__c asTeam : asst.Asset_Teams__r){
                                                                    
                                                                    if(asTEam.Relationship__c == 'AMPS Representative'){
                                                                        mapIdToAMPS.put(asst.Id , asTeam.User__c);
                                                                    }    
                                                                    
                                                                    if(asTeam.User__r.Email != null){
                                                                        if(emails != ''){
                                                                            emails = emails+';'+ asTeam.User__r.Email;
                                                                        }else{
                                                                            emails = asTeam.User__r.Email;
                                                                        }
                                                                    }        
                                                                 }
                                                                 mapIdToEMails.put(asst.Id , emails);
                                                              }                      
                                                        }
                                                        mapIdToAMPSUser = JSON.serialize(mapIdToAMPS);
                                                        return JSON.serialize(mapIdToEMails);
                                                        }set;}
    
   
    private List<sObject> activityRecords;
    public String activityRecordsJSON {get;set;}
    public List<Schema.FieldSetMember> listViewFieldSet {get;set;}
    public String listViewFieldSetJSON {get;set;}
    public String idMapJSON {get;set;}
    public String curRecordID {get;set;}
    public String curRecordName {get;set;}
    private String runningUser {get;set;}
    public Asset laser{get;set;}
    public Map<id,Asset> laserMap{get;set;}
    public boolean isAccountCodeBtVisibile{get;set;}
    public AccountChildrenActivities(ApexPages.StandardController controller)
    {  
        isAccountCodeBtVisibile = false; 
        sObject inRecord = (sObject)controller.getRecord();
        curRecordID = inRecord.ID;
        Account a = [Select Name From Account Where Id =: curRecordID];
        curRecordName = a.Name;
        runningUser = UserInfo.getUserId();
        if(strLaserSelect !='All'){
            laser = new Asset();
        }
        strLaserSelect = 'All';
        initialize();
    }
    
    /*method to addign Laser */
    public void assignLaser(){
        if(strLaserSelect!=null && strLaserSelect!='' && strLaserSelect != 'All' && strLaserSelect != 'None'){
         system.debug('strLaserSelect :'+strLaserSelect);
         
         laser =  [SELECT Id,Laser_Score__c,Product2ID,Product2.Name,Product2.Family,SerialNumber, Product2.ProductCode,AccountID FROM Asset WHERE id=:strLaserSelect];
         system.debug('laser :'+laser);
         if(laser.SerialNumber != null)
             if(laser.SerialNumber.startsWithIgnoreCase('SCLP')){
                 isAccountCodeBtVisibile = true;
             }else{
                 isAccountCodeBtVisibile = false;
             }
         
        }
        if(strLaserSelect == 'All' || strLaserSelect == 'None'){
            laser = new Asset();
            isAccountCodeBtVisibile = false;
        }
    } 
    
    /*method to initialize and populate data structures for the VF page */
    private void initialize()
    {
        String fieldsetName = 'Amps_Tasks';
        listViewFieldSet = SObjectType.Task.FieldSets.getMap().get(fieldsetName).getFields();
        listViewFieldSetJSON = JSON.serializePretty(listViewFieldSet);
        laserMap = new Map<Id,Asset>();
        
        List<Id> lasersOwned = new List<Id>();
        
        String strLaserQuery = 'SELECT Id,Laser_Score__c FROM Asset WHERE AccountID=: curRecordID';
        if(strLaserSelect != 'All'){
            strLaserQuery += ' AND Id =:strLaserSelect';
        }
        for(Asset lo : database.query(strLaserQuery)){
          lasersOwned.add(lo.Id);
          laserMap.put(lo.id,lo);  
        }
        String query1 = 'SELECT ';
        String query2 = 'SELECT ';
        Boolean useWhatId = false;
        Boolean useWhoId = false;
        //what should be done here is check if a field is a reference via fieldsetmember.gettype
        //if it is, add it to a map<string,list<id>> as a key. then when iterating over the tasks and 
        //events, the value list should be populated with the matching field value
        //next, for each key, a query should be ran to get records where Id is in the value list
        //in order to do that, you'll need to check the object type w/ myId.getSObjectType().getDescribe().getName()
        //using the result, place the id and name of the returned records into a map <id, string>
        //and the front end can utilize this to make links to those records
        for(Schema.FieldSetMember f : listViewFieldSet) {
            if(f.getFieldPath() != 'Id' && f.getFieldPath() != 'Subject' && f.getFieldPath() != 'Description'){
                query1 += f.getFieldPath() + ', ';
              query2 += f.getFieldPath() + ', ';
            }
            
            if(f.getFieldPath() != 'WhatId'){
                useWhatId = true;
            }
            if(f.getFieldPath() != 'WhoId'){
                useWhoId = true;
            }
        }
        //Test
        useWhatId = true;
        
        //Test -- added whatid
        if(strLaserSelect == 'None'){
            query1 += 'WhatId, WhoId, Subject, Description FROM Task WHERE  WhatId =:curRecordID ';
            query2 += 'WhatId, WhoId, Id, Subject, Description FROM Event WHERE WhatId =:curRecordID ';
        } else If(strLaserSelect == 'All'){
            query1 += 'WhatId, WhoId, Id, Subject, Description FROM Task WHERE  (WhatId IN :lasersOwned OR  WhatId =:curRecordID)';
            query2 += 'WhatId, WhoId, Id, Subject, Description FROM Event WHERE (WhatId IN :lasersOwned OR  WhatId =:curRecordID) '; 
        } else {
            query1 += 'WhatId, WhoId, Id, Subject, Description FROM Task WHERE  WhatId IN :lasersOwned ';
            query2 += 'WhatId, WhoId, Id, Subject, Description FROM Event WHERE WhatId IN :lasersOwned ';
        }
        
        
        
        List<sObject> activityRecords = new List<sObject>();
        List<Id> whatIds = new List<Id>();
        List<Id> whoIds = new List<Id>();
        List<Id> assIgnedToIds = new List<Id>();
        system.debug('query-------------1--- '+query1);
        for(sObject so : (List<sObject>)Database.query(query1)){
            activityRecords.add((sObject) so);
            if(useWhatId){
              whatIds.add((Id)so.get('WhatId'));
            }
            if(useWhoId){
              whoIds.add((Id)so.get('WhoId'));            
            }
            assIgnedToIds.add((Id)so.get('OwnerId')); 
        }
        system.debug('query-------------2--- '+query1);
        for(sObject so : (List<sObject>)Database.query(query2)){
            activityRecords.add((sObject) so);
            if(useWhatId){
              whatIds.add((Id)so.get('WhatId'));
            }
            if(useWhoId){
              whoIds.add((Id)so.get('WhoId'));            
            }
        }
        
        Map<Id, String> idMap = new Map<Id, String>();
        //idMap.put(curRecordId, curRecordName); //Commented to prevent duplication issue
        //
       for(Asset lo : [SELECT Id,Laser_Score__c, Name FROM Asset WHERE Id IN: whatIds]){
           idMap.put(lo.Id, lo.Name);
        }
        system.debug('whoIds---    '+whoIds);
        
        for(Contact c : [SELECT Name FROM Contact WHERE Id IN: whoIds]){
            idMap.put(c.Id, c.Name);
        }
        
        for(User u : [SELECT Name FROM User WHERE Id IN: assIgnedToIds]){
            idMap.put(u.Id, u.Name);
        }
        
        
        system.debug('idMap :'+idMap);
        system.debug('-----'+JSON.serializePretty(idMap));
        idMapJSON = JSON.serializePretty(idMap);
        system.debug('activityRecords :'+activityRecords);
        activityRecordsJSON = JSON.serializePretty(activityRecords);
        
        Map<Id, String>  optionsList = new Map<Id, String>();
        for(Asset lo : [SELECT ID,Name,AccountID FROM Asset WHERE AccountID=: curRecordID]){
            optionsList.put(lo.Id, lo.Name);
        }
        optionsList.put(curRecordId, curRecordName);
        system.debug('optionsList :'+optionsList);
        system.debug(JSON.serializePretty(optionsList));
        options = JSON.serializePretty(optionsList);
    }
    
    
    /* public method to first initialize data and then assign laser */
    public void updatePage()
    {
        initialize();
        assignLaser();
    }
    
    
}