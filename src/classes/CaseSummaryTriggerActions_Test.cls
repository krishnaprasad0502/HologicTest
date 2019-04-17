@isTest
private without sharing class CaseSummaryTriggerActions_Test {
	
	private static testMethod void testCreateNotesOnCases() {
		TestUtility.insertAllTriggerCustSettings();
        TestUtility.setupConfigurationSettings();
		
		//Create data
		Case cas = new Case();
        cas.Priority = 'Low';
		insert cas;
        system.debug(cas);
        
        Account acc = TestUtility.newAccount('Test Account', null);
		insert acc;
        
        List<Case> cases = new List<Case>();
        for(Integer i=0;i<=10;i++)
        {
        cases.add(TestUtility.newCase(acc.id, null, null, null, GlobalUtility.getRecordTypeId('Case', 'B_SH_Service'), 'Applications', 'New', 'Low', 'Phone'));
        //cases.add(TestUtility.newCase(a.AccountId, null, null, null, GlobalUtility.getRecordTypeId('Case', 'B_SH_Service'), 'Applications', 'New', 'Low', 'Phone'));
        }
        insert cases;
        
        Case_Summary__c caseSummary = new Case_Summary__c();
		caseSummary.Case__c = cases[0].Id;
		caseSummary.Problem_Subject__c = 'old subject';
		insert caseSummary;
		
		//Start test
		Test.startTest();
		
		//Update case summary
		caseSummary.Problem_Subject__c = 'new subject';
		update caseSummary;
		
		//Stop test
		Test.stopTest();
		
		//Validate data
		List<ContentDocumentLink> links = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :cases[0].Id];
		System.assertEquals(1, links.size());
	}
	
	private static testMethod void testUpdateAgileIntegrationString() {
		TestUtility.insertAllTriggerCustSettings();
		
		//Create data
		TestUtility.setupConfigurationSettings();
		
		Account acc = TestUtility.newAccount('Test Account', null);
		insert acc;
		
		Product2 prod = TestUtility.newProduct('Test Product');
		insert prod;
		
		Asset asst = TestUtility.newAsset('Child Asset', acc.Id, acc.Id, prod.Id);
		insert asst;
		
		WorkOrder wo = TestUtility.newWorkOrder(acc.Id, null, asst.Id, null);
		insert wo;
		
		/*Case legacyCase = new Case();
		insert legacyCase;*/
        
        List<Case> cases = new List<Case>();
        for(Integer i=0;i<=10;i++)
        {
        cases.add(TestUtility.newCase(acc.id, null, asst.id, null, GlobalUtility.getRecordTypeId('Case', 'B_SH_Service'), 'Applications', 'New', 'Low', 'Phone'));
        //cases.add(TestUtility.newCase(a.AccountId, null, null, null, GlobalUtility.getRecordTypeId('Case', 'B_SH_Service'), 'Applications', 'New', 'Low', 'Phone'));
        }
        insert cases;
        
		
		WorkOrderLineItem woli = TestUtility.newWorkOrderLineItem(wo.Id, asst.Id, GlobalUtility.getRecordTypeId('WorkOrderLineItem', 'Labor'), null);
		woli.Case__c = cases[0].Id;
		insert woli;
		
		Task tsk = new Task();
		tsk.WhatId = cases[0].Id;
		insert tsk;
		
		List<Case> cases1 = new List<Case>();
        for(Integer i=0;i<=10;i++)
        {
        cases1.add(TestUtility.newCase(acc.id, null, asst.id, null, GlobalUtility.getRecordTypeId('Case', 'B_SH_Service'), 'Applications', 'New', 'Low', 'Phone'));
        //cases.add(TestUtility.newCase(a.AccountId, null, null, null, GlobalUtility.getRecordTypeId('Case', 'B_SH_Service'), 'Applications', 'New', 'Low', 'Phone'));
        }
        insert cases1;
		
		ContentNote nte0 = new ContentNote();
		nte0.Title = 'Test Note';
		insert nte0;
		
		ContentNote nte1 = new ContentNote();
		nte1.Title = 'Test Note';
		insert nte1;
		
		ContentDocumentLink link0 = new ContentDocumentLink();
		link0.ContentDocumentId = nte0.Id;
		link0.LinkedEntityId = cases[0].Id;
		link0.ShareType = 'V';
		insert link0;
		
		ContentDocumentLink link1 = new ContentDocumentLink();
		link1.ContentDocumentId = nte1.Id;
		link1.LinkedEntityId = cases[0].Id;
		link1.ShareType = 'V';
		insert link1;
		
		List<Case_Summary__c> caseSummaries = new List<Case_Summary__c>();
		
		Case_Summary__c legacyCaseSummary = new Case_Summary__c();
		legacyCaseSummary.Case__c = cases[0].Id;
		legacyCaseSummary.Include_History__c = true;
		legacyCaseSummary.Problem_Subject__c = 'test subject';
		caseSummaries.add(legacyCaseSummary);
		
		Case_Summary__c standardCaseSummary = new Case_Summary__c();
		standardCaseSummary.Case__c = cases1[0].Id;
		standardCaseSummary.Include_History__c = false;
		standardCaseSummary.Problem_Subject__c = 'test subject';
		caseSummaries.add(standardCaseSummary);
		
		//Start test
		Test.startTest();
		
		//Insert case note
		insert caseSummaries;
		
		//Stop test
		Test.stopTest();
		
		//Validate data
		legacyCaseSummary =
			[SELECT Id, Quality_Integration_String__c
			   FROM Case_Summary__c
			  WHERE Id = :legacyCaseSummary.Id
			];
		System.assertNotEquals(null, legacyCaseSummary.Quality_Integration_String__c);
		
		standardCaseSummary =
			[SELECT Id, Quality_Integration_String__c
			   FROM Case_Summary__c
			  WHERE Id = :standardCaseSummary.Id
			];
		//System.assertNotEquals(null, standardCaseSummary.Quality_Integration_String__c);
	}

}