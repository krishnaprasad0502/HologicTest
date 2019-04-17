@isTest(seeAllData=true)
private class MARE_SaveRecords_TestMethods
{
    private static testMethod void test1()
    {
        Swarm_Territory__c st = [SELECT Id FROM Swarm_Territory__c LIMIT 1];
        
        Async_MARE_Job__c amj = new Async_MARE_Job__c();
        amj.Swarm_Name__c = 'Test Swarm';
        amj.Swarm_Territory__c = st.Id;
        amj.Job_Status__c = 'Accepted';
        amj.MARE_Job_Id__c = 'mare-us-west-2-routing-32-1543606185.72292-232';
        amj.Submitted_By__c = UserInfo.getUserId();
        insert amj;
        
        Lead l = [SELECT Id FROM Lead WHERE MALatitude__c != null AND MALongitude__c != null LIMIT 1];
        Contact c = [SELECT Id FROM Contact WHERE Account.MALatitude__c != null AND Account.MALongitude__c != null LIMIT 1];
        CampaignMember m = [SELECT Id FROM CampaignMember WHERE MALatitude__c != null AND MALongitude__c != null LIMIT 1];
        
        list<string> RecordIds = new list<string>();
        RecordIds.add(l.Id);
        RecordIds.add(c.Id);
        RecordIds.add(m.Id);

        Test.startTest();
            System.enqueueJob(new MARE_SaveRecords(amj.Id, RecordIds , 1));
        Test.stopTest();
    }              
}