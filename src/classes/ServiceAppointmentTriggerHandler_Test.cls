/*------------------------------------------------------------
Author          Rob Strickler
Company:        Salesforce
Description:    Tests functions related to Service Appointment trigger
Related:        ServiceAppointmentTrigger.trigger
                ServiceAppointmentTriggerHandler.cls

History:
<Date           <Authors Name       <Brief Description of Change>
04/23/2018      Rob Strickler       Initial Creation
------------------------------------------------------------*/

@isTest
public class ServiceAppointmentTriggerHandler_Test {

    static void doStaticSetup() {
        //Create test data
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
        insert servappt;
    }

    // private static testMethod void testTriggerCreate() {
    @isTest static void testTriggerCreate() {
        doStaticSetup();
        
        //Get Work Order
        WorkOrder wo = [
            SELECT Id
                  ,City
                  ,Street
                  ,StateCode
                  ,CountryCode
                  ,PostalCode
                  ,ServiceTerritoryId
                  ,OwnerId
                  ,ContactId
              FROM WorkOrder
        ];

        //Get Service Appointment
        ServiceAppointment servappt = [
            SELECT Related_Work_Order__c
                  ,City
                  ,Street
                  ,StateCode
                  ,CountryCode
                  ,PostalCode
                  ,ServiceTerritoryId
                  ,OwnerId
                  ,ContactId
                  ,Reassigned_Resource__r.RelatedRecordId
                  ,ActualStartTime
                  ,FSL__GanttLabel__c
              FROM ServiceAppointment
            //  WHERE Id = :servappt.Id
        ];

        System.assertEquals(wo.Id, servappt.Related_Work_Order__c);
        System.assertEquals(wo.City, servappt.City);
        System.assertEquals(wo.Street, servappt.Street);
        System.assertEquals(wo.StateCode, servappt.StateCode);
        System.assertEquals(wo.CountryCode, servappt.CountryCode);
        System.assertEquals(wo.PostalCode, servappt.PostalCode);
        System.assertEquals(wo.ServiceTerritoryId, servappt.ServiceTerritoryId);
        System.assertEquals(wo.OwnerId, servappt.OwnerId);
        System.assertEquals(wo.ContactId, servappt.ContactId);
        
        System.assertNotEquals(null, servappt.OwnerId);
        System.assertNotEquals(null, servappt.FSL__GanttLabel__c);
        // Service Appointment is never created under the status of 'In Progress'
        // System.assertNotEquals(null, servappt.ActualStartTime);
    }

    // private static testMethod void testTriggerUpdateChangeStatus1None() {
    @isTest static void testTriggerUpdateChangeStatus1None() {
        doStaticSetup();
        
        ServiceAppointment servappt = [
            SELECT Status
              FROM ServiceAppointment
            //  WHERE Id = :servappt.Id
        ];
        
        // make changes, firing the 'update' action
        servappt.Status = 'None';
        update servappt;
        
        servappt = [
            SELECT Related_Work_Order__c
              FROM ServiceAppointment
            //  WHERE Id = :servappt.Id
        ];
        
        WorkOrder wo = [
            SELECT Status
              FROM WorkOrder
             WHERE Id = :servappt.Related_Work_Order__c
        ];
        
        System.assertEquals('New', wo.Status);  //both are 'None/New'
    }
    // private static testMethod void testTriggerUpdateChangeStatus2InProgress() {
    /*@isTest static void testTriggerUpdateChangeStatus2InProgress() {
        doStaticSetup();
        
        ServiceAppointment servappt = [
            SELECT Status
              FROM ServiceAppointment
        ];
        
        // make changes, firing the 'update' action
        Test.startTest();
        servappt.Status = 'In Progress';
        update servappt;
        Test.stopTest();
        
        servappt = [
            SELECT Related_Work_Order__c,
                   ActualStartTime
              FROM ServiceAppointment
            //  WHERE Id = :servappt.Id
        ];
        
        WorkOrder wo = [
            SELECT Status
              FROM WorkOrder
             WHERE Id = :servappt.Related_Work_Order__c
        ];
        
        System.assertEquals('In-Progress', wo.Status);  //both are 'In Progress'
        System.assertNotEquals(null, servappt.ActualStartTime); //should have a date
    }*/
    // private static testMethod void testTriggerUpdateChangeStatus3Scheduled() {
    @isTest static void testTriggerUpdateChangeStatus3Scheduled() {
        doStaticSetup();
        
        ServiceAppointment servappt = [
            SELECT Status
              FROM ServiceAppointment
            //  WHERE Id = :servappt.Id
        ];
        
        // make changes, firing the 'update' action
        servappt.Status = 'Scheduled';
        update servappt;
        
        servappt = [
            SELECT Related_Work_Order__c
              FROM ServiceAppointment
            //  WHERE Id = :servappt.Id
        ];
        
        WorkOrder wo = [
            SELECT Status
              FROM WorkOrder
             WHERE Id = :servappt.Related_Work_Order__c
        ];
        
        System.assertEquals('Assigned', wo.Status);
    }
    // private static testMethod void testTriggerUpdateChangeStatus4Dispatched() {
    @isTest static void testTriggerUpdateChangeStatus4Dispatched() {
        doStaticSetup();
        
        ServiceAppointment servappt = [
            SELECT Status
              FROM ServiceAppointment
            //  WHERE Id = :servappt.Id
        ];
        
        // make changes, firing the 'update' action
        servappt.Status = 'Dispatched';
        servappt.Date_Time_Dispatched__c = System.Now();
        update servappt;
        
        servappt = [
            SELECT Related_Work_Order__c
                  ,Date_Time_Dispatched__c
              FROM ServiceAppointment
            //  WHERE Id = :servappt.Id
        ];
        
        WorkOrder wo = [
            SELECT Status
                  ,Dispatch_Date__c
              FROM WorkOrder
             WHERE Id = :servappt.Related_Work_Order__c
        ];
        
        System.assertEquals('Assigned', wo.Status);
        System.assertNotEquals(null, servappt.Date_Time_Dispatched__c, 'There needs to be a date assigned when Service Appointment is set to Dispatched');
    }
    // private static testMethod void testTriggerUpdateChangeStatus5CannotComplete() {
    @isTest static void testTriggerUpdateChangeStatus5CannotComplete() {
        doStaticSetup();
        
        ServiceAppointment servappt = [
            SELECT Status
              FROM ServiceAppointment
            //  WHERE Id = :servappt.Id
        ];
        
        // make changes, firing the 'update' action
        servappt.Status = 'Cannot Complete';
        update servappt;
        
        
        servappt = [
            SELECT Related_Work_Order__c
              FROM ServiceAppointment
            //  WHERE Id = :servappt.Id
        ];
        
        WorkOrder wo = [
            SELECT Status
              FROM WorkOrder
             WHERE Id = :servappt.Related_Work_Order__c
        ];
        
        System.assertEquals('Incomplete', wo.Status);
    }
    // private static testMethod void testTriggerUpdateChangeStatus6Cancelled() {
    @isTest static void testTriggerUpdateChangeStatus6Cancelled() {
        doStaticSetup();
        
        ServiceAppointment servappt = [
            SELECT Status
              FROM ServiceAppointment
            //  WHERE Id = :servappt.Id
        ];
        
        // make changes, firing the 'update' action
        servappt.Status = 'Canceled';
        update servappt;
        
        servappt = [
            SELECT Related_Work_Order__c
              FROM ServiceAppointment
            //  WHERE Id = :servappt.Id
        ];
        
        WorkOrder wo = [
            SELECT Status
              FROM WorkOrder
             WHERE Id = :servappt.Related_Work_Order__c
        ];
        
        System.assertEquals('Cancelled', wo.Status);
    }
    
    @isTest static void testTriggerUpdateChangeStatus8Confirmed() {
        doStaticSetup();
        
        ServiceAppointment servappt = [
            SELECT Status
              FROM ServiceAppointment
            //  WHERE Id = :servappt.Id
        ];
        
        // make changes, firing the 'update' action
        servappt.Status = 'Confirmed';
        update servappt;
        
        servappt = [
            SELECT Related_Work_Order__c
              FROM ServiceAppointment
            //  WHERE Id = :servappt.Id
        ];
        
        WorkOrder wo = [
            SELECT Status
              FROM WorkOrder
             WHERE Id = :servappt.Related_Work_Order__c
        ];
        
        System.assertEquals('Confirmed', wo.Status);
    }
    

    // local testing of post-creation via Schedule Maintenance flow; FSL-based actions that conflict/override the regular 
    @isTest static void testTriggerScheduledMaintenanceCreate() {
        doStaticSetup();
    
        //Get Work Order
        WorkOrder wo = [
            SELECT Id
                  ,City
                  ,Street
                  ,StateCode
                  ,CountryCode
                  ,PostalCode
              FROM WorkOrder
        ];

        //Get Service Appointment
        ServiceAppointment servappt = [
            SELECT Related_Work_Order__c
                  ,City
                  ,Street
                  ,StateCode
                  ,CountryCode
                  ,PostalCode
                  ,OwnerId
                  ,Reassigned_Resource__r.RelatedRecordId
              FROM ServiceAppointment
        ];

        System.assertEquals(wo.City, servappt.City);
        System.assertEquals(wo.Street, servappt.Street);
        System.assertEquals(wo.StateCode, servappt.StateCode);
        System.assertEquals(wo.CountryCode, servappt.CountryCode);
    }

    // simulate chatter post for reassignment
    @isTest static void testCreateNewOwnershipChatterPost() {
        TestUtility.setupConfigurationSettings();
        
        Account acc = TestUtility.newAccount('Test Account', null);
        insert acc;
        
        User use1 = TestUtility.newUser(UserInfo.getProfileId(), 'test1');
        insert use1;
        
        User use2 = TestUtility.newUser(UserInfo.getProfileId(), 'test2');
        insert use2;
        
        ServiceResource sr1 = new ServiceResource();
        sr1.RelatedRecordId = use1.Id;
        sr1.Name = 'Test SR';
        insert sr1;
        
        ServiceResource sr2 = new ServiceResource();
        sr2.RelatedRecordId = use2.Id;
        sr2.Name = 'Test SR';
        insert sr2;
        
        OperatingHours opHours = new OperatingHours();
        opHours.Name = 'Test Operating Hours';
        insert opHours;

        ServiceTerritory sTerr1 = new ServiceTerritory();
        sTerr1.Name = 'Test Service Territory1';
        sTerr1.IsActive = true;
        sTerr1.OperatingHoursId = opHours.Id;
        sTerr1.Field_Service_Manager__c = use1.Id;
        insert sTerr1;

        ServiceTerritory sTerr2 = new ServiceTerritory();
        sTerr2.Name = 'Test Service Territory2';
        sTerr2.IsActive = true;
        sTerr2.OperatingHoursId = opHours.Id;
        sTerr2.Field_Service_Manager__c = use2.Id;
        insert sTerr2;
        
        WorkType wt = new WorkType();
        wt.Name= 'PM';
        wt.EstimatedDuration = 20;
        wt.Division__c = 'BSH';
        insert wt;
        
        WorkOrder wo = new WorkOrder();
        wo.AccountId = acc.Id;
        wo.ServiceTerritoryId = sTerr1.Id;
        wo.WorkTypeid = wt.id;
        //wo.WorkType.Division__c = 'BSH';
        insert wo;
        
        ServiceAppointment sa = TestUtility.newServiceAppointment(wo.Id, null, wo.Id, DateTime.now(), DateTime.now());
        sa.Status = 'None';
        insert sa;
        
        Test.startTest();
        
        sa.Reassigned_Resource__c = sr1.Id;
        update sa;
        
        Test.stopTest();
    }

    private static testMethod void testSetWODateValues(){
        //Create data
        TestUtility.setupConfigurationSettings();
        
        Account acc = TestUtility.newAccount('Test Account', null);
        insert acc;
        
        WorkOrder wo = new WorkOrder();
        wo.AccountId = acc.Id;
        insert wo;
        
        ServiceAppointment sa = TestUtility.newServiceAppointment(wo.Id, null, wo.Id, DateTime.now(), DateTime.now());
        insert sa;
        
        DateTime time0 = DateTime.now().addSeconds(-1 * DateTime.now().second());
        DateTime time1 = time0.addDays(1);
        DateTime time2 = time0.addDays(2);
        DateTime time3 = time0.addDays(3);
        
        //Start test
        Test.startTest();
        
        //Fire trigger
        sa.SchedStartTime = time0;
        sa.SchedEndTime = time1;
        update sa;
        
        wo = [SELECT Id, StartDate, EndDate FROM WorkOrder WHERE Id = :wo.Id];
        System.assertEquals(time0, wo.StartDate);
        System.assertEquals(time1, wo.EndDate);
        
        sa.ActualStartTime = time2;
        sa.ActualEndTime = time3;
        update sa;
        
        wo = [SELECT Id, StartDate, EndDate FROM WorkOrder WHERE Id = :wo.Id];
        System.assertEquals(time2, wo.StartDate);
        System.assertEquals(time3, wo.EndDate);
        
        //Stop test
        Test.stopTest();
    }
    
}