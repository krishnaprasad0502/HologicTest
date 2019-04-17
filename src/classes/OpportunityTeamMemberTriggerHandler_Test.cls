/*------------------------------------------------------------
Author:     Dinesh Mummidi
Description:  Test class for  OpportunityTeamMemberTriggerHandler.
Test Class:    OpportunityTeamMemberTriggerHandler_Test

History:
<Date>      <Authors Name>    <Brief Description of Change>
06/29/2018  Dinesh Mummidi    Initial Creation (HD-)
06/29/2018  Dinesh Mummidi    Created Test Class for OpportunityTeamMemberTriggerHandler
06/29/2018  Dinesh Mummidi    Inititated Testing for Opportunity by record type ID of 'Medical Aesthetics Capital Sales Opportunity'
06/29/2018  Dinesh Mummidi    User is inserted,Trigger switch is activated and inserted a member in Opportunity Team member.
06/29/2018  Dinesh Mummidi    After test is succesfully excuted insert Opportunity Split member  

------------------------------------------------------------*/
@isTest
public class OpportunityTeamMemberTriggerHandler_Test {
    
    static testMethod void opptyTeamMemberTest(){
        TestUtility.setupConfigurationSettings();
        
        TestUtility.insertCustSetting('sitelocTrigger');
        
        List<Trigger_Switch__c> tsList = new List<Trigger_Switch__c>();
        
        Trigger_Switch__c ts = new Trigger_Switch__c();
        ts.Name = 'OpportunityTrigger';
        ts.Active__c = true;
        tsList.add(ts);
        
        
        Trigger_Switch__c ts1 = new Trigger_Switch__c();
        ts1.Name = 'OpportunityTeamMemberTrigger';
        ts1.Active__c = true;
        tsList.add(ts1);
        
        insert tsList;
        
        Profile p = [SELECT Id FROM Profile WHERE Name='Medical Aesthetics Sales Admin'];
        
        User u1 = TestUtility.newUser(p.Id,'Test') ;
        insert u1;
        
        Account custAcc = TestUtility.newAccount('Test Customer Account','');
        insert custAcc;
        
        Opportunity opp = TestUtility.newOpportunity('Test Opportunity',custAcc.Id,date.today(),'Close','Expected');
        opp.RecordTypeId = (Id)(String.valueOf(GlobalUtility.getRecordTypeId('Opportunity','Medical_Aesthetics_Capital_Sales_Opportunity')).substring(0,15));
        insert opp;
        
        Test.startTest();
        OpportunityTeamMember oppTeamMem = new OpportunityTeamMember(OpportunityId = opp.id, UserId = u1.Id, TeamMemberRole ='Account Manager',OpportunityAccessLevel = 'Edit');
        insert oppTeamMem;
        Test.stopTest();
        
        List<OpportunitySplit> osList = [SELECT Id, Split from OpportunitySplit where OpportunityId = :opp.Id];
        System.assertNotEquals(osList.size(),0);
        
    }
}