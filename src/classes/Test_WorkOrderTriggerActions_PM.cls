/*
Author: Amarendra Nagireddy
Organization: Apps Associates
Created Date: 02/20/2017
Purpose: Code Coverage for the Apex Class, WorkOrderTriggerActions_PM
*/
@isTest
public class Test_WorkOrderTriggerActions_PM {
    
  static testMethod void setPMWorkOrders_Case1() {
      // 13/09/2017-Krishna Prasad-Added trigger switch to fix case Trigger isuue  
       TestUtility.insertCustSetting('CaseTrigger');
      TestUtility.insertCustSetting('WorkOrderTrigger');
      Record_Type_IDs__c rtIds = TestUtility.setupRecordTypeIds();
      Configuration_Settings__c orgDefaultsorgDefaults = TestUtility.setupConfigurationSettings();
      Error_Handling_Emails__c errEmail = new   Error_Handling_Emails__c(Service_Email__c='sfdc.admin.qa@hologic.com', Name='Service Email');
      insert errEmail;
      
      Date Today = System.Today();
      Account Acc1= new Account();
      Acc1.Name='Test Account';
         Acc1.Facility_Type__c = 'Oncology Treatment';
         Acc1.BillingStreet = 'BillingStreet';
         Acc1.BillingCity = 'Austin';
         Acc1.BillingState = 'Texas';
         Acc1.BillingPostalCode = '12345';
         Acc1.BillingCountry = 'United States';
         Acc1.Credit_Hold__c=False;
     insert acc1;
     
     List<Product2> products = new List<Product2>();
        products.add(TestUtility.newProduct('Product 01'));
        products.add(TestUtility.newProduct('Product 02'));
        insert products;
     
     Account custAccount = TestUtility.newAccount('Customer Account', 'testCust', 'ABC Street', null, GlobalUtility.getRecordTypeId('Account', 'Customer'));
     custAccount.BillingCountryCode = 'US';
     custAccount.BillingStateCode = 'NY'; 
     
     insert custAccount;
     
     Account siteAccount = TestUtility.newAccount('Site Account', 'testSite', 'ABC Street', custAccount.Id, GlobalUtility.getRecordTypeId('Account', 'Site'));
     siteAccount.BillingCountryCode = 'US';
     siteAccount.BillingStateCode = 'NY';            
     insert siteAccount;
   
      Contact Con1 = new Contact();
          Con1.FirstName = 'FirstName';
          Con1.LastName = 'LastName';
          Con1.AccountId = Acc1.Id;
          Con1.Email = 'First.LastName@appsassociates.com';
      Insert con1;
      
      List<Asset> assets = new List<Asset>();
      assets.add(TestUtility.newAsset(siteAccount.Name + ' Asset 01', siteAccount.Id, custAccount.Id, products[0].Id));
      assets[0].ContactId = con1.Id;
      insert assets;
      
      SlaProcess workOrderEntitlementProcess;
      try{
          workOrderEntitlementProcess = [Select Id, Name From SlaProcess Where SObjectType = 'WorkOrder' Limit 1];
        }
      catch(Exception e){}
      System.assertNotEquals(null, workOrderEntitlementProcess, 'SETUP ERROR: test cannot proceed, no Work Order SLA Processes were found.');
      
      BusinessHours businessHours;
        try{
            businessHours = [Select Id, Name From BusinessHours Limit 1];
        }
        catch(Exception e){}
        System.assertNotEquals(null, businessHours, 'SETUP ERROR: test cannot proceed, no Business Hours were found.');
        
      Entitlement e = TestUtility.newEntitlement('Test ' + assets[0].Name, businessHours.Id, workOrderEntitlementProcess.Id, assets[0].AccountId, assets[0].Id, null, System.today().addDays(-30), System.today().addDays(365));
      insert e;

      
      Case CsRec= new Case();
            CsRec.Accountid=Acc1.id;
            //CsRec.CurrencyIsoCode='USD-U.S.Dollar';
            CsRec.Contactid=Con1.Id;
            CsRec.Status='New';
            CsRec.Origin='Phone';
            CsRec.System_Status__c='Up';
            CsRec.Type='PM';
            CsRec.Priority='PM';
            CsRec.Incident_Date__c= System.today();
            CsRec.Subject='Test';
            CsRec.RecordTypeId='01261000000MEIG';
           // CsRec.Complaint__c='Yes';
            //Csrec.Patient_Impact__c='Yes';
          insert CsRec; 
      
      CKSW_BASE__Service_Type__c  SerRec = New CKSW_BASE__Service_Type__c();
        SerRec.Name='Test';
        SerRec.CKSW_BASE__Duration__c=1233;
        insert SerRec;
      
      
      CKSW_BASE__Service__c Ckrec= new CKSW_BASE__Service__c();
        Ckrec.CKSW_BASE__Service_Type__c = SerRec.Id;
        Ckrec.FSL_INTG__Case__c=CsRec.id;
        insert CkRec;
        
      FSO__PreventiveMaintenancePlanTemplate__c pmTemplate = new FSO__PreventiveMaintenancePlanTemplate__c(Name = 'Test', FSO__Work_Order_Type__c='B&SH PM', FSO__Work_Order_Priority__c='PM',  Days_in_Advance_Create_Work_Order__c=15, FSO__Schedule_Frequency__c='Yearly');
      pmTemplate.FSO__Schedule_Duration__c = '1 Year';
      
      insert pmTemplate;
      
      FSO__PreventiveMaintenancePlan__c pmPlans = new FSO__PreventiveMaintenancePlan__c(Name='Test');
      pmPlans.FSO__Account__c = acc1.Id;
      pmPlans.FSO__Contact__c = con1.Id;
      pmPlans.Asset__c = assets[0].Id;
      pmPlans.FSO__Preventive_Maintenance_Plan_Template__c = pmTemplate.Id;
      pmPlans.Entitlement__c = e.Id;
      pmPlans.Service_Type__c = SerRec.Id;
      pmPlans.FSO__Work_Orders_Completed__c = 0;
      insert pmPlans;
      
      List<WorkOrder> woList = new List<WorkOrder>();
      
      WorkOrder wo=new WorkOrder();
         wo.Status='New';
         wo.FSO__Type__c='PM';
         wo.Priority='PM';
         wo.CaseId=CsRec.id;
         //wo.RecordTypeId='01261000000MEIwAAO';  //B_SH_PM
         wo.RecordTypeId = GlobalUtility.getRecordTypeId('WorkOrder', 'B_SH_PM');
         wo.FSL_INTG__Service__c=Ckrec.id;
         wo.FSO__Preventive_Maintenance_Plan__c = pmPlans.Id;
         woList.add(wo);
         
         //insert wo;
          system.assertEquals('01261000000MEIwAAO', wo.RecordTypeId);
          system.assertNotEquals(null, wo.FSO__Preventive_Maintenance_Plan__c);
          system.assertEquals(null, wo.Case.Preventive_Maintenance_Plan__c);
          
       /*WorkOrder wo2=new WorkOrder();
         wo2.Status='New';
         wo2.FSO__Type__c='PM';
         wo2.Priority='PM';
         wo2.CaseId=CsRec.id;
         //wo.RecordTypeId='01261000000MEIwAAO';  //B_SH_PM
         wo2.RecordTypeId = GlobalUtility.getRecordTypeId('WorkOrder', 'B_SH_PM');
         wo2.FSL_INTG__Service__c=Ckrec.id;
         wo2.FSO__Preventive_Maintenance_Plan__c = pmPlans.Id;
         wo2.FSO__Completed_Date__c = System.today();
         woList.add(wo2);*/
         
         insert woList;
         
        
      
      // List<WorkOrder> workorderlist=new List<WorkOrder>();
       //workorderlist.add(wo);
      //workorderlist.add(wo1);
      
      WorkOrderTriggerActions_PM.setPMWorkOrders(woList);
      WorkOrderTriggerActions_PM.afterServiceUpdate(woList);
      //WorkOrderTriggerActions_PM.updatePMPlans(woList,null);
      
      for(WorkOrder wo1 : woList){
          wo1.status = 'Closed';
          wo1.PMP_Updated__c = TRUE;
      }
      
      //GlobalUtility.run = true;
      update woList;
      //WorkOrderTriggerActions_PM.updatePMPlans(woList);   
      
      
       List<WorkOrder> wo_insertlist=new List<WorkOrder>();
      wo_insertlist=[select id,RecordTypeId,FSO__Preventive_Maintenance_Plan__c,Case.Preventive_Maintenance_Plan__c,Case.ContactId from WorkOrder where id=:wo.id];
      for(WorkOrder wo1:wo_insertlist)
      {
          system.assertNotEquals(null, wo1.FSO__Preventive_Maintenance_Plan__c);
          system.assertEquals(null, wo1.Case.Preventive_Maintenance_Plan__c);
          system.assertNotEquals(null, wo1.Case.ContactId);
          system.assertEquals(con1.id, wo1.Case.ContactId);
      }
      CKSW_BASE__Service__c CBS=new CKSW_BASE__Service__c();
      CBS=[select id,FSO__WorkOrder__c from CKSW_BASE__Service__c where id=:CkRec.id] ;
      system.assertEquals(wo_insertlist[0].id, CBS.FSO__WorkOrder__c);
      

  }
  
    static testMethod void setPMWorkOrders_Case2() {
         // 13/09/2017-Krishna Prasad-Added trigger switch to fix case Trigger isuue  
       TestUtility.insertCustSetting('CaseTrigger');
      TestUtility.insertCustSetting('WorkOrderTrigger');
  
      TestUtility.insertCustSetting('WorkOrderTrigger');
      Record_Type_IDs__c rtIds = TestUtility.setupRecordTypeIds();
      Configuration_Settings__c orgDefaultsorgDefaults = TestUtility.setupConfigurationSettings();
      
      Date Today = System.Today();
      Account Acc1= new Account();
      Acc1.Name='Test Account';
         Acc1.Facility_Type__c = 'Oncology Treatment';
         Acc1.BillingStreet = 'BillingStreet';
         Acc1.BillingCity = 'Austin';
         Acc1.BillingState = 'Texas';
         Acc1.BillingPostalCode = '12345';
         Acc1.BillingCountry = 'United States';
         Acc1.Credit_Hold__c=False;
     insert acc1;
     
    
   
      Contact Con1 = new Contact();
          Con1.FirstName = 'FirstName';
          Con1.LastName = 'LastName';
          Con1.AccountId = Acc1.Id;
          Con1.Email = 'First.LastName@appsassociates.com';
      Insert con1;
      
      
      Case CsRec= new Case();
            CsRec.Accountid=Acc1.id;
            //CsRec.CurrencyIsoCode='USD-U.S.Dollar';
            CsRec.Contactid=Con1.Id;
            CsRec.Status='New';
            CsRec.Origin='Phone';
            CsRec.System_Status__c='Up';
            CsRec.Type='PM';
            CsRec.Priority='PM';
            CsRec.Incident_Date__c= System.today();
            CsRec.Subject='Test';
            CsRec.RecordTypeId='01261000000MEIG';
           // CsRec.Complaint__c='Yes';
            //Csrec.Patient_Impact__c='Yes';
          insert CsRec; 
      
      CKSW_BASE__Service_Type__c  SerRec = New CKSW_BASE__Service_Type__c();
        SerRec.Name='Test';
        SerRec.CKSW_BASE__Duration__c=1233;
        insert SerRec;
      
      
      CKSW_BASE__Service__c Ckrec= new CKSW_BASE__Service__c();
        Ckrec.CKSW_BASE__Service_Type__c = SerRec.Id;
        Ckrec.FSL_INTG__Case__c=CsRec.id;
        insert CkRec;
        
      WorkOrder wo=new WorkOrder();
         wo.Status='New';
         wo.FSO__Type__c='PM';
         wo.Priority='PM';
         wo.CaseId=CsRec.id;
         //wo.RecordTypeId='01261000000MEIwAAO';  //B_SH_PM
         wo.RecordTypeId = GlobalUtility.getRecordTypeId('WorkOrder', 'B_SH_PM');
         wo.FSL_INTG__Service__c=Ckrec.id;
         //wo.FSO__Preventive_Maintenance_Plan__c = pmPlans.Id;
         insert wo;
          system.assertEquals('01261000000MEIwAAO', wo.RecordTypeId);
          system.assertEquals(null, wo.FSO__Preventive_Maintenance_Plan__c);
          system.assertEquals(null, wo.Case.Preventive_Maintenance_Plan__c);
      
      
       List<WorkOrder> workorderlist=new List<WorkOrder>();
       workorderlist.add(wo);
      //workorderlist.add(wo1);
      
      WorkOrderTriggerActions_PM.setPMWorkOrders(workorderlist);
      WorkOrderTriggerActions_PM.afterServiceUpdate(workorderlist);
      //WorkOrderTriggerActions_PM.updatePMPlans(workorderlist);
      
      
       List<WorkOrder> wo_insertlist=new List<WorkOrder>();
      wo_insertlist=[select id,RecordTypeId,FSO__Preventive_Maintenance_Plan__c,Case.Preventive_Maintenance_Plan__c,Case.ContactId from WorkOrder where id=:wo.id];
      for(WorkOrder wo1:wo_insertlist)
      {
          system.assertEquals(null, wo1.FSO__Preventive_Maintenance_Plan__c);
          system.assertEquals(null, wo1.Case.Preventive_Maintenance_Plan__c);
          system.assertNotEquals(null, wo1.Case.ContactId);
          system.assertEquals(con1.id, wo1.Case.ContactId);
      }
      CKSW_BASE__Service__c CBS=new CKSW_BASE__Service__c();
      CBS=[select id,FSO__WorkOrder__c from CKSW_BASE__Service__c where id=:CkRec.id] ;
      system.assertEquals(wo_insertlist[0].id, CBS.FSO__WorkOrder__c);
      

  }  
 
    
    
}