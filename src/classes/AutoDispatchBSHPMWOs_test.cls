/*--------------------------------------------------------------------------------------------------
Author:      Kasmoor Reddy
Description:  Test class to validate AutoDispatchBSHPMWOs scheduler and batch job
Tests Excecuted:

testScheduler - verifies the scheduler works

testBatch - verfies Schedulable Batch job that will auto dispatch the B&SH PM work orders through FSL schedule service class.

History:
<Date>      <Authors Name>    <Brief Description of Change>
04/10/2019   Kasmoor Reddy      Initial Creation
---------------------------------------------------------------------------------------------------------*/
@isTest
public class AutoDispatchBSHPMWOs_test {
    @isTest
    public static void AutoDispatchBSHPMWOstestMethod1()
    {
        TestUtility.setupConfigurationSettings();
        //TestUtility.insertCustSetting('WorkOrderTrigger');
        
        Trigger_Switch__c ts = new Trigger_Switch__c();
        ts.Name = 'WorkOrderTrigger';
        ts.Active__c = true;
        insert ts;
        
        //Setup Territory and Opperating Hours
        OperatingHours opHours = new OperatingHours();
        opHours.Name = 'Test Operating Hours';
        insert opHours;
        
        User use = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        use.Hologic_Division__c = 'DIAG';
        update use;
        
        ServiceTerritory sTerr = new ServiceTerritory();
        sTerr.Name = 'Test Service Territory';
        sTerr.IsActive = true;
        sTerr.OperatingHoursId = opHours.Id;
        sTerr.Field_Service_Manager__c = use.Id;
        insert sTerr;
        
        WorkType wt = new WorkType();
        wt.Name = 'PM Auto';
        wt.EstimatedDuration = 1;
        wt.Division__c='BSH';
        insert wt;
        
        Account custAcc = TestUtility.newAccount('Test Customer Account','');
        insert custAcc;
        custAcc.BillingStreet = '220 BRITANNIA RD E';
        custAcc.BillingCity = 'MISSISSAUGA';
        custAcc.BillingstateCode = 'ON';
        custAcc.BillingCountryCode = 'CA';
        custAcc.BillingpostalCode = 'L4Z-1S6';
        update custAcc;
        
        //Work Order
        WorkOrder wo = TestUtility.newWorkOrderWithAddressAndTerritory(
            sTerr.Id //Id serviceterritoryId
            , UserInfo.getUserId() //Id ownerId
            , '220 BRITANNIA RD E'   //String street
            , 'MISSISSAUGA'           //String city
            , 'L4Z-1S6'              //String postalCode
            , 'ON'                 //String stateCode 
            , 'CA'                 //String countryCode
        );
        wo.FE_Resolution__c = 'Test';
        wo.WorkTypeId = wt.Id;
        wo.Accountid = custAcc.id;
        wo.Reason_for_Cancellation__c = 'test';
       
        insert wo;
        FSL__Scheduling_Policy__c scPolicy=new FSL__Scheduling_Policy__c(Name='testPolicy',FSL__Commit_Mode__c='AlwaysCommit',FSL__Description__c='testDescription');
        insert scPolicy;
        ServiceAppointment servappt1 = TestUtility.newServiceAppointment(
            wo.Id //Id parentrecordId, needs to match WorkOrder Id
            , null             //String status
            , wo.Id              //Id relatedworkorderid, will match 'wo' above post trigger
            , datetime.newInstance(2018, 1, 15, 11, 30, 0) //Datetime schedendtime
            , datetime.newInstance(2018, 1, 15, 10, 30, 0) //Datetime schedstarttime
        );
        //servappt.ParentRecordType = 'WorkOrder';
        //servappt.Reassigned_Resource__c = sRes.Id;
        servappt1.OwnerId = UserInfo.getUserId(); //Id ownerId
        insert servappt1;
        //Service Appointment
        ServiceAppointment servappt = TestUtility.newServiceAppointment(
            wo.Id //Id parentrecordId, needs to match WorkOrder Id
            , null             //String status
            , wo.Id              //Id relatedworkorderid, will match 'wo' above post trigger
            , datetime.newInstance(2018, 1, 15, 11, 30, 0) //Datetime schedendtime
            , datetime.newInstance(2018, 1, 15, 10, 30, 0) //Datetime schedstarttime
        );
        //servappt.ParentRecordType = 'WorkOrder';
        //servappt.Reassigned_Resource__c = sRes.Id;
        servappt.OwnerId = UserInfo.getUserId(); //Id ownerId
        servappt.DueDate=system.today()+30;
        servappt.Status='None';
        servappt.FSL__Scheduling_Policy_Used__c=scPolicy.Id;
        servappt.FSL__Related_Service__c=servappt1.Id;
        servappt.FSL__Same_Day__c=true;
        servappt.FSL__Same_Resource__c=true;
        insert servappt;
        String sch = '0 0 23 * * ?';
        test.startTest();
         String jobId = System.schedule('AutoDispatchBSHPMWOsTestClassCheck',  sch, new AutoDispatchBSHPMWOs());
            CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
            System.assertEquals(sch, ct.CronExpression);
            System.assertEquals(0, ct.TimesTriggered);

        test.stopTest();
    }
    
}