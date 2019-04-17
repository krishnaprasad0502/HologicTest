/*------------------------------------------------------------
Author:     Mani Sundaresan
Description:  Trigger framework for Opportunity object
Test Class:    OpportunityTrigger_Test

History:
<Date>      <Authors Name>    <Brief Description of Change>
11/04/2016  Mani Sundaresan    Initial Creation (HD-)
11/28/2016  Mani Sundaresan    Assign Oppty Owner Territory to Oppty
1/18/2017   Netta Grant        added code to check 'Opportunity Trigger' and bypass code
09/06/2017  Kasmoor Reddy      Added the method to insert ot update profile data in after insert and after update(US-3316)
05/08/2018  Mani Sundaresan    Assign Pricebook and Currency based on Account's country(US-4158)
01/28/2019  Mani Sundaresan    Update Profile Data with Pipeline Prod details on oppty closure
------------------------------------------------------------*/
trigger OpportunityTrigger on Opportunity (before insert, before update, after insert, after update) {

    private static Boolean isActive = GlobalUtility.isTriggerActive('OpportunityTrigger');

    if(Trigger.isBefore && isActive){
      if(Trigger.isInsert){
            //Assign Pricebook and Currency based on Account's country on Medical Aesthetics Oppty's (US-4158)
            //OpportunityTriggerActions.updatePricebookInfo((List<Opportunity>) Trigger.new, null);
            //OpportunityTriggerActions.assignOwnerTerritory((List<Opportunity>) Trigger.New,null);
        }
       if(Trigger.isUpdate){
           system.debug('outsideloop--'+Validation_Rule_Exception__c.getInstance().Opportunity_validations__c);
           if(!(Validation_Rule_Exception__c.getInstance().Opportunity_validations__c)){
               system.debug('insideloop--'+Validation_Rule_Exception__c.getInstance().Opportunity_validations__c);
             OpportunityTriggerActions.validateQuote((List<Opportunity>) Trigger.New);
             OpportunityTriggerActions.mandatorySiteContact((List<Opportunity>) Trigger.New,Trigger.oldMap);  
           }   
            OpportunityTriggerActions.assignOwnerTerritory((List<Opportunity>) Trigger.New,Trigger.oldMap);
            
            OpportunityTriggerActions.updateInstallInvoved((List<Opportunity>) Trigger.New,Trigger.oldMap);
            //Assign Pricebook and Currency based on Account's country on Medical Aesthetics Oppty's (US-4158)
            OpportunityTriggerActions.updatePricebookInfo((List<Opportunity>) Trigger.New,Trigger.oldMap);

            //Update Profile Data with Pipeline Prod data when the Oppty is closed
            OpportunityTriggerActions.updateProfileData((List<Opportunity>) Trigger.new, Trigger.oldMap);
             // Validation for GrowthMapping fields on Opportunity 
            //OpportunityTriggerActions.ValidationForGrowthMappingFields((List<Opportunity>) Trigger.new, Trigger.oldMap);
         
            
        }
    }
    if(Trigger.isAfter && isActive){
       if(Trigger.isInsert){
            OpportunityTriggerActions.UpdateandInsertprofiledata((List<Opportunity>) Trigger.New,Trigger.oldMap);
        } 
        if(Trigger.isUpdate){
            OpportunityTriggerActions.UpdateandInsertprofiledata((List<Opportunity>) Trigger.New,Trigger.oldMap);
            
        }
    }

}