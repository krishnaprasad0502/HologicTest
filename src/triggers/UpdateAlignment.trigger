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
------------------------------------------------------------*/

trigger UpdateAlignment on Lead (before insert,before update) 
{
    //Variable to turn ON/OFF the UpdateAlignment Trigger
    private static Boolean isUpdateAlignmentTrigger = GlobalUtility.isTriggerActive('UpdateAlignment');
      if(trigger.isbefore && isUpdateAlignmentTrigger){
          if(trigger.isinsert){
                   //Invoke the ApexController i.e( UpdateAlignment_controller) class with Method i.e(BeforeinsertLeadActions)
                    UpdateAlignment_controller.BeforeinsertLeadActions(trigger.new);
                 
               }
              if(trigger.isupdate){
                    //Invoke the ApexController i.e( UpdateAlignment_controller) class with Method i.e(BeforeinsertLeadActions)
                    UpdateAlignment_controller.BeforeinsertLeadActions(trigger.new);
              }
       }
}