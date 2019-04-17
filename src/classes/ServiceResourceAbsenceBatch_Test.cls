@isTest
private class ServiceResourceAbsenceBatch_Test {

	private static testMethod void testServiceResourceAbsenceBatch_Before() {
		//Create test data
        TestUtility.setupConfigurationSettings();
        
        Account acc = TestUtility.newAccount('Test Account', null);
        insert acc;
        
        Product2 prod = TestUtility.newProduct('Test Product');
        insert prod;
        
        Asset asst = TestUtility.newAsset('Asset', acc.Id, acc.Id, prod.Id);
        insert asst;
        
        Id profId = UserInfo.getProfileId();//[SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id;
        
        User use = TestUtility.newUser(profId, 'TestUser');
        insert use;
        
        ServiceResource sr = new ServiceResource();
        sr.Name = 'Test SR';
        sr.RelatedRecordId = use.Id;
        sr.IsActive = true;
        insert sr;
        
        ResourceAbsence ra = new ResourceAbsence();
        ra.ResourceId = sr.Id;
        ra.Start = DateTime.now().addMinutes(60);
        ra.End = DateTime.now().addMinutes(120);
        ra.FSL__Approved__c = true;
        insert ra;
        
        //Start test
        Test.startTest();
        
        //Process batch
        ServiceResourceAbsenceBatch batch = new ServiceResourceAbsenceBatch();
		Database.executeBatch(batch, 200);
        
        //Stop test
        Test.stopTest();
        
        //Validate data
        sr = [SELECT Id, Absent__c FROM ServiceResource WHERE Id = :sr.Id];
        System.assertEquals(false, sr.Absent__c);
        
        //Call scheduler for coverage
        System.schedule('arbitraryNameAndDate', '0 0 0 31 3 ? 2027', new ServiceResourceAbsenceBatchScheduler());
	}

	private static testMethod void testServiceResourceAbsenceBatch_During() {
		//Create test data
        TestUtility.setupConfigurationSettings();
        
        Account acc = TestUtility.newAccount('Test Account', null);
        insert acc;
        
        Product2 prod = TestUtility.newProduct('Test Product');
        insert prod;
        
        Asset asst = TestUtility.newAsset('Asset', acc.Id, acc.Id, prod.Id);
        insert asst;
        
        Id profId = UserInfo.getProfileId();//[SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id;
        
        User use = TestUtility.newUser(profId, 'TestUser');
        insert use;
        
        ServiceResource sr = new ServiceResource();
        sr.Name = 'Test SR';
        sr.RelatedRecordId = use.Id;
        sr.IsActive = true;
        insert sr;
        
        ResourceAbsence ra = new ResourceAbsence();
        ra.ResourceId = sr.Id;
        ra.Start = DateTime.now().addMinutes(0);
        ra.End = DateTime.now().addMinutes(240);
        ra.FSL__Approved__c = true;
        insert ra;
        
        //Start test
        Test.startTest();
        
        //Process batch
        ServiceResourceAbsenceBatch batch = new ServiceResourceAbsenceBatch();
		Database.executeBatch(batch, 200);
        
        //Stop test
        Test.stopTest();
        
        //Validate data
        sr = [SELECT Id, Absent__c FROM ServiceResource WHERE Id = :sr.Id];
        System.assertEquals(true, sr.Absent__c);
        
        //Call scheduler for coverage
        System.schedule('arbitraryNameAndDate', '0 0 0 31 3 ? 2027', new ServiceResourceAbsenceBatchScheduler());
	}

	private static testMethod void testServiceResourceAbsenceBatch_After() {
		//Create test data
        TestUtility.setupConfigurationSettings();
        
        Account acc = TestUtility.newAccount('Test Account', null);
        insert acc;
        
        Product2 prod = TestUtility.newProduct('Test Product');
        insert prod;
        
        Asset asst = TestUtility.newAsset('Asset', acc.Id, acc.Id, prod.Id);
        insert asst;
        
        Id profId = UserInfo.getProfileId();//[SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id;
        
        User use = TestUtility.newUser(profId, 'TestUser');
        insert use;
        
        ServiceResource sr = new ServiceResource();
        sr.Name = 'Test SR';
        sr.RelatedRecordId = use.Id;
        sr.IsActive = true;
        sr.Absent__c = true;
        insert sr;
        
        ResourceAbsence ra = new ResourceAbsence();
        ra.ResourceId = sr.Id;
        ra.Start = DateTime.now().addMinutes(-240);
        ra.End = DateTime.now().addMinutes(-60);
        ra.FSL__Approved__c = true;
        insert ra;
        
        //Start test
        Test.startTest();
        
        //Process batch
        ServiceResourceAbsenceBatch batch = new ServiceResourceAbsenceBatch();
		Database.executeBatch(batch, 200);
        
        //Stop test
        Test.stopTest();
        
        //Validate data
        sr = [SELECT Id, Absent__c FROM ServiceResource WHERE Id = :sr.Id];
        System.assertEquals(false, sr.Absent__c);
        
        //Call scheduler for coverage
        System.schedule('arbitraryNameAndDate', '0 0 0 31 3 ? 2027', new ServiceResourceAbsenceBatchScheduler());
	}

	private static testMethod void testServiceResourceAbsenceBatch_WayAfter() {
		//Create test data
        TestUtility.setupConfigurationSettings();
        
        Account acc = TestUtility.newAccount('Test Account', null);
        insert acc;
        
        Product2 prod = TestUtility.newProduct('Test Product');
        insert prod;
        
        Asset asst = TestUtility.newAsset('Asset', acc.Id, acc.Id, prod.Id);
        insert asst;
        
        Id profId = UserInfo.getProfileId();//[SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id;
        
        User use = TestUtility.newUser(profId, 'TestUser');
        insert use;
        
        ServiceResource sr = new ServiceResource();
        sr.Name = 'Test SR';
        sr.RelatedRecordId = use.Id;
        sr.IsActive = true;
        sr.Absent__c = false;
        insert sr;
        
        ResourceAbsence ra = new ResourceAbsence();
        ra.ResourceId = sr.Id;
        ra.Start = DateTime.now().addMinutes(-240);
        ra.End = DateTime.now().addMinutes(240);
        ra.FSL__Approved__c = true;
        insert ra;
        
        //Start test
        Test.startTest();
        
        //Process batch
        ServiceResourceAbsenceBatch batch = new ServiceResourceAbsenceBatch();
		Database.executeBatch(batch, 200);
        
        //Stop test
        Test.stopTest();
        
        //Validate data
        sr = [SELECT Id, Absent__c FROM ServiceResource WHERE Id = :sr.Id];
        System.assertEquals(true, sr.Absent__c);
        
        //Call scheduler for coverage
        System.schedule('arbitraryNameAndDate', '0 0 0 31 3 ? 2027', new ServiceResourceAbsenceBatchScheduler());
	}

}