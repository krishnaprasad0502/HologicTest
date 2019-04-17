/*------------------------------------------------------------
Author:         Kasmoor Reddy
Company:        Apps Associates
Description:    Test class for ContactTriggerActions


History:
<Date>          <Authors Name>      <Brief Description of Change>
12/05/2018      Kasmoor Reddy        Initial Creation (US6207)
------------------------------------------------------------*/
@isTest
public class ContactTrigger_Test {
    @isTest
    public static void testConMethod()
    {
         List<Trigger_Switch__c> Trigger_switch_List = new List<Trigger_Switch__c>();
        
        Trigger_Switch__c ts_WorkOrderPM = new Trigger_Switch__c();
        ts_WorkOrderPM.Name = 'ContactTrigger';
        ts_WorkOrderPM.Active__c = TRUE;
        Trigger_switch_List.add(ts_WorkOrderPM);
        insert Trigger_switch_List;
        
        List<Contact> conList=new List<Contact>();
        for(Integer i=0;i<5;i++)
        {
            Contact c=new Contact(lastname='TesT',middlename='MIddle',firstname='FIrst');
            conList.add(c);
        }
        Test.startTest();
        insert conList;
        conList[0].firstName='TestT';
        update conList;
        Test.stopTest();
    }
    
    
}