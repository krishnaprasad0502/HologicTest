/*------------------------------------------------------------
Author:       Mani Sundaresan
Description:  Test Class for ProfileDataListController 

History:
<Date>       <Authors Name>    <Brief Description of Change>
03/21/2019   Mani Sundaresan    Initial Creation ()             
------------------------------------------------------------*/
@isTest 
private class ProfileDataListController_Test {

    private static void createTestData(){
        //Setup Data
        TestUtility.setupConfigurationSettings();
        //TestUtility.insertCustSetting('ProfileDataTrigger');

        Account custAcc = TestUtility.newAccountWithAddresses('Account-Customer', null, GlobalUtility.getRecordTypeId('Account', 'Customer'), 
                    '123 test', 'BillingCity', 'Massachusetts', 'United States', '55555', 
                    '123 test', 'ShippingCity', 'Massachusetts', 'United States', '55555');
        
        insert custAcc;
        
        Account custAcc1 = TestUtility.newAccountWithAddresses('Account-Customer1', null, GlobalUtility.getRecordTypeId('Account', 'Customer'), 
                    '123 test', 'BillingCity', 'Massachusetts', 'United States', '55555', 
                    '123 test', 'ShippingCity', 'Massachusetts', 'United States', '55555');
        custAcc1.ParentId = custAcc.Id;
        insert custAcc1;
        
        Account siteAcc1 = TestUtility.newAccountWithAddresses('Account-Site1', null, GlobalUtility.getRecordTypeId('Account', 'Site'), 
                    '123 test', 'BillingCity', 'Massachusetts', 'United States', '55555', 
                    '123 test', 'ShippingCity', 'Massachusetts', 'United States', '55555');
        siteAcc1.ParentId = custAcc.Id;
        insert siteAcc1;
        
        Account siteAcc2 = TestUtility.newAccountWithAddresses('Account-Site2', null, GlobalUtility.getRecordTypeId('Account', 'Site'), 
                    '123 test', 'BillingCity', 'Massachusetts', 'United States', '55555', 
                    '123 test', 'ShippingCity', 'Massachusetts', 'United States', '55555');
        siteAcc2.ParentId = custAcc1.Id;
        insert siteAcc2;

        //Insert Profile record
        Profile__c prof = new Profile__c(Active__c = true, Type__c='Diagnostics | Molecular', Category__c='STIs', Exclude_from_Segmentation__c=false);
        insert prof;
        
        //Inserting Average Selling Price records
        Profile_ASP__c pasp = new Profile_ASP__c(Profile__c = prof.Id, Country__c='United States', ASP__c=100);
        
        insert pasp;
        
        //Inserting ProfileData records
        
        Profile_Data__c pd1 = new Profile_Data__c(RecordTypeId=GlobalUtility.getRecordTypeId('Profile_Data__c', 'Lab_Landscape'), Profile__c=prof.Id, Volume__c=Integer.valueOf('1000'), Segment_ASP__c=Integer.valueOf('3'), Account__c=custAcc.Id, Division__c='Diagnostics | Molecular', Account_Site__c=siteAcc1.Id);
        insert pd1;
        
        Profile_Data__c pd2 = new Profile_Data__c(RecordTypeId=GlobalUtility.getRecordTypeId('Profile_Data__c', 'Lab_Landscape'), Profile__c=prof.Id, Volume__c=Integer.valueOf('1000'), Segment_ASP__c=Integer.valueOf('3'), Account__c=custAcc1.Id, Division__c='Diagnostics | Molecular', Account_Site__c=siteAcc2.Id);
        insert pd2;
        
        Opportunity opp = TestUtility.newOpportunity('Test Opportunity',custAcc.Id,date.today(),'Prospecting','Expected');
        opp.RecordTypeId = (Id)(String.valueOf(GlobalUtility.getRecordTypeId('Opportunity','International_Diagnostics_Sales_Opportunity')).substring(0,15));
        insert opp;
        
        Opportunity opp1 = TestUtility.newOpportunity('Test Opportunity1',custAcc1.Id,date.today(),'Prospecting','Expected');
        opp1.RecordTypeId = (Id)(String.valueOf(GlobalUtility.getRecordTypeId('Opportunity','International_Diagnostics_Sales_Opportunity')).substring(0,15));
        insert opp1;
    }

    @isTest
    private static void testFindAll() {
        
        //Setup Data
        TestUtility.setupConfigurationSettings();
        //TestUtility.insertCustSetting('ProfileDataTrigger');

        Account custAcc = TestUtility.newAccountWithAddresses('Account-Customer', null, GlobalUtility.getRecordTypeId('Account', 'Customer'), 
                    '123 test', 'BillingCity', 'Massachusetts', 'United States', '55555', 
                    '123 test', 'ShippingCity', 'Massachusetts', 'United States', '55555');
        
        insert custAcc;
        
        Account custAcc1 = TestUtility.newAccountWithAddresses('Account-Customer1', null, GlobalUtility.getRecordTypeId('Account', 'Customer'), 
                    '123 test', 'BillingCity', 'Massachusetts', 'United States', '55555', 
                    '123 test', 'ShippingCity', 'Massachusetts', 'United States', '55555');
        custAcc1.ParentId = custAcc.Id;
        insert custAcc1;
        
        Account siteAcc1 = TestUtility.newAccountWithAddresses('Account-Site1', null, GlobalUtility.getRecordTypeId('Account', 'Site'), 
                    '123 test', 'BillingCity', 'Massachusetts', 'United States', '55555', 
                    '123 test', 'ShippingCity', 'Massachusetts', 'United States', '55555');
        siteAcc1.ParentId = custAcc.Id;
        insert siteAcc1;
        
        Account siteAcc2 = TestUtility.newAccountWithAddresses('Account-Site2', null, GlobalUtility.getRecordTypeId('Account', 'Site'), 
                    '123 test', 'BillingCity', 'Massachusetts', 'United States', '55555', 
                    '123 test', 'ShippingCity', 'Massachusetts', 'United States', '55555');
        siteAcc2.ParentId = custAcc1.Id;
        insert siteAcc2;

        //Insert Profile record
        Profile__c prof = new Profile__c(Active__c = true, Type__c='Diagnostics | Molecular', Category__c='STIs', Exclude_from_Segmentation__c=false);
        insert prof;
        
        //Inserting Average Selling Price records
        Profile_ASP__c pasp = new Profile_ASP__c(Profile__c = prof.Id, Country__c='United States', ASP__c=100);
        
        insert pasp;
        
        //Inserting ProfileData records
        
        Profile_Data__c pd1 = new Profile_Data__c(RecordTypeId=GlobalUtility.getRecordTypeId('Profile_Data__c', 'Lab_Landscape'), Profile__c=prof.Id, Volume__c=Integer.valueOf('1000'), Segment_ASP__c=Integer.valueOf('3'), Account__c=custAcc.Id, Division__c='Diagnostics | Molecular', Account_Site__c=siteAcc1.Id);
        insert pd1;
        
        Profile_Data__c pd2 = new Profile_Data__c(RecordTypeId=GlobalUtility.getRecordTypeId('Profile_Data__c', 'Lab_Landscape'), Profile__c=prof.Id, Volume__c=Integer.valueOf('1000'), Segment_ASP__c=Integer.valueOf('3'), Account__c=custAcc1.Id, Division__c='Diagnostics | Molecular', Account_Site__c=siteAcc2.Id);
        insert pd2;
        
        Opportunity opp = TestUtility.newOpportunity('Test Opportunity',custAcc.Id,date.today(),'Prospecting','Expected');
        opp.RecordTypeId = (Id)(String.valueOf(GlobalUtility.getRecordTypeId('Opportunity','International_Diagnostics_Sales_Opportunity')).substring(0,15));
        insert opp;
        
        Opportunity opp1 = TestUtility.newOpportunity('Test Opportunity1',custAcc1.Id,date.today(),'Prospecting','Expected');
        opp1.RecordTypeId = (Id)(String.valueOf(GlobalUtility.getRecordTypeId('Opportunity','International_Diagnostics_Sales_Opportunity')).substring(0,15));
        insert opp1;
    
        Test.startTest();
        
        List<ProfileDataListController.wrapProfData> testWrapProfData = ProfileDataListController.findAll(opp.Id);
        List<ProfileDataListController.wrapProfData> testWrapProfData1 = ProfileDataListController.findAll(opp1.Id);

        System.assertEquals(true,testWrapProfData.size() > 0);
        System.assertEquals(true,testWrapProfData1.size() > 0);

        Test.stopTest();

    }
    
    @isTest
    private static void testsaveProfData() {
        
        
        //Setup Data
        TestUtility.setupConfigurationSettings();
        //TestUtility.insertCustSetting('ProfileDataTrigger');

        Account custAcc = TestUtility.newAccountWithAddresses('Account-Customer', null, GlobalUtility.getRecordTypeId('Account', 'Customer'), 
                    '123 test', 'BillingCity', 'Massachusetts', 'United States', '55555', 
                    '123 test', 'ShippingCity', 'Massachusetts', 'United States', '55555');
        insert custAcc;
        
        Account siteAcc1 = TestUtility.newAccountWithAddresses('Account-Site1', null, GlobalUtility.getRecordTypeId('Account', 'Site'), 
                    '123 test', 'BillingCity', 'Massachusetts', 'United States', '55555', 
                    '123 test', 'ShippingCity', 'Massachusetts', 'United States', '55555');
        siteAcc1.ParentId = custAcc.Id;
        insert siteAcc1;
        
        
        //Insert Profile record
        Profile__c prof = new Profile__c(Active__c = true, Type__c='Diagnostics | Molecular', Category__c='STIs', Exclude_from_Segmentation__c=false);
        insert prof;
        
        //Inserting Average Selling Price records
        Profile_ASP__c pasp = new Profile_ASP__c(Profile__c = prof.Id, Country__c='United States', ASP__c=100);
        insert pasp;
        
        //Inserting ProfileData records
        
        Profile_Data__c pd1 = new Profile_Data__c(RecordTypeId=GlobalUtility.getRecordTypeId('Profile_Data__c', 'Lab_Landscape'), Profile__c=prof.Id, Volume__c=Integer.valueOf('1000'), Segment_ASP__c=Integer.valueOf('3'), Account__c=custAcc.Id, Division__c='Diagnostics | Molecular', Account_Site__c=siteAcc1.Id);
        insert pd1;
        
        Opportunity opp = TestUtility.newOpportunity('Test Opportunity',custAcc.Id,date.today(),'Prospecting','Expected');
        opp.RecordTypeId = (Id)(String.valueOf(GlobalUtility.getRecordTypeId('Opportunity','International_Diagnostics_Sales_Opportunity')).substring(0,15));
        opp.Account_Site__c = siteAcc1.Id; 
        insert opp;
        
        Pipeline_Products__c pp = new Pipeline_Products__c(Opportunity__c = opp.Id);
        insert pp;
        
        Test.startTest();
        List<ProfileDataListController.wrapProfData> testWrapProfData = ProfileDataListController.findAll(opp.Id);
        for(ProfileDataListController.wrapProfData wd : testWrapProfData)
            wd.selected = true;
        ProfileDataListController.saveProfData(JSON.serialize(testWrapProfData),opp.Id);
        
        Test.stopTest();
    }
    
}