/*---------------------------------------------------------------------------------------------------------------------------------------------
Author:     Raviraj Reddy
Description:  Controller class for AssetReassignmentHandler page

Test Class:   AssetReassignmentHandlerCtlr_Test 

History:
<Date>      <Authors Name>    <Brief Description of Change>
03/23/2018   Raviraj Reddy    Initial Creation (US3819)
------------------------------------------------------------------------------------------------------------------------------------------------*/
public with sharing class AssetReassignmentHandlerCtlr {

    public Asset_Team__c  team1                         {get;set;}
    public Asset_Team__c  team2                         {get;set;}

    public List<AssetRec> laserList                     {get;set;}
    public String  strLaserOwnedQuery;
    public boolean isAssign;
    //constructor
    public AssetReassignmentHandlerCtlr() {
       laserList = new List<AssetRec>(); 
       isAssign = false;
       team1 = new Asset_Team__c();
       team2 = new Asset_Team__c();

    }
   
    public void getAssetRecords() {
        
       
        
        laserList = new List<AssetRec>(); 
        
        //Displaying empty laser list on selecting only Assigned Role 
        if(team1.RelationShip__c!=null && team1.User__c != null) { 
            laserList = new List<AssetRec>(); 
        }
        
        
       //forming a list of laserowned records based on selected role
            
            if(team1.RelationShip__c != null){
                Set<ID> assetIDDet = new Set<ID>();
                
                if(team1.User__c != null){
                    for(Asset_Team__c team : [select id,Relationship__c,Asset__c,Asset__r.Product2.Division__c,User__c from Asset_Team__c where Relationship__c=:team1.Relationship__c and User__c =:team1.User__c and Asset__r.Product2.Division__c LIKE '%Med%' limit 10000] ){
                        assetIDDet.add(team.Asset__c);
                        
                    }
                }else{
                    laserList = new List<AssetRec>();
                    for(Asset asst : [select id,name,Product2ID,Product2.ProductCode,Product2.Division__c,Product2.Name,AccountID,Account.Name,Account.ShippingCity,Account.BillingCity,Account.ShippingState,Account.BillingState,Account.ShippingPostalCode,Account.BillingPostalCode,Account.Phone,(select id,Relationship__c,User__c from Asset_Teams__r where Relationship__c=:team1.Relationship__c) from Asset where Product2.Division__c = 'Med Aesthetics' limit 1000]){
                        if(!asst.Asset_Teams__r.isEmpty()){
                            laserList.add(new AssetRec(asst));   
                        }
                    }
                }
                
                system.debug('assetIDDet :'+assetIDDet);
            
                if( !assetIDDet.isEmpty()){ 
                    laserList = new List<AssetRec>();
                    //List<Asset> assetList = [select id,Name,Product2ID,Product2.ProductCode,Poduct2.Name,AccountID,Account.Name,Account.ShippingCity,Account.ShippingState,Account.ShippingPostalCode,Account.Phone from Asset where ID IN:assetIDDet limit 1000];
                    for(Asset asst : [select id,Name,Product2ID,Product2.ProductCode,Product2.Name,AccountID,Account.Name,Account.ShippingCity,Account.BillingCity,Account.ShippingState,Account.BillingState,Account.ShippingPostalCode,Account.BillingPostalCode,Account.Phone from Asset where ID IN:assetIDDet limit 1000]){
                        laserList.add(new AssetRec(asst));
                    }
                }
                system.debug('laserList:'+laserList);                      
            }
        

        
    } 
    
  
     
    public void Assign(){
        
        
        List<Asset_Team__c> updateAssetTeam = new List<Asset_Team__c>();
        List<Task> updateTasks = new List<Task>();
        set<Id> selectedAsset = new set<Id>();
        
        
        // DK  Update To Assign Unassigned Lasers
        if(team2.User__c  == null) {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Please select a new User.'));
            return ;
        }
        //if Existing Assignee is New Assignee.    
        if(team1.User__c == team2.User__c) {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Users cannot be same'));
            return ;
        }
       
      
        //wrapper list to get the selected laserowned records
        for(AssetRec asstRecord: laserList) {
            if(asstRecord.selected == true) {
                selectedAsset.add(asstRecord.asst.id);
            }
        }
        
        //if LaserOwned records are not selected, displaying error message
        if(selectedAsset.isEmpty()){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'No records are selected.'));
            return ;
        }
        
        if(team1.User__c != null){
            updateAssetTeam = [select id,User__c, Relationship__c from Asset_Team__c where Asset__c IN:selectedAsset and Relationship__c=:team1.Relationship__c and User__c =:team1.User__c];
           
            for(Asset_Team__c astm : updateAssetTeam){
                astm.User__c = team2.User__c;   
            }
            
            update updateAssetTeam;
        
            updateTasks =  [select id,OwnerID,whatId from Task where whatId IN:selectedAsset and OwnerID =:team1.User__c and Status !='Completed'];
            
            for(Task tsk : updateTasks){
                tsk.OwnerID = team2.User__c;
            }
    
            update updateTasks;
         }else{
             List<Asset_Team__c> insertTeam = new List<Asset_Team__c>();
             
             for(ID assetID : selectedAsset){
                 insertTeam.add(new Asset_Team__c(User__c = team2.User__c,Relationship__c = team1.Relationship__c,Asset__c = assetID));
             }
             
             if(!insertTeam.isEmpty()){
                 insert insertTeam;
             }
         
         } 
         getAssetRecords();
    }
    
    //wrapper class to hold the list of Asset Records
     public class AssetRec{
        public Asset asst {get; set;}
        public Boolean selected {get; set;}

        public AssetRec(Asset asstRecord) { 
            asst = asstRecord;
            selected = false; 
        }
    } 

}