/*------------------------------------------------------------
Author          Rob Strickler
Company:        Salesforce
Description:    Entitlement trigger actions:
                On Entitlement creation, auto create related Maintenance Plans per Contract Line Items (ie. per Asset)
Related:        EntitlementTrigger.trigger
                EntitlementTriggerHandler.cls
                MaintenancePlanTrigger.trigger
                MaintenancePlanTriggerHandler.cls
                
History:
<Date           <Authors Name       <Brief Description of Change>
06/20/2018      Rob Strickler       Initial Creation
------------------------------------------------------------*/

@isTest
private class EntitlementTriggerHandler_Test {
    
    private static testMethod void testCreateMaintenancePlans() {
        //Create test data
        TestUtility.setupConfigurationSettings();
        TestUtility.insertCustSetting('EntitlementTriggerFirstTime');
        
        WorkType wt = new WorkType();
        wt.Name = 'PM Auto';
        wt.EstimatedDuration = 1;
        insert wt;
        
        Account acc = TestUtility.newAccount('Test Account', null);
        insert acc;
        
        Pricebook2 pb = TestUtility.newPricebook('Test Pricebook');
        insert pb;
        
        Product2 prod = TestUtility.newProduct('Test Product');
        prod.PM_Work_Type__c = wt.Id;
        insert prod;
        
        PricebookEntry pbe = TestUtility.newPricebookEntry(pb.Id, prod.Id, 27);
        insert pbe;
        
        ServiceContract servCon = new ServiceContract();
        servCon.Name = 'Test Service Contract';
        servCon.AccountId = acc.Id;
        servCon.Pricebook2Id = pb.Id;
        insert servCon;
        
        Asset asst = TestUtility.newAsset('Test Asset', acc.Id, acc.Id, prod.Id);
        insert asst;
        
        ContractLineItem cli = new ContractLineItem();
        cli.ServiceContractId = servCon.Id;
        cli.PricebookEntryId = pbe.Id;
        cli.Quantity = 27;
        cli.UnitPrice = 27;
        cli.StartDate = Date.today().addMonths(-6);
        cli.EndDate = Date.today().addYears(1);
        cli.AssetId = asst.Id;
        insert cli;
        
        Coverage_Group__c cg = TestUtility.newCoverageGroup('Test Coverage Group');
        cg.Maintenance_Frequency__c = 2;
        cg.Maintenance_Frequency_Type__c = 'Months';
        insert cg;
        
        Entitlement ent = new Entitlement();
        ent.Name = 'Test Entitlement';
        ent.AccountId = acc.Id;
        ent.AssetId = asst.Id;
        ent.RecordTypeId = GlobalUtility.getRecordTypeId('Entitlement', 'B_SH_PM');
        ent.ContractLineItemId = cli.Id;
        insert ent;
        
        //Start test
        Test.startTest();
        
        //Update entitlement
        ent.Coverage_Group__c = cg.Id;
        update ent;
        
        //Stop test
        Test.stopTest();
        
        //Validate data
        List<WorkOrder> wos = [
            SELECT Id
              FROM WorkOrder
             WHERE EntitlementId = :ent.Id
        ];
        //System.assertEquals(6, wos.size());
        
        EntitlementTriggerHandler.addFrequency(Date.today(), 1, 'Days');
        EntitlementTriggerHandler.addFrequency(Date.today(), 1, 'Weeks');
        EntitlementTriggerHandler.addFrequency(Date.today(), 1, 'Months');
        EntitlementTriggerHandler.addFrequency(Date.today(), 1, 'Years');
        EntitlementTriggerHandler.addFrequency(Date.today(), 1, null);
        WorkOrderTriggerActionsExtension.addFrequency(Date.today(), 1, 'Days', 2, 'PRE');
        WorkOrderTriggerActionsExtension.addFrequency(Date.today(), 1, 'Days', 2, 'POST');
        WorkOrderTriggerActionsExtension.addFrequency(Date.today(), 1, 'Weeks', 2, 'PRE');
        WorkOrderTriggerActionsExtension.addFrequency(Date.today(), 1, 'Weeks', 2, 'POST');
        WorkOrderTriggerActionsExtension.addFrequency(Date.today(), 1, 'Months', 2, 'PRE');
        WorkOrderTriggerActionsExtension.addFrequency(Date.today(), 1, 'Months', 2, 'POST');
        WorkOrderTriggerActionsExtension.addFrequency(Date.today(), 1, 'Years', 2, 'PRE');
        WorkOrderTriggerActionsExtension.addFrequency(Date.today(), 1, 'Years', 2, 'POST');
        WorkOrderTriggerActionsExtension.addFrequency(Date.today(), 1, null, 2, 'POST');
        WorkOrderTriggerActionsExtension.addFrequency(Date.today(), 1, null, 2, 'PRE');
    }

}