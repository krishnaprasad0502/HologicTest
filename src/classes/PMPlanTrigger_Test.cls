/*------------------------------------------------------------
Author:         Amarendra Nagireddy
Company:        Apps Associates
Description:    Test class to validate PMPlansTriggerActions
                Tests Excecuted:
                         
History:
<Date>          <Authors Name>        <Brief Description of Change>
03/16/2017      Amarendra Nagireddy    Initial Creation
05/31/2017      Amarendra Nagireddy    Added account id to FSO__PreventiveMaintenancePlan__c test record to cover Process Builder - "Case - Update Customer Name"
06/15/2017      Raj Sharan             Updated for new method in Test Utility for inserting Custom Setting
-------------------------------------------------------------------*/

@isTest
private class PMPlanTrigger_Test {

    private static Configuration_Settings__c orgDefaults;
    private static Date Today; 
    private static Site_Location__c sitelocation;
    private static Account SiteAccount;
    private static Account custAccount;
    private static contact aContact;
    Private static Asset anAsset; 
    private static Pricebook2 customPB;
    
    static 
    {
        
       TestUtility.insertCustSetting('sitelocTrigger');
        
        Today = System.Today();
        
         System.runAs ( new User(Id = UserInfo.getUserId()) ) {
    
        //Creating a queue for B&SH Service Admin
         Group grp = new Group(Name='B&SH Service Admin', type='Queue');
         insert grp;
         QueuesObject que = new QueueSObject(QueueID = grp.id, SobjectType = 'Case');
         insert que;
         
         orgDefaults = TestUtility.setupConfigurationSettings();
         orgDefaults.PM_Case_Owner__c=grp.Id;
         update orgDefaults;
         }
         
        
        
        
        //insert account
        
        custAccount = TestUtility.newAccount('Customer Account', 'testCust', 'ABC Street', null, GlobalUtility.getRecordTypeId('Account', 'Customer'));
        custAccount.BillingCountryCode = 'US';
        custAccount.BillingStateCode = 'NY';
        custAccount.BillingPostalCode='75034';
        insert custAccount;
        SiteAccount= TestUtility.newAccount('Site Account', 'testSite', 'ABC Street', null, GlobalUtility.getRecordTypeId('Account', 'Site'));
        SiteAccount.BillingCountryCode = 'US';
        SiteAccount.BillingStateCode = 'NY';            
        insert SiteAccount;
        
        //Insert Contact
        aContact = TestUtility.newContact('Default', 'Contact', custAccount.Id);
        aContact.Email = 'First.LastName@appsassociates.com';
        Insert aContact;
        
        
        sitelocation = TestUtility.newSiteLocation('Site Location', 'Address1', 'Address2', 'addr3', 'addr4'
            , 'city', 'HI','75034', 'US', null, SiteAccount.Id, true);
        insert sitelocation;
        
        TestUtility.insertCustSetting('ContactTrigger'); 
        TestUtility.insertCustSetting('OpportunityTrigger'); 
        TestUtility.insertCustSetting('PMPlans'); 
        TestUtility.insertCustSetting('CaseTrigger');
        
      
    }
    
    static testMethod void PMP_Plans_Test() {
        
        FSO__PreventiveMaintenancePlanTemplate__c  Pmtemplate = new FSO__PreventiveMaintenancePlanTemplate__c();
        Pmtemplate.Name='PreventiveMaintenanceTemplate Test';
        Pmtemplate.FSO__Work_Order_Type__c='Install';
        Pmtemplate.FSO__Work_Order_Priority__c='Medium';
        Pmtemplate.FSO__Status__c='Active';
        Pmtemplate.FSO__Schedule_Frequency__c='Monthly';
        Pmtemplate.FSO__Schedule_Duration__c='1 Year';
        Pmtemplate.Days_in_Advance_Create_Work_Order__c = 60;
        
        Test.StartTest();
        insert Pmtemplate;
                  
        CKSW_BASE__Service_Type__c  SerRec1 = New CKSW_BASE__Service_Type__c();
        SerRec1.Name='Test';
        SerRec1.CKSW_BASE__Duration__c=4;
        SerRec1.CKSW_BASE__Duration_Type__c='Hours';
        SerRec1.Work_Order_Type__c='PM';
        insert SerRec1;
        CKSW_BASE__Location__c loc=new CKSW_BASE__Location__c(Field_Service_Manager__c=userInfo.getUserId(),CKSW_BASE__First_Day_of_Working_Week__c='Sunday',CKSW_BASE__System_Jobs__c='BATCH_ServicesInJeopardy',CKSW_BASE__Time_Zone__c='Asia/Kolkata');
        insert loc;
        List<Product2> prodList2 = new List<Product2>();
       
         Product_Source_Division__c psd = TestUtility.newProductSourceDivision('1234','MAMMOGRAPHY');
       psd.Service_Region__c=loc.id;
        Insert psd;
        system.debug('psd===='+psd);
        Product_Source_Division__c psd1 = TestUtility.newProductSourceDivision('12345','MOLECULAR');
         psd1.Service_Region__c=loc.id;
        Insert psd1;
         Product2 prod = TestUtility.newProduct('Prodrec');
        insert prod;
        for(Integer i = 0; i < 1; i++){
            prodList2.add(TestUtility.newProduct('Product '+i));
            prodList2[i].Product_Source_Division__c = psd.id;
            prodList2[i].Replacement_Part__c = prod.id;
        }
        insert prodList2;
        
        List<User> userList2 = TestUtil_Hologic1.getUsers(1);
        insert userList2;
        
        CKSW_BASE__Zip_Code__c zip=new CKSW_BASE__Zip_Code__c();
        zip.Name='75034';
        zip.Country__c='US';
        insert zip;
        
        anAsset=TestUtility.newAsset(SiteAccount.Name + ' Asset 01', SiteAccount.Id, custAccount.Id, prodList2[0].Id);
        anAsset.Install_Location__c=sitelocation.id;
        insert anAsset;
        
        customPB=TestUtility.newPricebook('Custom Pricebook');
        insert customPB; 
        
        PricebookEntry customPrice=new PricebookEntry();
        customPrice= TestUtility.newPricebookEntry(customPB.Id,  prodList2[0].Id, 12000);
        insert customPrice;
                
        Date StartDate = Date.today();
        Date EndDate = StartDate.addDays(30); 

        ServiceContract sc2 = new ServiceContract();
        sc2 = TestUtility.newServiceContract('Service Contract 1', SiteAccount.Id, GlobalUtility.getRecordTypeId('ServiceContract','B_SH_Purchase_Order'), customPB.id,StartDate, EndDate );
        sc2.ApprovalStatus = 'Draft';
        sc2.Internal_Contact__c = userList2[0].Id; 
        sc2.Description = 'Description ';
        insert sc2;
        
       ContractLineItem cl1 = new ContractLineItem();
        cl1 = TestUtility.newContractLineItem(sc2.ID, customPrice.Id, 2, 500, anAsset.Id);
        insert cl1;



        SlaProcess workOrderEntitlementProcess;
        try{
            workOrderEntitlementProcess = [Select Id, Name From SlaProcess Where SObjectType = 'WorkOrder' Limit 1];
        }
        catch(Exception e){}
        System.assertNotEquals(null, workOrderEntitlementProcess, 'SETUP ERROR: test cannot proceed, no Work Order SLA Processes were found.');
        
        // create Business Hours
        BusinessHours businessHours;
        try{
            businessHours = [Select Id, Name From BusinessHours Limit 1];
        }
        catch(Exception e){}
        System.assertNotEquals(null, businessHours, 'SETUP ERROR: test cannot proceed, no Business Hours were found.');
        
        // create Coverage Group
        Coverage_Group__c coverageGroup;
        coverageGroup = TestUtility.newCoverageGroup('Test Coverage Group');
        insert coverageGroup;
        
        // create Coverage Template
        Integer int1 =3;
        
        Coverage_Template__c coverageTemplates; 
        coverageTemplates = new Coverage_Template__c();
        
        coverageTemplates = TestUtility.newCoverageTemplate('Test Coverage Template', coverageGroup.Id, GlobalUtility.getRecordTypeId('Coverage_Template__c', 'B_SH_SLA'), prodList2[0].Id, null, null, String.valueOf(Math.mod(int1, 5) + 1), null, workOrderEntitlementProcess.Name, int1+'-'+prodList2[0].Id);
        
        insert coverageTemplates;
        
        Entitlement en1 = new Entitlement();
        en1 = TestUtility.newEntitlement('Test PM Entitlment', businessHours.Id, workOrderEntitlementProcess.Id, SiteAccount.Id, anAsset.Id, coverageGroup.ID , coverageTemplates.ID, GlobalUtility.getRecordTypeId('Entitlement', 'B_SH_PM'),  StartDate, EndDate, null, null );
        en1.StartDate=system.today()-3;
        en1.EndDate=system.today()+3;
        insert en1;
        
        FSO__PreventiveMaintenancePlanTemplate__c  Pmtemplate1 = new FSO__PreventiveMaintenancePlanTemplate__c();
            Pmtemplate1.Name='PreventiveMaintenanceTemplate Test';
            Pmtemplate1.FSO__Work_Order_Type__c='Install';
            Pmtemplate1.FSO__Work_Order_Priority__c='Medium';
            //Pmtemplate.CurrencyIsoCode='';
            Pmtemplate1.FSO__Status__c='Active';
            Pmtemplate1.FSO__Schedule_Frequency__c='Monthly';
            Pmtemplate1.Days_in_Advance_Create_Work_Order__c = 60;
            Pmtemplate1.FSO__Schedule_Duration__c='1 Year';
                 insert Pmtemplate1;
        
        FSO__PreventiveMaintenancePlan__c  PmpRec4 = new FSO__PreventiveMaintenancePlan__c();
            PmpRec4.Name='PreventiveMaintenancePlan Test';
            PmpRec4.FSO__Work_Order_Last_Completed_Date__c=System.Today();
            PmpRec4.FSO__Contact__c = aContact.Id; 
            PmpRec4.FSO__Status__c = 'New';
            PmpRec4.FSO__Account__c=custAccount.id;
            PmpRec4.Service_Type__c =  SerRec1.id;
            PmpRec4.FSO__Work_Order_Last_Completed_Date__c=System.Today();
            PmpRec4.FSO__Preventive_Maintenance_Plan_Template__c=Pmtemplate1.id;
            PmpRec4.FSO__Work_Orders_Completed__c=20;
            PmpRec4.Total_PMs_To_Perform__c=40;
        
            date mydate = System.Today();
            PmpRec4.FSO__End_Date__c=mydate.addMonths(3);
            PmpRec4.Entitlement__c=en1.id;
            PmpRec4.Asset__c=anAsset.id;
            insert PmpRec4;
         
            
            system.assertNotEquals(null,PmpRec4.FSO__Preventive_Maintenance_Plan_Template__c);
            system.assertNotEquals(null,PmpRec4.FSO__Contact__c);
            system.assertNotEquals(null,PmpRec4.Entitlement__c);
            system.assertNotEquals(null,PmpRec4.Asset__c);
            system.assertNotEquals(null,PmpRec4.FSO__Work_Orders_Completed__c);
            system.assertNotEquals(null,PmpRec4.Service_Type__c);
        
            List<FSO__PreventiveMaintenancePlan__c> update_Pmplan=[select id,Service_Contract__c,FSO__Status__c from FSO__PreventiveMaintenancePlan__c where id=:PmpRec4.id];
            FSO__PreventiveMaintenancePlan__c pmp1=update_Pmplan[0];
            pmp1.FSO__Status__c='Scheduled';
            update pmp1;
            
            pmp1.FSO__Status__c='In Progress';
            update pmp1;
           
            
            pmp1.FSO__Work_Orders_Completed__c=20;
            pmp1.Total_PMs_To_Perform__c=20;
            update pmp1;
       		pmp1.FSO__Work_Order_Last_Completed_Date__c=null;
       		 update pmp1;
            
            
            
            FSO__PreventiveMaintenancePlan__c Get_PMP=[select id,Service_Contract__c,FSO__Status__c,FSO__PostalCode__c,FSO__Schedule_Duration__c,FSO__Schedule_Frequency__c from FSO__PreventiveMaintenancePlan__c where id=:PmpRec4.id];
           
            Test.StopTest();
            
            system.assertEquals(en1.ServiceContractId,Get_PMP.Service_Contract__c);
            system.assertEquals(sitelocation.Zip_Code__c,Get_PMP.FSO__PostalCode__c);
            system.assertEquals(Pmtemplate1.FSO__Schedule_Duration__c,Get_PMP.FSO__Schedule_Duration__c);
            system.assertEquals(Pmtemplate1.FSO__Schedule_Frequency__c,Get_PMP.FSO__Schedule_Frequency__c);
            
            
    }

    
}