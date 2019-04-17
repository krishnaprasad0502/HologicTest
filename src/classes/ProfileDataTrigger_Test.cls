/*------------------------------------------------------------
Author:         Mani Sundaresan
Company:        Hologic
Description:    Test class to validate ProfileDataTrigger
                Tests Excecuted:
                
                
History:
<Date>          <Authors Name>      <Brief Description of Change>
03/12/2019      Mani Sundaresan       Initial Creation (US-0006881)
------------------------------------------------------------*/
@isTest
private class ProfileDataTrigger_Test{

    static{
        TestUtility.setupConfigurationSettings();
        TestUtility.insertCustSetting('ProfileDataTrigger');
    }
    
    static testMethod void test_setProfileASP(){
        
        Test.startTest();
        //Insert Account record
        Account custAcc = TestUtility.newAccountWithAddresses('Account-Customer', null, GlobalUtility.getRecordTypeId('Account', 'Customer'), 
                    '123 test', 'BillingCity', 'Massachusetts', 'United States', '55555', 
                    '123 test', 'ShippingCity', 'Massachusetts', 'United States', '55555');
        
        insert custAcc;
        
        Account siteAcc1 = TestUtility.newAccountWithAddresses('Account-Site1', null, GlobalUtility.getRecordTypeId('Account', 'Site'), 
                    '123 test', 'BillingCity', 'Massachusetts', 'United States', '55555', 
                    '123 test', 'ShippingCity', 'Massachusetts', 'United States', '55555');
        
        insert siteAcc1;
        
        Account siteAcc2 = TestUtility.newAccountWithAddresses('Account-Site2', null, GlobalUtility.getRecordTypeId('Account', 'Site'), 
                    '123 test', 'BillingCity', 'Massachusetts', 'United States', '55555', 
                    '123 test', 'ShippingCity', 'Massachusetts', 'United States', '55555');
        
        insert siteAcc2;
        
        //Insert Profile record
        Profile__c prof = new Profile__c(Active__c = true, Type__c='Diagnostics | Molecular', Category__c='STIs', Exclude_from_Segmentation__c=false);
        insert prof;
        
        //Inserting Average Selling Price records
        Profile_ASP__c pasp = new Profile_ASP__c(Profile__c = prof.Id, Country__c='United States', ASP__c=100);
        
        insert pasp;
        
        //Inserting ProfileData records
        List<Profile_Data__c> pdList = new List<Profile_Data__c>();
        
        Profile_Data__c pd1 = new Profile_Data__c(RecordTypeId=GlobalUtility.getRecordTypeId('Profile_Data__c', 'Lab_Landscape'), Profile__c=prof.Id, Volume__c=Integer.valueOf('1000'), Segment_ASP__c=Integer.valueOf('3'), Account__c=custAcc.Id, Division__c='Diagnostics | Molecular', Account_Site__c=siteAcc1.Id);
        pdList.add(pd1);
        
        Profile_Data__c pd2 = new Profile_Data__c(RecordTypeId=GlobalUtility.getRecordTypeId('Profile_Data__c', 'Lab_Landscape'), Profile__c=prof.Id, Volume__c=Integer.valueOf('1000'), Segment_ASP__c=Integer.valueOf('3'), Account__c=custAcc.Id, Division__c='Diagnostics | Molecular', Account_Site__c=siteAcc2.Id);
        pdList.add(pd2);
        
        
        insert pdList;
        
        Test.stopTest();
        
        Profile_ASP__c paspAfterInsert = [SELECT Id, ASP__c from Profile_ASP__c where Id = :pasp.Id];
        
        List<Profile_Data__c> profDataList = [SELECT Id, Segment_ASP__c from Profile_Data__c where Id IN :pdList];
        
        for(Profile_Data__c pd : profDataList){
            System.assertEquals(true, pd.Segment_ASP__c == paspAfterInsert.ASP__c);
        }   
    
    
    }
    
    static testMethod void test_setProfileTotalVolume(){
        
        Test.startTest();
        //Insert Account record
        Account custAcc = TestUtility.newAccountWithAddresses('Account-Customer', null, GlobalUtility.getRecordTypeId('Account', 'Customer'), 
                    '123 test', 'BillingCity', 'Massachusetts', 'United States', '55555', 
                    '123 test', 'ShippingCity', 'Massachusetts', 'United States', '55555');
        
        insert custAcc;
        
        Account siteAcc1 = TestUtility.newAccountWithAddresses('Account-Site1', null, GlobalUtility.getRecordTypeId('Account', 'Site'), 
                    '123 test', 'BillingCity', 'Massachusetts', 'United States', '55555', 
                    '123 test', 'ShippingCity', 'Massachusetts', 'United States', '55555');
        
        insert siteAcc1;
        
        Account siteAcc2 = TestUtility.newAccountWithAddresses('Account-Site2', null, GlobalUtility.getRecordTypeId('Account', 'Site'), 
                    '123 test', 'BillingCity', 'Massachusetts', 'United States', '55555', 
                    '123 test', 'ShippingCity', 'Massachusetts', 'United States', '55555');
        
        insert siteAcc2;
        
        //Insert Profile record
        Profile__c prof = new Profile__c(Active__c = true, Type__c='Diagnostics | Molecular', Category__c='STIs', Exclude_from_Segmentation__c=false);
        insert prof;
        
        //Inserting Average Selling Price records
        Profile_ASP__c pasp = new Profile_ASP__c(Profile__c = prof.Id, Country__c='United States', ASP__c=100);
        
        insert pasp;
        
        //Inserting ProfileData records
        List<Profile_Data__c> pdList = new List<Profile_Data__c>();
        
        Profile_Data__c pd1 = new Profile_Data__c(RecordTypeId=GlobalUtility.getRecordTypeId('Profile_Data__c', 'Lab_Landscape'), Profile__c=prof.Id, Volume__c=Integer.valueOf('1000'), Segment_ASP__c=Integer.valueOf('3'), Account__c=custAcc.Id, Division__c='Diagnostics | Molecular', Account_Site__c=siteAcc1.Id);
        pdList.add(pd1);
        
        Profile_Data__c pd2 = new Profile_Data__c(RecordTypeId=GlobalUtility.getRecordTypeId('Profile_Data__c', 'Lab_Landscape'), Profile__c=prof.Id, Volume__c=Integer.valueOf('1000'), Segment_ASP__c=Integer.valueOf('3'), Account__c=custAcc.Id, Division__c='Diagnostics | Molecular', Account_Site__c=siteAcc2.Id);
        pdList.add(pd2);
        
        insert pdList;
        
        for(Profile_Data__c pd : pdList){
            pd.Volume__c = Integer.valueOf('50');
        }
        
        update pdList;
        
        Test.stopTest();  
        
        List<Profile_Data__c> profDataList = [SELECT Id, Segment_Total_Threshold__c, Segment_Total_Volume__c from Profile_Data__c where Id IN :pdList];
        
        for(Profile_Data__c pd : profDataList){
            System.assertEquals(50, pd.Segment_Total_Volume__c);
            System.assertEquals(5000, pd.Segment_Total_Threshold__c);
        }   
      
    }
    
        
}