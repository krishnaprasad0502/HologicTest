/**************************************************************************************
Author:Sunil Kumar Sharma
Company:Hexaware Technologies
Description: Test Class for DynamicObjectSummaryViewController class
Controller Class: DynamicObjectSummaryViewController

History:
<Date>              <Author Name>        <Brief description of change >     <Copa.do US#>           
09-21-2018          Sunil Kumar Sharma   Initial Creation                   US-0005701 
**************************************************************************************/
@isTest
private without sharing class DynamicObjectSummaryViewController_Test{
    @testSetup static void setupTestData() {
        TestUtility.insertAllTriggerCustSettings();
        TestUtility.setupConfigurationSettings();
    
        //Create data
        Case caseRec = new Case();
        caseRec.Priority = 'Low';
        database.insert(caseRec) ;
        
        Account acc = TestUtility.newAccount('Test Account', null);
        database.insert(acc) ;
        
        List<Case> cases = new List<Case>();
        
        Case_Summary__c caseSummary = new Case_Summary__c();
        caseSummary.Case__c = caseRec.Id;
        caseSummary.Problem_Subject__c = 'old subject';
        database.insert(caseSummary) ;
    }
    
    @isTest static void testReadFieldSet(){
        
        Test.startTest();
            List<String> fieldList = DynamicObjectSummaryViewController.readFieldSet('CommunityCaseSummaryFields','Case_Summary__c');
            system.assertEquals(2, fieldList.size(), 'Returned size of case summary field set is not matching with expected value.');
        Test.stopTest();
    }
    
    @isTest static void testgetRelatedObjectIdReturnSuccess(){
        List<Case> caseList = new List<Case> ([Select id from Case where Priority = 'Low']);
        List<Case_Summary__c> caseSummaryList = new List<Case_Summary__c>([SELECT id FROM Case_Summary__c where case__c =:caseList[0].Id]);
        Test.startTest();
            String caseSummaryRecId = DynamicObjectSummaryViewController.getRelatedObjectId(caseList[0].Id,'Case_Summary__c','Case__c');
            system.assertEquals(caseSummaryList[0].Id, caseSummaryRecId, 'Returned id of case summary record is not matching with expected value.');
        Test.stopTest();
    }  
    
    @isTest static void testgetRelatedObjectIdReturnFailure(){
        List<Case> caseList = new List<Case> ([Select id from Case where Priority = 'Low']);
        Test.startTest();
            String caseSummaryRecId = DynamicObjectSummaryViewController.getRelatedObjectId('5004D000005rLVg','Case_Summary__c','Case__c');
            system.assertEquals(null, caseSummaryRecId, 'Returned id of case summary record is not matching with expected value.');
        Test.stopTest();
    }  
    
    @isTest static void testgetParentObjectIdReturnFailure(){
        List<Case> caseList = new List<Case> ([Select id from Case where Priority = 'Low']);
        List<Case_Summary__c> caseSummaryList = new List<Case_Summary__c>([SELECT id FROM Case_Summary__c where case__c =:caseList[0].Id]);
        Test.startTest();
            String caseSummaryRecId = DynamicObjectSummaryViewController.getParentObjectId('5004D000005rLVg','Case','Case_Summary__c');
            system.assertEquals(null, caseSummaryRecId, 'Returned id of case summary record is not matching with expected value.');
        Test.stopTest();
    }  
    
    @isTest static void testgetParentObjectIdReturnSuccess(){
        List<Case> caseList = new List<Case> ([Select id,Service_Appointment__c from Case where Priority = 'Low']);
        List<Case_Summary__c> caseSummaryList = new List<Case_Summary__c>([SELECT id FROM Case_Summary__c where case__c =:caseList[0].Id]);
        Test.startTest();
            String caseSummaryRecId = DynamicObjectSummaryViewController.getParentObjectId(caseList[0].Id,'Case','Service_Appointment__c');
            system.assertEquals(caseList[0].Service_Appointment__c, caseSummaryRecId, 'Returned id of case summary record is not matching with expected value.');
        Test.stopTest();
    }  
}