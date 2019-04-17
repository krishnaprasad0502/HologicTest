/***************************************************************************************************
    Author       : Niraj Wani
    Company      : Hexaware Technologies
    Created Date : 10/11/2018 2:39 AM
    Description  : Test class for CommunitySelfRegistrationRequestTrigger   

    History:
    <Date>          <Author Name>                   <Brief Description of Change>   <Copa.do US#>
    8/13/2018       Community Enablement            Initial Creation                US-0005630 
    10/15/2018      Niraj Wani                      Asset Sharing                   US-0005861 
    11/01/2018      Vrushabh Katariya               TimeZone code covered           US-0005861 
    11/13/2018        Vrushabh katariya            Updated timezone code            US-0006062, US-0006075
    10/01/2019        Nomita Walke            Updated Profile with custom label US-0006524
***************************************************************************************************/
@isTest
public class CommunitySelfRegistrationReqTrigger_Test {
    
    @isTest static void TestCommunitySelfRegistrationReqTrigger() {
        
        list<Community_User_Mapper__mdt> CustomMetas = new list<Community_User_Mapper__mdt>();
        Community_User_Mapper__mdt cmdt1 = new Community_User_Mapper__mdt();
        cmdt1.MasterLabel = 'Community_Email';
        cmdt1.DeveloperName  = 'Community_Email';
        cmdt1.Community_Source_API__c = 'Community_Email__c';
        cmdt1.Community_Destination_Object_Type__c = 'User';
        cmdt1.Community_Destination_API__c = 'Username';
        CustomMetas.add(cmdt1);
            
        Community_User_Mapper__mdt cmdt2 = new Community_User_Mapper__mdt();
        cmdt2.MasterLabel = 'Community_Email2';
        cmdt2.DeveloperName  = 'Community_Email2';
        cmdt2.Community_Source_API__c = 'Community_Email__c';
        cmdt2.Community_Destination_Object_Type__c = 'User';
        cmdt2.Community_Destination_API__c = 'Email';
        CustomMetas.add(cmdt2);
        
        Community_User_Mapper__mdt cmdt3 = new Community_User_Mapper__mdt();
        cmdt3.MasterLabel = 'Mobile_Phone';
        cmdt3.DeveloperName  = 'Mobile_Phone';
        cmdt3.Community_Source_API__c = 'Community_Mobile_Phone__c';
        cmdt3.Community_Destination_Object_Type__c = 'User';
        cmdt3.Community_Destination_API__c = 'MobilePhone';
        CustomMetas.add(cmdt3);
        
        Community_User_Mapper__mdt cmdt4 = new Community_User_Mapper__mdt();
        cmdt4.MasterLabel = 'Street';
        cmdt4.DeveloperName  = 'Street';
        cmdt4.Community_Source_API__c = 'Community_Street_Address__c';
        cmdt4.Community_Destination_Object_Type__c = 'User';
        cmdt4.Community_Destination_API__c = 'Street';
        CustomMetas.add(cmdt4);
        
        Community_User_Mapper__mdt cmdt5 = new Community_User_Mapper__mdt();
        cmdt5.MasterLabel = 'Office_Phone';
        cmdt5.DeveloperName  = 'Office_Phone';
        cmdt5.Community_Source_API__c = 'Community_Office_Phone__c';
        cmdt5.Community_Destination_Object_Type__c = 'User';
        cmdt5.Community_Destination_API__c = 'Phone';
        CustomMetas.add(cmdt5);
        
        Community_User_Mapper__mdt cmdt6 = new Community_User_Mapper__mdt();
        cmdt6.MasterLabel = 'Company_Name';
        cmdt6.DeveloperName  = 'Company_Name';
        cmdt6.Community_Source_API__c = 'Community_Company_Name__c';
        cmdt6.Community_Destination_Object_Type__c = 'User';
        cmdt6.Community_Destination_API__c = 'CompanyName';
        CustomMetas.add(cmdt6);
        
        Community_User_Mapper__mdt cmdt7 = new Community_User_Mapper__mdt();
        cmdt7.MasterLabel = 'City';
        cmdt7.DeveloperName  = 'City';
        cmdt7.Community_Source_API__c = 'Community_City__c';
        cmdt7.Community_Destination_Object_Type__c = 'User';
        cmdt7.Community_Destination_API__c = 'City';
        CustomMetas.add(cmdt7);
        
        Community_User_Mapper__mdt cmdt8 = new Community_User_Mapper__mdt();
        cmdt8.MasterLabel = 'Job_Title';
        cmdt8.DeveloperName  = 'Job_Title';
        cmdt8.Community_Source_API__c = 'Community_Job_Title__c';
        cmdt8.Community_Destination_Object_Type__c = 'User';
        cmdt8.Community_Destination_API__c = 'Title';
        CustomMetas.add(cmdt8);
        
        Community_User_Mapper__mdt cmdt9 = new Community_User_Mapper__mdt();
        cmdt9.MasterLabel = 'First_Name';
        cmdt9.DeveloperName  = 'First_Name';
        cmdt9.Community_Source_API__c = 'Community_First_Name__c';
        cmdt9.Community_Destination_Object_Type__c = 'User';
        cmdt9.Community_Destination_API__c = 'FirstName';
        CustomMetas.add(cmdt9);
        
        Community_User_Mapper__mdt cmdt10 = new Community_User_Mapper__mdt();
        cmdt10.MasterLabel = 'State';
        cmdt10.DeveloperName     = 'State';
        cmdt10.Community_Source_API__c = 'Community_State__c';
        cmdt10.Community_Destination_Object_Type__c = 'User';
        cmdt10.Community_Destination_API__c = 'State';
        CustomMetas.add(cmdt10);
        
        Community_User_Mapper__mdt cmdt11 = new Community_User_Mapper__mdt();
        cmdt11.MasterLabel = 'Postal_Code';
        cmdt11.DeveloperName     = 'Postal_Code';
        cmdt11.Community_Source_API__c = 'Community_Zip_Code__c';
        cmdt11.Community_Destination_Object_Type__c = 'User';
        cmdt11.Community_Destination_API__c = 'PostalCode';
        CustomMetas.add(cmdt11);
        
        Community_User_Mapper__mdt cmdt12 = new Community_User_Mapper__mdt();
        cmdt12.MasterLabel = 'Last_Name';
        cmdt12.DeveloperName     = 'Last_Name';
        cmdt12.Community_Source_API__c = 'Community_Last_Name__c';
        cmdt12.Community_Destination_Object_Type__c = 'User';
        cmdt12.Community_Destination_API__c = 'LastName';
        CustomMetas.add(cmdt12);
        
        
        
        
        Community_User_Mapper__mdt cmdt22 = new Community_User_Mapper__mdt();
        cmdt22.MasterLabel = 'Community_Email__c';
        cmdt22.DeveloperName     = 'Community_Email';
        cmdt22.Community_Source_API__c = 'Community_Email__c';
        cmdt22.Community_Destination_Object_Type__c = 'Contact';
        cmdt22.Community_Destination_API__c = 'Email';
        CustomMetas.add(cmdt22);
        
        Community_User_Mapper__mdt cmdt32 = new Community_User_Mapper__mdt();
        cmdt32.MasterLabel = 'Community_Mobile_Phone__c';
        cmdt32.DeveloperName     = 'Community_Mobile_Phone';
        cmdt32.Community_Source_API__c = 'Community_Mobile_Phone__c';
        cmdt32.Community_Destination_Object_Type__c = 'Contact';
        cmdt32.Community_Destination_API__c = 'MobilePhone';
        CustomMetas.add(cmdt32);
        
        Community_User_Mapper__mdt cmdt42 = new Community_User_Mapper__mdt();
        cmdt42.MasterLabel = 'Community_Street_Address__c';
        cmdt42.DeveloperName     = 'Community_Street_Address';
        cmdt42.Community_Source_API__c = 'Community_Street_Address__c';
        cmdt42.Community_Destination_Object_Type__c = 'Contact';
        cmdt42.Community_Destination_API__c = 'MailingStreet';
        CustomMetas.add(cmdt42);
        
        Community_User_Mapper__mdt cmdt52 = new Community_User_Mapper__mdt();
        cmdt52.MasterLabel = 'Office_Phone2';
        cmdt52.DeveloperName     = 'Office_Phone2';
        cmdt52.Community_Source_API__c = 'Community_Office_Phone__c';
        cmdt52.Community_Destination_Object_Type__c = 'Contact';
        cmdt52.Community_Destination_API__c = 'Phone';
        CustomMetas.add(cmdt52);
        
        
        Community_User_Mapper__mdt cmdt72 = new Community_User_Mapper__mdt();
        cmdt72.MasterLabel = 'City';
        cmdt72.DeveloperName     = 'City';
        cmdt72.Community_Source_API__c = 'Community_City__c';
        cmdt72.Community_Destination_Object_Type__c = 'Contact';
        cmdt72.Community_Destination_API__c = 'MailingCity';
        CustomMetas.add(cmdt72);
        
        Community_User_Mapper__mdt cmdt82 = new Community_User_Mapper__mdt();
        cmdt82.MasterLabel = 'Job_Title2';
        cmdt82.DeveloperName     = 'Job_Title2';
        cmdt82.Community_Source_API__c = 'Community_Job_Title__c';
        cmdt82.Community_Destination_Object_Type__c = 'Contact';
        cmdt82.Community_Destination_API__c = 'Title';
        CustomMetas.add(cmdt82);
        
        Community_User_Mapper__mdt cmdt92 = new Community_User_Mapper__mdt();
        cmdt92.MasterLabel = 'First_Name';
        cmdt92.DeveloperName     = 'First_Name';
        cmdt92.Community_Source_API__c = 'Community_First_Name__c';
        cmdt92.Community_Destination_Object_Type__c = 'Contact';
        cmdt92.Community_Destination_API__c = 'FirstName';
        CustomMetas.add(cmdt92);
        
        Community_User_Mapper__mdt cmdt102 = new Community_User_Mapper__mdt();
        cmdt102.MasterLabel = 'State';
        cmdt102.DeveloperName    = 'State';
        cmdt102.Community_Source_API__c = 'Community_State__c';
        cmdt102.Community_Destination_Object_Type__c = 'Contact';
        cmdt102.Community_Destination_API__c = 'MailingState';
        CustomMetas.add(cmdt102);
        
        
        Community_User_Mapper__mdt cmdt122 = new Community_User_Mapper__mdt();
        cmdt122.MasterLabel = 'Last_Name';
        cmdt122.DeveloperName    = 'Last_Name';
        cmdt122.Community_Source_API__c = 'Community_Last_Name__c';
        cmdt122.Community_Destination_Object_Type__c = 'Contact';
        cmdt122.Community_Destination_API__c = 'LastName';
        CustomMetas.add(cmdt122);
        
        Community_User_Mapper__mdt cmdt123 = new Community_User_Mapper__mdt();
        cmdt123.MasterLabel = 'TimeZone';
        cmdt123.DeveloperName    = 'TimeZone';
        cmdt123.Community_Source_API__c = 'Community_Timezone__c';
        cmdt123.Community_Destination_Object_Type__c = 'User';
        cmdt123.Community_Destination_API__c = 'TimeZoneSidKey';
        CustomMetas.add(cmdt123);
        
        
        string jsonstr = JSON.serialize(CustomMetas);
        Context_Test.communityMapperData = (List<Community_User_Mapper__mdt>) JSON.deserialize(jsonstr , list<Community_User_Mapper__mdt>.class );
        
        TestUtility.setupConfigurationSettings(); 
        Trigger_Switch__c ts = new Trigger_Switch__c();
        ts.Name = 'CommunitySelfRegistrationTrigger';
        ts.Active__c = true;
        insert ts; 
        
        Service_Community_Config__c SCC = new Service_Community_Config__c();
        SCC.Community_Profile_Name__c = Label.Community_Profile_Name;
        insert SCC;
        //Account and Contact Creation
        //
       
        Id customerRecID = GlobalUtility.getRecordTypeId('Account','Customer');
        Id siteRecID = GlobalUtility.getRecordTypeId('Account','Site');
        
        Account testL2Account ;        
        testL2Account = TestUtility.newAccount('Parent Account', 'Account1');
        testL2Account.RecordTypeId = customerRecID;
        database.insert(testL2Account) ;
        
        Account testAccount ;        
        testAccount = TestUtility.newAccount('Self Registration Account', 'Account0');
        testAccount.ParentId = testL2Account.Id;
        testAccount.RecordTypeId =  siteRecID;
        database.insert(testAccount) ;
        
        Contact cont = new Contact();
        cont.FirstName='Test';
        cont.LastName='Test';
        cont.Email = 'testcontact@test.com';
        cont.Accountid= testAccount.id;
        database.insert(cont);
        
    
        // Test data setup
        Community_Self_Registration_Request__c commUserReq = new Community_Self_Registration_Request__c();
        commUserReq.Community_First_Name__c = 'FirstName';
        commUserReq.Community_Last_Name__c = 'LastName';
        commUserReq.Community_Email__c = 'test@test.com';
        commUserReq.Community_Status__c = 'Submitted';
        commUserReq.Community_Timezone__c = 'America/Chicago';
       // commUserReq.Password__c = 'Hl123456';
       commUserReq.Community_Customer_Account__c = testL2Account.Id;
       commUserReq.Community_Account__c = testAccount.Id;       
       insert commUserReq;
       
        // Perform test
        Test.startTest();
             commUserReq.Community_Status__c = 'Approved';
             commUserReq.Community_Account__c =testAccount.Id;
             update commUserReq;
             System.assertEquals(null, commUserReq.Community_Contact__c);
        Test.stopTest();
    }


}