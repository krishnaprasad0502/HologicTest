/**********************************************************************************************************************
    Author 		 : Nikhil Mutyam
    Company 	 : Hexaware Technologies
	Created Date : 8/13/2018 7:30 AM
    Description  : Test Class for Box_EmbedRecordDetailController    

    History:
    <Date>         	<Author Name>       	<Brief Description of Change> 	<Copa.do US#>
	10/9/2018 	    Nikhil Mutyam			Initial Creation				US-0005861
	22/11/2018 	    Nikhil Mutyam			Versioning						US-0006168
**********************************************************************************************************************/
@isTest
public class Box_EmbedRecordDetailController_Test {
    public static Id accountSiteRecordTypeId = GlobalUtility.getRecordTypeId('Account', 'Site');
    
    public static testMethod void testFetchBoxDetails(){
		list<Box_Auth__c> Credentials = new list<Box_Auth__c>();
        Credentials = TestUtility.getBoxCredentials(1);
        database.insert(Credentials);
        system.debug('The Cases are: '+Credentials);
        
        list<Knowledge__kav> Articles = new list<Knowledge__kav>();
        Articles = TestUtility.getArticles(2);
        database.insert(Articles);
        system.debug('The Articles are: '+Articles);
        
        list<Box_Mapper__c> Mappers = new list<Box_Mapper__c>();
        Mappers = TestUtility.getBoxArticleMappers(1,Articles[0].Id);
        database.insert(Mappers);
        system.debug('The Cases are: '+Mappers);
        
        test.startTest();
        	Box_EmbedRecordDetailController BERDC = new Box_EmbedRecordDetailController();
        	BERDC.FetchBoxDetails();
        	list<Knowledge__kav> KArticles = new list<Knowledge__kav>();
        	
        
        	Apexpages.currentPage().getParameters().put('Id',Articles[0].Id);
        	Box_EmbedRecordDetailController BERDC2 = new Box_EmbedRecordDetailController();
        	BERDC2.FetchBoxDetails();
        	
        	Mappers[0].Folder_ID__c = 'Tst Folder Id';
        	update Mappers[0];

        	Apexpages.currentPage().getParameters().put('Id',Articles[0].Id);
        	Box_EmbedRecordDetailController BERDC3 = new Box_EmbedRecordDetailController();
        	BERDC3.FetchBoxDetails();
        	Box_EmbedRecordDetailController.sendException(123,'Test Exception Message');
		test.stopTest();        
    }
    
    public static testMethod void testFetchBoxDetails_CommUser(){
    	UserRole portalRole = [SELECT Id FROM UserRole WHERE PortalType = 'None' Limit 1];
        Profile profile1 = [SELECT Id FROM Profile WHERE name = 'System Administrator'];
        User Admin = new User(
            UserRoleId = portalRole.Id,
            ProfileId = profile1.Id,
            Username = System.now().millisecond() +'HealthAdmin@test.test',
            Alias = 'batman',
            Email='bruce.wayne@wayneenterprises.com',
            EmailEncodingKey='UTF-8',
            Firstname='FirstName',
            Lastname='LastName',
            LanguageLocaleKey='en_US',
            LocaleSidKey='en_US',
            TimeZoneSidKey='America/Chicago'
        );
        Database.insert(Admin);
        
        list<Account> Accounts = new list<Account>();
        list<Contact> Contacts = new list<Contact>();
        list<Box_Auth__c> Credentials = new list<Box_Auth__c>();
        list<Knowledge__kav> Articles = new list<Knowledge__kav>();
        list<Box_Mapper__c> Mappers = new list<Box_Mapper__c>();
        system.runAs(Admin){
            TestUtility.setupConfigurationSettings();   
            Trigger_Switch__c ts = new Trigger_Switch__c();
            ts.Name = 'AccountContactRelationTrigger';
            ts.Active__c = true;
            insert ts;
            
            //Create test Account record
            Account acc1 = TestUtility.newAccount('Test Account1',null);
            acc1.recordTypeId = accountSiteRecordTypeId;
            Account acc2 = TestUtility.newAccount('Test Account1',null);
            Accounts.add(acc1);
            Accounts.add(acc2);
            database.insert(Accounts);
           
            Contacts = TestUtility.getContacts(2);
            Contacts[0].AccountId = Accounts[0].Id;
            Contacts[1].AccountId = Accounts[1].Id;
            database.insert(Contacts);
            
	        Credentials = TestUtility.getBoxCredentials(1);
	        database.insert(Credentials);
	        system.debug('The Cases are: '+Credentials);
	        
	        Articles = TestUtility.getArticles(2);
	        database.insert(Articles);
	        system.debug('The Articles are: '+Articles);
	        
	        Mappers = TestUtility.getBoxArticleMappers(1,Articles[0].Id);
	        database.insert(Mappers);
	        system.debug('The Cases are: '+Mappers);
        
    	}
    	
    	Profile profile2 = [SELECT Id FROM Profile WHERE name =: Label.Community_Profile_Name];
        User Customer1 = new User(
            ProfileId = profile2.Id,
            Username = System.now().millisecond() +'HealthAdmin@test.test',
            Alias = 'batman',
            Email='bruce.wayne@wayneenterprises.com',
            EmailEncodingKey='UTF-8',
            Firstname='FirstName',
            Lastname='LastName',
            LanguageLocaleKey='en_US',
            LocaleSidKey='en_US',
            TimeZoneSidKey='America/Chicago',
            ContactId = Contacts[0].Id    
        );
        Database.insert(Customer1);
        
        system.runAs(Customer1){
        	Box_EmbedRecordDetailController BERDC = new Box_EmbedRecordDetailController();
        	BERDC.FetchBoxDetails();
        	list<Knowledge__kav> KArticles = new list<Knowledge__kav>();
        	
        
        	Apexpages.currentPage().getParameters().put('Id',Articles[0].Id);
        	Box_EmbedRecordDetailController BERDC2 = new Box_EmbedRecordDetailController();
        	BERDC2.FetchBoxDetails();
        	
        	Mappers[0].Folder_ID__c = 'Tst Folder Id';
        	update Mappers[0];

        	Apexpages.currentPage().getParameters().put('Id',Articles[0].Id);
        	Box_EmbedRecordDetailController BERDC3 = new Box_EmbedRecordDetailController();
        	BERDC3.FetchBoxDetails();
        	Box_EmbedRecordDetailController.sendException(123,'Test Exception Message');
            
            Box_Auth__c BA1 = new Box_Auth__c();
            BERDC3.CreateFolder('Test Id',BA1);         
        }
    }

}