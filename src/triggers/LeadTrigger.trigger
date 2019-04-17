/*------------------------------------------------------------
Author:         Kasmoor Reddy
Company:        Apps Associates
Description:    Trigger on the Lead Object to update the alignment metadata when inserting and updating the lead
Trigger:        UpdateAlignment
Class:          UpdateAlignment_controller
Test class:     UpdateAlignment_Controller_Test
History:
<Date>          <Authors Name>      <Brief Description of Change>
06/06/2017      Kasmoor Reddy       Initial Creation (US2676)
01/14/2019      Mani Sundaresan     Introduce logic to handle lead creation from CVent system (US-0006523)   
------------------------------------------------------------*/
trigger LeadTrigger on Lead (before insert,before update, after insert, after update, before delete) 
{
    //Variable to turn ON/OFF the UpdateAlignment Trigger
    private static Boolean isUpdateAlignmentTrigger = GlobalUtility.isTriggerActive('UpdateAlignment');
    private static Boolean LeadTrigger = GlobalUtility.isTriggerActive('LeadTrigger');
    
      if(trigger.isbefore && LeadTrigger){
          if(trigger.isinsert){
                    if(isUpdateAlignmentTrigger){
                   //Invoke the ApexController i.e( UpdateAlignment_controller) class with Method i.e(BeforeinsertLeadActions)
                    LeadTriggerActions.BeforeinsertLeadActions(trigger.new);
                    }
                    //Logic to handle the lead creation from CVent system
                    LeadTriggerActions.cventCounty(trigger.new);
                 
               }
              if(trigger.isupdate){
                    if(isUpdateAlignmentTrigger){
                    //Invoke the ApexController i.e( UpdateAlignment_controller) class with Method i.e(BeforeinsertLeadActions)
                    LeadTriggerActions.BeforeinsertLeadActions(trigger.new);
                    }
              }
       }
       if(trigger.isafter && LeadTrigger){
       }
}