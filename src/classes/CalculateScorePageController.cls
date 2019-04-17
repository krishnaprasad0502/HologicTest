/*-----------------------------------------------------------------------------------------------------------------------------------
Author:       Raviraj Reddy
Description:  Controller class for CalculateScorePage 
Test Class:   CalculateScorePageController_Test

History:
<Date>       <Authors Name>    <Brief Description of Change>
03/15/2018    Raviraj Reddy     Initial Creation (US3808)         
------------------------------------------------------------------------------------------------------------------------------------*/
public class CalculateScorePageController{
    public task obj{get;set;}
    public List<SelectOption> options{get;set;}
    
    public String revenueGrowth{get;set;}
    public String sculpsureBrand{get;set;}
    public String staffAndProviders{get;set;}
    public String cashPayBusiness{get;set;}
    public String finalCode{get;set;}
    public Asset assetRecord{get;set;}
    public CalculateScorePageController(ApexPages.StandardController controller) {
        obj= new task();
        obj.Subject = 'Account Code';
        obj.status = 'Completed';
        obj.whatID = ID.ValueOF(Apexpages.currentpage().getparameters().get('ParentID'));
        obj.ownerid= UserInfo.getUserID();
        obj.recordTypeID = Schema.SObjectType.task.getRecordTypeInfosByName().get('Task').getRecordTypeId();
        
        assetRecord = [select id,Name from Asset where ID=:obj.whatID];
        options = new List<SelectOption>();
        options.add(new SelectOption('','--')); 
         
        
        options.add(new SelectOption('Green','Green'));
        options.add(new SelectOption('Yellow','Yellow'));
        options.add(new SelectOption('Red','Red'));
    }
    
   
    public void SaveTask(){
        if(!String.isBlank(revenueGrowth)){
            obj.Annual_Revenue_Impact__c =revenueGrowth;
        }
        if(!String.isBlank(sculpsureBrand)){
            obj.Brand_Impact__c=sculpsureBrand;
        }
        if(!String.isBlank(staffAndProviders)){
            obj.Customer_Engagement__c=staffAndProviders;
        }
        if(!String.isBlank(cashPayBusiness)){
            obj.Clinic_Capability__c=cashPayBusiness;
        }
        if(!String.isBlank(finalCode)){
            obj.Overall_Code__c =finalCode;
            insert obj;
            updateAsset(finalCode,obj.Whatid);
        }
        
        
    }
    
    @future
    public static void updateAsset(String str,ID assetID){
        system.debug('Flag Color :'+str);
        system.debug('assetID :'+assetID);
        Asset asst = [select id,Name,Laser_Score_Indicator__c,(select id,User__c, Relationship__c from Asset_Teams__r where Relationship__c ='Practice Support Partner') from Asset where ID =:assetID];
        asst.Laser_Score_Indicator__c = str;
        Asset_Team__c asTeam ;
        if(!asst.Asset_Teams__r.isEmpty()){
            asTeam = asst.Asset_Teams__r[0];
            asTeam.User__c = UserInfo.getUserId();
            update asTeam;
        }else{
            asTeam = new Asset_Team__c(Asset__c = asst.ID,User__c=UserInfo.getUserId(),Relationship__c ='Practice Support Partner');
            insert asTeam;    
        }
        update asst;
        system.debug('Asset :'+asst);
        QuaterlyActivityTrackInsert2(asst.id);
        
    }
   
     public static void QuaterlyActivityTrackInsert2(ID assetID){
        
        Asset asstRec= [select id,Name,Laser_Score_Indicator__c,(select id,User__c,Relationship__c from Asset_Teams__r where Relationship__c ='Practice Support Partner') from Asset where ID =:assetID];
        system.debug('asstRec Color :'+asstRec.Laser_Score_Indicator__c);

        AMPS_Marketing_Activity_Flow__c objTaskFlow = [Select Id,Name,Number_of_days_to_be_added__c,
                                                                    AMPS_Track__c,
                                                                    Next_Task__c,Next_Task__r.Name,
                                                                    Cross_object_Asset_Team__c,
                                                                    Sub_Task__c,Sub_Task__r.Name,                                                                    
                                                                    Parent_Task__c,Parent_Task__r.Name,
                                                                    Initiating_Task_Type__c,
                                                                    Type__c,
                                                                    Priority__c 
                                                                    From AMPS_Marketing_Activity_Flow__c WHERE Initiating_Task_Type__c!= NULL AND AMPS_Track__c =: asstRec.Laser_Score_Indicator__c AND Name like '%ACTIVITY - 01%' ];
        
        system.debug('objTaskFlow :'+objTaskFlow);
        Task tsk  = new Task();
        tsk.whatid = asstRec.id;
        tsk.subject = objTaskFlow.Name;
        if(!asstRec.Asset_Teams__r.isEmpty()){
            tsk.ownerID = asstRec.Asset_Teams__r[0].User__c;
        }
        Decimal days = objTaskFlow.Number_of_days_to_be_added__c;
        if(days == null){
         days = 0;
        }
        tsk.ActivityDate =  date.today().addDays(Integer.valueOF(days ));
        insert tsk;
        system.debug('Task :'+tsk); 

    }   
    

}