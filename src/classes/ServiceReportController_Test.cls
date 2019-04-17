/***************************************************************************************
Author : Niraj
Company : Hexaware Technologies
Description : Test Class for ServiceReportController 

History:
<Date>         <Author Name>            <Brief Description of Change>     <Copa.do US#>
09/24/2018      Niraj                   Initial Creation                   US-0005791
10/15/2018      Niraj Wani              Asset Sharing changes              US-0005861
11/02/2018      Nomita Walke            Invoked fetchConfigData()            US-0006062
11/13/2018      Niraj Wani            Updated sharing issue                US-0006075
11/20/2018      Niraj Wani              Account Validation                 US-0006167
*******************************************************************************************/
@isTest 
public class ServiceReportController_Test {
    private static Account customerAccount;
    private static Product_Source_Division__c psd;
    private static Product2 prod;
    private static Account siteAccount;
    private static List<Product2> products = new List<Product2>();
    private static List<Asset> assets = new List<Asset>();
    private static Map<Id, Id> assetToProduct = new Map<Id, Id>();
    private static List<Case> cases = new List<Case>();
    private static Asset a1;
    private static User u;
    private static Contact cont;
    
    static testMethod void TestServiceReport() {
        
        TestUtility.setupConfigurationSettings();
        
        Trigger_Switch__c ts = new Trigger_Switch__c();
        ts.Name = 'UserTrigger';
        ts.Active__c = true;
        insert ts;
        
        customerAccount = TestUtility.newAccount('Customer Account', 'testCust', null, null, GlobalUtility.getRecordTypeId('Account', 'Customer'));
        insert customerAccount;
        
        siteAccount = TestUtility.newAccount('Site Account', 'testSite', 'ABC Street', customerAccount.Id,GlobalUtility.getRecordTypeId('Account', 'Site'));
        insert siteAccount;
        
        System.debug('siteAccount: ' + siteAccount);
        
        cont = new Contact();
        cont.FirstName='Test';
        cont.LastName='Test';
        cont.Accountid= siteAccount.id;
        database.insert(cont);
        
        //Create custom setting data for test class
        Id recID = GlobalUtility.getRecordTypeId('WorkOrder','B_SH_FE_Service');
        System.debug('WO recID:' + recID);
        CSRWOTypes__c configSetting = new CSRWOTypes__c();
        configSetting.Name = 'Test';
        configSetting.RecordType_Id__c = recID; 
        configSetting.RecordType_Name__c =  'B_SH_FE_Service';
        database.insert(configSetting); 
        
        Product_Source_Division__c psd = TestUtility.newProductSourceDivision('1234','MAMMOGRAPHY');
        psd.Sunshine_Act__c =true;
        Insert psd;
        system.debug('psd===='+psd);
        Product_Source_Division__c psd1 = TestUtility.newProductSourceDivision('12345','MOLECULAR');
        Insert psd1;
        
        Product2 prod = TestUtility.newProduct('Prodrec');
        insert prod;
        for(Integer i = 0; i < 1; i++){
            products.add(TestUtility.newProduct('Product '+i));
            products[i].Product_Source_Division__c = psd.id;
            products[i].Replacement_Part__c = prod.id;
            products[i].Community_Visible__c = true;
        }
        insert products;
        
        for(Product2 p : products){
            a1=TestUtility.newAsset(siteAccount.Name + ' Asset ' + p.Name, siteAccount.Id, customerAccount.Id,p.Id);
            a1.ContactId= cont.Id;
            a1.RecordTypeId = GlobalUtility.getRecordTypeId('Asset','System');
            //a1.Community_Visible1__c = true;
            assets.add(a1);
            
        }
        insert assets;
        
        for(Asset a : assets){
            assetToProduct.put(a.Id, a.Product2Id);
            cases.add(TestUtility.newCase(siteAccount.Id, null, a.Id, null,GlobalUtility.getRecordTypeId('Case','Support'), 'Applications', 'New', 'Low', 'Phone'));
        }
        Case cs = cases.get(0); 
        cs.ClosedDate = Date.today();
        cs.ContactId = cont.Id;
        
        //Create User 
        //Profile
        //Customer Community Plus Login User - Custom
        Profile p = [SELECT Id FROM Profile WHERE Name=:Label.Community_Profile_Name]; 
        u = new User(Alias = 'hotest', Email='hotest@test.com', 
                     EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                     LocaleSidKey='en_US', ProfileId = p.Id, 
                     TimeZoneSidKey='America/Los_Angeles', UserName='hotest@test.com', ContactId=cont.Id);
        database.insert(u);
        
        System.debug('User Account: ' + u.AccountId);
        
        //Assume read access to asset through sharing rule 
        /* AssetShare assetShr  = new AssetShare();
assetShr.AssetId = a1.Id;
assetShr.UserOrGroupId = u.Id;
assetShr.AssetAccessLevel = 'Read';
assetShr.RowCause = Schema.AssetShare.RowCause.Manual;
Database.SaveResult sr2 = Database.insert(assetShr,false); 
*/
        
        System.runAs (u) 
        { 
            insert cases;
        }
        
        System.debug('Cases' + cases);
        
        WorkOrder wo = TestUtility.newWorkOrder(siteAccount.Id, cs.Id, a1.Id, 'New');
        wo.ContactId = cont.Id;
        wo.RecordTypeId = GlobalUtility.getRecordTypeId('WorkOrder','B_SH_FE_Service');
        System.debug('wo.RecordTypeId' + wo.RecordTypeId);
        insert wo;
        
        WorkOrderLineItem woli = TestUtility.newWorkOrderLineItem(wo.Id, a1.Id, GlobalUtility.getRecordTypeId('WorkOrderLineItem','Labor'), 'New');
        woli.Note_Type__c = 'FE Update';
        insert woli;
        
        
        WorkOrderShare woShr  = new WorkOrderShare();
        woShr.ParentId = wo.Id;
        woShr.UserOrGroupId = u.Id;
        woShr.AccessLevel = 'Read';
        woShr.RowCause = Schema.WorkOrderShare.RowCause.Manual;
        Database.SaveResult sr = Database.insert(woShr,false); 
        
        
        ServiceAppointment SA = TestUtility.newServiceAppointment(siteAccount.Id, 'Scheduled', wo.Id, Date.today(), Date.today());
        SA.Date_Time_Dispatched__c = Date.today();
        SA.ContactId = cont.Id;        
        insert SA;
        
        ServiceAppointmentShare saShr  = new ServiceAppointmentShare();
        saShr.ParentId = SA.Id;
        saShr.UserOrGroupId = u.Id;
        saShr.AccessLevel = 'Read';
        saShr.RowCause = Schema.WorkOrderShare.RowCause.Manual;
        Database.SaveResult sr2 = Database.insert(saShr,false); 
        
        
        System.debug('Service Appointment:' + SA);
        System.runAs (u) 
        { 
            
            test.startTest();
           
            //Test all controller methods
            ServiceReportController.AccountStepResult accountResult = new ServiceReportController.AccountStepResult();
            accountResult =  ServiceReportController.GetAccountData ();    
            //Verify Account returned 
            //System.assertEquals(2,accountResult.accountWrapper.size());
            boolean accountReturned = false;
            List<ServiceReportController.account_Wrapper> accountWrapper = accountResult.accountWrapper;
            for (ServiceReportController.account_Wrapper accWrap: accountWrapper ) 
            {
                if (accWrap.acc.Name == 'Site Account')
                {
                    accountReturned = true;
                }
            }
            System.assertEquals(true, accountReturned);
            
            ServiceReportController.MasterResult m = new ServiceReportController.MasterResult();
            m = ServiceReportController.GetAssetData(siteAccount.id,'Site','');
            //One asset returned
            System.assertEquals(1, m.mas.size);
            String strAssetJSON = m.masterJSON;
            
            ServiceReportController.CaseStepResult csStepResult = ServiceReportController.GetCaseDetailsData(siteAccount.id,'Site', a1.Id, null, null);
            //one case based on asset selection
            System.debug('Case Result: ' + csStepResult);
            System.assertEquals(1,csStepResult.caseWrapper.size());
            for (ServiceReportController.case_Wrapper c: csStepResult.caseWrapper) {
                c.selected = true;
            }
            String caseStepResult = System.JSON.serialize(csStepResult);
            
            String strWOJSON =  ServiceReportController.GetWODetailsData (siteAccount.id,'Site', cs.id,caseStepResult, strAssetJSON, a1.Id);
            System.debug('strWOJSON:' + strWOJSON);
            ServiceReportController.Master result = (ServiceReportController.Master) System.JSON.deserialize(strWOJSON, ServiceReportController.Master.class);
            System.debug(result.accountAddress);
            String strAddress = result.accountAddress;
            System.assertEquals('ABC',strAddress.mid(0, 3));
            
            List<ServiceAppointment> lstSA = new List<ServiceAppointment>();
            lstSA = ServiceReportController.GetSADetailsData(siteAccount.Id,'Site', a1.Id, '2018-01-01', '2099-12-31');
            System.assertEquals(1,lstSA.size());  
            
            //Asset Data 
            ServiceReportController.MasterResult mAssetOnly = new ServiceReportController.MasterResult();
            mAssetOnly = ServiceReportController.GetAssetData(a1.Id, '', 'Asset');
            System.assertEquals(1, mAssetOnly.mas.size);
            
            String mAssetOnlyJSON;
            mAssetOnlyJSON = ServiceReportController.GetWODetailsData(a1.Id, '', cs.id,caseStepResult, strAssetJSON, a1.Id);
            ServiceReportController.Master resultAssetOnly = (ServiceReportController.Master) System.JSON.deserialize(mAssetOnlyJSON, ServiceReportController.Master.class);
            strAddress = resultAssetOnly.accountAddress;
            System.assertEquals('ABC',strAddress.mid(0, 3));
            ServiceReportController.fetchConfigData(); 
            
            test.stopTest();
            
        }
        
        
    }
    
    
    
    
}