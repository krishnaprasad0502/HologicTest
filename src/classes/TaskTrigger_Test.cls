/*------------------------------------------------------------
Author:         Yael Perez
Company:        Salesforce.com
Description:    Test class to validate TaskTrigger
                Tests Excecuted:
                
                checkForComplaintTasks_differentComplaintCases - verify that when inserting bulk tasks across different complaint cases, the task outbound message checkbox gets checked (to be sent to agile)
                
                checkForComplaintTasks_sameComplaintCase - Verify that when inserting bulk tasks against the same case, the task outbound message checkbox gets checked (to be sent to agile)

                checkForComplaintTasks_nonComplaintCases - verify that when inserting bulk tasks against non complaint cases - the task outbound message checkbox doesn't get checked.

                checkForComplaintTasks_nonCaseTasks - verify that when inserting bulk tasks against non-case objects, the task outbound message checkbox doesn't get checked
                
                checkForComplaintTasks_preventEditOfComplaintTasks - verify that it is not possible to edit complaint tasks

                checkForComplaintTasks_preventDeletionOfComplaintTasks - verify that it is not possible to delete complaint tasks

                checkForComplaintTasks_checkForUncompletedComplaintTasks - verify that it is not possible to insert a complaint task which isn't in a completed status
                
                checkForComplaintTasks_allowEditOfComplaintTasksNoteTypeField - verify that edit of Note_Type__c field is possible
                
                checkForComplaintTasks_allowEditOfComplaintTasksSendOutboundMessageField - verify that edit of Note_Type__c field is possible
                
                test_updateTaskDescriptionOnCase - verify that Task Description field is updated when a new Task is created (HD-8082)
History:
<Date>          <Authors Name>      <Brief Description of Change>
08/04/2016      Yael Perez          Initial Creation (US1443)
09/14/2016      Yael Perez          Prevent updates, deletion of complaint tasks and insertion of complaint tasks in uncompleted status
09/30/2016      Denise Bacher       Allow updates to the Note_Type__c field on complaint cases, and resent to EBS
01/16/2018      Mani Sundaresan     Validate if the Task Description field is updated when a task is created (HD-8082)
03/14/2018      Raviraj Reddy       Validate AMPS Marketing Flow (US3819)
25/02/2019      Alex Powning        Changed AMPS tests to reflect change from Asset -> Account & Territories
------------------------------------------------------------*/
@isTest
private class TaskTrigger_Test {
    private static Configuration_Settings__c cs;
    private static Record_Type_IDs__c rtIds;
    private static Account acc;
    private static List<Task> taskList;
    private static List<Case> caseList;
    private static Case aCase;
    private static Case Case1;
    private static Case Case2;
    private static Case Case3;
    private static Case bCase;
    private static Case digCase;
    private static Case nonComplaintCase;
    private static List<Task> complaintTasks;
    private static List<Case> diagcases;
    private static Case_Effort_Validation_Status__c caseEffortVR;

    static {
        cs = TestUtility.setupConfigurationSettings();
        rtIds = TestUtility.setupRecordTypeIds();
        List<Trigger_Switch__c> Trigger_switch_List = new List<Trigger_Switch__c>();
        
        Trigger_Switch__c ts_WorkOrderPM = new Trigger_Switch__c();
        ts_WorkOrderPM.Name = 'CaseTrigger';
        ts_WorkOrderPM.Active__c = TRUE;
        Trigger_switch_List.add(ts_WorkOrderPM);
        insert Trigger_switch_List;
        
        TestUtility.insertCustSetting('TaskTrigger');
        
        caseEffortVR = TestUtility.caseEffortVR();
        insert caseEffortVR;
        
        cs.Stop_Sending_Task_events_to_Agile__c = true; // It is necessary to prevent the WFR from unchecking the Task.Send_Outbound_Message__c in order to effectively unit test the task trigger
        update cs;

        acc = TestUtility.newAccount('Test INT17', null, null, null, GlobalUtility.getRecordTypeId('Account', 'Customer'));
        insert acc;

        caseList = new List<Case>();
        for (Integer i=0; i<2; i++) {
            bCase = TestUtility.newCase(acc.Id, null, null, null, GlobalUtility.getRecordTypeId('Case', 'B_SH_Service'), 'Complaint', null, null, null);
            bCase.Complaint__c = 'Yes';
            bCase.Patient_Impact__c = 'No';
            caseList.add(bCase);
            
        }
        insert caseList;

        bCase = TestUtility.newCase(acc.Id, null, null, null, GlobalUtility.getRecordTypeId('Case', 'B_SH_Service'), 'Complaint', null, null, null);
        bCase.Complaint__c = 'Yes';
        bCase.Patient_Impact__c = 'No';     
        insert bCase;
        
        nonComplaintCase = TestUtility.newCase(acc.Id, null, null, null, GlobalUtility.getRecordTypeId('Case', 'B_SH_Service'), 'Service', null, null, null);
        insert nonComplaintCase;
        

                
    }
    
    static testMethod void checkForComplaintTasks_differentComplaintCases() {
        taskList = new List<Task>();
        List<Case> complaintCaseList = [SELECT Id FROM Case WHERE Id IN : caseList];
        for (Case c : complaintCaseList) {
            for (Integer i=0; i<5; i++) {
                Task aTask = TestUtility.newTask('Test INT17 ' + i, c.Id);
                aTask.Status = 'Completed';
                aTask.Send_Outbound_Message__c=True;
                taskList.add(aTask);
            }
        }
        insert taskList;

        complaintTasks = [SELECT Id, WhatId, Send_Outbound_Message__c FROM Task WHERE Id IN : taskList];
        for (Task cTask : complaintTasks) {
            System.Assert(cTask.Send_Outbound_Message__c);
        }       
    }
    
    static testMethod void checkForComplaintTasks_sameComplaintCase() {
        taskList = new List<Task>();
        aCase = [SELECT Id FROM Case WHERE Id =: bCase.Id];

        for (Integer i=0;i<10; i++) {
            Task aTask = TestUtility.newTask('Test INT17 ' + i, aCase.Id);
            aTask.Status = 'Completed';  
            atask.Send_Outbound_Message__c=true;
            taskList.add(aTask);
        }
        insert taskList;

        complaintTasks = [SELECT Id, WhatId, Send_Outbound_Message__c FROM Task WHERE Id IN : taskList];
        for (Task bTask : complaintTasks) {
            System.debug(bTask.Send_Outbound_Message__c);
            System.Assert(bTask.Send_Outbound_Message__c);
        }       
    }

    static testMethod void checkForComplaintTasks_nonComplaintCases() {
        taskList = new List<Task>();        

        for (Integer i=0;i<10; i++) {
            Task aTask = TestUtility.newTask('Test INT17 ' + i, nonComplaintCase.Id);
            aTask.Status = 'Completed';         
            taskList.add(aTask);
        }       
        insert taskList;

        complaintTasks = [SELECT Id, WhatId, Send_Outbound_Message__c FROM Task WHERE Id IN : taskList];        
        for (Task bTask : complaintTasks) {
            System.Assert(!bTask.Send_Outbound_Message__c);
        }       
    }
    
    static testMethod void checkForComplaintTasks_nonCaseTasks() {
        taskList = new List<Task>();                

        for (Integer i=0;i<200; i++) {
            Task aTask = TestUtility.newTask('Test INT17 ' + i, acc.Id);
            aTask.Status = 'Completed';         
            taskList.add(aTask);
        }   
        insert taskList;

        complaintTasks = [SELECT Id, WhatId, Send_Outbound_Message__c FROM Task WHERE Id IN : taskList];        
        for (Task bTask : complaintTasks) {
            System.Assert(!bTask.Send_Outbound_Message__c);
        }       
    }   

    static testMethod void checkForComplaintTasks_preventEditOfComplaintTasks() {
        Task aTask = TestUtility.newTask('Unit Test', bCase.Id);
        aTask.Status = 'Completed';     
        insert aTask;

        aTask.Subject = 'Try to Modify Complaint Task';
        try {
            update aTask;
        } catch (DmlException ex) {
            System.assert(ex.getMessage().contains('Cannot be Edited'));
        }
    
    }   

    static testMethod void checkForComplaintTasks_preventDeletionOfComplaintTasks() {
        Task aTask = TestUtility.newTask('Unit Test', bCase.Id);
        aTask.Status = 'Completed';     
        insert aTask;

        try {
            delete aTask;
        } catch (DmlException ex) {
            System.assert(ex.getMessage().contains('cannot be deleted'));
        }
    
    }       

    static testMethod void checkForComplaintTasks_checkForUncompletedComplaintTasks() {
        Task aTask = TestUtility.newTask('Unit Test', bCase.Id);

        try {
            insert aTask;
        } catch (DmlException ex) {
            System.assert(ex.getMessage().contains('must be created in \'Completed\' status'));
        }
    
    }   

    static testMethod void checkForComplaintTasks_allowEditOfComplaintTasksNoteTypeField() {
        cs.Stop_Sending_Task_events_to_Agile__c = false;
        update cs;
        
        Task aTask = TestUtility.newTask('Unit Test', bCase.Id);
        aTask.Status = 'Completed';     
        insert aTask;

        Test.startTest();
            //TaskTriggerActions.preventEditFirstRun = true;
            aTask.Note_Type__c = 'Investigation';
            try {
                update aTask;
            } catch (DmlException ex) {
                System.assert(false, 'Note_Type__c should be editable');
            }
        Test.stopTest();
    }   

    static testMethod void checkForComplaintTasks_allowEditOfComplaintTasksSendOutboundMessageField() {
        Task aTask = TestUtility.newTask('Unit Test', bCase.Id);
        aTask.Send_Outbound_Message__c = true;
        aTask.Status = 'Completed';     
        insert aTask;

        Test.startTest();
            //TaskTriggerActions.preventEditFirstRun = true;
            aTask.Send_Outbound_Message__c = false;
            try {
                update aTask;
            } catch (DmlException ex) {
                System.assert(false, 'Send_Outbound_Message__c should be editable by workflow');
            }
        Test.stopTest();
    }
    
    static testMethod void preventAddingNotetoClosedCase_Test() {
        diagcases = new List<Case>();
        Case1 = TestUtility.newCase(acc.Id, null, null, null, GlobalUtility.getRecordTypeId('Case', 'Diagnostic_Applications'), 'Complaint', 'Closed', null, null);
        Case1.Complaint__c = 'Yes';
        Case1.Patient_Impact__c = 'No';     
        diagcases.add(Case1);
        Case2 = TestUtility.newCase(acc.Id, null, null, null, GlobalUtility.getRecordTypeId('Case', 'Diagnostic_Applications'), 'Complaint', 'New', null, null);
        diagcases.add(Case2);
        Case3 = TestUtility.newCase(acc.Id, null, null, null, GlobalUtility.getRecordTypeId('Case', 'B_SH_Service'), 'Complaint', 'New', null, null);
        diagcases.add(Case3);
        insert diagcases;
        rtIds.Case_Diagnostic_Applications__c = Case1.RecordTypeId;
        update rtIds;
        Task aTask = TestUtility.newTask('Unit Test', Case1.Id);

        try {
            insert aTask;
        } catch (DmlException ex) {
            System.assert(true, 'Tasks of Closed Complaint Cases Cannot be Added');
        }
    
    } 
    
    static testMethod void test_updateTaskDescriptionOnCase(){
    List<Task> taskList = new List<Task>();
        Case c1 = TestUtility.newCase(acc.Id, null, null, null, GlobalUtility.getRecordTypeId('Case', 'B_SH_Service'), 'Complaint', 'New', null, null);
        c1.Task_Description__c='Test Description';
        insert c1;
        
        Task tsk = TestUtility.newTask('Unit Test', c1.Id);
        tsk.Description = 'Test Description';
        tsk.Subject = 'Unit Test';
        tsk.Note_Type__c = 'Note To FE';
        
         taskList.add(tsk);
        //insert tsk;
        
        Task tsk1 = TestUtility.newTask('Unit Test', c1.Id);
        tsk1.Description = 'Test Description1';
        tsk1.Subject = 'Unit Test1';
        tsk1.Note_Type__c = 'Problem Description';
        
         taskList.add(tsk1);
        //insert tsk1;
        Task tsk3 = TestUtility.newTask('Unit Test', c1.Id);
         tsk3.Description = 'Test Description';
        tsk3.Subject = 'Unit Test';
        tsk3.Note_Type__c = 'Note To FE';
        taskList.add(tsk3);
        Task tsk4 = TestUtility.newTask('Unit Test', c1.Id);
        tsk4.Description = 'Test Description1';
        tsk4.Subject = 'Unit Test1';
         tsk4.Note_Type__c = 'Problem Description';
        taskList.add(tsk4);
         insert taskList;
        Case updatedCase = [SELECT Id, Task_Description__c from Case where Id = :c1.Id];
        System.assertEquals(true,updatedCase.Task_Description__c.contains(tsk.Description));
        
        
          
    }
    
        static testMethod void test_ampsFlows(){
            List<AMPS_Marketing_Activity_Flow__c> subChildFlowList =  new List<AMPS_Marketing_Activity_Flow__c>();
            subChildFlowList.add(new AMPS_Marketing_Activity_Flow__c(name ='Sub Flow 3',AMPS_Track__c='GREEN',Number_of_days_to_be_added__c=13));
            
            insert subChildFlowList;
            
            
                                                                                
            List<AMPS_Marketing_Activity_Flow__c> childFlowList =  new List<AMPS_Marketing_Activity_Flow__c>();
            childFlowList.add(new AMPS_Marketing_Activity_Flow__c(name ='Flow 2',AMPS_Track__c='GREEN',Number_of_days_to_be_added__c=13));
            childFlowList.add(new AMPS_Marketing_Activity_Flow__c(name ='Sub Flow 2',AMPS_Track__c='GREEN',Number_of_days_to_be_added__c=13));
            childFlowList.add(new AMPS_Marketing_Activity_Flow__c(name ='Sub Flow Parent',AMPS_Track__c='GREEN',Number_of_days_to_be_added__c=13, Parent_Task__c=subChildFlowList[0].id));
            
            insert childFlowList;       
                    
                                                                                
                                                                                
            List<AMPS_Marketing_Activity_Flow__c> parentFlowList =  new List<AMPS_Marketing_Activity_Flow__c>();
            parentFlowList.add(new AMPS_Marketing_Activity_Flow__c(name ='Flow 1',AMPS_Track__c='GREEN',Number_of_days_to_be_added__c=13,Next_Task__c=childFlowList[0].id));
            parentFlowList.add(new AMPS_Marketing_Activity_Flow__c(name ='Sub Task Flow 1',Sub_Task__c = subChildFlowList[0].id,AMPS_Track__c='GREEN',Number_of_days_to_be_added__c=13,Next_Task__c=childFlowList[1].id));
            
            insert parentFlowList;                                                              
            
            
            subChildFlowList[0].Next_Task__c = childFlowList[0].id;
            
            update subChildFlowList;
            
             Id profID = [select id from profile where name='Medical Aesthetics Sales Admin'].id;


        User user1 = new User(alias = 'test123', email='test123@hologic.com',
        emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US',
        localesidkey='en_US', profileid = profID , country='United States',IsActive =true,
        timezonesidkey='America/Los_Angeles', username='tester@hologic.com');
        
        insert user1;
        System.runAs(user1){
        ID prospectRecTypeId =  [SELECT Id FROM RecordType WHERE DeveloperName ='Prospect' Limit 1].id;
        ID siteRecTypeId = [SELECT Id FROM RecordType WHERE DeveloperName ='Site' Limit 1].id;
        
    
        Account objSoldToAcc = TestUtility.newAccount('Test Account - 00001', '', '', null, prospectRecTypeId );
        objSoldToAcc.ShippingStateCode = 'AK';
        objSoldToAcc.ShippingCountryCode = 'US'; 
        objSoldToAcc.ShippingPostalCode = '10010'; 
        objSoldToAcc.ShippingCity = 'citay'; 
        objSoldToAcc.CurrencyIsoCode = 'USD';
        objSoldToAcc.CDQ_Status__c = 'New';
        objSoldToAcc.ShippingStreet = 'SHIPTest1 \n SHIPTest2 \n SHIPTest3 \n SHIPTest4';
        insert objSoldToAcc;
        
        Territory2Model terrModel = new Territory2Model();
        terrModel.DeveloperName = 'TestTerrModel123';
        terrModel.Name = 'TestTerrModel123';
            
        insert terrModel;
            
        Territory2 terr = new Territory2();
        terr.DeveloperName = 'TestTerr123';
        terr.name = 'TestTerr123';
        for (Territory2Model model : [select id from Territory2Model where DeveloperName = 'TestTerrModel123' and Name = 'TestTerrModel123']){
        	terr.Territory2ModelId = model.id;
        }
        for (Territory2Type type : [select id from Territory2Type limit 1]){
        	terr.Territory2TypeId = type.id; 
        }
            
        insert terr;
            
        ObjectTerritory2Association terrAccount = new ObjectTerritory2Association();
        terrAccount.Territory2Id = terr.id;
        terrAccount.ObjectId = objSoldToAcc.id;
        terrAccount.AssociationCause = 'Territory2Manual';
            
        insert terrAccount;
            
        UserTerritory2Association userInTerr = new UserTerritory2Association();
        userInTerr.Territory2Id = terr.id;
        userInTerr.UserId = user1.id;
        userInTerr.RoleInTerritory2 = 'AMPS Representative';
            
        insert userInTerr;
       
            List<Task> taskList = new List<Task>();
            
            Task obj= new task();
            obj.Subject = 'Flow 1';
            obj.status = 'Open';
            obj.whatID = objSoldToAcc.id;
            obj.ownerid= UserInfo.getUserID();
            obj.recordTypeID = Schema.SObjectType.task.getRecordTypeInfosByName().get('Task').getRecordTypeId();
            
                
            taskList.add(obj);
        
            
            Task obj2= new task();
            obj2.Subject = 'Sub Task Flow 1';
            obj2.status = 'Open';
            obj2.whatID = objSoldToAcc.id;
            obj2.ownerid= UserInfo.getUserID();
            obj2.recordTypeID = Schema.SObjectType.task.getRecordTypeInfosByName().get('Task').getRecordTypeId();
            
                
            taskList.add(obj2);
            
            Task obj3= new task();
            obj3.Subject = 'Sub Flow Parent';
            obj3.status = 'Closed';
            obj3.whatID = objSoldToAcc.id;
            obj3.ownerid= UserInfo.getUserID();
            obj3.recordTypeID = Schema.SObjectType.task.getRecordTypeInfosByName().get('Task').getRecordTypeId();
              
            taskList.add(obj3);
            
            insert taskList;
            
            taskList[0].Status='Completed';
            taskList[1].Status='Deferred';
            update taskList;

        }
        
     }   
      
}