/**************************************************************************************
Author:Vrushabh Kataria
Company:Hexaware Technologies
Description: Test Class for ServiceReportSummaryViewController class
Controller Class: ServiceReportSummaryViewController

History:
<Date>              <Author Name>        <Brief description of change >		<Copa.do US#>			
11/15/2018			Vrushabh Kataria	 Initial Creation					 US-0006170
**************************************************************************************/
@isTest
public class ServiceReportSummaryViewControllerTest {

    // Test Setup Data 
     @testSetup static void setupTestData() {
        TestUtility.setupConfigurationSettings();
        Account testAccount = TestUtility.newAccount('Account0', 'Account0');
        database.insert(testAccount) ;
            
        Contact cont = new Contact();
        cont.FirstName='ContactFirstName';
        cont.LastName='ContactLastName';
        cont.Accountid= testAccount.id;
        database.insert(cont);
            
        Profile p = [SELECT Id FROM Profile WHERE Name='Customer Community Plus Login User - Custom']; 
            
        User u = new User(Alias = 'testUser', Email='currentuser@test.com', 
        EmailEncodingKey='UTF-8', FirstName='UserFirstName',LastName='UserLastName', LanguageLocaleKey='en_US', 
        LocaleSidKey='en_US', ProfileId = p.Id, 
        TimeZoneSidKey='America/Los_Angeles', UserName='currentuser@test.com', ContactId=cont.Id);
        database.insert(u);       
    }
    
    
    /*Test method to test fucntionality of controller method -"getServiceAppointment()"*/
    @isTest
    static void testgetServiceAppointment(){
       	
		Test.startTest();
		account newAcc = [Select Id, Name from Account where Name = 'Account0'];
        contact newCon = [Select Id, Name from Contact where FirstName = 'ContactFirstName'];
        
        workOrder wo = new workorder (AccountId = newAcc.Id,ContactId= newCon.Id,Street='Street',City = 'city',PostalCode='10012',StateCode='NY',CountryCode='US');
        database.insert(wo);
        ServiceAppointment newSA = new ServiceAppointment(ParentRecordId = wo.Id, 
                                                          Related_Work_Order__c= wo.Id,
                                                          SchedStartTime = datetime.newInstance(2019, 1, 15, 10, 30, 0), 
                                                          SchedEndTime = datetime.newInstance(2019, 1, 15, 11, 30, 0));
        database.insert(newSA);
        ServiceAppointment SARec= ServiceReportSummaryViewController.getServiceAppointment(newSA.Id);
        system.assertequals(SARec.ParentRecordId,wo.Id); 
        Test.stopTest();
    }
}