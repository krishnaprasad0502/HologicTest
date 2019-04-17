/*------------------------------------------------------------
Author:         Raj Sharan
Company:        AppsAssociates 
Description:    PM Trigger Functions
Test Class:     PMPlanTrigger_Test

History:
<Date>          <Authors Name>          <Brief Description of Change>
03/03/2017      Raj Sharan           Initial Creation(HD-2967 & US-0001643) 
04/04/2017      Amarendra Nagireddy  rather than hard coding case ownerid value assigned through custom setting "Configuration_Settings__c"
06/06/2017      Raj Sharan      Update to determine Serivce Locations based on three Business Divisions and bulkify results by using a Map (US-0002006) 
12/12/2017      Mani Sundaresan       Updated to assign PM cases to Diag PM queue when the PM has a Diag PM Template (US-0003723)
------------------------------------------------------------*/

public with sharing class PMPlanTriggerActions {

      private static final ID RECORD_TYPE_ID_CASE_PM = GlobalUtility.getRecordTypeId('Case', 'B_SH_PM');
private static Configuration_Settings__c orgDefaults = Configuration_Settings__c.getOrgDefaults();

  //Static variable to prevent recursion in before update
    static Boolean assessPMPlanFlag = FALSE;
    
    
/*------------------------------------------------------------
Author:       Raj Sharan
Company:      AppsAssociates 
Description:  Determine whether to Create a PM Case, Service.
              Based on Status being 'Scheduled' and if PM Plan has additional PMs to create.
              If true to create update fields on PM Plan then create PM Case and Service
Inputs:       List of PM Plans,Map of Old PMPlans
Returns: 
    
History:
<Date>          <Authors Name>      <Brief Description of Change>
03/03/2017      Raj Sharan      Initial Creation(HD-2967 & US-0001643) 
------------------------------------------------------------*/

    public static void assessPMPlan(List<FSO__PreventiveMaintenancePlan__c> allPMPlans, Map<Id, FSO__PreventiveMaintenancePlan__c> oldPMPlans){

    List<Id> updateIdPMPlans = new List<Id>();
    List<FSO__PreventiveMaintenancePlan__c> updatePMPlans = new List<FSO__PreventiveMaintenancePlan__c>();
    List<FSO__PreventiveMaintenancePlan__c> pmPlansCreateCase = new List<FSO__PreventiveMaintenancePlan__c>();
    List<FSO__PreventiveMaintenancePlan__c> closePMPlans = new List<FSO__PreventiveMaintenancePlan__c>();
    List<String> accountPostalCodeList = new List<String>();
        
    //Map<Id, FSO__PreventiveMaintenancePlanTemplate__c> pmPlanTemplateMap = new Map<Id, FSO__PreventiveMaintenancePlanTemplate__c>();

    Boolean activatePMPlan = FALSE;
    Boolean closePMPlan = FALSE;
    Boolean inProgressPMPlan = FALSE;
    DateTime  scheduledDateTimeService;
    Date today = System.today();


      if(allPMPlans != NULL && oldPMPlans != NULL){


        for(FSO__PreventiveMaintenancePlan__c pmp0:allPMPlans){

          activatePMPlan = FALSE;
          closePMPlan = FALSE;
          inProgressPMPlan = FALSE;
    
             //If PreventiveMaintenancePlan(PMP) PMPTemplate,Contact,Entitlement,Asset,ServiceType, Status and Work order completed not =null
    
             if(pmp0.FSO__Preventive_Maintenance_Plan_Template__c != NULL && pmp0.FSO__Contact__c != NULL && pmp0.Entitlement__c != NULL && pmp0.Asset__c != NULL && 
                pmp0.Service_Type__c != NULL && pmp0.FSO__Status__c != NULL && pmp0.FSO__Work_Orders_Completed__c != NULL){

               if(pmp0.Total_PMs_To_Perform__c != 0 && (pmp0.Total_PMs_To_Perform__c == pmp0.FSO__Work_Orders_Completed__c)) closePMPlan = TRUE; 

                // If current PMP status equals Scheduled and old PMP status not equal to Scheduled

                if(pmp0.FSO__Status__c == 'Scheduled' &&  oldPMPlans.get(pmp0.Id).FSO__Status__c != 'Scheduled') activatePMPlan = TRUE; 
     
                if((((pmp0.FSO__Status__c == 'In Progress' &&  oldPMPlans.get(pmp0.Id).FSO__Status__c == 'In Progress') && 
                (pmp0.FSO__Work_Order_Last_Completed_Date__c != oldPMPlans.get(pmp0.Id).FSO__Work_Order_Last_Completed_Date__c)) || 
                (pmp0.FSO__Status__c == 'In Progress' &&  oldPMPlans.get(pmp0.Id).FSO__Status__c == 'Scheduled')) && !closePMPlan) inProgressPMPlan = TRUE; 

                 // If activatePMPlan is true add PMP record to update list

                 if(activatePMPlan) {
        
                   updatePMPlans.add(pmp0); 
                   updateIdPMPlans.add(pmp0.Id);
                   accountPostalCodeList.add(pmp0.Account_Postal_Code__c);

                 }

                 // If inProgressPMPlan is true add PMP record to pmPlansCreateCase list

                 if(inProgressPMPlan){

                 scheduledDateTimeService = PMPlanTriggerActions.calculateDateTime(pmp0.FSO__Work_Order_Last_Completed_Date__c, pmp0.FSO__Start_Date__c, pmp0.Frequency_Months__c, 
                                                                           pmp0.Days_in_Advance_Create_Work_Order__c); 

                 pmp0.Next_Scheduled_Date_Time__c = scheduledDateTimeService.addDays(Integer.valueOf(pmp0.Days_in_Advance_Create_Work_Order__c)); 
                 pmp0.Next_Create_PM_Schedule_Date_Time__c = scheduledDateTimeService;
                 pmPlansCreateCase.add(pmp0);
                 //pmPlanTemplateMap(pmp0.Id, pmp0.FSO__Preventive_Maintenance_Plan_Template__c);

                 }

                // If closePMPlan is true add PMP record to closePMPlans list
                if(closePMPlan)  closePMPlans.add(pmp0);
             }
          }

        // updatePMPlans list size > 0 call updatePMPRecords method
        if(updatePMPlans.size() > 0 && updateIdPMPlans.size() > 0) {
        
        PMPlanTriggerActions.updatePMPRecords(updateIdPMPlans, updatePMPlans, accountPostalCodeList); 

        }
        
        //pmPlansCreateCase list size>0 call createPMCase Method

        if(pmPlansCreateCase.size() > 0){
        
          PMPlanTriggerActions.createPMCase(pmPlansCreateCase);

        }

        // IF closePMPlans list size>0 call closePMPlans method
        if(closePMPlans.size() > 0) {
        
          PMPlanTriggerActions.closePMPlans(closePMPlans); 

         }

         assessPMPlanFlag = TRUE;

      }

    }

    /*------------------------------------------------------------
    Author:       Raj Sharan
    Company:      AppsAssociates 
    Description:  Update PM Plan fields requiring informaiton 
           
    Inputs:       List of PM Plans id and List PM plans to update
    Returns: 

    History:
    <Date>          <Authors Name>      <Brief Description of Change>
    03/03/2017      Raj Sharan      Initial Creation(HD-2967 & US-0001643) 
    06/06/2017      Raj Sharan      Update to determine Serivce Locations based on three Business Divisions and bulkify results by using a Map (US-0002006) 
    ------------------------------------------------------------*/

    public static void updatePMPRecords(List<Id> updateIdPMPlans, List<FSO__PreventiveMaintenancePlan__c> updatePMPlans, List<String> accountPostalCodes){

      DateTime scheduledDateTimeService;
      Decimal totalPMWorkOrders;
      List<FSO__PreventiveMaintenancePlan__c> pmListCreatePMCase = new List<FSO__PreventiveMaintenancePlan__c>();
      DateTime rightNow = System.Now();
      String contractStatus = '';
      Map<String,CKSW_BASE__Zip_Code__c> mapPostalCodeValues = new Map<String, CKSW_BASE__Zip_Code__c>();

      if(updateIdPMPlans.size() > 0){
      //Get PMP records and related Entitlement,PMP Template,Asset details based on PMP ids
        Map<Id, FSO__PreventiveMaintenancePlan__c> pmpMap = new Map<Id, FSO__PreventiveMaintenancePlan__c>( [Select Id, Name, FSO__Work_Order_Priority__c, 
        Asset__c, FSO__Account__c, FSO__Account__r.ParentId, FSO__Contact__c, 
        FSO__Work_Order_Type__c, Service_Contract__c, FSO__End_Date__c, FSO__Schedule_Duration__c, FSO__Schedule_Frequency__c, FSO__Start_Date__c,  Total_PMs_To_Perform__c,
        Entitlement__r.ServiceContractId, Entitlement__r.ContractLineItem.EndDate, FSO__Preventive_Maintenance_Plan_Template__r.Name, FSO__Preventive_Maintenance_Plan_Template__r.FSO__Schedule_Duration__c, 
        FSO__Preventive_Maintenance_Plan_Template__r.FSO__Schedule_Frequency__c, Entitlement__r.ContractLineItem.StartDate, Entitlement__r.Status,
        FSO__Preventive_Maintenance_Plan_Template__r.FSO__Work_Order_Priority__c, FSO__Preventive_Maintenance_Plan_Template__r.FSO__Work_Order_Type__c, 
        FSO__Preventive_Maintenance_Plan_Template__r.Days_in_Advance_Create_Work_Order__c, Asset__r.Product2.Product_Source_Division__r.Service_Region__c, 
        Asset__r.SerialNumber, Asset__r.Install_Location__r.Zip_Code__c, Asset__r.Install_Location__r.City__c, Asset__r.Install_Location__r.State__c, 
        Asset__r.Install_Location__r.Country__c, Asset__r.Install_Location__r.Address_Line_1__c, FSO__PreventiveMaintenancePlan__c.Frequency_Months__c 
        From FSO__PreventiveMaintenancePlan__c Where Id IN: updateIdPMPlans]);


         // 06-06-2017 Update Raj Sharan  Query for the Serivce Locations based on three Business Divisions and bulkify by using a Map (US-0002006) 
        
         if(accountPostalCodes.size() > 0) {  
         
           //Get service loaction details based on zip code
           List<CKSW_BASE__Zip_Code__c> zipCodeValue = new List<CKSW_BASE__Zip_Code__c>([Select Id, Name,  Surgical_Location__c, Surgical_Location__r.Root_Service_Team__c,
           Service_Location__c, Service_Location__r.Root_Service_Team__c, Diagnostic_Location__c, Diagnostic_Location__r.Root_Service_Team__c
           FROM CKSW_BASE__Zip_Code__c WHERE Name = :accountPostalCodes]); 


           if(zipCodeValue.size() > 0){ 

             for(CKSW_BASE__Zip_Code__c zc1:zipCodeValue){
               mapPostalCodeValues.put(zc1.Name, zc1);
             } 

            }
          }
 
          // End of Update for (US-0002007) 

          if(updateIdPMPlans.size() > 0) {

            for(FSO__PreventiveMaintenancePlan__c pmp1 : updatePMPlans){

            // Calculate toal workorders based on ContractLineItem startdate ,enddate and PMP Frequency Months

              totalPMWorkOrders =  PMPlanTriggerActions.determineTotalPMs(pmpMap.get(pmp1.Id).Entitlement__r.ContractLineItem.StartDate, 
                                 pmpMap.get(pmp1.Id).Entitlement__r.ContractLineItem.EndDate, pmp1.Frequency_Months__c);

             scheduledDateTimeService = PMPlanTriggerActions.calculateDateTime(pmp1.FSO__Work_Order_Last_Completed_Date__c, 
                                         pmpMap.get(pmp1.Id).Entitlement__r.ContractLineItem.StartDate, pmp1.Frequency_Months__c, pmp1.Days_in_Advance_Create_Work_Order__c); 

             contractStatus = pmpMap.get(pmp1.Id).Entitlement__r.Status;

             //Update PMP fields

             pmp1.Customer_Name__c = pmpMap.get(pmp1.Id).FSO__Account__r.ParentId;
             pmp1.Service_Contract__c = pmpMap.get(pmp1.Id).Entitlement__r.ServiceContractId;
             pmp1.FSO__End_Date__c = pmpMap.get(pmp1.Id).Entitlement__r.ContractLineItem.EndDate;
             pmp1.FSO__Schedule_Duration__c = pmpMap.get(pmp1.Id).FSO__Preventive_Maintenance_Plan_Template__r.FSO__Schedule_Duration__c;
             pmp1.FSO__Schedule_Frequency__c = pmpMap.get(pmp1.Id).FSO__Preventive_Maintenance_Plan_Template__r.FSO__Schedule_Frequency__c;
             pmp1.FSO__Start_Date__c = pmpMap.get(pmp1.Id).Entitlement__r.ContractLineItem.StartDate;
             pmp1.FSO__Work_Order_Priority__c = pmpMap.get(pmp1.Id).FSO__Preventive_Maintenance_Plan_Template__r.FSO__Work_Order_Priority__c;
             pmp1.FSO__Work_Order_Type__c = pmpMap.get(pmp1.Id).FSO__Preventive_Maintenance_Plan_Template__r.FSO__Work_Order_Type__c;
             pmp1.FSO__Street_Address__c =  pmpMap.get(pmp1.Id).Asset__r.Install_Location__r.Address_Line_1__c;
             pmp1.FSO__City__c =  pmpMap.get(pmp1.Id).Asset__r.Install_Location__r.City__c;
             pmp1.FSO__State__c =  pmpMap.get(pmp1.Id).Asset__r.Install_Location__r.State__c;
             pmp1.FSO__PostalCode__c =  pmpMap.get(pmp1.Id).Asset__r.Install_Location__r.Zip_Code__c;
             pmp1.FSO__Country__c =  pmpMap.get(pmp1.Id).Asset__r.Install_Location__r.Country__c;
             pmp1.Service_Location__c = PMPlanTriggerActions.determineServiceLocation(pmp1.Account_Postal_Code__c, 
             pmpMap.get(pmp1.Id).Asset__r.Product2.Product_Source_Division__r.Service_Region__c, mapPostalCodeValues);
             pmp1.Next_Create_PM_Schedule_Date_Time__c = scheduledDateTimeService; 
             pmp1.Next_Scheduled_Date_Time__c = scheduledDateTimeService.addDays(Integer.valueOf(pmp1.Days_in_Advance_Create_Work_Order__c)); 
             pmp1.Total_PMs_To_Perform__c = totalPMWorkOrders;

              // If current date time is greater than next PM Schedule Date Time 

               if(rightNow >= scheduledDateTimeService)  {
               //Update PMP fields
                 pmp1.Next_Scheduled_Date_Time__c = rightnow.addDays(1);
                 pmp1.FSO__Status__c = 'In Progress';
                 pmListCreatePMCase.add(pmp1);

                }

                // If current date time is less than  next PM Schedule Date Time  and PMP related Entitlement status is active
                if(rightNow <= scheduledDateTimeService && contractStatus == 'Active')  {
     
                  pmp1.FSO__Status__c = 'In Progress';

                  // Add PMP record to pmListCreatePMCase list to create new case

                  pmListCreatePMCase.add(pmp1);

                }
              }
            }
          }

         if(pmListCreatePMCase.size() > 0) PMPlanTriggerActions.createPMCase(pmListCreatePMCase); 

     }

     /*------------------------------------------------------------
     Author:       Raj Sharan
     Company:      AppsAssociates 
     Description:  Create PM Case 
                   Based on Status being 'In Progress' or If Scheduled Date is greater than now.  
         
     Inputs:       List of PM Plans 
     Returns: 

     History:
     <Date>          <Authors Name>      <Brief Description of Change>
     03/03/2017      Raj Sharan            Initial Creation(HD-2967 & US-0001643) 
     12/12/2017      Mani Sundaresan       Updated to assign PM cases to Diag PM queue when the PM has a Diag PM Template (US-0003723)
     ------------------------------------------------------------*/

     public static void createPMCase(List<FSO__PreventiveMaintenancePlan__c> pmCasePlans){

         List<Case> addPMCaseList = new List<Case>();
         //Fetch PM details
         Map<Id,FSO__PreventiveMaintenancePlan__c> pmpTempMap = new Map<Id,FSO__PreventiveMaintenancePlan__c>([SELECT Id, FSO__Preventive_Maintenance_Plan_Template__r.Name from FSO__PreventiveMaintenancePlan__c Where Id IN: pmCasePlans]);
       

         for(FSO__PreventiveMaintenancePlan__c pmp2:pmCasePlans){

          // Create Case Record
   
         Case cs1 = new Case();
                  
           cs1.AssetId = pmp2.Asset__c;
           cs1.AccountId = pmp2.FSO__Account__c;
           cs1.Customer_Name__c = pmp2.Customer_Name__c; 
           cs1.ContactId = pmp2.FSO__Contact__c;
           cs1.Subject = 'Preventative Maintenance for SN: ' + pmp2.Asset_Serial_Number__c; 
           cs1.Description = 'Preventative Maintenance for SN: ' + pmp2.Asset_Serial_Number__c;
           cs1.Origin = 'Automatic';
           cs1.Priority = 'PM';
           cs1.Type = 'PM';
           cs1.Status = 'Dispatched';
           cs1.Preventive_Maintenance_Plan__c = pmp2.Id;
           cs1.Service_Location__c = pmp2.Service_Location__c;
           cs1.RecordTypeId = RECORD_TYPE_ID_CASE_PM;
           //cs1.OwnerId = '00G61000000anEb';
           system.debug('orgDefaults.PM_Case_Owner__c'+orgDefaults.PM_Case_Owner__c);
           if(pmpTempMap.size() > 0 && pmpTempMap.get(pmp2.Id).FSO__Preventive_Maintenance_Plan_Template__r.Name.contains('Diagnostic'))
               cs1.OwnerId = orgDefaults.Diagnostics_PM_Case_Owner__c;
           else
               cs1.OwnerId =orgDefaults.PM_Case_Owner__c;
                       
           addPMCaseList.add(cs1);

         }

         // Insert the Case
         if(addPMCaseList.size() > 0) {
   
           insert(addPMCaseList);

          }


          if(addPMCaseList.size() > 0){ 

          PMPlanTriggerActions.createPMService(pmCasePlans, addPMCaseList);

          }

     }

    /*------------------------------------------------------------
    Author:       Raj Sharan
    Company:      AppsAssociates 
    Description:  Create Service for the PM Cases 
              
    Inputs:       List of PM Plans, List of Cases Inserted
    Returns: 

    History:
    <Date>          <Authors Name>           <Brief Description of Change>
    03/03/2017      Raj Sharan            Initial Creation(HD-2967 & US-0001643) 
    03/28/2017      Amarendra Nagireddy   Added few changes to avoid duplicate Service and workorder creation
    ------------------------------------------------------------*/

    public static void createPMService (List<FSO__PreventiveMaintenancePlan__c> pmCasePlans,  List<Case> addPMCaseList){

      List<CKSW_BASE__Service__c> addPMServiceList = new List<CKSW_BASE__Service__c>();
      Map<Id,Case> PMPid_caseMap=new Map<Id,Case>(); //Map<PMP ID,Case>
    
        for(case casecheck:addPMCaseList){

        // put elements into Map, contains PMP Id as key and case as value, to use in further steps
        PMPid_caseMap.put(casecheck.Preventive_Maintenance_Plan__c,casecheck);

        }
   
        for(FSO__PreventiveMaintenancePlan__c pmp3 : pmCasePlans){
        //If Map Contains PMP Id
          if(PMPid_caseMap.containskey(pmp3.id)){
           //If PMP asset is equal to Case asset
            if(pmp3.Asset__c == PMPid_caseMap.get(pmp3.id).AssetId){
                
               // Create Service Record
                 CKSW_BASE__Service__c spm1 = new CKSW_BASE__Service__c();
                 spm1.FSL_INTG__Case__c = PMPid_caseMap.get(pmp3.id).Id; 
                 spm1.CKSW_BASE__Account__c = pmp3.FSO__Account__c; 
                 if(pmp3.FSO__Work_Order_Last_Completed_Date__c == NULL){
                     spm1.CKSW_BASE__Appointment_Start__c = pmp3.Next_Create_PM_Schedule_Date_Time__c;
                     spm1.CKSW_BASE__Early_Start__c =  pmp3.Next_Create_PM_Schedule_Date_Time__c;
                 }
                if(pmp3.FSO__Work_Order_Last_Completed_Date__c != NULL){
                    spm1.CKSW_BASE__Appointment_Start__c = pmp3.Next_Scheduled_Date_Time__c;
                    spm1.CKSW_BASE__Early_Start__c =  pmp3.Next_Scheduled_Date_Time__c;
                }    
                 spm1.CKSW_BASE__Auto_Geocode__c = TRUE; 
                 spm1.CKSW_BASE__City__c = pmp3.FSO__City__c;
                 spm1.CKSW_BASE__Description__c = PMPid_caseMap.get(pmp3.id).Subject;
                // if(pmp3.FSO__Work_Order_Last_Completed_Date__c == NULL)    spm1.CKSW_BASE__Early_Start__c =  pmp3.Next_Create_PM_Schedule_Date_Time__c;
                //if(pmp3.FSO__Work_Order_Last_Completed_Date__c != NULL)    spm1.CKSW_BASE__Early_Start__c =  pmp3.Next_Scheduled_Date_Time__c;
                 spm1.CKSW_BASE__Is_MultiDay__c = TRUE; 
                 spm1.CKSW_BASE__Location__c = PMPid_caseMap.get(pmp3.id).Service_Location__c;
                 spm1.CKSW_BASE__Service_Type__c = pmp3.Service_Type__c; 
                 spm1.CKSW_BASE__Street__c = pmp3.FSO__Street_Address__c; 
                 //spm1.CKSW_BASE__State__c = pmp3.FSO__State__c;
                 //spm1.CKSW_BASE__Country__c = pmp3.FSO__Country__c;
                 spm1.CKSW_Base__Zip__c = pmp3.FSO__PostalCode__c; 
                 addPMServiceList.add(spm1); 
            } 
        }
      }
 
     // Insert Service Record
    
     if(addPMServiceList.size() > 0) {
        insert addPMServiceList;
     }

   }

     /*------------------------------------------------------------
     Author:       Raj Sharan
     Company:      AppsAssociates 
     Description:  Determine the next Schedule Date for a PM Service. 
                  If no Last Date, then two thirds of the Frequency in Months else Last Completed Date plus Frequency_Months__c 
     Inputs:       Last Completed Date of PM Plan, Frequency of PM Plans 
     Returns: 

     History:
     <Date>          <Authors Name>      <Brief Description of Change>
     03/03/2017      Raj Sharan      Initial Creation(HD-2967 & US-0001643) 
     ------------------------------------------------------------*/

     private static DateTime calculateDateTime(Date lastCompletedDate, Date StartDate, Decimal frequencyMonths, Decimal daysInAdvance){

       Date Today = System.Today();
       Date scheduledDate;
       DateTime scheduledDateTime;
       Integer periodMonths = Integer.valueOf(frequencyMonths);
       Integer daysAdvance = Integer.valueOf(daysInAdvance);

         if(lastCompletedDate == NULL && periodMonths > 0) scheduledDate = StartDate.addMonths(periodMonths).addDays(-daysAdvance);

         if(lastCompletedDate != NULL && periodMonths > 0) scheduledDate = lastCompletedDate.addmonths(periodMonths).addDays(-daysAdvance); 

         // if(Today > scheduledDate)  scheduledDate = Today.addDays(1);

         Time myTime = Time.newInstance(0, 0, 0, 0);
         scheduledDateTime = DateTime.newInstance(scheduledDate, myTime); 

         return scheduledDateTime;

     }

     /*------------------------------------------------------------
     Author:       Raj Sharan
     Company:      AppsAssociates 
     Description:  Determine the Service Location for the Asset by taking Zip Code of Asset and retrieving from Zip Code Records the Service Location 
     Inputs:       Zip Code of Asset 
     Returns:      Service Location Id 

     History:
     <Date>          <Authors Name>      <Brief Description of Change>
     03/03/2017      Raj Sharan      Initial Creation(HD-2967 & US-0001643) 
     06/06/2017      Raj Sharan      Update to determine Serivce Locations based on three Business Divisions (US-0002006) 
     ------------------------------------------------------------*/

     private static Id determineServiceLocation(String zipCode, Id RootServiceTeam, Map<String,CKSW_BASE__Zip_Code__c> postalCodeValues){

       Id serviceLocationId;

         if(zipCode == NULL)   serviceLocationId = NULL; 

           if(zipCode != NULL && RootServiceTeam != NULL && !postalCodeValues.isEmpty())  { 

           system.debug('zipCode value'+zipCode);
 
           //Get service loaction details based on zip code

             if(postalCodeValues.get(zipCode).Surgical_Location__c != NULL && postalCodeValues.get(zipCode).Surgical_Location__r.Root_Service_Team__c != NULL){
               if(postalCodeValues.get(zipCode).Surgical_Location__r.Root_Service_Team__c == RootServiceTeam) {
               
                 serviceLocationId = postalCodeValues.get(zipCode).Surgical_Location__c;

               }
             }

             if(postalCodeValues.get(zipCode).Service_Location__c != NULL && postalCodeValues.get(zipCode).Service_Location__r.Root_Service_Team__c != NULL){
               if(postalCodeValues.get(zipCode).Service_Location__r.Root_Service_Team__c == RootServiceTeam) {
               
                 serviceLocationId = postalCodeValues.get(zipCode).Service_Location__c;

               }
             }

             if(postalCodeValues.get(zipCode).Diagnostic_Location__c != NULL && postalCodeValues.get(zipCode).Diagnostic_Location__r.Root_Service_Team__c != NULL){
               if(postalCodeValues.get(zipCode).Diagnostic_Location__r.Root_Service_Team__c == RootServiceTeam) {
               
                 serviceLocationId = postalCodeValues.get(zipCode).Diagnostic_Location__c;

               }
             }

           }
           return serviceLocationId;
       }

     /*------------------------------------------------------------
     Author:       Raj Sharan
     Company:      AppsAssociates 
     Description:  Determine Total PMs required for a PM Plan based on Frequency of PM Plan and Service Contract Start & End Dates.   
     Inputs:       PM Plan Start Date, PM Plan End Date & Frequency 
     Returns:      Total PMs 

     History:
     <Date>          <Authors Name>      <Brief Description of Change>
     03/03/2017      Raj Sharan      Initial Creation(HD-2967 & US-0001643) 
     ------------------------------------------------------------*/

     private static Decimal determineTotalPMs(Date startDate, Date endDate, Decimal frequency){

       Decimal totalPMs;

       //Calculate Total PMs based on start date, end date and frequency

         if(startDate != NULL && endDate != NULL && frequency != NULL && frequency > 0){

           totalPMs = (startDate.monthsBetween(EndDate)/frequency).round(System.RoundingMode.HALF_UP);
         }
    
         else if(startDate == NULL || endDate == NULL || frequency == NULL || frequency <= 0){

         totalPMs = Null;

         }

     return totalPMs;

     }

     /*------------------------------------------------------------
     Author:       Raj Sharan
     Company:      AppsAssociates 
     Description:  PM Plan closure actions. 
     Inputs:       PM Plan Start Date, PM Plan End Date & Frequency 
     Returns:      Closure Status 

     History:
     <Date>          <Authors Name>      <Brief Description of Change>
     03/03/2017      Raj Sharan      Initial Creation(HD-2967 & US-0001643) 

     ------------------------------------------------------------*/
   
     public static void closePMPlans(List<FSO__PreventiveMaintenancePlan__c> closePMPlans){

       List<FSO__PreventiveMaintenancePlan__c> closeUpdatePMPlans = new List<FSO__PreventiveMaintenancePlan__c>();

       if(closePMPlans.size()>0){
         for(FSO__PreventiveMaintenancePlan__c pmpClosed:closePMPlans){
           //Set PreventiveMaintenancePlan status to Complete
           pmpClosed.FSO__Status__c = 'Complete';

         }
        }
      }

}