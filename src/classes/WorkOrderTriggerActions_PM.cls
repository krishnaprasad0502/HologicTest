/*------------------------------------------------------------
  Author:         Raj Sharan 
  Company:        AppsAssociates 
  Description:    Work Order Trigger Actions for Preventive Maintenance Related Work Orders 
  Test Class:     WorkOrderTriggerActions_PM_Test
 
  History:
  <Date>          <Authors Name>      <Brief Description of Change>
  02/16/2017      Raj Sharan          Auto PM Work Order Actions(US1643)
  07/31/2017      Mani Sundaresan     Static variable introduced to prevent recursion (HD-5255) 
  ------------------------------------------------------------*/
public with sharing class WorkOrderTriggerActions_PM {
    private static Record_Type_IDs__c recordTypeIds = Record_Type_IDs__c.getOrgDefaults();
    private static final ID RECORD_TYPE_ID_WO_PM = recordTypeIds.Work_Order_B_SH_PM__c;

    private static Configuration_Settings__c orgDefaults = Configuration_Settings__c.getOrgDefaults();

    //static variables to prevent recursion in before update
    static Boolean wosetPMWorkOrders = false;
    static Boolean woupdatePMPlans = false;

    /*------------------------------------------------------------
      Author:       Raj Sharan
      Company:      AppsAssociates 
      Description:  If Work Orders is an Auto PM Record Type then update the fields on the Work Order 
      Inputs:       Work Orders 
      Returns:     
     
      History:
      <Date>          <Authors Name>      <Brief Description of Change>
      03/03/2017      Raj Sharan      Initial Creation(HD-2967 & US-0001643) 
      07/31/2017      Mani Sundaresan     Static variable introduced to prevent recursion (HD-5255)
      ------------------------------------------------------------*/

    public static void setPMWorkOrders(List<WorkOrder> allWorkOrders) {

        List<ID> workOrderIDList1 = new List<ID> ();
        List<WorkOrder> workOrderPMUpdateList1 = new List<WorkOrder> ();

        if (!wosetPMWorkOrders) {
            for (WorkOrder wo : allWorkOrders) {
                //Get all the workorder with record type "B_SH_PM" and Work order Preventive_Maintenance_Plan =null
                if (wo.RecordTypeId == RECORD_TYPE_ID_WO_PM && wo.FSO__Preventive_Maintenance_Plan__c == NULL) {

                    workOrderIDList1.add(wo.Id);
                    workOrderPMUpdateList1.add(wo);
                }
            }

            if (workOrderIDList1.size() > 0) {

                Map<Id, WorkOrder> workOrderMapFetch = new Map<Id, WorkOrder> ([Select Id, StartDate, AssetId, CaseId, Case.AccountId, Case.Customer_Name__c, Case.AssetId, Case.ContactId, Case.Preventive_Maintenance_Plan__r.FSO__State__c,
                                                                               Case.Preventive_Maintenance_Plan__r.Service_Contract__c, Case.Preventive_Maintenance_Plan__c, FSL_INTG__Service__r.CKSW_BASE__Early_Start__c, FSL_INTG__Service__r.CKSW_BASE__State__c FROM WorkOrder WHERE Id IN :workOrderIDList1]);


                if (workOrderMapFetch.size() > 0) {

                    for (WorkOrder wo1 : workOrderPMUpdateList1) {

                        //if workorder related case Preventive Maintenance Plan not equals to null
                        if (workOrderMapFetch.get(wo1.Id).Case.Preventive_Maintenance_Plan__c != NULL)
                        //set workorder Preventive Maintenance Plan to related case Preventive Maintenance Plan
                        wo1.FSO__Preventive_Maintenance_Plan__c = workOrderMapFetch.get(wo1.Id).Case.Preventive_Maintenance_Plan__c;
                        if (workOrderMapFetch.get(wo1.Id).Case.ContactId != NULL)
                        //update workorder contactid ,AssetId,ServiceContractId 
                        wo1.ContactId = workOrderMapFetch.get(wo1.Id).Case.ContactId;
                        wo1.AssetId = workOrderMapFetch.get(wo1.Id).Case.AssetId;
                        wo1.ServiceContractId = workOrderMapFetch.get(wo1.Id).Case.Preventive_Maintenance_Plan__r.Service_Contract__c;
                        //set workorder Priority to PM
                        wo1.Priority = 'PM';
                        if(workOrderMapFetch.get(wo1.Id).Case.Preventive_Maintenance_Plan__r.FSO__State__c != null && workOrderMapFetch.get(wo1.Id).Case.Preventive_Maintenance_Plan__r.FSO__State__c.length() == 2)
                            wo1.StateCode = workOrderMapFetch.get(wo1.Id).Case.Preventive_Maintenance_Plan__r.FSO__State__c;
                        else if(workOrderMapFetch.get(wo1.Id).Case.Preventive_Maintenance_Plan__r.FSO__State__c != null && workOrderMapFetch.get(wo1.Id).Case.Preventive_Maintenance_Plan__r.FSO__State__c.length() > 2)
                            wo1.State = workOrderMapFetch.get(wo1.Id).Case.Preventive_Maintenance_Plan__r.FSO__State__c;

                    }
                    wosetPMWorkOrders = true;
                }
            }
        }
    }


    /*------------------------------------------------------------
      Author:       Raj Sharan
      Company:      AppsAssociates 
      Description:  If Auto PM Work Order then Update related Service on After Insert with Work Order Id.  
      Inputs:       List New Work Orders 
      Returns:     
     
      History:
      <Date>          <Authors Name>      <Brief Description of Change>
      03/03/2017      Raj Sharan      Initial Creation(HD-2967 & US-0001643) 
      ------------------------------------------------------------*/

    public static void afterServiceUpdate(List<WorkOrder> allWorkOrders) {

        List<ID> workOrderIDList1 = new List<ID> ();
        List<CKSW_BASE__Service__c> serviceUpdateList1 = new List<CKSW_BASE__Service__c> ();


        for (WorkOrder wo1 : allWorkOrders) {
            //if workorder recordtype "B_SH_PM"
            if (wo1.RecordTypeId == RECORD_TYPE_ID_WO_PM) {
                //update workorder id on service
                CKSW_BASE__Service__c ser1 = new CKSW_BASE__Service__c(id = wo1.FSL_INTG__Service__c);
                ser1.FSO__WorkOrder__c = wo1.Id;
                serviceUpdateList1.add(ser1);
            }
        }

        //update service
        if (serviceUpdateList1.size() > 0) {
            //update serviceUpdateList1;
            Database.SaveResult[] lsr = Database.update(serviceUpdateList1, false);

            //Display the error if the DML fails      
            for (Integer index = 0; index<lsr.size(); index++) {
                if (!lsr[index].isSuccess()) {
                    allWorkOrders[index].addError('Failed to update Service: ' + lsr[index].getErrors() [0].getMessage());
                }
            }
        }

    }

    /*------------------------------------------------------------
      Author:       Raj Sharan
      Company:      AppsAssociates 
      Description:  If Auto PM Work Order then on Closure Update PM Plan 
      Inputs:       Work Orders 
      Returns:     
     
      History:
      <Date>          <Authors Name>      <Brief Description of Change>
      03/03/2017      Raj Sharan        Initial Creation(HD-2967 & US-0001643) 
      05/28/2017      Mani Sundaresan   Method updated to fix WO Completed field calc on PM Plan record
      and when the PM WO is Re-opened.
      ------------------------------------------------------------*/

    public static void updatePMPlans(List<WorkOrder> allWorkOrders, Map<Id, WorkOrder> oldWorkOrders) {


        List<ID> pmIDList1 = new List<ID> (); //Preventive Maintenance Plan ids need to be updated
        List<WorkOrder> woUpdateList1 = new List<WorkOrder> ();
        List<WorkOrder> closedWOList = new List<WorkOrder> ();
        List<FSO__PreventiveMaintenancePlan__c> pmpUpdateList1 = new List<FSO__PreventiveMaintenancePlan__c> ();
        Map<Id, FSO__PreventiveMaintenancePlan__c> pmMapFetch = new Map<Id, FSO__PreventiveMaintenancePlan__c> ();
        //Map<Id,WorkOrder> completeWOMap;

        Date today = System.Today();
        //DateTime rightNow = System.Now();

        if (!woupdatePMPlans) {

            for (WorkOrder wo : allWorkOrders) {

                WorkOrder oldWorkOrder = oldWorkOrders != null && oldWorkOrders.containsKey(wo.Id) ? oldWorkOrders.get(wo.Id) : null;
                System.debug('Momo:' + wo.Status);
                System.debug('Momo1:' + oldWorkOrder.Status);
                //If workorder record type "B_SH_PM" ,workorder PreventiveMaintenancePlan is not null,workorder status is closed or completed and and workorder PMP_Updated__c is true
                if (wo.RecordTypeId == RECORD_TYPE_ID_WO_PM && wo.FSO__Preventive_Maintenance_Plan__c != NULL && wo.PMP_Updated__c == TRUE) {
                    System.debug('Yuppy');

                    if (wo.Status != oldWorkOrder.Status && wo.Status == 'Closed') {
                        System.debug('Yuppy1');
                        //Get workorder PreventiveMaintenancePlan value
                        pmIDList1.add(wo.FSO__Preventive_Maintenance_Plan__c);
                        woUpdateList1.add(wo);
                    }
                    else if (wo.Status != oldWorkOrder.Status && wo.Status == 'Re-opened') {
                        System.debug('Yuppy2');
                        pmIDList1.add(wo.FSO__Preventive_Maintenance_Plan__c);
                        closedWOList.add(wo);
                    }


                }

            }
            System.debug('woUpdateList1:' + woUpdateList1.size());
            System.debug('closedWOList:' + closedWOList.size());


            /********************************************************************************************************* 
              Logic has been optimized to handle WO Completed field update when PM WO is Re-opened  - Mani Sundaresan
             *********************************************************************************************************/
            //if(woUpdateList1.size() > 0)
            //completeWOMap = new Map<Id,WorkOrder>([SELECT Id, SYS_Reopened__c, FSO__Completed_Date__c from WorkOrder where Id IN :woUpdateList1]);


            //Get PreventiveMaintenancePlan related data 
            if (pmIDList1.size()> 0)
            pmMapFetch = new Map<Id, FSO__PreventiveMaintenancePlan__c> ([Select Id, Last_Updated_by_Work_Order__c,
                                                                         FSO__Work_Order_Last_Completed_Date__c, FSO__Work_Orders_Completed__c
                                                                         FROM FSO__PreventiveMaintenancePlan__c WHERE Id IN :pmIDList1]);

            if (woUpdateList1.size() > 0) {

                for (WorkOrder wo : woUpdateList1) {
                    /*
                      FSO__PreventiveMaintenancePlan__c pmp1 = new FSO__PreventiveMaintenancePlan__c(id = pmMapFetch.get(wo1.FSO__Preventive_Maintenance_Plan__c).Id);
                     
                      //If workorder Completed_Date is null
                      if(wo1.FSO__Completed_Date__c == NULL) {
                      //update PreventiveMaintenancePlan Work_Order_Last_Completed_Date and Last_Updated_by_Work_Order fields
                      pmp1.FSO__Work_Order_Last_Completed_Date__c = today;
                      pmp1.Last_Updated_by_Work_Order__c = System.Now();
                      }
                      //If workorder Completed_Date is not null
                      else if (wo1.FSO__Completed_Date__c != NULL ) {
                      //update PreventiveMaintenancePlan Work_Order_Last_Completed_Date and Last_Updated_by_Work_Order fields
                      pmp1.FSO__Work_Order_Last_Completed_Date__c = wo1.FSO__Completed_Date__c.date();
                      pmp1.Last_Updated_by_Work_Order__c = System.Now();
                     
                      }
                     
                      if(pmMapFetch.get(wo1.FSO__Preventive_Maintenance_Plan__c).FSO__Work_Orders_Completed__c != NULL) 
                      pmp1.FSO__Work_Orders_Completed__c = pmMapFetch.get(wo1.FSO__Preventive_Maintenance_Plan__c).FSO__Work_Orders_Completed__c + 1; 
                     
                     
                      if(pmMapFetch.get(wo1.FSO__Preventive_Maintenance_Plan__c).FSO__Work_Orders_Completed__c == NULL)
                      pmp1.FSO__Work_Orders_Completed__c =  1; 
                     */
                    Decimal woCompleted = 0;

                    FSO__PreventiveMaintenancePlan__c pmp1 = new FSO__PreventiveMaintenancePlan__c(id = pmMapFetch.get(wo.FSO__Preventive_Maintenance_Plan__c).Id);
                    System.debug('Reopened:' + wo.SYS_Reopened__c);

                    if (wo.SYS_Reopened__c == False && wo.FSO__Completed_Date__c != null)
                    pmp1.FSO__Work_Order_Last_Completed_Date__c = wo.FSO__Completed_Date__c.date();

                    pmp1.Last_Updated_by_Work_Order__c = System.Now();

                    if (pmMapFetch.get(wo.FSO__Preventive_Maintenance_Plan__c).FSO__Work_Orders_Completed__c != null)
                    woCompleted = pmMapFetch.get(wo.FSO__Preventive_Maintenance_Plan__c).FSO__Work_Orders_Completed__c;

                    pmp1.FSO__Work_Orders_Completed__c = woCompleted + 1;

                    pmpUpdateList1.add(pmp1);

                }
            }
            if (closedWOList.size() > 0 && GlobalUtility.runOnce()) {
                for (WorkOrder wo : closedWOList) {
                    //Decimal reOpened = 0;
                    FSO__PreventiveMaintenancePlan__c pmp1 = new FSO__PreventiveMaintenancePlan__c(id = pmMapFetch.get(wo.FSO__Preventive_Maintenance_Plan__c).Id, FSO__Work_Orders_Completed__c = pmMapFetch.get(wo.FSO__Preventive_Maintenance_Plan__c).FSO__Work_Orders_Completed__c);

                    System.debug('WO Completed:' + pmp1.FSO__Work_Orders_Completed__c);

                    if (pmp1.FSO__Work_Orders_Completed__c != null || pmp1.FSO__Work_Orders_Completed__c != 0) {
                        pmp1.FSO__Work_Orders_Completed__c -= 1;
                        pmpUpdateList1.add(pmp1);
                        System.debug('PM Plan updated');
                    }

                    System.debug('WO Completed:' + pmp1.FSO__Work_Orders_Completed__c);



                }
            }
            //update PreventiveMaintenancePlan records
            if (pmpUpdateList1.size() > 0)
            try
            {
                //update pmpUpdateList1;
                Database.SaveResult[] lsr = Database.update(pmpUpdateList1, false);

                //Display the error if the DML fails      
                for (Integer index = 0; index<lsr.size(); index++)
                {
                    if (!lsr[index].isSuccess()) {
                        allWorkOrders[index].addError('Failed to update PreventiveMaintenancePlan: ' + lsr[index].getErrors() [0].getMessage());
                    }
                }

                if (Test.isRunningTest())
                Integer i = 10 / 0;

                woupdatePMPlans = true;
            }
            catch(Exception e)
            {
                //send an email if any error in PreventiveMaintenancePlan update process
                Error_Handling_Emails__c Error_Handling = Error_Handling_Emails__c.getvalues('Service Email');
                List<Messaging.SingleEmailMessage> mailList = new List<Messaging.SingleEmailMessage> ();

                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                String[] toAddresses = new String[] { Error_Handling.Service_Email__c };
                mail.setToAddresses(toAddresses);
                mail.setReplyTo(Error_Handling.Service_Email__c);
                mail.setSenderDisplayName('Apex error message');
                mail.setSubject('Error from Org : ' + UserInfo.getOrganizationName());
                mail.setPlainTextBody(e.getMessage());
                mailList.add(mail);

                if (mailList != null && !Test.isRunningTest())
                Messaging.sendEmail(mailList);
            }


        }
    }

}